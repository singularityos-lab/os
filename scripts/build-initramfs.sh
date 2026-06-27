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
	echo "dropping to a rescue shell" >&2
	exec busybox sh
}

# device-mapper control node (no udev in the initramfs to create it).
if [ ! -e /dev/mapper/control ]; then
	mm=$(busybox cat /sys/class/misc/device-mapper/dev 2>/dev/null)
	[ -n "$mm" ] && busybox mknod /dev/mapper/control c "${mm%:*}" "${mm#*:}"
fi

ROOTHASH=
for tok in $(busybox cat /proc/cmdline); do
	case "$tok" in sing.roothash=*) ROOTHASH=${tok#sing.roothash=} ;; esac
done
[ -n "$ROOTHASH" ] || rescue "no sing.roothash= on the kernel command line"

# Identify the data partition by its erofs filesystem and the hash partition by
# the dm-verity superblock magic ("verity"), scanning only partition nodes.
DATA= ; HASH= ; i=0
while [ $i -lt 50 ]; do
	for d in /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
		[ -b "$d" ] || continue
		if [ -z "$HASH" ] && [ "$(busybox dd if="$d" bs=6 count=1 2>/dev/null)" = "verity" ]; then
			HASH="$d"; continue
		fi
		if [ -z "$DATA" ]; then
			m=$(busybox dd if="$d" bs=1 skip=1024 count=4 2>/dev/null | busybox od -An -tx1 | busybox tr -d ' \n')
			[ "$m" = "e2e1f5e0" ] && DATA="$d"
		fi
	done
	[ -n "$DATA" ] && [ -n "$HASH" ] && break
	busybox sleep 0.2; i=$((i + 1))
done
[ -n "$DATA" ] || rescue "erofs data partition not found"
[ -n "$HASH" ] || rescue "dm-verity hash partition not found"

veritysetup open "$DATA" vroot "$HASH" "$ROOTHASH" || rescue "veritysetup open failed"

busybox mount -t erofs -o ro /dev/mapper/vroot /lower || rescue "cannot mount erofs root"
busybox mount -t tmpfs -o mode=0755 tmpfs /over || rescue "cannot mount tmpfs"
busybox mkdir -p /over/upper /over/work
busybox mount -t overlay overlay \
    -o lowerdir=/lower,upperdir=/over/upper,workdir=/over/work /sysroot \
    || rescue "cannot mount overlay root"
INIT=
for cand in /sbin/init /usr/lib/systemd/systemd /lib/systemd/systemd; do
	[ -x "/sysroot$cand" ] && { INIT="$cand"; break; }
done
[ -n "$INIT" ] || rescue "no init found in root"

exec busybox switch_root /sysroot "$INIT"
INIT
chmod +x "$WORK/init"

mkdir -p "$(dirname "$OUT")"
( cd "$WORK" && find . | cpio -o -H newc --quiet | xz -9 --check=crc32 ) > "$OUT"
echo "[initramfs] wrote $OUT ($(du -sh "$OUT" | cut -f1))"
