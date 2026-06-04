################################################################################
#
# gnome-online-accounts
#
################################################################################

GNOME_ONLINE_ACCOUNTS_VERSION = 3.58.1
GNOME_ONLINE_ACCOUNTS_SOURCE = gnome-online-accounts-$(GNOME_ONLINE_ACCOUNTS_VERSION).tar.xz
GNOME_ONLINE_ACCOUNTS_SITE = https://download.gnome.org/sources/gnome-online-accounts/3.58
GNOME_ONLINE_ACCOUNTS_LICENSE = LGPL-2.0+
GNOME_ONLINE_ACCOUNTS_LICENSE_FILES = COPYING
GNOME_ONLINE_ACCOUNTS_CPE_ID_VENDOR = gnome
GNOME_ONLINE_ACCOUNTS_INSTALL_STAGING = YES
GNOME_ONLINE_ACCOUNTS_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libglib2 \
	libsoup3 \
	json-glib \
	librest \
	gcr \
	libsecret \
	webkitgtk

GNOME_ONLINE_ACCOUNTS_CONF_OPTS = \
	-Dgoabackend=false \
	-Ddocumentation=false \
	-Dman=false \
	-Dvapi=true \
	-Dintrospection=true \
	-Dgoogle=true \
	-Downcloud=true \
	-Dexchange=true \
	-Dimap_smtp=true \
	-Dkerberos=false

$(eval $(meson-package))
