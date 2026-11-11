################################################################################
#
# singularity-qrcodes
#
################################################################################

SINGULARITY_QRCODES_VERSION = 644cec6dfd2f39f785d2bc1049a07f6c298e32a7
SINGULARITY_QRCODES_SITE = $(call github,singularityos-lab,singularity-qrcodes,$(SINGULARITY_QRCODES_VERSION))
SINGULARITY_QRCODES_LICENSE = GPL-3.0+
SINGULARITY_QRCODES_LICENSE_FILES = LICENSE
SINGULARITY_QRCODES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gstreamer1 gst1-plugins-base json-glib libpeas2 zbar

SINGULARITY_QRCODES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
