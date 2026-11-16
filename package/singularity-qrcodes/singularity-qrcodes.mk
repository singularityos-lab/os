################################################################################
#
# singularity-qrcodes
#
################################################################################

SINGULARITY_QRCODES_VERSION = ae5c63c5bc4ad6b6a9d2e430e66b765c92e904de
SINGULARITY_QRCODES_SITE = $(call github,singularityos-lab,singularity-qrcodes,$(SINGULARITY_QRCODES_VERSION))
SINGULARITY_QRCODES_LICENSE = GPL-3.0+
SINGULARITY_QRCODES_LICENSE_FILES = LICENSE
SINGULARITY_QRCODES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gstreamer1 gst1-plugins-base json-glib libpeas2 zbar

SINGULARITY_QRCODES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
