################################################################################
#
# singularity-keyframe
#
################################################################################

SINGULARITY_KEYFRAME_VERSION = 79913aa23197bc92fba9acd160a409b2cebdcb74
SINGULARITY_KEYFRAME_SITE = $(call github,singularityos-lab,singularity-keyframe,$(SINGULARITY_KEYFRAME_VERSION))
SINGULARITY_KEYFRAME_LICENSE = GPL-3.0+
SINGULARITY_KEYFRAME_LICENSE_FILES = LICENSE
SINGULARITY_KEYFRAME_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gstreamer1 gst1-plugins-base json-glib libpeas2 pango zlib

SINGULARITY_KEYFRAME_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
