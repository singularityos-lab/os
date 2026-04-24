#!/bin/bash

set -e

BUILDROOT_VERSION="2024.02.9"
REPO_DIR="$(pwd)"

if [ ! -d "buildroot-src" ]; then
    wget -q "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.xz"
    tar xf "buildroot-${BUILDROOT_VERSION}.tar.xz"
    mv "buildroot-${BUILDROOT_VERSION}" buildroot-src
fi

mkdir -p buildroot-build buildroot-dl
cp buildroot-config/singularity_defconfig buildroot-src/configs/singularity_defconfig

make -C buildroot-src \
    O="${REPO_DIR}/buildroot-build" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    singularity_defconfig

sed -i "s|\$(BR2_EXTERNAL_SINGULARITY_PATH)|${REPO_DIR}|g" buildroot-build/.config
