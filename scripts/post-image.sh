#!/bin/sh

BINARIES_DIR="$1"
BUILD_DIR="$(dirname "$BINARIES_DIR")/build"
OUTPUT_DIR="$BINARIES_DIR/singularity"

mkdir -p "$OUTPUT_DIR"

echo "[singularity] post-image: starting..."

# rootfs.erofs
if command -v mkfs.erofs >/dev/null 2>&1; then
    echo "[singularity] Building rootfs.erofs..."
    mkfs.erofs \
        -z lz4hc,12 \
        -E ztailpacking \
        "$OUTPUT_DIR/rootfs.erofs" \
        "$BINARIES_DIR/../target"
    echo "[singularity] rootfs.erofs: $(du -sh $OUTPUT_DIR/rootfs.erofs | cut -f1)"
else
    echo "[singularity] WARNING: mkfs.erofs not found, skipping erofs build"
    echo "[singularity] Install erofs-utils on the host to enable erofs output"
fi

# kernelcache.efi
KERNEL="$BINARIES_DIR/bzImage"
INITRD="$BINARIES_DIR/rootfs.cpio.xz"
CMDLINE="console=ttyS0,115200 console=tty0 ro quiet"

if [ -f "$KERNEL" ] && command -v ukify >/dev/null 2>&1; then
    echo "[singularity] Building kernelcache.efi (UKI)..."
    ukify build \
        --linux="$KERNEL" \
        --initrd="$INITRD" \
        --cmdline="$CMDLINE" \
        --output="$OUTPUT_DIR/kernelcache.efi"
    echo "[singularity] kernelcache.efi: $(du -sh $OUTPUT_DIR/kernelcache.efi | cut -f1)"
elif [ -f "$KERNEL" ] && command -v objcopy >/dev/null 2>&1; then
    # Fallback to objcopy
    echo "[singularity] Building kernelcache.efi via objcopy (fallback)..."
    
    STUB="/usr/lib/systemd/boot/efi/linuxx64.efi.stub"
    if [ ! -f "$STUB" ]; then
        echo "[singularity] WARNING: EFI stub not found at $STUB"
        echo "[singularity] Skipping UKI build. Install systemd-boot-efi on host."
    else
        CMDLINE_FILE=$(mktemp)
        echo -n "$CMDLINE" > "$CMDLINE_FILE"

        objcopy \
            --add-section .osrel=/etc/os-release \
            --change-section-vma .osrel=0x20000 \
            --add-section .cmdline="$CMDLINE_FILE" \
            --change-section-vma .cmdline=0x30000 \
            --add-section .linux="$KERNEL" \
            --change-section-vma .linux=0x40000 \
            --add-section .initrd="$INITRD" \
            --change-section-vma .initrd=0x3000000 \
            "$STUB" "$OUTPUT_DIR/kernelcache.efi"

        rm -f "$CMDLINE_FILE"
        echo "[singularity] kernelcache.efi: $(du -sh $OUTPUT_DIR/kernelcache.efi | cut -f1)"
    fi
else
    echo "[singularity] WARNING: kernel not found or no UKI tool available"
    echo "[singularity] Copying bzImage as fallback..."
    cp "$KERNEL" "$OUTPUT_DIR/bzImage" 2>/dev/null || true
    cp "$INITRD" "$OUTPUT_DIR/initrd.cpio.xz" 2>/dev/null || true
fi

echo "[singularity] Output artifacts:"
ls -lh "$OUTPUT_DIR/"
