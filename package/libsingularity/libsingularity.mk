################################################################################
#
# libsingularity
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
LIBSINGULARITY_VERSION = 0d41c9554e7fc07e8b9ebc20604bc54b5f798cea
LIBSINGULARITY_SITE = $(call github,singularityos-lab,libsingularity,$(LIBSINGULARITY_VERSION))
LIBSINGULARITY_LICENSE = GPL-3.0+
LIBSINGULARITY_LICENSE_FILES = LICENSE
LIBSINGULARITY_INSTALL_STAGING = YES
LIBSINGULARITY_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libgtk4 \
	gtk4-layer-shell \
	libgee \
	json-glib \
	libpeas2 \
	gtksourceview \
	pulseaudio \
	libgudev \
	upower \
	network-manager \
	libsoup3

LIBSINGULARITY_CONF_OPTS = -Dsystem=true

$(eval $(meson-package))
