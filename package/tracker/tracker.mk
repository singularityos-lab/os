################################################################################
#
# tracker
#
################################################################################

TRACKER_VERSION_MAJOR = 3.7
TRACKER_VERSION = $(TRACKER_VERSION_MAJOR).3
TRACKER_SOURCE = tracker-$(TRACKER_VERSION).tar.xz
TRACKER_SITE = https://download.gnome.org/sources/tracker/$(TRACKER_VERSION_MAJOR)
TRACKER_LICENSE = GPL-2.0+, LGPL-2.1+
TRACKER_LICENSE_FILES = COPYING COPYING.LESSER
TRACKER_CPE_ID_VENDOR = gnome
TRACKER_INSTALL_STAGING = YES
TRACKER_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libglib2 \
	sqlite \
	json-glib \
	icu \
	dbus

TRACKER_CONF_OPTS = \
	-Ddocs=false \
	-Dman=false \
	-Dsystemd_user_services=false \
	-Dstemmer=disabled \
	-Dtests=false \
	-Dintrospection=enabled \
	-Dvapi=enabled \
	-Dbash_completion=false \
	--cross-file=$(TRACKER_PKGDIR)/tracker-crossfile.txt

$(eval $(meson-package))
