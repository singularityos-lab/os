################################################################################
#
# labwc
#
################################################################################

LABWC_VERSION = 3c81be7eea29de8506baebae09040b3ba3e39659
LABWC_SITE = $(call github,singularityos-lab,labwc,$(LABWC_VERSION))
LABWC_LICENSE = GPL-2.0
LABWC_LICENSE_FILES = LICENSE
LABWC_DEPENDENCIES = \
	host-pkgconf \
	wlroots020 \
	wayland \
	wayland-protocols \
	libxml2 \
	cairo \
	pango \
	libglib2 \
	libdrm \
	libinput \
	libxkbcommon \
	librsvg \
	libpng \
	libxcb \
	xcb-util-wm \
	xwayland

LABWC_CONF_OPTS = \
	-Dxwayland=enabled \
	-Dman-pages=disabled \
	-Dicon=disabled

$(eval $(meson-package))
