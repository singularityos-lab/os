#!/usr/bin/env bash
#
# Build the minimal initramfs for the immutable boot.
#
# The kernel creates the dm-verity device from the dm-mod.create= cmdline
# (CONFIG_DM_INIT). This initramfs only has to wait for /dev/dm-0, mount the
# verified erofs read-only and switch_root into it. busybox plus its shared
# libraries are pulled from the already-built target.
#
# Usage: scripts/build-initramfs.sh <target_dir> <output_cpio_xz>

set -euo pipefail

TARGET_DIR="$1"
OUT="$2"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK"/{bin,sbin,proc,sys,dev,sysroot,lower,over,lib,lib64,run,etc}

# busybox plus the shared libraries it needs (target is glibc, dynamically linked).
cp -a "$TARGET_DIR/bin/busybox" "$WORK/bin/busybox"
copy_lib() {
	local lib="$1"
	for root in "$TARGET_DIR/lib" "$TARGET_DIR/lib64" "$TARGET_DIR/usr/lib"; do
		if [ -e "$root/$lib" ]; then
			mkdir -p "$WORK/lib"
			cp -aL "$root/$lib" "$WORK/lib/$lib"
			return 0
		fi
	done
	return 1
}
# Resolve the loader and DT_NEEDED of busybox from the target sysroot.
READELF="$(command -v x86_64-buildroot-linux-gnu-readelf || command -v readelf)"
INTERP="$("$READELF" -l "$TARGET_DIR/bin/busybox" 2>/dev/null | sed -n 's/.*interpreter: \(.*\)\]/\1/p' | head -1)"
INTERP="${INTERP##*/}"
[ -n "$INTERP" ] && copy_lib "$INTERP" || true
"$READELF" -d "$TARGET_DIR/bin/busybox" 2>/dev/null \
	| sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' \
	| while read -r so; do copy_lib "$so" || true; done

# The glibc loader searches /lib64 and /usr/lib64 by default on x86-64, so
# mirror every collected library into all of them (cheap, a handful of files).
mkdir -p "$WORK/lib64" "$WORK/usr/lib" "$WORK/usr/lib64"
cp -a "$WORK/lib/." "$WORK/lib64/"
cp -a "$WORK/lib/." "$WORK/usr/lib/"
cp -a "$WORK/lib/." "$WORK/usr/lib64/"

# Applet symlinks the init relies on.
for applet in sh mount switch_root sleep mkdir mknod cat; do
	ln -sf busybox "$WORK/bin/$applet"
done

cat > "$WORK/init" <<'INIT'
#!/bin/busybox sh
/bin/busybox mount -t proc     proc /proc
/bin/busybox mount -t sysfs    sys  /sys
/bin/busybox mount -t devtmpfs dev  /dev

rescue() {
	echo "initramfs: $1" >&2
	echo "dropping to a rescue shell" >&2
	exec /bin/busybox sh
}

# The kernel sets up dm-verity from dm-mod.create=; wait for the node.
ROOT=/dev/dm-0
i=0
while [ ! -b "$ROOT" ] && [ $i -lt 50 ]; do /bin/busybox sleep 0.2; i=$((i + 1)); done
[ -b "$ROOT" ] || rescue "verity device $ROOT never appeared"

# Read-only verified erofs is the lower layer; a tmpfs supplies the writable
# upper so the booted system can write /var, /etc, /run while the image stays
# immutable. Swap the tmpfs for a persistent partition once one exists.
/bin/busybox mount -t erofs -o ro "$ROOT" /lower || rescue "cannot mount erofs root"
/bin/busybox mount -t tmpfs -o mode=0755 tmpfs /over || rescue "cannot mount tmpfs"
/bin/busybox mkdir -p /over/upper /over/work
/bin/busybox mount -t overlay overlay \
    -o lowerdir=/lower,upperdir=/over/upper,workdir=/over/work /sysroot \
    || rescue "cannot mount overlay root"
[ -x /sysroot/sbin/init ] || rescue "/sbin/init missing in root"

exec /bin/busybox switch_root /sysroot /sbin/init
INIT
chmod +x "$WORK/init"

mkdir -p "$(dirname "$OUT")"
( cd "$WORK" && find . | cpio -o -H newc --quiet | xz -9 --check=crc32 ) > "$OUT"
echo "[initramfs] wrote $OUT ($(du -sh "$OUT" | cut -f1))"
