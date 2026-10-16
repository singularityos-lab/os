#!/bin/bash
set -euo pipefail

TAG=$1
REVIEW=$2
SHA=$3
IMAGES=$4
REPO=${GITHUB_REPOSITORY:-singularityos-lab/os}
S=${SHA:0:7}
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

VERSION="$(cat "$ROOT/release/product-version") ($(cat "$ROOT/release/product-build"))"
DATE="$(date -u +%Y-%m-%d)"

declare -A names=(
    [sinty-os.img]="sinty-os-$S.img"
    [sinty-os.iso]="sinty-os-$S.iso"
    [sinty-os-portable.img]="sinty-os-portable-$S.img"
    [kernelcache.efi]="kernelcache-$S.efi"
    [kernelcache.efi.sig]="kernelcache-$S.efi.sig"
    [kernelcache-recovery.efi]="kernelcache-recovery-$S.efi"
    [kernelcache-recovery.efi.sig]="kernelcache-recovery-$S.efi.sig"
    [rootfs.erofs]="rootfs-$S.erofs"
    [rootfs.hash]="rootfs-$S.hash"
    [verity-output.txt]="verity-output-$S.txt"
)
for src in "${!names[@]}"; do
    [ -f "$IMAGES/$src" ] || { echo "publish: missing $src" >&2; exit 1; }
    cp "$IMAGES/$src" "$OUT/${names[$src]}"
done

firmware_from() {
    gh release view "$1" -R "$REPO" --json assets \
        -q '[.assets[]|select(.name|test("^sinty-firmware-nvidia-[0-9a-f]{7}\\.tar\\.zst$"))]|sort_by(.createdAt)|last|.name // ""' 2>/dev/null \
        | sed -E 's/^sinty-firmware-nvidia-([0-9a-f]{7})\.tar\.zst$/\1/'
}

FW=0
FW_RELEASE=$TAG
PREV=$(firmware_from "$TAG")
if [ -z "$PREV" ] && [ "$TAG" != nightly ]; then
    FW_RELEASE=nightly
    PREV=$(firmware_from nightly)
fi
if [ -n "$PREV" ]; then
    gh release download "$FW_RELEASE" -R "$REPO" -D "$OUT/prev" \
        -p "SHA256SUMS-$PREV.txt" -p "sinty-firmware-*-$PREV.*"
    (cd "$OUT/prev" && grep -E " sinty-firmware-(amd|nvidia)-$PREV\." "SHA256SUMS-$PREV.txt" | sha256sum -c -)
    for f in "$OUT"/prev/sinty-firmware-*-"$PREV".*; do
        n=$(basename "$f")
        mv "$f" "$OUT/${n/-$PREV./-$S.}"
    done
    rm -rf "$OUT/prev"
    FW=1
fi

(cd "$OUT" && sha256sum -- * > "SHA256SUMS-$S.txt")

if ! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    PRERELEASE=--prerelease
    [ "$TAG" = stable ] && PRERELEASE=
    python3 "$HERE/release-table.py" - "$REPO" "$TAG" "$REVIEW" "$VERSION" "$DATE" "$S" "$FW" > "$OUT.notes"
    gh release create "$TAG" -R "$REPO" --target "$SHA" --title "Sinty OS $TAG" $PRERELEASE --notes-file "$OUT.notes"
    rm -f "$OUT.notes"
    BODY_DONE=1
else
    BODY_DONE=0
fi

gh release upload "$TAG" -R "$REPO" --clobber "$OUT"/*

for f in "$OUT"/*; do
    n=$(basename "$f")
    size=$(gh release view "$TAG" -R "$REPO" --json assets -q ".assets[]|select(.name==\"$n\")|.size")
    [ "$size" = "$(stat -c %s "$f")" ] || { echo "publish: $n did not upload intact" >&2; exit 1; }
done

if [ "$BODY_DONE" = 0 ]; then
    gh release view "$TAG" -R "$REPO" --json body -q .body > "$OUT.body"
    python3 "$HERE/release-table.py" "$OUT.body" "$REPO" "$TAG" "$REVIEW" "$VERSION" "$DATE" "$S" "$FW" > "$OUT.notes"
    gh release edit "$TAG" -R "$REPO" --notes-file "$OUT.notes"
    rm -f "$OUT.body" "$OUT.notes"
fi

echo "publish: $REVIEW on $TAG from $S ($VERSION)"
