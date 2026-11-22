################################################################################
#
# singularity-montage
#
################################################################################

SINGULARITY_MONTAGE_VERSION = d0a528ea8d49ce84da3ca3a371506a2194563dac
SINGULARITY_MONTAGE_SITE = $(call github,singularityos-lab,singularity-montage,$(SINGULARITY_MONTAGE_VERSION))
SINGULARITY_MONTAGE_LICENSE = GPL-3.0+
SINGULARITY_MONTAGE_LICENSE_FILES = LICENSE
SINGULARITY_MONTAGE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gstreamer1 gst1-plugins-base json-glib libxml2 pango zlib

SINGULARITY_MONTAGE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MONTAGE_DEPENDENCIES += host-iride
SINGULARITY_MONTAGE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
