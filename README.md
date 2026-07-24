# Sinty OS

Build system for the Sinty OS root and kernelcache images.

## Prerequisites

On Ubuntu/Debian:

```bash
sudo apt-get install -y \
  build-essential gcc g++ make \
  bc bison flex libssl-dev libelf-dev \
  libncurses-dev wget rsync cpio \
  xz-utils gzip bzip2 zstd patch perl python3 \
  git unzip erofs-utils cryptsetup-bin \
  systemd-boot binutils
```

## Build

```bash
./scripts/prepare.sh
./scripts/compile.sh
./scripts/package.sh
```

## License

The build system and the original Sinty OS components in this repository are
under the MIT license (see LICENSE). The built image bundles third-party
software (the Linux kernel, glibc, and other packages) under their own
licenses; use Buildroot's `legal-info` target to generate the full license
manifest and the matching source archive.
