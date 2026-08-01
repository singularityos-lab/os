#!/bin/sh

set -eu

OUT="${1:?usage: write-os-release.sh OUTPUT}"
VERSION="${SINTY_PRODUCT_VERSION:-26}"
BUILD="${SINTY_PRODUCT_BUILD:-26A000}"

printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+([.][0-9]+)*$' || {
    echo "write-os-release: invalid product version: $VERSION" >&2
    exit 1
}
printf '%s\n' "$BUILD" | grep -Eq '^[0-9]{2}A[0-9]{3}$' || {
    echo "write-os-release: invalid product build: $BUILD" >&2
    exit 1
}
if [ "${ATOM_BUILD:-}" = "rc" ] && [ "$BUILD" = "26A000" ]; then
    echo "write-os-release: SINTY_PRODUCT_BUILD is required for an RC build" >&2
    exit 1
fi

cat > "$OUT" <<EOF
NAME="Sinty OS"
PRETTY_NAME="Sinty OS Event Horizon $VERSION"
ID=sinty
VERSION="$VERSION (Event Horizon)"
VERSION_ID=$VERSION
VERSION_CODENAME=event-horizon
BUILD_ID=$BUILD
ANSI_COLOR="1;36"
HOME_URL="https://sinty.dev/"
DOCUMENTATION_URL="https://sinty.dev/docs/"
SUPPORT_URL="https://sinty.dev/support/"
BUG_REPORT_URL="https://sinty.dev/bugs/"
LOGO=sinty
EOF
