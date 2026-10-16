################################################################################
#
# libgusb
#
################################################################################

LIBGUSB_VERSION = 0.4.9
LIBGUSB_SITE = $(call github,hughsie,libgusb,$(LIBGUSB_VERSION))
LIBGUSB_LICENSE = LGPL-2.1+
LIBGUSB_LICENSE_FILES = COPYING
LIBGUSB_INSTALL_STAGING = YES
LIBGUSB_DEPENDENCIES = host-pkgconf libglib2 libusb json-glib
LIBGUSB_CONF_OPTS = \
	-Dtests=false \
	-Dvapi=false \
	-Ddocs=false \
	-Dintrospection=false \
	-Dumockdev=disabled \
	-Dusb_ids=/usr/share/hwdata/usb.ids

$(eval $(meson-package))
