#!/bin/bash

set -e

REPO_DIR="$(pwd)"
. "${REPO_DIR}/scripts/arch.sh"

make -C buildroot-src \
    O="${REPO_DIR}/${BUILD_DIR}" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    -j$(nproc)
