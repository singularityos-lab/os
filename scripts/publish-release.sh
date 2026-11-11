#!/bin/bash
set -euo pipefail

TAG=$1
REVIEW=$2
SHA=$3
IMAGES=$4
REPO=${GITHUB_REPOSITORY:-singularityos-lab/os}
ARCH=${ARCH:-x86_64}
S=${SHA:0:7}
N=$S
FAMILIES=""
if [ "$ARCH" = aarch64 ]; then
    TAG=$TAG-arm64
    N=arm64-$S
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

VERSION="$(cat "$ROOT/release/product-version") ($(cat "$ROOT/release/product-build"))"
DATE="$(date -u +%Y-%m-%d)"

declare -A names=(
    [sinty-os.img]="sinty-os-$N.img"
    [sinty-os.iso]="sinty-os-$N.iso"
    [sinty-os-portable.img]="sinty-os-portable-$N.img"
    [kernelcache.efi]="kernelcache-$N.efi"
    [kernelcache.efi.sig]="kernelcache-$N.efi.sig"
    [kernelcache-recovery.efi]="kernelcache-recovery-$N.efi"
    [kernelcache-recovery.efi.sig]="kernelcache-recovery-$N.efi.sig"
    [rootfs.erofs]="rootfs-$N.erofs"
    [rootfs.hash]="rootfs-$N.hash"
    [verity-output.txt]="verity-output-$N.txt"
)
for src in "${!names[@]}"; do
    [ -f "$IMAGES/$src" ] || { echo "publish: missing $src" >&2; exit 1; }
    cp "$IMAGES/$src" "$OUT/${names[$src]}"
done

FW=0
if [ "$ARCH" = aarch64 ]; then
    for kc in "$IMAGES"/kernelcache.*.efi; do
        [ -f "$kc" ] || continue
        fam=$(basename "$kc" .efi)
        fam=${fam#kernelcache.}
        [ -f "$kc.sig" ] || { echo "publish: $fam kernelcache is not signed" >&2; exit 1; }
        cp "$kc" "$OUT/kernelcache-$fam-$N.efi"
        cp "$kc.sig" "$OUT/kernelcache-$fam-$N.efi.sig"
        FAMILIES=${FAMILIES:+$FAMILIES,}$fam
    done
    if [ -f "$IMAGES/sinty-board-firmware.tar.xz" ]; then
        cp "$IMAGES/sinty-board-firmware.tar.xz" "$OUT/sinty-board-firmware-$N.tar.xz"
        FW=1
    fi
fi

firmware_from() {
    gh release view "$1" -R "$REPO" --json assets \
        -q '[.assets[]|select(.name|test("^sinty-firmware-nvidia-[0-9a-f]{7}\\.tar\\.zst$"))]|sort_by(.createdAt)|last|.name // ""' 2>/dev/null \
        | sed -E 's/^sinty-firmware-nvidia-([0-9a-f]{7})\.tar\.zst$/\1/'
}

FW_RELEASE=$TAG
PREV=""
if [ "$ARCH" != aarch64 ]; then
    PREV=$(firmware_from "$TAG")
    if [ -z "$PREV" ] && [ "$TAG" != nightly ]; then
        FW_RELEASE=nightly
        PREV=$(firmware_from nightly)
    fi
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

(cd "$OUT" && sha256sum -- * > "SHA256SUMS-$N.txt")

if ! gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    PRERELEASE=--prerelease
    case "$TAG" in stable|stable-arm64) PRERELEASE= ;; esac
    python3 "$HERE/release-table.py" - "$REPO" "$TAG" "$REVIEW" "$VERSION" "$DATE" "$S" "$FW" "$ARCH" "$FAMILIES" > "$OUT.notes"
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
    python3 "$HERE/release-table.py" "$OUT.body" "$REPO" "$TAG" "$REVIEW" "$VERSION" "$DATE" "$S" "$FW" "$ARCH" "$FAMILIES" > "$OUT.notes"
    gh release edit "$TAG" -R "$REPO" --notes-file "$OUT.notes"
    rm -f "$OUT.body" "$OUT.notes"
fi

echo "publish: $REVIEW on $TAG from $S ($VERSION, $ARCH)"
