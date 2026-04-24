# Singularity OS

Build system for the Singularity OS root and kernelcache images.

## Prerequisites

On Ubuntu/Debian:

```bash
sudo apt-get install -y \
  build-essential gcc g++ make \
  bc bison flex libssl-dev libelf-dev \
  libncurses-dev wget rsync cpio \
  xz-utils gzip bzip2 patch perl python3 \
  git unzip erofs-utils cryptsetup-bin \
  systemd-boot binutils
```

## Build

```bash
./scripts/prepare.sh
./scripts/compile.sh
./scripts/package.sh
```
