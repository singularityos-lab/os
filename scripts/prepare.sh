#!/bin/bash

set -e

BUILDROOT_VERSION="2026.02.2"
REPO_DIR="$(pwd)"

if [ ! -d "buildroot-src" ]; then
    wget -q "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.xz"
    tar xf "buildroot-${BUILDROOT_VERSION}.tar.xz"
    mv "buildroot-${BUILDROOT_VERSION}" buildroot-src
    sed -i '/\$(eval \$(generic-package))/i SQLITE_CFLAGS += -DSQLITE_ENABLE_FTS5' \
        buildroot-src/package/sqlite/sqlite.mk
    # wlroots 0.20.1 requires wayland-protocols >= 1.47; this Buildroot ships 1.45, and
    # its meson wrap fallback is disabled, so the wlroots020 configure step dies with
    # "Subproject wayland-protocols is buildable: NO". Bump the core package in place.
    sed -i 's/^WAYLAND_PROTOCOLS_VERSION = .*/WAYLAND_PROTOCOLS_VERSION = 1.47/' \
        buildroot-src/package/wayland-protocols/wayland-protocols.mk
    cat > buildroot-src/package/wayland-protocols/wayland-protocols.hash <<'EOF'
# Locally computed from the release tarball at
# https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.47/downloads
sha256  5fd4349bcbc9bab9a46f8cf77d1f434296a7a052c87440a094f63fcf62a58e20  wayland-protocols-1.47.tar.xz
sha512  2a89d5b2f16a42a195acd09ff5e093e4ef021ee7f50447bb59890d5fe630bad353485b6edcdfd5e193e8262ce538a4aff57a49b2dd5cc14b2858bf3e5b7ee17e  wayland-protocols-1.47.tar.xz
sha256  f1a2b233e8a9a71c40f4aa885be08a0842ac85bb8588703c1dd7e6e6502e3124  COPYING
EOF
    # libsingularity is Vala and valac needs gtksourceview-5.vapi, which is only built
    # together with the gir data. Meson's 'auto' introspection resolves to off when
    # cross-compiling, so the stock package installs neither and valac fails with
    # "Package `gtksourceview-5' not found". Request both explicitly.
    # lz4 generates liblz4.pc while building, before the install-time PREFIX=/usr applies,
    # so the .pc ships lz4's own /usr/local default and its -I${includedir} points at a
    # sysroot dir that does not exist. vte-gtk4 builds with -Werror=missing-include-dirs
    # and dies on it.
    sed -i '/^ifeq (\$(BR2_STATIC_LIBS),y)$/i LZ4_MAKE_OPTS += PREFIX=/usr\n' \
        buildroot-src/package/lz4/lz4.mk

    # Buildroot hardcodes -Dintrospection=disabled for GTK4, so no Gtk-4.0.gir lands in
    # staging and g-ir-scanner cannot scan anything that includes Gtk-4.0 (gtksourceview
    # below). Make it follow BR2_PACKAGE_GOBJECT_INTROSPECTION instead.
    sed -i '/^\t-Dintrospection=disabled \\$/d' buildroot-src/package/libgtk4/libgtk4.mk
    sed -i '/^\$(eval \$(meson-package))$/i \
ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)\
LIBGTK4_CONF_OPTS += -Dintrospection=enabled\
LIBGTK4_DEPENDENCIES += gobject-introspection\
else\
LIBGTK4_CONF_OPTS += -Dintrospection=disabled\
endif\
' buildroot-src/package/libgtk4/libgtk4.mk

    # The block has to land BEFORE the meson-package eval: _DEPENDENCIES is read when
    # the eval builds the dependency graph, so appending after it would be ignored.
    sed -i '/^\$(eval \$(meson-package))$/d' \
        buildroot-src/package/gtksourceview/gtksourceview.mk
    cat >> buildroot-src/package/gtksourceview/gtksourceview.mk <<'EOF'
ifeq ($(BR2_PACKAGE_GOBJECT_INTROSPECTION),y)
GTKSOURCEVIEW_CONF_OPTS += -Dintrospection=enabled -Dvapi=true
GTKSOURCEVIEW_DEPENDENCIES += gobject-introspection host-vala
else
GTKSOURCEVIEW_CONF_OPTS += -Dintrospection=disabled -Dvapi=false
endif

$(eval $(meson-package))
EOF
fi

mkdir -p buildroot-build buildroot-dl
cp buildroot-config/singularity_defconfig buildroot-src/configs/singularity_defconfig

make -C buildroot-src \
    O="${REPO_DIR}/buildroot-build" \
    BR2_EXTERNAL="${REPO_DIR}" \
    BR2_DL_DIR="${REPO_DIR}/buildroot-dl" \
    singularity_defconfig

sed -i "s|\$(BR2_EXTERNAL_SINGULARITY_PATH)|${REPO_DIR}|g" buildroot-build/.config
