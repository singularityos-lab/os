#!/bin/bash

set -e

REPO_DIR="$(pwd)"
. "${REPO_DIR}/scripts/arch.sh"

JOBS=$(nproc)
MEM_JOBS=$(awk '/^MemTotal:/ { print int($2 / 2621440) }' /proc/meminfo)
[ "${MEM_JOBS}" -ge 1 ] || MEM_JOBS=1
[ "${MEM_JOBS}" -lt "${JOBS}" ] && JOBS=${MEM_JOBS}
echo "compile: ${JOBS} jobs"

env -u BUILD_DIR make -C buildroot-src \
    O="${REPO_DIR}/${BUILD_DIR}" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    -j${JOBS}
