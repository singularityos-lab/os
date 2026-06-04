################################################################################
#
# libpeas2
#
################################################################################

LIBPEAS2_VERSION_MAJOR = 2.2
LIBPEAS2_VERSION = $(LIBPEAS2_VERSION_MAJOR).1
LIBPEAS2_SOURCE = libpeas-$(LIBPEAS2_VERSION).tar.xz
LIBPEAS2_SITE = https://download.gnome.org/sources/libpeas/$(LIBPEAS2_VERSION_MAJOR)
LIBPEAS2_LICENSE = LGPL-2.1+
LIBPEAS2_LICENSE_FILES = COPYING
LIBPEAS2_CPE_ID_VENDOR = gnome
LIBPEAS2_INSTALL_STAGING = YES
LIBPEAS2_DEPENDENCIES = \
	host-libglib2 \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libglib2 \
	$(TARGET_NLS_DEPENDENCIES)

LIBPEAS2_LDFLAGS = $(TARGET_LDFLAGS) $(TARGET_NLS_LIBS)

LIBPEAS2_CONF_OPTS = \
	-Dgtk_doc=false \
	-Dintrospection=true \
	-Dvapi=true \
	-Dlua51=false \
	-Dpython3=false \
	-Dgjs=false

$(eval $(meson-package))
