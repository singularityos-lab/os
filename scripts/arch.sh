ARCH="${ARCH:-x86_64}"
case "$ARCH" in
    x86_64)
        BUILD_DIR="${BUILD_DIR:-buildroot-build}"
        EFI_ARCH=x64
        KERNEL_IMAGE=bzImage
        CROSS_PREFIX=x86_64-buildroot-linux-gnu-
        ;;
    aarch64)
        BUILD_DIR="${BUILD_DIR:-buildroot-build-aarch64}"
        EFI_ARCH=aa64
        KERNEL_IMAGE=Image
        CROSS_PREFIX=aarch64-buildroot-linux-gnu-
        ;;
    *)
        echo "unsupported ARCH: $ARCH" >&2
        exit 1
        ;;
esac
LOADER_NAME="boot${EFI_ARCH}.efi"
LOADER_ESP_NAME="BOOT$(printf '%s' "$EFI_ARCH" | tr a-z A-Z).EFI"
export ARCH BUILD_DIR EFI_ARCH LOADER_NAME LOADER_ESP_NAME

STUB_DEB_VERSION="257.13-1~deb13u1"
STUB_DEB_SHA256="0e4529d9a72b35c31f34151ef8a0df20f322cfef679f4f5439394e60505b91a2"

pe_tool() {
    local name="$1" t
    if [ "$ARCH" = x86_64 ]; then
        command -v "$name"
        return
    fi
    for t in "${REPO_DIR}/${BUILD_DIR}/host/bin/${CROSS_PREFIX}${name}" "$(command -v "${ARCH}-linux-gnu-${name}" 2>/dev/null)"; do
        [ -n "$t" ] && [ -x "$t" ] && { printf '%s' "$t"; return; }
    done
    echo "no ${name} for ${ARCH} PE images" >&2
    exit 1
}

efi_stub() {
    local stub="linux${EFI_ARCH}.efi.stub" dir deb
    if [ -n "${STUB:-}" ]; then
        printf '%s' "$STUB"
        return
    fi
    for dir in /usr/lib/systemd/boot/efi "${REPO_DIR}/${BUILD_DIR}/target/usr/lib/systemd/boot/efi"; do
        [ -f "$dir/$stub" ] && { printf '%s' "$dir/$stub"; return; }
    done
    [ "$ARCH" = aarch64 ] || { echo "no $stub found" >&2; exit 1; }
    dir="${REPO_DIR}/buildroot-dl/systemd-boot-efi-arm64"
    deb="$dir/systemd-boot-efi_${STUB_DEB_VERSION}_arm64.deb"
    if [ ! -f "$dir/$stub" ]; then
        mkdir -p "$dir"
        [ -f "$deb" ] || curl -fsSL -o "$deb" "https://deb.debian.org/debian/pool/main/s/systemd/systemd-boot-efi_${STUB_DEB_VERSION}_arm64.deb" \
            || curl -fsSL -o "$deb" "https://snapshot.debian.org/archive/debian/20260503T204801Z/pool/main/s/systemd/systemd-boot-efi_${STUB_DEB_VERSION}_arm64.deb"
        echo "${STUB_DEB_SHA256}  $deb" | sha256sum --check --quiet >&2
        ( cd "$dir" && ar p "$deb" "$(ar t "$deb" | grep '^data.tar')" | tar -xJf - --strip-components=6 "./usr/lib/systemd/boot/efi/$stub" )
    fi
    printf '%s' "$dir/$stub"
}

uki_initrd_offset() {
    local end=$(( 0x200000 + $(stat -c %s "$1") ))
    end=$(( (end + 0x1fffff) & ~0x1fffff ))
    [ "$end" -lt $((0x2000000)) ] && end=$((0x2000000))
    printf '0x%x' "$end"
}

uki_add_dtbs() {
    local uki="$1" args="" dtb
    [ "$ARCH" = aarch64 ] || return 0
    for dtb in "${REPO_DIR}/${BUILD_DIR}"/images/*.dtb; do
        [ -f "$dtb" ] && args="$args .dtbauto $dtb"
    done
    [ -n "$args" ] || return 0
    python3 -I "${REPO_DIR}/scripts/pe-add-sections.py" "$uki" $args
}
