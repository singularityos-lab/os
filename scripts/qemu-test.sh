#!/usr/bin/env bash
#
# Boot-test the immutable image in QEMU.
#
#   scripts/qemu-test.sh [direct|uki]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "$SINTY_WORK_ROOT"
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
    # Boot artifacts/sinty-os.img the way real hardware does: OVMF -> the signed
    # loader on the ESP -> UKI -> initramfs. This is the only mode that exercises the
    # slot layout (system partition, loop-attached rootfs file, dm-verity, ESP mount);
    # `direct` bypasses all of it. The image is copied first because the firmware and
    # the system partition are written to, and a boot must not mutate the artifact.
    OVMF="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd 2>/dev/null | head -1)"
    OVMF_VARS="$(ls /usr/share/OVMF/OVMF_VARS_4M.fd 2>/dev/null | head -1)"
    [ -n "$OVMF" ] && [ -n "$OVMF_VARS" ] || { echo "OVMF firmware not found"; exit 1; }
    # QEMU_IMG boots a different disk, e.g. the installed image from
    # scripts/make-installed-image.sh, which is the only one that exercises OTA.
    SRC="${QEMU_IMG:-$REPO_DIR/artifacts/sinty-os.img}"
    [ -f "$SRC" ] || { echo "no $SRC (run scripts/package.sh)"; exit 1; }
    WORK="${QEMU_WORK:-$(mktemp -d "${SINTY_WORK_ROOT}/qemu-uki.XXXXXX")}"
    mkdir -p "$WORK"
    cp "$SRC" "$WORK/disk.img"
    cp "$OVMF_VARS" "$WORK/vars.fd"
    echo "[qemu-test] work dir: $WORK"
    exec qemu-system-x86_64 $ACCEL -m 4096 -smp 4 \
      -machine q35 \
      -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF" \
      -drive if=pflash,format=raw,unit=1,file="$WORK/vars.fd" \
      -drive file="$WORK/disk.img",format=raw,if=virtio \
      -vga virtio -display none \
      -nic user,model=virtio-net-pci \
      -serial "file:$WORK/serial.log" \
      ${QEMU_EXTRA:-}
    ;;
  install)
    # Boot the live medium with a blank second disk so atom-install can provision it,
    # then boot that disk. This is the only mode that exercises the installer itself:
    # every other mode starts from an image built on the host, which proves the layout
    # but never proves the code that writes it onto real hardware.
    OVMF="$(ls /usr/share/OVMF/OVMF_CODE_4M.fd 2>/dev/null | head -1)"
    OVMF_VARS="$(ls /usr/share/OVMF/OVMF_VARS_4M.fd 2>/dev/null | head -1)"
    [ -n "$OVMF" ] && [ -n "$OVMF_VARS" ] || { echo "OVMF firmware not found"; exit 1; }
    SRC="${QEMU_IMG:-$REPO_DIR/artifacts/sinty-os.img}"
    [ -f "$SRC" ] || { echo "no $SRC (run scripts/package.sh)"; exit 1; }
    WORK="${QEMU_WORK:-$(mktemp -d "${SINTY_WORK_ROOT}/qemu-install.XXXXXX")}"
    mkdir -p "$WORK"
    cp "$OVMF_VARS" "$WORK/vars.fd"
    # TARGET_GB sizes the blank disk the installer provisions; it must fit two slots.
    [ -f "$WORK/target.img" ] || truncate -s "${TARGET_GB:-12}G" "$WORK/target.img"
    # BOOT_TARGET boots the provisioned disk instead of the live medium, so the same
    # mode can run both halves of the test.
    if [ -n "${BOOT_TARGET:-}" ]; then
      DISKS="-drive file=$WORK/target.img,format=raw,if=virtio"
    else
      cp "$SRC" "$WORK/live.img"
      DISKS="-drive file=$WORK/live.img,format=raw,if=virtio -drive file=$WORK/target.img,format=raw,if=virtio"
    fi
    echo "[qemu-test] work dir: $WORK"
    exec qemu-system-x86_64 $ACCEL -m 4096 -smp 4 \
      -machine q35 \
      -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF" \
      -drive if=pflash,format=raw,unit=1,file="$WORK/vars.fd" \
      $DISKS \
      -vga virtio -display none \
      -nic user,model=virtio-net-pci \
      -serial "file:$WORK/serial.log" \
      ${QEMU_EXTRA:-}
    ;;
  *)
    echo "usage: $0 [direct|uki|install]"; exit 1 ;;
esac
