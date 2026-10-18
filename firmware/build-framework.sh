#!/usr/bin/env bash
#
# Builds the Singularity framework bundle: libsingularity, libsingularity-system,
# the GTK library and their typelibs as a signed, dm-verity sealed erofs image.
# It travels on the firmware track and the initramfs mounts it over
# /usr/lib/sinty-framework when its version is above the one in the root, so the
# framework can be updated without a new system image.
#
#   firmware/build-framework.sh [version]
#
# The version defaults to the root's own .overlay-version, which builds a bundle
# the root ignores; pass a higher one to ship a newer framework.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OS="$(cd "$HERE/.." && pwd)"

ATOMLOOPS="${ATOMLOOPS:-$OS/../AtomLoops}"
SRC="${FRAMEWORK_SRC:-$OS/buildroot-build/target/usr/lib/sinty-framework}"
URL_BASE="${URL_BASE:-https://updates.sinty.dev/firmware}"
OUT="${OUT:-$OS/artifacts/framework}"
TOOLS="$HERE/.tools"
NAME=singularity-framework

SIGNING_KEY="${SIGNING_KEY:-${ATOM_SIGNING_KEY:-}}"
SIGNING_CERT="${SIGNING_CERT:-${ATOM_SIGNING_CERT:-}}"
ROOT_PUB="${ROOT_PUB:-${ATOM_ROOT_PUB:-}}"

log() { printf '[framework] %s\n' "$*" >&2; }
die() { printf '[framework] ERROR: %s\n' "$*" >&2; exit 1; }

[ -d "$SRC" ] || die "framework tree $SRC not found"
[ -f "$SRC/.overlay-version" ] || die "$SRC has no .overlay-version"
VERSION="${1:-$(cat "$SRC/.overlay-version")}"
case "$VERSION" in ''|*[!0-9]*) die "version must be a positive integer" ;; esac
for f in "$SIGNING_KEY" "$SIGNING_CERT" "$SIGNING_CERT.sig" "$ROOT_PUB"; do
	[ -n "$f" ] && [ -f "$f" ] || die "missing key/cert file: ${f:-unset}"
done
command -v mkfs.erofs >/dev/null || die "mkfs.erofs not found (install erofs-utils)"
command -v veritysetup >/dev/null || die "veritysetup not found (install cryptsetup)"

mkdir -p "$TOOLS"
ATOM_SIGN="${ATOM_SIGN:-$TOOLS/atom-sign}"
FW_VERIFY="${FW_VERIFY:-$TOOLS/fw-verify}"
[ -x "$ATOM_SIGN" ] || ( cd "$ATOMLOOPS" && go build -o "$ATOM_SIGN" ./cmd/atom-sign )
[ -x "$FW_VERIFY" ] || ( cd "$ATOMLOOPS" && CGO_ENABLED=0 go build -o "$FW_VERIFY" ./cmd/fw-verify )

bdir="$OUT/$NAME" stage="$OUT/.stage-$NAME"
rm -rf "$bdir" "$stage"
mkdir -p "$bdir" "$OUT"
cp -a "$SRC" "$stage"
printf '%s\n' "$VERSION" > "$stage/.overlay-version"
printf 'target=/usr/lib/sinty-framework\nversion=%s\n' "$VERSION" > "$stage/.overlay"
log "staged $(find "$stage" -type f | wc -l) files, version $VERSION"

mkfs.erofs -zlz4hc,9 -E ztailpacking -T0 --all-root "$bdir/firmware-active.img" "$stage" >/dev/null
roothash="$(veritysetup format "$bdir/firmware-active.img" "$bdir/firmware-active.hash" | awk '/Root hash:/{print $NF}')"
[ -n "$roothash" ] || die "veritysetup produced no root hash"

PLACE="$OUT/.placeholder"
printf 'framework-only anchor placeholder\n' > "$PLACE"
"$ATOM_SIGN" manifest --out "$bdir/fw-manifest-active.json" \
	--version "v$VERSION" \
	--rootfs "$PLACE" --rootfs-url "$URL_BASE/_unused/rootfs" \
	--rootfs-verity-hash "$(printf '0%.0s' $(seq 64))" \
	--rootfs-hashtree "$PLACE" --rootfs-hashtree-url "$URL_BASE/_unused/rootfs.hash" \
	--kernelcache "$PLACE" --kc-url "$URL_BASE/_unused/kernelcache" \
	--kc-sig "$PLACE" --kc-sig-url "$URL_BASE/_unused/kernelcache.sig" \
	--bundle "name=$NAME,img=$bdir/firmware-active.img,url=$URL_BASE/$NAME/firmware-active.img,verity=$roothash,hashtree=$bdir/firmware-active.hash,hashtree-url=$URL_BASE/$NAME/firmware-active.hash,version=$VERSION" >&2
"$ATOM_SIGN" sign --manifest "$bdir/fw-manifest-active.json" --priv "$SIGNING_KEY" >&2
cp "$SIGNING_CERT" "$bdir/fw-signing-cert-active.json"
cp "$SIGNING_CERT.sig" "$bdir/fw-signing-cert-active.json.sig"
rm -rf "$stage" "$PLACE"

verified="$("$FW_VERIFY" "$bdir" active "$ROOT_PUB" "$NAME")"
[ "$verified" = "$roothash" ] || die "fw-verify root hash mismatch ($verified != $roothash)"
log "VERIFIED $bdir version $VERSION, root hash $roothash"
