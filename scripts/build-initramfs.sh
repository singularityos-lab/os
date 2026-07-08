#!/usr/bin/env bash
#
# Build the initramfs for the immutable verity boot.
#
# The initramfs discovers the data and hash partitions by GPT PARTLABEL
# (sing-root and sing-hash), opens the dm-verity device with veritysetup using
# the root hash passed on the kernel command line (sing.roothash=), mounts the
# verified erofs read-only and overlays a tmpfs for the writable layer.
#
# Usage: scripts/build-initramfs.sh <target_dir> <output_cpio_xz>

set -euo pipefail

TARGET_DIR="$1"
OUT="$2"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK"/{bin,sbin,proc,sys,dev,sysroot,lower,over,lib,lib64,run,etc} \
         "$WORK"/usr/{bin,sbin,lib,lib64}

READELF="$(command -v x86_64-buildroot-linux-gnu-readelf || command -v readelf)"

# Copy a binary from the target (searching the usual bin dirs) into the same
# relative path in the initramfs.
copy_bin() {
	local name="$1" dest="$2"
	for d in sbin usr/sbin bin usr/bin; do
		if [ -e "$TARGET_DIR/$d/$name" ]; then
			cp -aL "$TARGET_DIR/$d/$name" "$WORK/$dest/$name"
			return 0
		fi
	done
	echo "build-initramfs: $name not found in target" >&2
	return 1
}

find_lib() {
	for d in lib lib64 usr/lib usr/lib64; do
		[ -e "$TARGET_DIR/$d/$1" ] && { echo "$TARGET_DIR/$d/$1"; return 0; }
	done
	return 1
}

# Recursively copy the shared-library closure (interpreter + DT_NEEDED) of every
# ELF already staged, until no new library appears.
resolve_libs() {
	local prev=-1 now elf need src
	while :; do
		while IFS= read -r elf; do
			{ "$READELF" -l "$elf" 2>/dev/null | sed -n 's/.*interpreter: \(.*\)\]/\1/p'
			  "$READELF" -d "$elf" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p'
			} | while IFS= read -r need; do
				need="${need##*/}"
				[ -e "$WORK/lib/$need" ] && continue
				src="$(find_lib "$need")" || continue
				cp -aL "$src" "$WORK/lib/$need"
			done
		done < <(find "$WORK/bin" "$WORK/sbin" "$WORK/usr" "$WORK/lib" -type f 2>/dev/null \
			| while IFS= read -r f; do file -b "$f" 2>/dev/null | grep -q ELF && echo "$f"; done)
		now="$(find "$WORK/lib" -type f | wc -l)"
		[ "$now" = "$prev" ] && break
		prev="$now"
	done
}

# busybox and the tools the init needs.
copy_bin busybox bin
copy_bin veritysetup sbin

# Kernel modules for the persistent /var (ext4 is a module in the Sinty kernel).
KVER="$(basename "$(ls -d "$TARGET_DIR"/lib/modules/*/ 2>/dev/null | head -1)")"
if [ -n "$KVER" ]; then
	mkdir -p "$WORK/lib/modules/$KVER"
	for mod in crc16 mbcache jbd2 ext4; do
		ko="$(find "$TARGET_DIR/lib/modules/$KVER" \( -name "$mod.ko" -o -name "$mod.ko.*" \) 2>/dev/null | head -1)"
		[ -n "$ko" ] || continue
		case "$ko" in
			*.zst) zstd -dqf "$ko" -o "$WORK/lib/modules/$KVER/$mod.ko" 2>/dev/null ;;
			*.xz)  xz -dc "$ko" > "$WORK/lib/modules/$KVER/$mod.ko" 2>/dev/null ;;
			*.gz)  gzip -dc "$ko" > "$WORK/lib/modules/$KVER/$mod.ko" 2>/dev/null ;;
			*)     cp "$ko" "$WORK/lib/modules/$KVER/$mod.ko" ;;
		esac
	done
fi

resolve_libs

# The glibc loader searches /lib64, /usr/lib and /usr/lib64; mirror the closure.
cp -a "$WORK/lib/." "$WORK/lib64/"
cp -a "$WORK/lib/." "$WORK/usr/lib/"
cp -a "$WORK/lib/." "$WORK/usr/lib64/"

for applet in sh mount switch_root sleep mkdir mknod cat blkid dd; do
	ln -sf busybox "$WORK/bin/$applet"
done

cat > "$WORK/init" <<'INIT'
#!/bin/busybox sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export DM_DISABLE_UDEV=1
busybox mount -t proc     proc /proc
busybox mount -t sysfs    sys  /sys
busybox mount -t devtmpfs dev  /dev
busybox mkdir -p /dev/mapper /run/cryptsetup

rescue() {
	echo "initramfs: $1" >&2
	# Module-independent capture: raw-write the diagnostic to the 4th partition of the
	# removable disk (the USB SINTYLOGS), at a fixed offset, so it can be read back even
	# if ext4 won't mount. Marker SINTYRESCUE makes it greppable in the raw device.
	_diag="SINTYRESCUE_BEGIN
reason: $1
cmdline: $(busybox cat /proc/cmdline)
roothash=$ROOTHASH
DATAS=$DATAS HASHES=$HASHES DATA=$DATA HASH=$HASH VAR=$VAR
block: $(busybox ls /dev/vd* /dev/sd* /dev/nvme* /dev/mmcblk* 2>/dev/null | busybox tr '\n' ' ')
dmesg_tail:
$(busybox dmesg | busybox tail -30)
SINTYRESCUE_END
"
	for _p in /dev/sda4 /dev/sdb4 /dev/sdc4 /dev/mmcblk0p4; do
		[ -b "$_p" ] || continue
		printf '%s' "$_diag" | busybox dd of="$_p" bs=512 seek=200 conv=notrunc 2>/dev/null
		busybox sync
		break
	done
	echo "dropping to a rescue shell" >&2
	exec busybox sh
}

# device-mapper control node (no udev in the initramfs to create it).
if [ ! -e /dev/mapper/control ]; then
	mm=$(busybox cat /sys/class/misc/device-mapper/dev 2>/dev/null)
	[ -n "$mm" ] && busybox mknod /dev/mapper/control c "${mm%:*}" "${mm#*:}"
fi

# Load ext4 early so rescue() can mount SINTYLOGS to auto-capture, and /var later.
for m in crc16 mbcache jbd2 ext4; do
	ko=$(busybox find /lib/modules -name "$m.ko" 2>/dev/null | busybox head -n1)
	[ -n "$ko" ] && busybox insmod "$ko" 2>/dev/null
done

ROOTHASH=
CMDINIT=
for tok in $(busybox cat /proc/cmdline); do
	case "$tok" in
		sing.roothash=*) ROOTHASH=${tok#sing.roothash=} ;;
		init=*) CMDINIT=${tok#init=} ;;
	esac
done
[ -n "$ROOTHASH" ] || rescue "no sing.roothash= on the kernel command line"

# Collect ALL erofs data + dm-verity hash partitions -- there can be several (a USB
# stick AND an already-installed disk) -- then verity-open the pair whose hash matches
# the baked sing.roothash. This picks the correct rootfs regardless of extra installs.
DATA= ; HASH= ; DATAS= ; HASHES= ; i=0
while [ $i -lt 75 ]; do
	DATAS= ; HASHES=
	for d in /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
		[ -b "$d" ] || continue
		if [ "$(busybox dd if="$d" bs=6 count=1 2>/dev/null)" = "verity" ]; then
			HASHES="$HASHES $d"; continue
		fi
		m=$(busybox dd if="$d" bs=1 skip=1024 count=4 2>/dev/null | busybox od -An -tx1 | busybox tr -d ' \n')
		[ "$m" = "e2e1f5e0" ] && DATAS="$DATAS $d"
	done
	for _dt in $DATAS; do
		for _hs in $HASHES; do
			veritysetup close vroot 2>/dev/null
			veritysetup open "$_dt" vroot "$_hs" "$ROOTHASH" 2>/dev/null || continue
			vm=$(busybox dd if=/dev/mapper/vroot bs=1 skip=1024 count=4 2>/dev/null | busybox od -An -tx1 | busybox tr -d ' \n')
			if [ "$vm" = "e2e1f5e0" ]; then
				DATA="$_dt"; HASH="$_hs"; break
			fi
			veritysetup close vroot 2>/dev/null
		done
		[ -n "$DATA" ] && break
	done
	[ -n "$DATA" ] && break
	busybox sleep 0.2; i=$((i + 1))
done
[ -n "$DATA" ] || rescue "no verified data/hash pair for sing.roothash (data:$DATAS hash:$HASHES)"

busybox mkdir -p /varprobe
# /var must live on the SAME physical disk as the verified root erofs. Otherwise a live/
# installer boot scans every disk and mounts an internal disk's /var (another install's
# user data) into the live session -- a data-exposure bypass.
_parentdisk() {
	_pp=$(busybox basename "$1")
	busybox basename "$(busybox readlink -f "/sys/class/block/$_pp/.." 2>/dev/null)"
}
ROOTDISK=$(_parentdisk "$DATA")
VAR=
for d in /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
	[ -b "$d" ] || continue
	[ "$d" = "$DATA" ] && continue
	[ "$d" = "$HASH" ] && continue
	[ "$(_parentdisk "$d")" = "$ROOTDISK" ] || continue
	{ busybox mount -t f2fs "$d" /varprobe 2>/dev/null || busybox mount -t ext4 "$d" /varprobe 2>/dev/null; } || continue
	if [ -e /varprobe/.atom-var ]; then VAR="$d"; busybox umount /varprobe; break; fi
	busybox umount /varprobe 2>/dev/null
done

if [ -n "$VAR" ]; then
	busybox mount -t erofs -o ro /dev/mapper/vroot /sysroot || rescue "cannot mount erofs root"
	{ busybox mount -t f2fs "$VAR" /sysroot/var || busybox mount -t ext4 "$VAR" /sysroot/var; } || rescue "cannot mount /var"
	busybox echo "[init] persistent /var: $VAR ($(busybox awk '$2=="/sysroot/var"{print $3}' /proc/mounts)) same disk as root"
	busybox mkdir -p /sysroot/var/etc-upper /sysroot/var/etc-work /sysroot/var/home
	busybox mount -t overlay overlay \
	    -o lowerdir=/sysroot/etc,upperdir=/sysroot/var/etc-upper,workdir=/sysroot/var/etc-work /sysroot/etc || true
	busybox mount -t tmpfs -o mode=1777 tmpfs /sysroot/tmp || true
	busybox mount -o bind /sysroot/var/home /sysroot/home || true
else
	busybox mount -t erofs -o ro /dev/mapper/vroot /lower || rescue "cannot mount erofs root"
	busybox mount -t tmpfs -o mode=0755 tmpfs /over || rescue "cannot mount tmpfs"
	busybox mkdir -p /over/upper /over/work
	busybox mount -t overlay overlay \
	    -o lowerdir=/lower,upperdir=/over/upper,workdir=/over/work /sysroot \
	    || rescue "cannot mount overlay root"
fi
INIT=
if [ -n "$CMDINIT" ] && [ -x "/sysroot$CMDINIT" ]; then
	INIT="$CMDINIT"
else
	for cand in /sbin/init /usr/lib/sinit/sinit; do
		[ -x "/sysroot$cand" ] && { INIT="$cand"; break; }
	done
fi
[ -n "$INIT" ] || rescue "no init found in root"

exec busybox switch_root /sysroot "$INIT"
INIT
chmod +x "$WORK/init"

mkdir -p "$(dirname "$OUT")"
( cd "$WORK" && find . | cpio -o -H newc --quiet | xz -9 --check=crc32 ) > "$OUT"
echo "[initramfs] wrote $OUT ($(du -sh "$OUT" | cut -f1))"
