#!/bin/bash
set -eo pipefail
REPO_DIR="$(pwd)"
. "${REPO_DIR}/scripts/arch.sh"
ATOMLOOPS="${ATOMLOOPS:?set ATOMLOOPS to an AtomLoops checkout}"
SINTY_WORK_ROOT="${SINTY_WORK_ROOT:-${HOME}/sinty-work}"
mkdir -p "${SINTY_WORK_ROOT}"

for f in "${ATOM_SIGNING_KEY}" "${ATOM_SIGNING_CERT}" "${ATOM_SIGNING_CERT_SIG}"; do
    [ -f "$f" ] || { echo "sign-release: signing chain file missing" >&2; exit 1; }
done
( cd artifacts && sha256sum --strict --check unsigned.sha256 )

RELEASE_VERSION="$(cat artifacts/release-version.txt)"
case "${RELEASE_VERSION}" in
    v[0-9]*) ;;
    *) echo "sign-release: bad release version" >&2; exit 1 ;;
esac

python3 - package/atomloops/root.pub "artifacts/${LOADER_NAME}" <<'PY'
import sys
key = open(sys.argv[1], 'rb').read()
if key not in open(sys.argv[2], 'rb').read():
    sys.exit("sign-release: the loader does not embed the release root")
PY

ATOMLOOPS_GO="${ATOMLOOPS_GO:-$(command -v go)}"
ATOM_LOADER_EFI="${REPO_DIR}/artifacts/${LOADER_NAME}"
RECOVERY_PREBUILT=1
HOSTBIN="${HOSTBIN:-/usr/bin}"
HOSTSBIN="${HOSTSBIN:-/usr/sbin}"
export ATOMLOOPS ATOMLOOPS_GO ATOM_SIGNING_KEY ATOM_SIGNING_CERT ATOM_SIGNING_CERT_SIG RECOVERY_PREBUILT

. scripts/assemble-image.sh

FAMILY_SIGS=""
for family in $(uki_families); do
    FAMILY_SIGS="${FAMILY_SIGS} kernelcache.${family}.efi.sig kernelcache-live.${family}.efi.sig kernelcache-portable.${family}.efi.sig"
done
( cd artifacts && sha256sum kernelcache.efi.sig kernelcache-live.efi.sig kernelcache-portable.efi.sig \
    kernelcache-recovery.efi.sig ${FAMILY_SIGS} sinty-os.img sinty-os-portable.img sinty-os.iso ) > artifacts/signed.sha256
cat artifacts/signed.sha256
