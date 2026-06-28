#!/bin/sh

set -eu

MARKER=/var/lib/sinty/.oobe-done
if [ -f "${MARKER}" ]; then
    exit 0
fi

export ATOM_OOBE_APPLY=1
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
mkdir -p "${XDG_RUNTIME_DIR}"

exec labwc -s "singularity-installer --oobe"
