#!/bin/bash

set -e

BUILDROOT_VERSION="2026.02.2"
REPO_DIR="$(pwd)"

if [ ! -d "buildroot-src" ]; then
    wget -q "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.xz"
    tar xf "buildroot-${BUILDROOT_VERSION}.tar.xz"
    mv "buildroot-${BUILDROOT_VERSION}" buildroot-src
fi

for patch_file in buildroot-source-patches/*.patch; do
    if patch --directory=buildroot-src --strip=1 --reverse --dry-run < "$patch_file" >/dev/null 2>&1; then
        echo "[prepare] already applied: $patch_file"
    elif patch --directory=buildroot-src --strip=1 --forward --dry-run < "$patch_file" >/dev/null 2>&1; then
        patch --directory=buildroot-src --strip=1 --forward < "$patch_file"
    else
        echo "[prepare] cannot apply or verify: $patch_file" >&2
        exit 1
    fi
done

mkdir -p buildroot-build buildroot-dl
cp buildroot-config/singularity_defconfig buildroot-src/configs/singularity_defconfig

make -C buildroot-src \
    O="${REPO_DIR}/buildroot-build" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    singularity_defconfig

sed -i "s|\$(BR2_EXTERNAL_SINGULARITY_PATH)|${REPO_DIR}|g" buildroot-build/.config
