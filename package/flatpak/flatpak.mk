################################################################################
#
# flatpak
#
################################################################################

FLATPAK_VERSION = 1.14.10
FLATPAK_SOURCE = flatpak-$(FLATPAK_VERSION).tar.xz
FLATPAK_SITE = https://github.com/flatpak/flatpak/releases/download/$(FLATPAK_VERSION)
FLATPAK_LICENSE = LGPL-2.1+
FLATPAK_LICENSE_FILES = COPYING
FLATPAK_CPE_ID_VENDOR = flatpak
FLATPAK_INSTALL_STAGING = YES
FLATPAK_DEPENDENCIES = \
	host-pkgconf \
	host-bison \
	host-python3 \
	host-python-pyparsing \
	host-libglib2 \
	appstream \
	bubblewrap \
	xdg-dbus-proxy \
	libglib2 \
	libostree \
	libgpgme \
	json-glib \
	libcurl \
	libarchive \
	libseccomp \
	libfuse3 \
	libxml2 \
	libcap \
	gdk-pixbuf

FLATPAK_CONF_OPTS = \
	--with-curl \
	--with-systemd=no \
	--with-priv-mode=none \
	--with-system-bubblewrap=/usr/bin/bwrap \
	--with-system-dbus-proxy=/usr/bin/xdg-dbus-proxy \
	--with-systemduserunitdir=no \
	--with-systemdsystemunitdir=no \
	--disable-documentation \
	--disable-docbook-docs \
	--disable-gtk-doc \
	--disable-gtk-doc-html \
	--disable-system-helper \
	--disable-selinux-module \
	--disable-xauth \
	--enable-introspection=no

$(eval $(autotools-package))
