#!/usr/bin/env bash
#
# Sinty firmware add-on bundle factory.
#
# Builds signed, dm-verity-sealed erofs firmware add-on bundles for OTA delivery.
# The base survival firmware (CPU microcode, iwlwifi, ath, rtw, base Intel display)
# stays in the Root; these bundles are the EXTRA hardware-detected add-ons that the
# installer/updater fetches only for the detected hardware, post-install.
#
# Each bundle dir is a complete anchor the initramfs (mount_firmware) can verify and
# mount fail-open:
#   firmware-active.img            erofs image (unioned over base at /usr/lib/firmware)
#   firmware-active.hash           dm-verity hash tree sidecar
#   fw-manifest-active.json(.sig)  release-signed manifest naming the bundle
#   fw-signing-cert-active.json(.sig)  root-signed signing cert (root -> cert -> manifest)
#
# The proprietary NVIDIA GSP firmware is fetched from NVIDIA at BUILD time and never
# committed (NVIDIA license). Only this script (and .gitignore) live in the repo; the
# licensed blobs go straight into the built bundle under out/ (gitignored).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OS="$(cd "$HERE/.." && pwd)"

ATOMLOOPS="${ATOMLOOPS:-/home/mirko/Projects/personal/AtomLoops}"
LINUX_FIRMWARE="${LINUX_FIRMWARE:-$OS/buildroot-build/build/linux-firmware-20251011}"
URL_BASE="${URL_BASE:-https://ota.sinty.local/firmware}"
OUT="${OUT:-$HERE/out}"
TOOLS="$HERE/.tools"
DL="$TOOLS/dl"

# TEST keys (override for production).
SIGNING_KEY="${SIGNING_KEY:-$ATOMLOOPS/signing-v1.key}"
SIGNING_CERT="${SIGNING_CERT:-$ATOMLOOPS/signing-cert-v1.json}"
ROOT_PUB="${ROOT_PUB:-$ATOMLOOPS/loader/src/root.pub}"

# NVIDIA proprietary driver to source the GSP firmware from. "latest" resolves the
# current production release.
NVIDIA_VERSION="${NVIDIA_VERSION:-latest}"

log() { printf '[fw] %s\n' "$*" >&2; }
die() { printf '[fw] ERROR: %s\n' "$*" >&2; exit 1; }

# --- NVIDIA proprietary GSP firmware: fetched at build, never committed --------
# Downloads the .run installer and extracts firmware/gsp_*.bin. The blobs are
# NVIDIA-licensed; they stay under .tools/ (gitignored) and go only into the built
# bundle, never into the repo. Set NVIDIA_FW_DIR to reuse an already-extracted tree.
resolve_nvidia() {
	if [ -n "${NVIDIA_FW_DIR:-}" ]; then
		NVIDIA_DEST="${NVIDIA_FW_DEST:-nvidia}"
		return
	fi
	command -v curl >/dev/null || die "curl needed to fetch the NVIDIA driver"
	local base="https://download.nvidia.com/XFree86/Linux-x86_64" ver="$NVIDIA_VERSION"
	[ "$ver" = latest ] && ver="$(curl -fsSL "$base/latest.txt" | awk '{print $1}')"
	[ -n "$ver" ] || die "could not resolve the NVIDIA driver version"
	local run="NVIDIA-Linux-x86_64-$ver.run" ex="$DL/NVIDIA-Linux-x86_64-$ver"
	mkdir -p "$DL"
	[ -f "$DL/$run" ] || { log "nvidia: downloading proprietary driver $ver (licensed, not committed)"; curl -fSL --retry 3 -o "$DL/$run" "$base/$ver/$run"; }
	[ -d "$ex" ] || ( cd "$DL" && sh "$run" --extract-only >/dev/null 2>&1 )
	local gsp; gsp="$(find "$ex" -name 'gsp_*.bin' | head -1)"
	[ -n "$gsp" ] || die "no gsp_*.bin in the NVIDIA driver $ver"
	NVIDIA_FW_DIR="$(dirname "$gsp")"
	NVIDIA_DEST="nvidia/$ver"
	log "nvidia: proprietary GSP firmware $ver at $NVIDIA_FW_DIR"
}

# --- tooling: build atom-sign + fw-verify from AtomLoops if absent ------------
mkdir -p "$TOOLS"
ATOM_SIGN="${ATOM_SIGN:-$TOOLS/atom-sign}"
FW_VERIFY="${FW_VERIFY:-$TOOLS/fw-verify}"
[ -d "$ATOMLOOPS" ] || die "AtomLoops not found at $ATOMLOOPS (set ATOMLOOPS=)"
[ -x "$ATOM_SIGN" ] || { log "building atom-sign"; ( cd "$ATOMLOOPS" && go build -o "$ATOM_SIGN" ./cmd/atom-sign ); }
[ -x "$FW_VERIFY" ] || { log "building fw-verify"; ( cd "$ATOMLOOPS" && CGO_ENABLED=0 go build -o "$FW_VERIFY" ./cmd/fw-verify ); }
for f in "$SIGNING_KEY" "$SIGNING_CERT" "$SIGNING_CERT.sig" "$ROOT_PUB"; do
	[ -f "$f" ] || die "missing key/cert file: $f"
done
command -v mkfs.erofs >/dev/null || die "mkfs.erofs not found (install erofs-utils)"
command -v veritysetup >/dev/null || die "veritysetup not found (install cryptsetup)"

resolve_nvidia

# "<name> <source-tree> <dest-subdir under /usr/lib/firmware>". nvidia is the
# PROPRIETARY driver firmware (gsp_*.bin), staged under nvidia/<version> exactly
# where the closed driver loads it; amd is linux-firmware's amdgpu (AMD's official
# redistributable GPU firmware).
BUNDLES=(
	"nvidia $NVIDIA_FW_DIR $NVIDIA_DEST"
	"amd $LINUX_FIRMWARE/amdgpu amdgpu"
)

# atom-sign manifest requires rootfs+kernelcache fields (it is the whole-system
# manifest format); a firmware-only anchor fills them with a placeholder fw-verify
# never reads (it extracts only the named firmware bundle).
mkdir -p "$OUT"
PLACE="$OUT/.placeholder"
printf 'firmware-only anchor placeholder\n' > "$PLACE"

build_bundle() {
	local name="$1" src="$2" dest="$3"
	[ -d "$src" ] || die "firmware source $src not found"
	local bdir="$OUT/$name" stage="$OUT/.stage-$name"
	rm -rf "$bdir" "$stage"; mkdir -p "$bdir" "$stage/$(dirname "$dest")"

	# Stage so the erofs root mirrors /usr/lib/firmware: files land at
	# /usr/lib/firmware/<dest>/ once overlay-unioned over the base.
	cp -al "$src" "$stage/$dest" 2>/dev/null || cp -a "$src" "$stage/$dest"
	local nfiles; nfiles="$(find "$stage" -type f | wc -l)"
	log "$name: staged $nfiles files -> /usr/lib/firmware/$dest ($(du -sh "$src" | cut -f1))"

	mkfs.erofs -zlz4hc "$bdir/firmware-active.img" "$stage" >/dev/null
	local roothash
	roothash="$(veritysetup format "$bdir/firmware-active.img" "$bdir/firmware-active.hash" \
		| awk '/Root hash:/{print $NF}')"
	[ -n "$roothash" ] || die "$name: veritysetup produced no root hash"
	log "$name: erofs $(du -h "$bdir/firmware-active.img" | cut -f1), verity roothash $roothash"

	"$ATOM_SIGN" manifest --out "$bdir/fw-manifest-active.json" \
		--version v1 \
		--rootfs "$PLACE" --rootfs-url "$URL_BASE/_unused/rootfs" \
		--kernelcache "$PLACE" --kc-url "$URL_BASE/_unused/kernelcache" \
		--bundle "name=$name,img=$bdir/firmware-active.img,url=$URL_BASE/$name/firmware-active.img,verity=$roothash,hashtree=$bdir/firmware-active.hash,hashtree-url=$URL_BASE/$name/firmware-active.hash,version=1,chips=$name" >&2
	"$ATOM_SIGN" sign --manifest "$bdir/fw-manifest-active.json" --priv "$SIGNING_KEY" >&2

	cp "$SIGNING_CERT" "$bdir/fw-signing-cert-active.json"
	cp "$SIGNING_CERT.sig" "$bdir/fw-signing-cert-active.json.sig"

	# Prove the anchor: re-run the offline trust chain, must print the same roothash.
	local verified
	verified="$("$FW_VERIFY" "$bdir" active "$ROOT_PUB" "$name")"
	[ "$verified" = "$roothash" ] || die "$name: fw-verify roothash mismatch ($verified != $roothash)"
	log "$name: VERIFIED, anchor roothash matches ($verified)"
	rm -rf "$stage"
}

log "output -> $OUT"
for spec in "${BUNDLES[@]}"; do
	set -- $spec
	log "=== bundle: $1 (from $2) ==="
	build_bundle "$1" "$2" "$3"
done
rm -f "$PLACE"
log "DONE. Built ${#BUNDLES[@]} signed firmware bundles under $OUT"
