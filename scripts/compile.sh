#!/bin/bash

set -e

REPO_DIR="$(pwd)"

make -C buildroot-src \
    O="${REPO_DIR}/buildroot-build" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    -j$(nproc)
