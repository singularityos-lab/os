#!/bin/sh
# Flash an image to the USB stick at /dev/sda, refusing anything non-removable.
# Installed as /usr/local/bin/flash-sinty and allowed passwordless via
# /etc/sudoers.d/flash-sinty so the assistant can write the test USB without run0.
set -e
IMG="$1"
[ -n "$IMG" ] && [ -r "$IMG" ] || { echo "usage: flash-sinty <image>"; exit 2; }
[ "$(cat /sys/block/sda/removable 2>/dev/null)" = "1" ] || { echo "refusing: /dev/sda is not a removable device"; exit 1; }
dd if="$IMG" of=/dev/sda bs=4M conv=fsync status=progress
sync
SZ=$(stat -c%s "$IMG")
A=$(head -c "$SZ" "$IMG" | sha256sum | cut -d' ' -f1)
B=$(head -c "$SZ" /dev/sda | sha256sum | cut -d' ' -f1)
[ "$A" = "$B" ] && echo "VERIFY_OK" || { echo "VERIFY_MISMATCH"; exit 3; }
