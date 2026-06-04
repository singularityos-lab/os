#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/../buildroot-build/images" && pwd)"
S="$DIR/singularity"
CMD="$(sed -e 's#/dev/vda2#/dev/vda#g' -e 's# quiet # #' "$S/cmdline.txt")"
ACCEL="-accel tcg"; [ -e /dev/kvm ] && ACCEL="-enable-kvm"
exec qemu-system-x86_64 $ACCEL -m 4096 -smp 4 \
  -kernel "$DIR/bzImage" -initrd "$S/initramfs.cpio.xz" -append "$CMD" \
  -drive file="$S/root.img",format=raw,if=virtio,readonly=on \
  -vga virtio -spice port=5930,addr=127.0.0.1,disable-ticketing=on \
  -device virtio-keyboard-pci -device virtio-tablet-pci \
  -netdev user,id=n0 -device virtio-net-pci,netdev=n0 \
  -no-reboot
