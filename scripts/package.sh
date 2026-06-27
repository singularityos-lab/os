#!/bin/bash

set -e

REPO_DIR="$(pwd)"
mkdir -p artifacts

# RootFS
ROOTFS_TAR=artifacts/rootfs.tar
bzcat buildroot-build/images/rootfs.tar.bz2 > "$ROOTFS_TAR"
mkfs.erofs --tar=f -z lz4hc,9 -E ztailpacking artifacts/rootfs.erofs "$ROOTFS_TAR"

# Verity
veritysetup format artifacts/rootfs.erofs artifacts/rootfs.hash | tee artifacts/verity-output.txt
ROOT_HASH=$(awk '/Root hash:/{print $3}' artifacts/verity-output.txt)
DATA_BLOCKS=$(awk '/Data blocks:/{print $3}' artifacts/verity-output.txt)
SALT=$(awk '/Salt:/{print $2}' artifacts/verity-output.txt)
DM_LEN=$((DATA_BLOCKS * 8))

if [ -n "$GITHUB_ENV" ]; then
    echo "ROOT_HASH=${ROOT_HASH}" >> "$GITHUB_ENV"
fi

# Initramfs: the dm-verity aware init that waits for the kernel-created
# verity device, mounts the verified erofs read-only and overlays a tmpfs.
bash scripts/build-initramfs.sh buildroot-build/target artifacts/initrd.cpio.xz

# The initramfs finds the data/hash partitions by GPT PARTLABEL and opens the
# verity device with this root hash, so no device names are baked in.
CMDLINE="console=ttyS0,115200 console=tty0 ro quiet rootwait sing.roothash=${ROOT_HASH}"

# UKI: place the added sections above the stub's image so they do not fall
# below the PE image base.
KERNEL="buildroot-build/images/bzImage"
STUB="/usr/lib/systemd/boot/efi/linuxx64.efi.stub"
BASE=$((16#$(objdump -p "$STUB" | awk '/ImageBase/{print $2}')))
vma() { printf "0x%x" $((BASE + $1)); }

OSREL=""
[ -f buildroot-build/target/usr/lib/os-release ] && OSREL="--add-section .osrel=buildroot-build/target/usr/lib/os-release --change-section-vma .osrel=$(vma 0x100000)"

printf '%s' "$CMDLINE" > artifacts/cmdline.txt

objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache.efi

echo "[package] UKI: artifacts/kernelcache.efi"
echo "[package] root hash: ${ROOT_HASH}"

# Installable GPT disk image: ESP (UKI as default boot) + labelled data/hash.
HOSTBIN="${REPO_DIR}/buildroot-build/host/bin"
HOSTSBIN="${REPO_DIR}/buildroot-build/host/sbin"
export PATH="${HOSTBIN}:${HOSTSBIN}:${PATH}"
export MTOOLS_SKIP_CHECK=1

rm -f artifacts/esp.vfat
dd if=/dev/zero of=artifacts/esp.vfat bs=1M count=64 status=none
mkfs.fat -F 16 -n SINGEFI artifacts/esp.vfat >/dev/null
mmd -i artifacts/esp.vfat ::EFI ::EFI/BOOT
mcopy -i artifacts/esp.vfat artifacts/kernelcache.efi ::EFI/BOOT/BOOTX64.EFI

rm -rf genimage-tmp
"${HOSTBIN}/genimage" \
    --config scripts/genimage.cfg \
    --inputpath artifacts \
    --outputpath artifacts \
    --tmppath genimage-tmp

# Bootable hybrid ISO: efiboot.img holds the UKI for El Torito EFI boot, the ESP
# plus data and hash are appended as GPT partitions for USB boot; the initramfs
# finds data and hash by content.
ISO_ROOT="$(mktemp -d)"
mkdir -p "${ISO_ROOT}/EFI"
rm -f artifacts/efiboot.img
dd if=/dev/zero of=artifacts/efiboot.img bs=1M count=32 status=none
mkfs.fat -F 16 artifacts/efiboot.img >/dev/null
mmd -i artifacts/efiboot.img ::EFI ::EFI/BOOT
mcopy -i artifacts/efiboot.img artifacts/kernelcache.efi ::EFI/BOOT/BOOTX64.EFI
cp artifacts/efiboot.img "${ISO_ROOT}/EFI/efiboot.img"
"${HOSTBIN}/xorriso" -as mkisofs \
    -iso-level 3 -volid SINTY_OS \
    -e EFI/efiboot.img -no-emul-boot \
    -append_partition 2 0xef artifacts/esp.vfat \
    -append_partition 3 0x83 artifacts/rootfs.erofs \
    -append_partition 4 0x83 artifacts/rootfs.hash \
    -appended_part_as_gpt -isohybrid-gpt-basdat \
    -o artifacts/sinty-os.iso "${ISO_ROOT}"
rm -rf "${ISO_ROOT}" artifacts/efiboot.img

echo "[package] disk image: artifacts/sinty-os.img"
echo "[package] iso: artifacts/sinty-os.iso"
