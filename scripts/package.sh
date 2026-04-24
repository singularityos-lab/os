#!/bin/bash

set -e

REPO_DIR="$(pwd)"
mkdir -p artifacts

# RootFS
mkdir -p rootfs-staging
tar xf buildroot-build/images/rootfs.tar.bz2 -C rootfs-staging
mkfs.erofs -z lz4hc,9 -E ztailpacking artifacts/rootfs.erofs rootfs-staging/

# Verity
veritysetup format artifacts/rootfs.erofs artifacts/rootfs.hash | tee artifacts/verity-output.txt

if [ -n "$GITHUB_ENV" ]; then
    ROOT_HASH=$(grep "Root hash:" artifacts/verity-output.txt | awk '{print $3}')
    echo "ROOT_HASH=${ROOT_HASH}" >> "$GITHUB_ENV"
fi

# UKI
KERNEL="buildroot-build/images/bzImage"
STUB="/usr/lib/systemd/boot/efi/linuxx64.efi.stub"
CMDLINE="console=ttyS0,115200 console=tty0 ro quiet root=/dev/mapper/erofs-verity"

mkdir -p initrd-staging/{bin,dev,proc,sys}
(cd initrd-staging && find . | cpio -H newc -o | xz > ../artifacts/initrd.cpio.xz)

objcopy \
    --add-section .cmdline=<(echo -n "$CMDLINE") \
    --change-section-vma .cmdline=0x30000 \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=0x40000 \
    --add-section .initrd="artifacts/initrd.cpio.xz" \
    --change-section-vma .initrd=0x3000000 \
    "$STUB" artifacts/kernelcache.efi
