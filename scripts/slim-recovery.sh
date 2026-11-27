#!/bin/sh
set -eu
root="$1"
fwsrc="${2:-}"
find "$root/usr/share/singularity" -mindepth 1 -maxdepth 1 ! -name splash-logo.png -exec rm -rf {} +
rm -rf "$root"/lib/modules/*/kernel/sound
rm -rf "$root"/lib/firmware/ath11k/IPQ* "$root"/lib/firmware/ath11k/QCN* \
	"$root"/lib/firmware/ath11k/WCN6750 "$root"/lib/firmware/ath12k/QCN*
fw="$root/lib/firmware"
ucode_name() { n=${1##*/}; printf '%s' "${n%.xz}"; }
ucode_ver() { n=$(ucode_name "$1"); v=${n##*-}; printf '%s' "${v%.ucode}"; }
ucode_base() { n=$(ucode_name "$1"); printf '%s' "${n%-*.ucode}"; }
for f in "$fw"/iwlwifi-*.ucode "$fw"/iwlwifi-*.ucode.xz; do
	[ -e "$f" ] || [ -L "$f" ] || continue
	base=$(ucode_base "$f")
	ver=$(ucode_ver "$f")
	case "$ver" in ''|*[!0-9]*) continue ;; esac
	for g in "$fw/$base"-*.ucode "$fw/$base"-*.ucode.xz; do
		[ -e "$g" ] || [ -L "$g" ] || continue
		other=$(ucode_ver "$g")
		case "$other" in ''|*[!0-9]*) continue ;; esac
		if [ "$other" -gt "$ver" ]; then rm -f "$f"; break; fi
	done
done
if [ -n "$fwsrc" ]; then
	for f in "$fw"/iwlwifi-*.ucode "$fw"/iwlwifi-*.ucode.xz; do
		[ -L "$f" ] || continue
		name=${f##*/}
		real=$(readlink -f "$fwsrc/$name" 2>/dev/null || true)
		rm -f "$f"
		[ -f "$real" ] && cp "$real" "$f"
		family=$(ucode_base "$f")
		for pn in "$family.pnvm" "$family.pnvm.xz"; do
			pnvm=$(readlink -f "$fwsrc/$pn" 2>/dev/null || true)
			[ -f "$pnvm" ] && cp "$pnvm" "$fw/$pn"
		done
	done
fi
