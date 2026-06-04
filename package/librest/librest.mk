################################################################################
#
# librest
#
################################################################################

LIBREST_VERSION = 0.9.1
LIBREST_SOURCE = rest-$(LIBREST_VERSION).tar.xz
LIBREST_SITE = https://download.gnome.org/sources/rest/0.9
LIBREST_LICENSE = LGPL-2.1
LIBREST_LICENSE_FILES = COPYING
LIBREST_CPE_ID_VENDOR = gnome
LIBREST_INSTALL_STAGING = YES
LIBREST_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libglib2 \
	libsoup3 \
	json-glib

LIBREST_CONF_OPTS = \
	-Dexamples=false \
	-Dtests=false \
	-Dgtk_doc=false \
	-Dvapi=true \
	-Dintrospection=true \
	-Dsoup2=false

$(eval $(meson-package))
