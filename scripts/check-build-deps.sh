#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPS="${REPO_DIR}/build-deps"
fail=0

die() {
    echo "check-build-deps: $*" >&2
    fail=1
}

declared() {
    local v
    v=$(sed -n "s/^$1=//p" "$DEPS")
    [[ "$v" =~ ^[0-9a-f]{40}$ ]] || { echo "check-build-deps: $1 must be a full commit in build-deps" >&2; exit 1; }
    echo "$v"
}

pin() {
    sed -n "s/^$2_VERSION = //p" "${REPO_DIR}/package/$1/$1.mk"
}

[ -f "$DEPS" ] || { echo "check-build-deps: build-deps is missing" >&2; exit 1; }
ATOMLOOPS_REF=$(declared ATOMLOOPS)
RECOVERY_REF=$(declared SINTY_RECOVERY)
INITRAMFS_REF=$(declared SINTY_INITRAMFS)

[ "$(pin atomloops ATOMLOOPS)" = "$ATOMLOOPS_REF" ] || die "package/atomloops is not at the declared AtomLoops $ATOMLOOPS_REF"
[ "$(pin atom-recovery ATOM_RECOVERY)" = "$RECOVERY_REF" ] || die "package/atom-recovery is not at the declared sinty-recovery $RECOVERY_REF"
[ "$(pin sinty-recovery-ui SINTY_RECOVERY_UI)" = "$RECOVERY_REF" ] || die "package/sinty-recovery-ui is not at the declared sinty-recovery $RECOVERY_REF"

checkout() {
    local dir=$1 want=$2 name=$3 have
    [ -n "$dir" ] || return 0
    have=$(git -C "$dir" rev-parse HEAD)
    [ "$have" = "$want" ] || die "$name checkout is at $have, build-deps declares $want"
    if [ -f "$dir/go.mod" ] && [ "$name" != AtomLoops ]; then
        grep -q "github.com/mirkobrombin/atomloops v.*-${ATOMLOOPS_REF:0:12}$" "$dir/go.mod" \
            || die "$name requires a different AtomLoops than the declared ${ATOMLOOPS_REF:0:12}"
    fi
}

checkout "${ATOMLOOPS:-}" "$ATOMLOOPS_REF" AtomLoops
checkout "${SINTY_RECOVERY:-}" "$RECOVERY_REF" sinty-recovery
checkout "${SINTY_INITRAMFS:-}" "$INITRAMFS_REF" sinty-initramfs

[ "$fail" = 0 ] || exit 1
echo "check-build-deps: AtomLoops ${ATOMLOOPS_REF:0:7}, sinty-recovery ${RECOVERY_REF:0:7}, sinty-initramfs ${INITRAMFS_REF:0:7}"
