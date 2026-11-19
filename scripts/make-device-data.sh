#!/usr/bin/env bash
# Data image for a device that boots from its data partition and has no ESP,
# such as the Pixel 7 Pro: the signed release staged by atom-install, packed
# into an f2fs image as small as its contents. The device grows it to the whole
# partition on its first boot.
set -euo pipefail

usage() { echo "usage: make-device-data.sh <signed release dir> <userdata.img>" >&2; exit 2; }
[ $# -eq 2 ] || usage
REL="$(cd "$1" && pwd)"
OUT="$2"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for t in mkfs.f2fs sload.f2fs fsck.f2fs dump.erofs; do
	command -v "$t" >/dev/null || { echo "make-device-data: $t not found" >&2; exit 1; }
done
for f in manifest.json manifest.json.sig signing-cert.json signing-cert.json.sig rootfs.erofs rootfs.hash; do
	[ -f "$REL/$f" ] || { echo "make-device-data: the release has no $f" >&2; exit 1; }
done

WORK="$(mktemp -d "${SINTY_WORK_ROOT:-${TMPDIR:-/tmp}}/device-data.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

ATOM_INSTALL="${ATOM_INSTALL:-}"
if [ -z "$ATOM_INSTALL" ]; then
	ATOM_INSTALL="$WORK/atom-install"
	( cd "$REPO_DIR/package/atom-install" && CGO_ENABLED=0 go build -o "$ATOM_INSTALL" . )
fi

mkdir -p "$WORK/sysroot/etc/greetd"
dump.erofs --cat --path=/etc/greetd/config.toml "$REL/rootfs.erofs" > "$WORK/sysroot/etc/greetd/config.toml"
[ -s "$WORK/sysroot/etc/greetd/config.toml" ] || { echo "make-device-data: the root has no greetd config" >&2; exit 1; }

"$ATOM_INSTALL" --data-dir "$WORK/data" --from "$REL" --sysroot "$WORK/sysroot"

used_mb=$(( $(du -sm --apparent-size "$WORK/data" | cut -f1) ))
size_mb=$(( used_mb + used_mb / 10 + 512 ))
rm -f "$OUT"
truncate -s "${size_mb}M" "$OUT"
mkfs.f2fs -q -f -l atom-data -O encrypt,extra_attr "$OUT"
sload.f2fs -f "$WORK/data" -t / "$OUT" >/dev/null
fsck.f2fs -f "$OUT" >/dev/null 2>&1 || { echo "make-device-data: the packed image does not check clean" >&2; exit 1; }
echo "make-device-data: $OUT, ${size_mb} MiB, release $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$REL/manifest.json" | head -1)"
