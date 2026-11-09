#!/bin/bash

set -e

BUILDROOT_VERSION="2026.02.2"
BUILDROOT_SHA256="a833429929aefd4175b0651b2b356b761960cd46d36df6a0049d1f117e3ac8a6"
REPO_DIR="$(pwd)"
ARCH="${ARCH:-x86_64}"
case "$ARCH" in
    x86_64) BUILD_DIR="buildroot-build" ;;
    aarch64) BUILD_DIR="buildroot-build-aarch64" ;;
    *) echo "[prepare] unsupported ARCH $ARCH" >&2; exit 1 ;;
esac

if [ ! -d "buildroot-src" ]; then
    wget -q "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.xz"
    echo "${BUILDROOT_SHA256}  buildroot-${BUILDROOT_VERSION}.tar.xz" | sha256sum -c --quiet -
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

mkdir -p "$BUILD_DIR" buildroot-dl
if [ "$ARCH" = x86_64 ]; then
    cp buildroot-config/singularity_defconfig buildroot-src/configs/singularity_defconfig
else
    fragment="buildroot-config/$ARCH.fragment"
    symbols=$(sed -n 's/^\(# \)\{0,1\}\(BR2_[A-Za-z0-9_]*\).*/\2/p' "$fragment" | sort -u)
    grep -v -E "^(# )?($(echo $symbols | tr ' ' '|'))[= ]" buildroot-config/singularity_defconfig | grep -v '^BR2_x86_64=y' > buildroot-src/configs/singularity_defconfig
    cat "$fragment" >> buildroot-src/configs/singularity_defconfig
fi

make -C buildroot-src \
    O="${REPO_DIR}/${BUILD_DIR}" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    singularity_defconfig

sed -i "s|\$(BR2_EXTERNAL_SINGULARITY_PATH)|${REPO_DIR}|g" "${BUILD_DIR}/.config"
