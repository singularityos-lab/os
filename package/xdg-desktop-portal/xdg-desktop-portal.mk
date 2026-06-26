################################################################################
#
# xdg-desktop-portal
#
################################################################################

XDG_DESKTOP_PORTAL_VERSION = 1.20.3
XDG_DESKTOP_PORTAL_SITE = https://github.com/flatpak/xdg-desktop-portal/releases/download/$(XDG_DESKTOP_PORTAL_VERSION)
XDG_DESKTOP_PORTAL_SOURCE = xdg-desktop-portal-$(XDG_DESKTOP_PORTAL_VERSION).tar.xz
XDG_DESKTOP_PORTAL_LICENSE = LGPL-2.1+
XDG_DESKTOP_PORTAL_LICENSE_FILES = COPYING
XDG_DESKTOP_PORTAL_DEPENDENCIES = \
	host-pkgconf \
	host-gettext \
	libglib2 \
	json-glib \
	gdk-pixbuf \
	libfuse3 \
	gstreamer1 \
	gst1-plugins-base \
	pipewire \
	systemd \
	dbus

XDG_DESKTOP_PORTAL_CONF_OPTS = \
	-Dflatpak-interfaces=disabled \
	-Dgeoclue=disabled \
	-Ddocumentation=disabled \
	-Dman-pages=disabled \
	-Dtests=disabled \
	-Dinstalled-tests=false

$(eval $(meson-package))
