################################################################################
#
# singularity-wave
#
################################################################################

SINGULARITY_WAVE_VERSION = cf3feb7aa9f76986581ed1f993e6b0da6cb091d3
SINGULARITY_WAVE_SITE = $(call github,singularityos-lab,singularity-wave,$(SINGULARITY_WAVE_VERSION))
SINGULARITY_WAVE_LICENSE = GPL-3.0+
SINGULARITY_WAVE_LICENSE_FILES = LICENSE
SINGULARITY_WAVE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo libgee gstreamer1 gst1-plugins-base json-glib libxml2 pango zlib

SINGULARITY_WAVE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
