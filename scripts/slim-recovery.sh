#!/bin/sh
set -eu
root="$1"
fwsrc="${2:-}"
find "$root/usr/share/singularity" -mindepth 1 -maxdepth 1 ! -name splash-logo.png -exec rm -rf {} +
rm -rf "$root"/lib/modules/*/kernel/sound
rm -rf "$root"/lib/firmware/ath11k/IPQ* "$root"/lib/firmware/ath11k/QCN* \
	"$root"/lib/firmware/ath11k/WCN6750 "$root"/lib/firmware/ath12k/QCN*
fw="$root/lib/firmware"
for f in "$fw"/iwlwifi-*.ucode; do
	[ -e "$f" ] || [ -L "$f" ] || continue
	name=${f##*/}
	base=${name%-*.ucode}
	ver=${name##*-}; ver=${ver%.ucode}
	case "$ver" in *[!0-9]*) continue ;; esac
	for g in "$fw/$base"-*.ucode; do
		other=${g##*-}; other=${other%.ucode}
		case "$other" in *[!0-9]*) continue ;; esac
		if [ "$other" -gt "$ver" ]; then rm -f "$f"; break; fi
	done
done
if [ -n "$fwsrc" ]; then
	for f in "$fw"/iwlwifi-*.ucode; do
		[ -L "$f" ] || continue
		name=${f##*/}
		real=$(readlink -f "$fwsrc/$name" 2>/dev/null || true)
		rm -f "$f"
		[ -f "$real" ] && cp "$real" "$f"
		family=${name%-*.ucode}
		pnvm=$(readlink -f "$fwsrc/$family.pnvm" 2>/dev/null || true)
		[ -f "$pnvm" ] && cp "$pnvm" "$fw/$family.pnvm"
	done
fi
