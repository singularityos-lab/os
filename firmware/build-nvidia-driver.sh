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

# Kernel-ABI stamp: the bundle is bound to this exact kernel. build-fw.sh copies this
# into the manifest (kernel=<ver>) and mount_firmware refuses a mismatch at boot.
printf '%s\n' "$KVER" > "$OUT/.kernel-abi"
printf '%s\n' "$ver"  > "$OUT/.nvidia-version"
log "DONE. payload -> $OUT   (kernel-abi=$KVER, nvidia=$ver, $(du -sh "$OUT" | cut -f1))"
