#!/usr/bin/env bash
#
# Boot-test the immutable image in QEMU.
#
#   scripts/qemu-test.sh [direct|uki]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMG="$REPO_DIR/buildroot-build/images"
S="$IMG/singularity"
MODE="${1:-direct}"

ACCEL="-accel tcg"
[ -e /dev/kvm ] && qemu-system-x86_64 -enable-kvm -version >/dev/null 2>&1 && ACCEL="-enable-kvm"

case "$MODE" in
  direct)
    CMD="$(sed -e 's#/dev/vda2#/dev/vda#g' \
               -e 's#console=ttyS0,115200 console=tty0#console=tty0 console=ttyS0,115200#' \
               "$S/cmdline.txt")"
    exec qemu-system-x86_64 $ACCEL -m 2048 -smp 2 \
      -kernel "$IMG/bzImage" -initrd "$S/initramfs.cpio.xz" \
      -append "$CMD" \
      -drive file="$S/root.img",format=raw,if=virtio,readonly=on \
      -nographic -no-reboot
    ;;
  uki)
    OVMF="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/ovmf/OVMF.fd 2>/dev/null | head -1)"
    [ -n "$OVMF" ] || { echo "OVMF firmware not found"; exit 1; }
    echo "UKI boot needs a disk image (ESP + root partition); not wired yet."
    echo "kernelcache.efi is at $S/kernelcache.efi"
    exit 1
    ;;
  *)
    echo "usage: $0 [direct|uki]"; exit 1 ;;
esac
