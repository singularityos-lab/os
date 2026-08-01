# Sinty OS

Build system for the Sinty OS Event Horizon 26 root and kernelcache images.

## Prerequisites

On Ubuntu/Debian:

```bash
sudo apt-get install -y \
  build-essential gcc g++ make \
  bc bison flex libssl-dev libelf-dev \
  libncurses-dev wget rsync cpio \
  xz-utils gzip bzip2 zstd patch perl python3 \
  git unzip erofs-utils cryptsetup-bin \
  systemd-boot binutils sassc mtools dosfstools golang-go \
  bubblewrap xdg-dbus-proxy
```

`sassc` compiles the libsingularity GTK theme, `mtools`/`dosfstools` build the ESP
image, and the Go toolchain builds the Atom Loops signing and recovery binaries;
`bubblewrap` and `xdg-dbus-proxy` are executed while configuring Flatpak. None of
them come from Buildroot, so the host has to provide them.

## Build

```bash
./scripts/prepare.sh
./scripts/compile.sh
./scripts/package.sh
```

The build produces an install image with raw verified root/hash partitions and a
portable image. The portable image boots its signed root from removable media
and can attach an existing Sinty OS data partition for recovery or release
testing without installing that root.
Cross-disk writable data is enabled only by the portable image's signed kernel
command line; the normal image never opts into it. Boot confirmation and update
staging stay disabled in portable sessions so the installed deployment state is
not changed by a removable root.

## License

The build system and the original Sinty OS components in this repository are
under the MIT license (see LICENSE). The built image bundles third-party
software (the Linux kernel, glibc, and other packages) under their own
licenses; use Buildroot's `legal-info` target to generate the full license
manifest and the matching source archive.
