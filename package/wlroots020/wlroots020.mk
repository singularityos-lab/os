################################################################################
#
# wlroots020
#
################################################################################

WLROOTS020_VERSION = 0.20.1
WLROOTS020_SITE = https://gitlab.freedesktop.org/wlroots/wlroots/-/releases/$(WLROOTS020_VERSION)/downloads
WLROOTS020_SOURCE = wlroots-$(WLROOTS020_VERSION).tar.gz
WLROOTS020_LICENSE = MIT
WLROOTS020_LICENSE_FILES = LICENSE
WLROOTS020_INSTALL_STAGING = YES

WLROOTS020_DEPENDENCIES = \
	host-pkgconf \
	host-wayland \
	hwdata \
	libdisplay-info \
	libdrm \
	libinput \
	libliftoff \
	libxkbcommon \
	libegl \
	libgles \
	libgbm \
	pixman \
	seatd \
	udev \
	wayland \
	wayland-protocols

WLROOTS020_CONF_OPTS = \
	-Dexamples=false \
	-Dxcb-errors=disabled \
	-Dxwayland=disabled \
	-Dbackends=libinput,drm \
	-Drenderers=gles2

$(eval $(meson-package))
