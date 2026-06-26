################################################################################
#
# libsingularity
#
################################################################################

LIBSINGULARITY_VERSION = cac94560c7d918e3d948a7a43806a10af2b1aba4
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
