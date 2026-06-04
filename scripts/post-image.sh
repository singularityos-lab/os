#!/bin/sh
#
# post-image: assemble the immutable boot artifacts.
#
#   rootfs.erofs   the read-only root filesystem
#   root.img       rootfs.erofs with the dm-verity hash tree appended
#   initramfs.cpio.xz  minimal busybox initramfs (mounts the verity root)
#   kernelcache.efi    UKI = kernel + initramfs + cmdline (with the root hash)
#
# The kernel builds the dm-verity device straight from dm-mod.create= in the
# cmdline (CONFIG_DM_INIT); the initramfs just mounts /dev/dm-0 and pivots.
#
# SINGULARITY_ROOT_DEV is the block device that will hold root.img on the
# target. It must match the real partition at deploy time (virtio VM default).

set -e

BINARIES_DIR="$1"
TARGET_DIR="$(dirname "$BINARIES_DIR")/target"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$BINARIES_DIR/singularity"
ROOT_DEV="${SINGULARITY_ROOT_DEV:-/dev/vda2}"

mkdir -p "$OUTPUT_DIR"
echo "[singularity] post-image: starting..."

# rootfs.erofs
SRC_EROFS="$BINARIES_DIR/rootfs.erofs"
if [ ! -f "$SRC_EROFS" ]; then
    echo "[singularity] ERROR: $SRC_EROFS missing (enable BR2_TARGET_ROOTFS_EROFS)"; exit 1
fi
cp -f "$SRC_EROFS" "$OUTPUT_DIR/rootfs.erofs"
echo "[singularity] rootfs.erofs: $(du -sh "$OUTPUT_DIR/rootfs.erofs" | cut -f1)"

# dm-verity hash tree
if ! command -v veritysetup >/dev/null 2>&1; then
    echo "[singularity] ERROR: veritysetup not found (install cryptsetup-bin)"; exit 1
fi
echo "[singularity] Formatting dm-verity..."
VERITY_LOG="$OUTPUT_DIR/verity.log"
# --no-superblock: the hash file holds only the hash tree, so the appended
# hash starts exactly at hash_start_block in root.img (no off-by-one block).
veritysetup format --no-superblock "$OUTPUT_DIR/rootfs.erofs" "$OUTPUT_DIR/rootfs.verity" > "$VERITY_LOG"
cat "$VERITY_LOG"

field() { sed -n "s/^$1:[[:space:]]*//p" "$VERITY_LOG" | head -1 | awk '{print $1}'; }
ROOT_HASH="$(field 'Root hash')"
SALT="$(field 'Salt')"
DATA_BLOCKS="$(field 'Data blocks')"
DATA_BS="$(field 'Data block size')"
HASH_BS="$(field 'Hash block size')"
HASH_ALG="$(field 'Hash algorithm')"

# root.img = data followed by its hash tree; the hash starts right after the
# data, so hash_start_block (in hash blocks) == number of data blocks.
cat "$OUTPUT_DIR/rootfs.erofs" "$OUTPUT_DIR/rootfs.verity" > "$OUTPUT_DIR/root.img"
DATA_SECTORS=$(( DATA_BLOCKS * DATA_BS / 512 ))
echo "$ROOT_HASH" > "$OUTPUT_DIR/roothash.txt"

# dm-mod.create table
DM_TABLE="vroot,,,ro,0 $DATA_SECTORS verity 1 $ROOT_DEV $ROOT_DEV $DATA_BS $HASH_BS $DATA_BLOCKS $DATA_BLOCKS $HASH_ALG $ROOT_HASH $SALT"
CMDLINE="console=ttyS0,115200 console=tty0 ro quiet loglevel=3 vt.global_cursor_default=0 rootfstype=erofs dm-mod.create=\"$DM_TABLE\" root=/dev/dm-0"
echo "$CMDLINE" > "$OUTPUT_DIR/cmdline.txt"

# initramfs
echo "[singularity] Building initramfs..."
INITRD="$OUTPUT_DIR/initramfs.cpio.xz"
"$SCRIPT_DIR/build-initramfs.sh" "$TARGET_DIR" "$INITRD"

# UKI
KERNEL="$BINARIES_DIR/bzImage"
if [ -f "$KERNEL" ] && command -v ukify >/dev/null 2>&1; then
    echo "[singularity] Building kernelcache.efi (UKI)..."
    ukify build \
        --linux="$KERNEL" \
        --initrd="$INITRD" \
        --cmdline="$CMDLINE" \
        --output="$OUTPUT_DIR/kernelcache.efi"
    echo "[singularity] kernelcache.efi: $(du -sh "$OUTPUT_DIR/kernelcache.efi" | cut -f1)"
else
    echo "[singularity] WARNING: kernel or ukify missing, UKI not built"
fi

# GPT disk image (ESP + root)
if command -v genimage >/dev/null 2>&1; then
    echo "[singularity] Building disk image (genimage)..."
    GTMP="$(mktemp -d)"
    mkdir -p "$GTMP/root"
    genimage \
        --config "$SCRIPT_DIR/../board/genimage.cfg" \
        --inputpath "$BINARIES_DIR" \
        --outputpath "$BINARIES_DIR" \
        --tmppath "$GTMP/tmp" \
        --rootpath "$GTMP/root" \
        && echo "[singularity] singularity.img: $(du -sh "$BINARIES_DIR/singularity.img" | cut -f1)" \
        || echo "[singularity] WARNING: genimage failed"
    rm -rf "$GTMP"
else
    echo "[singularity] genimage not found, skipping disk image (enable host-genimage/mtools/dosfstools)"
fi

echo "[singularity] Output artifacts:"
ls -lh "$OUTPUT_DIR/"
