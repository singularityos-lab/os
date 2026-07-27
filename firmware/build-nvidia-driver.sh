#!/usr/bin/env bash
#
# Builds the PROPRIETARY NVIDIA driver payload (kernel modules + userspace) for the
# NVIDIA GPU add-on bundle, against the EXACT shipped kernel. Output is a staging tree
# stamped with the kernel version; build-fw.sh turns it into the signed, kernel-bound
# dm-verity bundle. The .run is NVIDIA-licensed: fetched at build, extracted under
# .tools/ (gitignored), never committed; the built .ko/userspace go only into the
# bundle, which ships from a PRIVATE feed (not a public release).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OS="$(cd "$HERE/.." && pwd)"
TOOLS="$HERE/.tools"; DL="$TOOLS/dl"
OUT="${OUT:-$HERE/out/nvidia-driver}"

log() { printf '[nv-drv] %s\n' "$*" >&2; }
die() { printf '[nv-drv] ERROR: %s\n' "$*" >&2; exit 1; }

# Kernel to build against: the built buildroot tree (has Module.symvers + .config).
KDIR="${KDIR:-$(for d in "$OS"/buildroot-build/build/linux-[0-9]*/; do [ -f "${d}Module.symvers" ] && { echo "$d"; break; }; done)}"
[ -f "${KDIR%/}/Module.symvers" ] || die "kernel build tree not built at KDIR=$KDIR (run the kernel build first)"
KDIR="${KDIR%/}"
KVER="$(cat "$KDIR/include/config/kernel.release")"
CROSS="${CROSS:-$OS/buildroot-build/host/bin/x86_64-buildroot-linux-gnu-}"
[ -x "${CROSS}gcc" ] || die "cross toolchain not found at ${CROSS}gcc"
log "kernel: $KVER   KDIR=$KDIR   CROSS=${CROSS##*/bin/}"

# Resolve + fetch the .run (licensed; never committed). "latest" resolves current prod.
NVIDIA_VERSION="${NVIDIA_VERSION:-latest}"
base="https://download.nvidia.com/XFree86/Linux-x86_64"
ver="$NVIDIA_VERSION"
[ "$ver" = latest ] && ver="$(curl -fsSL "$base/latest.txt" | awk '{print $1}')"
[ -n "$ver" ] || die "cannot resolve the NVIDIA driver version"
run="NVIDIA-Linux-x86_64-$ver.run"; ex="$DL/NVIDIA-Linux-x86_64-$ver"
mkdir -p "$DL"
[ -f "$DL/$run" ] || { log "downloading proprietary driver $ver (licensed, not committed)"; curl -fSL --retry 3 -o "$DL/$run" "$base/$ver/$run"; }
[ -d "$ex" ] || ( cd "$DL" && sh "$run" --extract-only >/dev/null 2>&1 ) || die "extract failed"
log "driver $ver extracted at $ex"

# Proprietary kernel modules live in kernel/ (kernel-open/ is the open variant we are
# NOT using per the proprietary decision). Build against our kernel with our toolchain.
KSRC="$ex/kernel"
[ -d "$KSRC" ] || die "no proprietary kernel/ module source in the .run (only kernel-open/?)"
log "building nvidia kernel modules against $KVER ..."
make -C "$KSRC" -j"$(nproc)" \
	SYSSRC="$KDIR" SYSOUT="$KDIR" \
	ARCH=x86_64 CC="${CROSS}gcc" LD="${CROSS}ld" OBJCOPY="${CROSS}objcopy" \
	modules >&2 || die "nvidia kernel module build FAILED against $KVER (kernel API drift?)"

mods="$(find "$KSRC" -maxdepth 1 -name 'nvidia*.ko' | sort)"
[ -n "$mods" ] || die "no nvidia*.ko produced"
log "built modules:"; echo "$mods" | sed 's/^/[nv-drv]   /' >&2

# Stage: modules under /usr/lib/modules/<kver>/extra/nvidia, userspace .so under /usr/lib.
rm -rf "$OUT"; mkdir -p "$OUT/usr/lib/modules/$KVER/extra/nvidia" "$OUT/usr/lib"
for m in $mods; do "${CROSS}strip" --strip-debug "$m" -o "$OUT/usr/lib/modules/$KVER/extra/nvidia/$(basename "$m")"; done
for so in \
	libGLX_nvidia.so."$ver" libEGL_nvidia.so."$ver" libGLESv2_nvidia.so."$ver" \
	libnvidia-glcore.so."$ver" libnvidia-eglcore.so."$ver" libnvidia-glsi.so."$ver" \
	libnvidia-glvkspirv.so."$ver" libnvidia-rtcore.so."$ver" libnvidia-gpucomp.so."$ver" \
	libnvidia-tls.so."$ver" libnvidia-ml.so."$ver" libcuda.so."$ver" \
	libnvidia-egl-gbm.so.* libnvidia-egl-wayland.so.* ; do
	f="$(ls "$ex/$so" 2>/dev/null | head -1)" || true
	[ -n "${f:-}" ] && [ -f "$f" ] && cp -a "$f" "$OUT/usr/lib/" || true
done

# GSP firmware the proprietary driver loads at runtime, staged where it looks for it.
if [ -d "$ex/firmware" ]; then
	mkdir -p "$OUT/usr/lib/firmware/nvidia/$ver"
	cp -a "$ex"/firmware/* "$OUT/usr/lib/firmware/nvidia/$ver/" 2>/dev/null || true
fi

# Kernel-ABI stamp at the bundle root: mount_firmware reads .kernel-abi and refuses the
# bundle if it does not match the running kernel (a kernel update invalidates it).
printf '%s\n' "$KVER" > "$OUT/.kernel-abi"
printf '%s\n' "$ver"  > "$OUT/.nvidia-version"
log "payload -> $OUT   (kernel-abi=$KVER, nvidia=$ver, $(du -sh "$OUT" | cut -f1))"

# --- package into the signed, kernel-bound dm-verity bundle -------------------
# Same trust chain as firmware/build-fw.sh (root.pub -> signing cert -> manifest ->
# verity), so the initramfs fw-verify accepts it. TEST keys by default; production
# injects the real signing key/cert. The driver payload IS the erofs root (it already
# mirrors /usr/lib), so no dest-staging: mkfs.erofs straight over $OUT.
if [ "${PACKAGE:-1}" = 1 ]; then
	ATOMLOOPS="${ATOMLOOPS:-$OS/../AtomLoops}"
	SIGNING_KEY="${SIGNING_KEY:-$ATOMLOOPS/signing-v1.key}"
	SIGNING_CERT="${SIGNING_CERT:-$ATOMLOOPS/signing-cert-v1.json}"
	ROOT_PUB="${ROOT_PUB:-$ATOMLOOPS/loader/src/root.pub}"
	URL_BASE="${URL_BASE:-https://updates.sinty.dev/firmware}"
	ATOM_SIGN="${ATOM_SIGN:-$TOOLS/atom-sign}"
	FW_VERIFY="${FW_VERIFY:-$TOOLS/fw-verify}"
	[ -d "$ATOMLOOPS" ] || die "AtomLoops not found at $ATOMLOOPS (set ATOMLOOPS=)"
	[ -x "$ATOM_SIGN" ] || ( cd "$ATOMLOOPS" && go build -o "$ATOM_SIGN" ./cmd/atom-sign )
	[ -x "$FW_VERIFY" ] || ( cd "$ATOMLOOPS" && CGO_ENABLED=0 go build -o "$FW_VERIFY" ./cmd/fw-verify )
	command -v mkfs.erofs >/dev/null || die "mkfs.erofs not found (erofs-utils)"
	command -v veritysetup >/dev/null || die "veritysetup not found (cryptsetup)"

	BDIR="$HERE/out/nvidia"; rm -rf "$BDIR"; mkdir -p "$BDIR"
	PLACE="$HERE/out/.place-nv"; printf 'anchor placeholder\n' > "$PLACE"
	log "packaging bundle -> $BDIR (erofs of the driver payload) ..."
	mkfs.erofs -zlz4hc "$BDIR/firmware-active.img" "$OUT" >/dev/null
	roothash="$(veritysetup format "$BDIR/firmware-active.img" "$BDIR/firmware-active.hash" | awk '/Root hash:/{print $NF}')"
	[ -n "$roothash" ] || die "veritysetup produced no root hash"
	"$ATOM_SIGN" manifest --out "$BDIR/fw-manifest-active.json" --version v1 \
		--rootfs "$PLACE" --rootfs-url "$URL_BASE/_unused/rootfs" \
		--kernelcache "$PLACE" --kc-url "$URL_BASE/_unused/kernelcache" \
		--bundle "name=nvidia,img=$BDIR/firmware-active.img,url=$URL_BASE/nvidia/firmware-active.img,verity=$roothash,hashtree=$BDIR/firmware-active.hash,hashtree-url=$URL_BASE/nvidia/firmware-active.hash,version=1,chips=nvidia" >&2
	"$ATOM_SIGN" sign --manifest "$BDIR/fw-manifest-active.json" --priv "$SIGNING_KEY" >&2
	cp "$SIGNING_CERT" "$BDIR/fw-signing-cert-active.json"
	cp "$SIGNING_CERT.sig" "$BDIR/fw-signing-cert-active.json.sig"
	verified="$("$FW_VERIFY" "$BDIR" active "$ROOT_PUB" nvidia)"
	[ "$verified" = "$roothash" ] || die "fw-verify roothash mismatch ($verified != $roothash)"
	rm -f "$PLACE"
	log "BUNDLE VERIFIED: $BDIR (roothash $verified, kernel-abi $KVER, erofs $(du -h "$BDIR/firmware-active.img" | cut -f1))"
fi
