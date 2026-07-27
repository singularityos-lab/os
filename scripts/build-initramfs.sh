#!/usr/bin/env bash
#
# Build the initramfs for the immutable verity boot.
#
# The OS root ships as rootfs-<slot>.erofs FILES (active/next/prev) on a writable
# ext4 partition (label atom-system) that becomes /boot, not as a raw partition: the
# Atom Loops slot model, where an update is staged as -next and promoted by rename,
# so the slot files are reachable as /boot/rootfs/... at runtime. The init mounts
# that partition, loop-attaches each slot file and its verity hash, then opens the
# dm-verity device with veritysetup for the slot whose hash matches sing.roothash
# (baked in the UKI), mounts the verified erofs read-only and overlays a tmpfs.
# Kept in lockstep with the reference AtomLoops init (scripts/boot/initramfs-main.go).
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

# sintykey (in /usr/bin) reads the TPM lock bit and verity toggle to honor a
# bootloader unlock; it execs its helper from /usr/libexec/sintykey-tpm, so stage
# that at the SAME path. Both optional: if absent, the unlock escape hatch never
# triggers and the init stays on full dm-verity (fail closed). Their shared-library
# closure (tpm2-tss, libsintykey) is pulled in by resolve_libs below, so they must
# be staged before it runs.
copy_bin sintykey usr/bin 2>/dev/null || true
if [ -e "$TARGET_DIR/usr/libexec/sintykey-tpm" ]; then
	mkdir -p "$WORK/usr/libexec"
	cp -aL "$TARGET_DIR/usr/libexec/sintykey-tpm" "$WORK/usr/libexec/sintykey-tpm"
fi
# tss2-tctildr dlopens the TCTI backend by SONAME at runtime (it is not a DT_NEEDED,
# so resolve_libs below cannot discover it). Stage the device TCTI into /lib (mirrored
# to the other loader dirs) so sintykey-tpm can reach /dev/tpmrm0; without it the TPM
# read fails and the unlock check fails closed to full dm-verity.
if [ -e "$TARGET_DIR/usr/lib/libtss2-tcti-device.so.0" ]; then
	cp -aL "$TARGET_DIR/usr/lib/libtss2-tcti-device.so.0" "$WORK/lib/libtss2-tcti-device.so.0"
fi

# Firmware add-on trust anchor verifier + baked release root public key. fw-verify is
# a statically linked (CGO_ENABLED=0) binary that re-verifies the on-disk firmware
# anchor (root pubkey -> signing cert -> manifest) and prints the trusted dm-verity
# root hash. Baked here so it lives inside the Ed25519-signed UKI: the root.pub cannot
# be swapped without re-signing the whole image. Both optional -- absent, the init
# simply never activates a firmware add-on and boots on base survival firmware.
if [ -n "${FW_VERIFY_BIN:-}" ] && [ -f "$FW_VERIFY_BIN" ]; then
	cp "$FW_VERIFY_BIN" "$WORK/sbin/fw-verify"
	chmod 0755 "$WORK/sbin/fw-verify"
fi
if [ -n "${FW_ROOT_PUB:-}" ] && [ -f "$FW_ROOT_PUB" ]; then
	mkdir -p "$WORK/etc"
	cp "$FW_ROOT_PUB" "$WORK/etc/atom-fw-root.pub"
fi

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

for applet in sh mount umount switch_root sleep mkdir mknod cat blkid dd losetup basename readlink; do
	ln -sf busybox "$WORK/bin/$applet"
done

cat > "$WORK/init" <<'INIT'
#!/bin/busybox sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export DM_DISABLE_UDEV=1
busybox mount -t proc     proc /proc
busybox mount -t sysfs    sys  /sys
busybox mount -t devtmpfs dev  /dev
# Reconnect stdio to the real console: the kernel exec'd this init with no
# /dev/console node in the cpio, so every [init] diagnostic was silently discarded.
[ -c /dev/console ] && exec >/dev/console 2>/dev/console </dev/console
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

# Atom Loops system partition: the root image ships as rootfs-<slot>.erofs FILES
# (active/next/prev) plus their verity hash under rootfs/ on an ext4 partition that
# becomes /boot (so they are reachable as /boot/rootfs/... on the running system),
# not as a raw partition, so an update is staged as a file and promoted by rename.
# Probe every partition for rootfs/rootfs-active.erofs, then loop-attach each
# slot file read-only: the pairing below picks the pair whose hash matches the
# sing.roothash baked in this UKI, which is what makes a promoted slot boot.
# Mounted read-only here; remounted rw once moved to /sysroot/boot/rootfs, where the
# update daemon stages the next slot. Absent partition = raw-partition layout, which
# the globs below still handle.
SYSDEV= ; SYSMNT=/sysdata
mount_system() {
	busybox mkdir -p "$SYSMNT"
	for d in /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
		[ -b "$d" ] || continue
		busybox mount -t ext4 -o ro "$d" "$SYSMNT" 2>/dev/null || continue
		if [ -f "$SYSMNT/rootfs/rootfs-active.erofs" ]; then
			SYSDEV="$d"
			busybox echo "[init] system partition: $d"
			for f in "$SYSMNT"/rootfs/rootfs-*.erofs "$SYSMNT"/rootfs/rootfs-*.hash; do
				[ -f "$f" ] || continue
				_lp=$(busybox losetup -f) && busybox losetup -r "$_lp" "$f" 2>/dev/null \
					&& busybox echo "[init]   $f -> $_lp"
			done
			return 0
		fi
		busybox umount "$SYSMNT" 2>/dev/null
	done
	busybox echo "[init] no Atom Loops system partition (raw-partition layout)"
	return 0
}
mount_system

# Firmware add-on bundles: union each verified /boot/firmware/<bundle>/ over the base
# survival firmware baked in the rootfs. UNLIKE the rootfs this is FAIL-OPEN and per-bundle:
# a missing, tampered or unmountable bundle is dropped and the rest (plus base) still mount,
# and the system STILL boots -- a firmware failure must never brick. Each bundle's dm-verity
# root hash comes from its own release-signed anchor, re-verified here by fw-verify (root
# pubkey -> signing cert -> manifest, matched to the bundle name); an unverified bundle is
# never mounted. (Shell mirror of AtomLoops' Go mountFirmware, kept in lockstep.)
mount_firmware() {
	_fwroot=/sysroot/boot/firmware
	[ -d "$_fwroot" ] || { busybox echo "[init] no firmware dir, base firmware only"; return 0; }
	[ -x /sbin/fw-verify ] || { busybox echo "[init] no firmware verifier, base firmware only"; return 0; }

	# Accumulated across bundles so a degraded union tears everything down cleanly: no loop
	# device or verity mapper may leak across switch_root.
	_fw_loops="" ; _fw_maps="" ; _fw_mnts="" ; _lowers=""
	_fw_cleanup() {
		for _m in $_fw_mnts; do busybox umount "$_m" 2>/dev/null; done
		for _v in $_fw_maps; do veritysetup close "$_v" 2>/dev/null; done
		for _l in $_fw_loops; do busybox losetup -d "$_l" 2>/dev/null; done
	}

	# Each /boot/firmware/<bundle>/ is an independently signed + versioned add-on. Verify,
	# verity-open and mount each; PER-BUNDLE never-brick: a bundle whose anchor/verity/mount
	# fails is skipped (its partial state cleaned up inline) and the others still mount.
	for _bdir in "$_fwroot"/*/; do
		[ -d "$_bdir" ] || continue
		_b=$(busybox basename "$_bdir")
		_img="${_bdir}firmware-active.img"
		_hsh="${_bdir}firmware-active.hash"
		[ -f "$_img" ] || continue

		_bh=$(/sbin/fw-verify "$_bdir" active /etc/atom-fw-root.pub "$_b" 2>/dev/null)
		[ -n "$_bh" ] || { busybox echo "[init] firmware bundle $_b unverified, skipped"; continue; }

		_dev=$(busybox losetup -f) && busybox losetup "$_dev" "$_img" 2>/dev/null \
			|| { busybox echo "[init] firmware bundle $_b attach failed, skipped"; busybox losetup -d "$_dev" 2>/dev/null; continue; }
		_hdev=$(busybox losetup -f) && busybox losetup "$_hdev" "$_hsh" 2>/dev/null
		[ -n "$_hdev" ] || { busybox echo "[init] firmware bundle $_b hash attach failed, skipped"; busybox losetup -d "$_dev" 2>/dev/null; continue; }
		if ! veritysetup open "$_dev" "${_b}-fwverity" "$_hdev" "$_bh" 2>/dev/null; then
			busybox echo "[init] firmware bundle $_b verity failed, skipped"
			busybox losetup -d "$_dev" 2>/dev/null; busybox losetup -d "$_hdev" 2>/dev/null; continue
		fi
		_mnt="/sysroot/var/.fw-$_b"
		busybox mkdir -p "$_mnt"
		if ! busybox mount -t erofs -o ro "/dev/mapper/${_b}-fwverity" "$_mnt" 2>/dev/null; then
			busybox echo "[init] firmware bundle $_b mount failed, skipped"
			veritysetup close "${_b}-fwverity" 2>/dev/null
			busybox losetup -d "$_dev" 2>/dev/null; busybox losetup -d "$_hdev" 2>/dev/null; continue
		fi
		# Kernel-bound driver bundle: refuse it unless its stamped kernel-ABI matches the
		# running kernel. A kernel update invalidates an old driver bundle (ABI mismatch
		# would fail the module load), so it stays on base until the matching one arrives.
		# Firmware-only bundles carry no .kernel-abi and are never gated.
		if [ -f "${_mnt}/.kernel-abi" ]; then
			_abi=$(busybox cat "${_mnt}/.kernel-abi" 2>/dev/null | busybox tr -d '\r\n ')
			_run=$(busybox uname -r)
			if [ "$_abi" != "$_run" ]; then
				busybox echo "[init] driver bundle $_b built for kernel $_abi != running $_run, skipped"
				busybox umount "$_mnt" 2>/dev/null
				veritysetup close "${_b}-fwverity" 2>/dev/null
				busybox losetup -d "$_dev" 2>/dev/null; busybox losetup -d "$_hdev" 2>/dev/null
				continue
			fi
		fi

		_fw_loops="$_dev $_hdev $_fw_loops"
		_fw_maps="${_b}-fwverity $_fw_maps"
		_fw_mnts="$_mnt $_fw_mnts"
		# Firmware bundles union over /usr/lib/firmware. A DRIVER bundle (.kernel-abi)
		# carries /usr/lib/modules + libs, not just firmware, so it does NOT join that
		# union: it stays mounted at /var/.fw-<b> and the post-boot nvidia-driver-activate
		# service insmods its modules and wires its userspace libs.
		if [ -f "${_mnt}/.kernel-abi" ]; then
			busybox echo "[init] driver bundle $_b verified + mounted (kernel $_abi, activated post-boot)"
		else
			_lowers="${_mnt}:${_lowers}"
			busybox echo "[init] firmware bundle $_b verified + mounted (anchor-verified)"
		fi
	done

	[ -n "$_lowers" ] || { busybox echo "[init] no firmware bundle mounted, base firmware only"; return 0; }

	# Union every mounted bundle over the base survival firmware in one overlay (bundles
	# highest priority, base last).
	busybox mkdir -p /sysroot/var/.base-firmware
	busybox mount --bind /sysroot/usr/lib/firmware /sysroot/var/.base-firmware 2>/dev/null \
		|| { busybox echo "[init] firmware base bind failed, base only"; _fw_cleanup; return 0; }
	if busybox mount -t overlay overlay \
		-o "ro,lowerdir=${_lowers}/sysroot/var/.base-firmware" /sysroot/usr/lib/firmware 2>/dev/null; then
		busybox echo "[init] firmware add-on bundles unioned over base firmware"
		return 0
	fi
	busybox echo "[init] firmware overlay failed, using base firmware"
	busybox umount /sysroot/var/.base-firmware 2>/dev/null
	_fw_cleanup
	return 0
}

# Collect ALL erofs data + dm-verity hash partitions -- there can be several (a USB
# stick AND an already-installed disk) -- then verity-open the pair whose hash matches
# the baked sing.roothash. This picks the correct rootfs regardless of extra installs.
DATA= ; HASH= ; DATAS= ; HASHES= ; i=0

# Bootloader-unlock escape hatch. KEEP IN LOCKSTEP with the AtomLoops standalone
# init (scripts/boot/initramfs-main.go unlockGrantsNoVerity): a device the owner
# deliberately unlocked in recovery has its dm-verity toggle turned off in the TPM.
# Honor it ONLY when sintykey asserts BOTH facts (lock bit unlocked AND verity off);
# it fails closed -- a missing sintykey, an unreachable TPM, or either fact reading
# locked/on leaves UNLOCKED empty and the verified path below runs unchanged.
UNLOCKED=
if command -v sintykey >/dev/null 2>&1; then
	# Read both TPM facts once. Skip dm-verity ONLY when the device is both unlocked
	# and its verity toggle is off; any TPM read failure fails closed (verity kept).
	_ls="$(sintykey lock-state 2>/dev/null)"
	_vs="$(sintykey verity-state 2>/dev/null)"
	case "$_ls" in *locked=false*) case "$_vs" in *verity=off*) UNLOCKED=1 ;; esac ;; esac
fi

ROOTSRC=/dev/mapper/vroot
if [ -n "$UNLOCKED" ]; then
	# Unlocked: mount the erofs root directly, no dm-verity. Find the data partition
	# by its erofs magic (the same probe as the verified path, without hash pairing).
	while [ $i -lt 75 ]; do
		for d in /dev/loop[0-9]* /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
			[ -b "$d" ] || continue
			m=$(busybox dd if="$d" bs=1 skip=1024 count=4 2>/dev/null | busybox od -An -tx1 | busybox tr -d ' \n')
			[ "$m" = "e2e1f5e0" ] && { DATA="$d"; DATAS="$DATAS $d"; break; }
		done
		[ -n "$DATA" ] && break
		busybox sleep 0.2; i=$((i + 1))
	done
	[ -n "$DATA" ] || rescue "unlocked: no erofs root partition found"
	ROOTSRC="$DATA"
	# Persistent per-boot notice: an unlocked device warns every time it boots.
	busybox echo "[init] =================================================================="
	busybox echo "[init]  DEVICE UNLOCKED - verified boot is OFF, this system is not sealed"
	busybox echo "[init]  mounting the root image without dm-verity"
	busybox echo "[init] =================================================================="
else
	while [ $i -lt 75 ]; do
		DATAS= ; HASHES=
		for d in /dev/loop[0-9]* /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
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
fi

busybox mkdir -p /varprobe
# /var must live on the SAME physical disk as the verified root erofs. Otherwise a live/
# installer boot scans every disk and mounts an internal disk's /var (another install's
# user data) into the live session -- a data-exposure bypass.
_parentdisk() {
	_pp=$(busybox basename "$1")
	busybox basename "$(busybox readlink -f "/sys/class/block/$_pp/.." 2>/dev/null)"
}
# With the file-based slots the root device is a loop, whose sysfs parent is not a disk
# at all, so the reference for "same disk" is the partition the slot files live on. Using
# the loop here matches nothing: /var is never found, the system silently falls back to
# tmpfs /var and OTA stays inert forever.
ROOTDISK=$(_parentdisk "${SYSDEV:-$DATA}")
VAR=
for d in /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
	[ -b "$d" ] || continue
	[ "$d" = "$DATA" ] && continue
	[ "$d" = "$HASH" ] && continue
	[ -n "$SYSDEV" ] && [ "$d" = "$SYSDEV" ] && continue
	[ "$(_parentdisk "$d")" = "$ROOTDISK" ] || continue
	{ busybox mount -t f2fs "$d" /varprobe 2>/dev/null || busybox mount -t ext4 "$d" /varprobe 2>/dev/null; } || continue
	if [ -e /varprobe/.atom-var ]; then VAR="$d"; busybox umount /varprobe; break; fi
	busybox umount /varprobe 2>/dev/null
done

if [ -n "$VAR" ]; then
	busybox mount -t erofs -o ro "$ROOTSRC" /sysroot || rescue "cannot mount erofs root"
	{ busybox mount -t f2fs "$VAR" /sysroot/var || busybox mount -t ext4 "$VAR" /sysroot/var; } || rescue "cannot mount /var"
	busybox echo "[init] persistent /var: $VAR ($(busybox awk '$2=="/sysroot/var"{print $3}' /proc/mounts)) same disk as root"
	busybox mkdir -p /sysroot/var/etc-upper /sysroot/var/etc-work /sysroot/var/home
	busybox mount -t overlay overlay \
	    -o lowerdir=/sysroot/etc,upperdir=/sysroot/var/etc-upper,workdir=/sysroot/var/etc-work /sysroot/etc || true
	busybox mount -t tmpfs -o mode=1777 tmpfs /sysroot/tmp || true
	busybox mount -o bind /sysroot/var/home /sysroot/home || true
else
	busybox mount -t erofs -o ro "$ROOTSRC" /lower || rescue "cannot mount erofs root"
	busybox mount -t tmpfs -o mode=0755 tmpfs /over || rescue "cannot mount tmpfs"
	busybox mkdir -p /over/upper /over/work
	busybox mount -t overlay overlay \
	    -o lowerdir=/lower,upperdir=/over/upper,workdir=/over/work /sysroot \
	    || rescue "cannot mount overlay root"
fi

# Carry the system partition into the new root. Its own /boot/rootfs is where otad
# stages the next slot and boot-success promotes by rename, so it is mounted at
# /boot and remounted rw. It also has to survive switch_root anyway: the loop
# devices backing the verified root keep its files open.
if [ -n "$SYSDEV" ]; then
	busybox mkdir -p /sysroot/boot 2>/dev/null || true
	if busybox mount --move "$SYSMNT" /sysroot/boot 2>/dev/null; then
		busybox mount -o remount,rw /sysroot/boot 2>/dev/null \
			|| busybox echo "[init] warning: /boot stays read-only, updates cannot stage"
	else
		busybox echo "[init] warning: system partition not carried to /boot"
	fi

	# The ESP has to be mounted for an update to land: otad stages kernelcache-next
	# and rewrites boot-state under /boot/efi/EFI/atom, and the loader reads them on
	# the next boot. Nothing else mounts it (fstab carries only /), so do it here,
	# where the disk is already known. Identified by content, not by device name.
	for e in /dev/vd*[0-9] /dev/sd*[0-9] /dev/nvme*p[0-9]* /dev/mmcblk*p[0-9]*; do
		[ -b "$e" ] || continue
		busybox mkdir -p /sysroot/boot/efi 2>/dev/null || true
		busybox mount -t vfat "$e" /sysroot/boot/efi 2>/dev/null || continue
		if [ -d /sysroot/boot/efi/EFI/atom ]; then
			busybox echo "[init] ESP: $e"
			break
		fi
		busybox umount /sysroot/boot/efi 2>/dev/null
	done
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

# Union the firmware add-on over the base firmware before handing off. Fail-open:
# never blocks the boot, only enriches /usr/lib/firmware when a valid image exists.
mount_firmware

# sinit.debug on the kernel command line makes PID 1 log per-unit start progress.
# Passed as an argument because the init takes it as a flag, not from the cmdline.
# The init is reached as /usr/lib/sinit/sinit (the /sbin/init symlink is absolute, so
# it does not resolve from here), and under that name the flag has to follow the
# `init` subcommand.
INITARGS=
case " $(busybox cat /proc/cmdline) " in
	*" sinit.debug "*)
		case "$INIT" in */init) INITARGS=--debug ;; *) INITARGS="init --debug" ;; esac
		;;
esac
exec busybox switch_root /sysroot "$INIT" $INITARGS
INIT
chmod +x "$WORK/init"

mkdir -p "$(dirname "$OUT")"
( cd "$WORK" && find . | cpio -o -H newc --quiet | xz -9 --check=crc32 ) > "$OUT"
echo "[initramfs] wrote $OUT ($(du -sh "$OUT" | cut -f1))"
