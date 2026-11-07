#!/bin/bash

set -eo pipefail

REPO_DIR="$(pwd)"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$REPO_DIR" log -1 --format=%ct)}"
export SOURCE_DATE_EPOCH
BUILD_SEED="$(git -C "$REPO_DIR" rev-parse HEAD)"
seed_uuid() {
    printf '%s-%s' "$1" "$BUILD_SEED" | sha256sum | sed -E 's/^(.{8})(.{4})(.{4})(.{4})(.{12}).*/\1-\2-\3-\4-\5/'
}
ATOMLOOPS="${ATOMLOOPS:-${REPO_DIR}/../AtomLoops}"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "${SINTY_WORK_ROOT}"
if [ -z "${ATOM_VERSION:-}" ]; then
    ATOM_VERSION="$(cat "${REPO_DIR}/release/atom-version")"
fi
case "${ATOM_VERSION}" in
    *[!0-9]*|"")
        echo "package: ATOM_VERSION must be a positive integer" >&2
        exit 1
        ;;
esac
if [ "${ATOM_VERSION}" -le 0 ]; then
    echo "package: ATOM_VERSION must be a positive integer" >&2
    exit 1
fi
RELEASE_VERSION="v${ATOM_VERSION}"
export ATOM_VERSION
echo "[package] release version: ${RELEASE_VERSION}"
if [ ! -f "${ATOMLOOPS}/go.mod" ] || [ ! -f "${ATOMLOOPS}/loader/build.sh" ]; then
    echo "package: AtomLoops checkout not found at ${ATOMLOOPS}" >&2
    exit 1
fi
ATOMLOOPS="${ATOMLOOPS}" SINTY_RECOVERY="${SINTY_RECOVERY:-}" SINTY_INITRAMFS="${SINTY_INITRAMFS:-}" \
    bash "${REPO_DIR}/scripts/check-build-deps.sh"
mkdir -p artifacts

SIGNING_WORK=""
cleanup() {
    [ -z "${SIGNING_WORK}" ] || rm -rf "${SIGNING_WORK}"
}
trap cleanup EXIT

ATOM_ROOT_PUB="${ATOM_ROOT_PUB:-${ATOMLOOPS}/loader/src/root.pub}"
ATOM_SIGNING_KEY="${ATOM_SIGNING_KEY:-${ATOMLOOPS}/signing-v1.key}"
ATOM_SIGNING_CERT="${ATOM_SIGNING_CERT:-${ATOMLOOPS}/signing-cert-v1.json}"
ATOM_SIGNING_CERT_SIG="${ATOM_SIGNING_CERT_SIG:-${ATOM_SIGNING_CERT}.sig}"
# Whether the caller pinned a loader binary. Only an explicit ATOM_LOADER_EFI is
# trusted to match the signing chain: defaulting to the AtomLoops checkout would let
# a leftover dev-root bootx64.efi sitting there silently replace the release loader,
# and the image then halts at "signature INVALID" because that loader cannot verify
# a production-signed UKI. Unset means always rebuild against ATOM_ROOT_PUB.
LOADER_PINNED=1
[ -n "${ATOM_LOADER_EFI:-}" ] || LOADER_PINNED=0
ATOM_LOADER_EFI="${ATOM_LOADER_EFI:-${ATOMLOOPS}/loader/bootx64.efi}"

if [ -n "${ATOM_UNSIGNED:-}" ]; then
    echo "[package] unsigned stage: no signing key is read, sign-release.sh signs the output"
    ATOM_ROOT_PUB="${REPO_DIR}/package/atomloops/root.pub"
    SIGNING_WORK="$(mktemp -d "${SINTY_WORK_ROOT}/package-signing.XXXXXX")"
    cp -a "${ATOMLOOPS}/loader" "${SIGNING_WORK}/loader"
    cp "${ATOM_ROOT_PUB}" "${SIGNING_WORK}/loader/src/root.pub"
    ( cd "${SIGNING_WORK}/loader" && ZIG="${ZIG:-zig}" ./build.sh )
    ATOM_LOADER_EFI="${SIGNING_WORK}/loader/bootx64.efi"
elif [ -f "${ATOM_ROOT_PUB}" ] && [ -f "${ATOM_SIGNING_KEY}" ] \
    && [ -f "${ATOM_SIGNING_CERT}" ] && [ -f "${ATOM_SIGNING_CERT_SIG}" ]; then
    # A signing chain was provided (release/production). Build a loader that trusts
    # this root.pub unless the caller pinned a matching loader EFI.
    if [ "${LOADER_PINNED}" = 0 ] || [ ! -f "${ATOM_LOADER_EFI}" ]; then
        SIGNING_WORK="$(mktemp -d "${SINTY_WORK_ROOT}/package-signing.XXXXXX")"
        cp -a "${ATOMLOOPS}/loader" "${SIGNING_WORK}/loader"
        cp "${ATOM_ROOT_PUB}" "${SIGNING_WORK}/loader/src/root.pub"
        ( cd "${SIGNING_WORK}/loader" && ZIG="${ZIG:-zig}" ./build.sh )
        ATOM_LOADER_EFI="${SIGNING_WORK}/loader/bootx64.efi"
    fi
else
    echo "[package] release signing assets incomplete; generating an ephemeral development chain"
    SIGNING_WORK="$(mktemp -d "${SINTY_WORK_ROOT}/package-signing.XXXXXX")"
    ROOT_KEY="${SIGNING_WORK}/root.key"
    ATOM_ROOT_PUB="${SIGNING_WORK}/root.pub"
    ATOM_SIGNING_KEY="${SIGNING_WORK}/signing-v1.key"
    ATOM_SIGNING_CERT="${SIGNING_WORK}/signing-cert-v1.json"
    ATOM_SIGNING_CERT_SIG="${ATOM_SIGNING_CERT}.sig"
    (
        cd "${ATOMLOOPS}"
        "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign keygen \
            --priv "${ROOT_KEY}" --pub "${ATOM_ROOT_PUB}"
        "${ATOMLOOPS_GO:-go}" run ./cmd/atom-sign issue-cert \
            --root "${ROOT_KEY}" --version 1 \
            --cert "${ATOM_SIGNING_CERT}" --signing-key "${ATOM_SIGNING_KEY}"
    )
    cp -a "${ATOMLOOPS}/loader" "${SIGNING_WORK}/loader"
    cp "${ATOM_ROOT_PUB}" "${SIGNING_WORK}/loader/src/root.pub"
    ( cd "${SIGNING_WORK}/loader" && ZIG="${ZIG:-zig}" ./build.sh )
    ATOM_LOADER_EFI="${SIGNING_WORK}/loader/bootx64.efi"
fi
export ATOM_ROOT_PUB ATOM_SIGNING_KEY ATOM_SIGNING_CERT ATOM_SIGNING_CERT_SIG

# The loader is the root of the whole verified chain, and shipping one built against
# the wrong root.pub produces an image that halts at "signature INVALID" only once it
# is booted on real hardware. Assert the trust root is actually inside the binary.
# The key is 32 raw bytes with embedded NULs, so this is a byte search, not a grep.
python3 - "${ATOM_ROOT_PUB}" "${ATOM_LOADER_EFI}" <<'PY' || exit 1
import sys
key = open(sys.argv[1], 'rb').read()
if key not in open(sys.argv[2], 'rb').read():
    print(f"package: {sys.argv[2]} does not embed {sys.argv[1]} -- refusing to ship", file=sys.stderr)
    sys.exit(1)
PY
echo "[package] loader trust root verified: $(sha256sum "${ATOM_ROOT_PUB}" | cut -c1-16)"

# RootFS
ROOTFS_TAR=artifacts/rootfs.tar
bzcat buildroot-build/images/rootfs.tar.bz2 > "$ROOTFS_TAR"
python3 - "${ATOM_ROOT_PUB}" "$ROOTFS_TAR" <<'PY' || exit 1
import sys, tarfile
key = open(sys.argv[1], 'rb').read()
want = {'usr/libexec/updated.real': 'embed', 'etc/atom-fw-root.pub': 'equal'}
seen = set()
with tarfile.open(sys.argv[2]) as tar:
    for m in tar:
        name = m.name[2:] if m.name.startswith('./') else m.name
        if name not in want or not m.isfile():
            continue
        data = tar.extractfile(m).read()
        if (key not in data) if want[name] == 'embed' else (data != key):
            print(f"package: rootfs {name} does not carry {sys.argv[1]} -- refusing to ship", file=sys.stderr)
            sys.exit(1)
        seen.add(name)
missing = set(want) - seen
if missing:
    print(f"package: rootfs is missing {', '.join(sorted(missing))} -- refusing to ship", file=sys.stderr)
    sys.exit(1)
PY
echo "[package] update agent trust root verified"
# mkfs.erofs does not truncate an existing output file: a stale rootfs.erofs from a
# previous build would survive and get shipped, silently embedding an old rootfs (e.g.
# missing a package added since). Remove it first so the image always reflects the
# current tarball.
rm -f artifacts/rootfs.erofs
mkfs.erofs --tar=f -z lz4hc,9 -E ztailpacking -T"$SOURCE_DATE_EPOCH" -U "$(seed_uuid erofs)" artifacts/rootfs.erofs "$ROOTFS_TAR"

# Verity
# Same class as the erofs above: veritysetup format does not truncate a pre-existing
# hash file, so a larger stale rootfs.hash would keep a dead tail past the hash tree.
rm -f artifacts/rootfs.hash
veritysetup format --salt="$(printf 'verity-salt-%s' "$BUILD_SEED" | sha256sum | cut -c1-64)" --uuid="$(seed_uuid verity)" artifacts/rootfs.erofs artifacts/rootfs.hash | tee artifacts/verity-output.txt
ROOT_HASH=$(awk '/Root hash:/{print $3}' artifacts/verity-output.txt)
DATA_BLOCKS=$(awk '/Data blocks:/{print $3}' artifacts/verity-output.txt)
SALT=$(awk '/Salt:/{print $2}' artifacts/verity-output.txt)
DM_LEN=$((DATA_BLOCKS * 8))

if [ -n "$GITHUB_ENV" ]; then
    echo "ROOT_HASH=${ROOT_HASH}" >> "$GITHUB_ENV"
fi

# The initramfs init, built from sinty-initramfs. It re-verifies the release-signed
# firmware anchors in-process, so only the release root public key is baked next to it.
# FW_ROOT_PUB may be pre-set (e.g. a test trust root for a VM trial); default to the
# release root the loader verifies the UKI with.
: "${FW_ROOT_PUB:=${ATOM_ROOT_PUB}}"
export FW_ROOT_PUB
if [ -z "${SINTY_INIT_BIN:-}" ] || [ ! -x "${SINTY_INIT_BIN}" ]; then
    ( cd "${SINTY_INITRAMFS:?set SINTY_INITRAMFS to a sinty-initramfs checkout}" \
        && CGO_ENABLED=0 "${ATOMLOOPS_GO:-go}" build -trimpath -ldflags '-s -w' \
            -o "${REPO_DIR}/artifacts/sinty-initramfs" ./cmd/sinty-initramfs )
    SINTY_INIT_BIN="${REPO_DIR}/artifacts/sinty-initramfs"
fi
export SINTY_INIT_BIN

# Initramfs: the dm-verity aware init that waits for the kernel-created
# verity device, mounts the verified erofs read-only and overlays a tmpfs.
bash scripts/build-initramfs.sh buildroot-build/target artifacts/initrd.cpio.xz

# The initramfs finds the root/hash partitions by content and opens the
# verity device with this root hash, so no device names are baked in. The firmware
# add-on's dm-verity hash is intentionally NOT here (see the anchor note above).
CMDLINE="console=tty0 console=ttyS0,115200 ro quiet loglevel=0 vt.global_cursor_default=0 udev.log_level=0 rd.systemd.show_status=0 systemd.show_status=0 rootwait sing.roothash=${ROOT_HASH} atom.version=${RELEASE_VERSION} lsm=landlock,lockdown,yama,bpf lockdown=integrity module.sig_enforce=1 init_on_alloc=1 slab_nomerge page_alloc.shuffle=1 randomize_kstack_offset=1 vsyscall=none cfg80211.ieee80211_regdom=IT${EXTRA_CMDLINE:+ ${EXTRA_CMDLINE}}"

# UKI: place the added sections above the stub's image so they do not fall
# below the PE image base.
KERNEL="buildroot-build/images/bzImage"
STUB="/usr/lib/systemd/boot/efi/linuxx64.efi.stub"
BASE=$((16#$(objdump -p "$STUB" | awk '/ImageBase/{print $2}')))
vma() { printf "0x%x" $((BASE + $1)); }

OSREL=""
[ -f buildroot-build/target/usr/lib/os-release ] && OSREL="--add-section .osrel=buildroot-build/target/usr/lib/os-release --change-section-vma .osrel=$(vma 0x100000)"

printf '%s' "$CMDLINE" > artifacts/cmdline.txt
# .atomver: the kernelcache version baked into the SIGNED UKI, read by the loader to
# enforce anti-rollback. The daemon's NV counter (index 0x0150A701) is the floor.
printf '%s' "${ATOM_VERSION}" > artifacts/atomver.txt

objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .atomver=artifacts/atomver.txt \
    --change-section-vma .atomver=$(vma 0x108000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache.efi

echo "[package] UKI: artifacts/kernelcache.efi"
echo "[package] root hash: ${ROOT_HASH}"

# Live and installed kernelcaches select different root layouts. The signed flag keeps
# a slow removable root from falling through to an installed slot with the same hash.
LIVE_CMDLINE="${CMDLINE} sing.live=1"
printf '%s' "$LIVE_CMDLINE" > artifacts/cmdline-live.txt
objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline-live.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .atomver=artifacts/atomver.txt \
    --change-section-vma .atomver=$(vma 0x108000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache-live.efi

# Portable mode uses the live raw root and may attach installed writable data.
PORTABLE_CMDLINE="${LIVE_CMDLINE} sing.portable=1"
printf '%s' "$PORTABLE_CMDLINE" > artifacts/cmdline-portable.txt
objcopy \
    $OSREL \
    --add-section .cmdline=artifacts/cmdline-portable.txt \
    --change-section-vma .cmdline=$(vma 0x110000) \
    --add-section .atomver=artifacts/atomver.txt \
    --change-section-vma .atomver=$(vma 0x108000) \
    --add-section .linux="$KERNEL" \
    --change-section-vma .linux=$(vma 0x200000) \
    --add-section .initrd=artifacts/initrd.cpio.xz \
    --change-section-vma .initrd=$(vma 0x2000000) \
    "$STUB" artifacts/kernelcache-portable.efi

if [ -n "${ATOM_UNSIGNED:-}" ]; then
    bash scripts/build-recovery.sh
    cp "${ATOM_LOADER_EFI}" artifacts/bootx64.efi
    printf '%s\n' "${RELEASE_VERSION}" > artifacts/release-version.txt
    ( cd artifacts && sha256sum release-version.txt bootx64.efi rootfs.erofs rootfs.hash verity-output.txt \
        kernelcache.efi kernelcache-live.efi kernelcache-portable.efi kernelcache-recovery.efi ) > artifacts/unsigned.sha256
    echo "[package] unsigned stage done:"
    cat artifacts/unsigned.sha256
    exit 0
fi

. scripts/assemble-image.sh
