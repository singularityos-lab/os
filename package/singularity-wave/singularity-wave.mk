################################################################################
#
# singularity-wave
#
################################################################################

SINGULARITY_WAVE_VERSION = 9cd27226a837be0c1bf5f156fa5fa23f874ce386
SINGULARITY_WAVE_SITE = $(call github,singularityos-lab,singularity-wave,$(SINGULARITY_WAVE_VERSION))
SINGULARITY_WAVE_LICENSE = GPL-3.0+
SINGULARITY_WAVE_LICENSE_FILES = LICENSE
SINGULARITY_WAVE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo libgee gstreamer1 gst1-plugins-base json-glib libxml2 pango zlib

SINGULARITY_WAVE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
