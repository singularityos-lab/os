#!/usr/bin/env bash
#
# Capture a freshly built Fotone engine into a reusable prebuilt tarball.
# Run it from the OS repo root after a green fotone build.
#
# Usage:
#   scripts/capture-fotone-prebuilt.sh [OUTPUT_DIR]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$REPO_DIR/scripts/arch.sh"
BUILD_PATH="$REPO_DIR/$BUILD_DIR"
TARGET_DIR="${TARGET_DIR:-$BUILD_PATH/target}"
OUT_DIR="${1:-$REPO_DIR/prebuilt}"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "$SINTY_WORK_ROOT"

PKG_BUILD="$(ls -d "$BUILD_PATH"/build/fotone-* 2>/dev/null | grep -v prebuilt | head -1)"
[ -n "$PKG_BUILD" ] || { echo "ERROR: fotone was not built from source in $BUILD_PATH"; exit 1; }
LIST="$PKG_BUILD/.files-list.txt"
[ -s "$LIST" ] || { echo "ERROR: missing/empty $LIST (build fotone first)"; exit 1; }

COMMIT="${PKG_BUILD##*/fotone-}"
PC="$(ls "$PKG_BUILD"/upstream/build/stage/usr/local/lib/pkgconfig/wpe-webkit-*.pc 2>/dev/null | head -1)"
WPE_VERSION="$(sed -n 's/^Version: //p' "$PC" 2>/dev/null || true)"
[ -n "$WPE_VERSION" ] || { echo "ERROR: cannot determine the WPE WebKit version"; exit 1; }
VERSION="${FOTONE_PREBUILT_VERSION:-$WPE_VERSION-${COMMIT:0:7}.1}"

WORK="$(mktemp -d "$SINTY_WORK_ROOT/fotone-prebuilt.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
TOP=fotone-engine
mkdir -p "$WORK/$TOP"

n=0
while IFS=, read -r _pkg path; do
	[ -n "$path" ] || continue
	rel="${path#./}"
	src="$TARGET_DIR/$rel"
	if [ -e "$src" ] || [ -L "$src" ]; then
		mkdir -p "$WORK/$TOP/$(dirname "$rel")"
		cp -a "$src" "$WORK/$TOP/$rel"
		n=$((n + 1))
	fi
done < "$LIST"
[ "$n" -gt 0 ] || { echo "ERROR: no fotone files found in $TARGET_DIR"; exit 1; }
for l in usr/lib/libwebkitgtk-6.0.so.4 usr/lib/libjavascriptcoregtk-6.0.so.1; do
	[ -L "$WORK/$TOP/$l" ] || { echo "ERROR: $l is not the proxy link"; exit 1; }
done
echo "[capture] fotone $VERSION ($ARCH): $n files"

mkdir -p "$OUT_DIR"
TARBALL="$OUT_DIR/fotone-engine-$VERSION-$ARCH.tar.zst"
tar -C "$WORK" --owner=0 --group=0 -cf - "$TOP" | zstd -19 -T0 -q -o "$TARBALL" -f
echo "[capture] wrote $TARBALL ($(du -sh "$TARBALL" | cut -f1))"
echo "[capture] sha256: $(sha256sum "$TARBALL" | cut -d' ' -f1)"
