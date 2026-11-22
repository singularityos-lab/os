################################################################################
#
# singularity-wave
#
################################################################################

SINGULARITY_WAVE_VERSION = 966d9e0856d2bad9bf5270ef395b314c1f76f32c
SINGULARITY_WAVE_SITE = $(call github,singularityos-lab,singularity-wave,$(SINGULARITY_WAVE_VERSION))
SINGULARITY_WAVE_LICENSE = GPL-3.0+
SINGULARITY_WAVE_LICENSE_FILES = LICENSE
SINGULARITY_WAVE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo libgee gstreamer1 gst1-plugins-base json-glib libxml2 pango zlib

SINGULARITY_WAVE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_WAVE_DEPENDENCIES += host-iride
SINGULARITY_WAVE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
