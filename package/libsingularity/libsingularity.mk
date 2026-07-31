################################################################################
#
# libsingularity
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
LIBSINGULARITY_VERSION = e2f5fa6b723dd8590f95255e3dc5f17ffe856f5b
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
