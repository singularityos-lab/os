#!/usr/bin/env bash
#
# Capture a freshly built WebKitGTK into a reusable prebuilt tarball.
# Must be run it from the OS repo root after a green webkitgtk build.
#
# Usage:
#   scripts/capture-webkit-prebuilt.sh [OUTPUT_DIR]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$REPO_DIR/buildroot-build}"
STAGING_DIR="${STAGING_DIR:-$(ls -d "$BUILD_DIR"/host/*/sysroot 2>/dev/null | head -1)}"
TARGET_DIR="${TARGET_DIR:-$BUILD_DIR/target}"
OUT_DIR="${1:-$REPO_DIR/prebuilt}"

WK_VERSION="$(sed -n 's/^WEBKITGTK_VERSION = //p' "$REPO_DIR/buildroot-src/package/webkitgtk/webkitgtk.mk" 2>/dev/null || true)"
[ -n "$WK_VERSION" ] || WK_VERSION="$(basename "$(ls -d "$BUILD_DIR"/build/webkitgtk-* 2>/dev/null | head -1)" | sed 's/^webkitgtk-//')"
[ -n "$WK_VERSION" ] || { echo "ERROR: cannot determine webkitgtk version"; exit 1; }

ARCH="$(uname -m)"
PKG_BUILD="$BUILD_DIR/build/webkitgtk-$WK_VERSION"
STAGING_LIST="$PKG_BUILD/.files-list-staging.txt"
TARGET_LIST="$PKG_BUILD/.files-list.txt"

for f in "$STAGING_LIST" "$TARGET_LIST"; do
	[ -s "$f" ] || { echo "ERROR: missing/empty $f (build webkitgtk first)"; exit 1; }
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
# Single top-level dir so Buildroot's extract (--strip-components=1) leaves
# staging/ and target/ at the package build root.
TOP="webkitgtk-prebuilt-$WK_VERSION"
mkdir -p "$WORK/$TOP/staging" "$WORK/$TOP/target"

copy_list() {
	local list="$1" src_root="$2" dst_root="$3" n=0
	while IFS=, read -r _pkg path; do
		[ -n "$path" ] || continue
		local rel="${path#./}"
		local src="$src_root/$rel"
		if [ -e "$src" ] || [ -L "$src" ]; then
			mkdir -p "$dst_root/$(dirname "$rel")"
			cp -a "$src" "$dst_root/$rel"
			n=$((n + 1))
		fi
	done < "$list"
	echo "$n"
}

echo "[capture] webkitgtk $WK_VERSION ($ARCH)"
sn="$(copy_list "$STAGING_LIST" "$STAGING_DIR" "$WORK/$TOP/staging")"
echo "[capture] staging files: $sn"
tn="$(copy_list "$TARGET_LIST" "$TARGET_DIR" "$WORK/$TOP/target")"
echo "[capture] target files:  $tn"

mkdir -p "$OUT_DIR"
TARBALL="$OUT_DIR/webkitgtk-prebuilt-$WK_VERSION-$ARCH.tar.zst"
if command -v zstd >/dev/null 2>&1; then
	tar -C "$WORK" -cf - "$TOP" | zstd -19 -T0 -q -o "$TARBALL" -f
else
	TARBALL="${TARBALL%.zst}.xz"
	tar -C "$WORK" -cJf "$TARBALL" "$TOP"
fi

echo "[capture] wrote $TARBALL ($(du -sh "$TARBALL" | cut -f1))"
echo "[capture] sha256: $(sha256sum "$TARBALL" | cut -d' ' -f1)"
