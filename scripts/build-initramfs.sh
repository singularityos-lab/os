#!/usr/bin/env bash
#
# Build the initramfs for the immutable verity boot.
#
# Beyond the ESP there is ONE partition: the OS root lives on it as
# rootfs-<slot>.erofs FILES (active/next/prev) alongside the user data, so an update
# is staged as -next in free space and promoted by rename -- no A/B layout, no second
# copy of the OS reserved up front. The init is sinty-initramfs, built on the Atom Loops
# boot package: it loop-attaches each slot file and its verity hash, opens dm-verity
# for the slot whose hash matches sing.roothash (baked in the UKI), mounts the verified
# erofs read-only, and hands the same partition back as /var with boot/ on /boot.
#
# Usage: scripts/build-initramfs.sh <target_dir> <output_cpio_xz>

set -euo pipefail

TARGET_DIR="$1"
OUT="$2"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "$SINTY_WORK_ROOT"
WORK="$(mktemp -d "${SINTY_WORK_ROOT}/initramfs.XXXXXX")"
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

[ -n "${SINTY_INIT_BIN:-}" ] && [ -x "$SINTY_INIT_BIN" ] || { echo "build-initramfs: SINTY_INIT_BIN is not set" >&2; exit 1; }
cp "$SINTY_INIT_BIN" "$WORK/init"
chmod 0755 "$WORK/init"
copy_bin sinty-sh bin
ln -sf sinty-sh "$WORK/bin/sh"

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

# Release root public key for the firmware add-on anchors, which the init re-verifies
# (root pubkey -> signing cert -> manifest) before trusting a bundle's dm-verity hash.
# Baked here so it lives inside the Ed25519-signed UKI: the root.pub cannot be swapped
# without re-signing the whole image. Optional -- absent, the init never activates a
# firmware add-on and boots on base survival firmware.
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

mkdir -p "$(dirname "$OUT")"
( cd "$WORK" && find . | cpio -o -H newc -R 0:0 --quiet | xz -9 --check=crc32 ) > "$OUT"
echo "[initramfs] wrote $OUT ($(du -sh "$OUT" | cut -f1))"
