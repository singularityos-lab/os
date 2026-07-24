#!/bin/sh
# Drops what the shipped system cannot use. Runs on the assembled target tree, so
# nothing has to be rebuilt and every cut is reversible by removing a block here.
#
# NVIDIA is not supported: the proprietary stack is not shipped and nouveau is
# not wanted, so both the GSP blobs and the module go. A laptop with a discrete
# NVIDIA card still boots on its integrated GPU; the card simply stays unused.
set -eu
TARGET="${1:?usage: trim-image.sh <target-dir>}"
FW="$TARGET/usr/lib/firmware"
before=$(du -sm "$TARGET" | cut -f1)

rm -rf "$FW/nvidia"
find "$TARGET/usr/lib/modules" -name 'nouveau*' -prune -exec rm -rf {} + 2>/dev/null || true

# Modules for any kernel other than the one being shipped are leftovers from an
# earlier build: they are never loaded and cost their full size in every image
# and every update.
shipped=$(sed -n 's/^BR2_LINUX_KERNEL_VERSION="\(.*\)"$/\1/p' "$(dirname "$0")/../buildroot-build/.config" 2>/dev/null | tail -1)
if [ -n "$shipped" ] && [ -d "$TARGET/usr/lib/modules/$shipped" ]; then
    for d in "$TARGET"/usr/lib/modules/*/; do
        [ "$(basename "$d")" = "$shipped" ] || rm -rf "$d"
    done
fi

# Hardware that predates the TPM 2.0 and Secure Boot requirements cannot run this
# system, so its firmware is dead weight.
rm -rf "$FW/mrvl" "$FW/ath10k" "$FW/radeon" "$FW/rtlwifi"
for gen in 3945 4965 1000 5000 5150 6050 6000g2a 6000g2b 100 105 135 2000 2030 3160 3168 7260 7265 7265D 6000; do
    rm -f "$FW/iwlwifi-$gen"-*.ucode "$FW/intel/iwlwifi/iwlwifi-$gen"-*.ucode
done

find "$TARGET/usr/bin" "$TARGET/usr/lib" -type f -name '*.so*' -exec strip --strip-unneeded {} + 2>/dev/null || true

after=$(du -sm "$TARGET" | cut -f1)
echo "trim-image: $before MB -> $after MB (freed $((before - after)) MB)"
