################################################################################
#
# singularity-voice
#
################################################################################

SINGULARITY_VOICE_VERSION = e76c3867f9b9e2e02c630eeee8d3a4b9d1ed8215
SINGULARITY_VOICE_SITE = $(call github,singularityos-lab,singularity-voice,$(SINGULARITY_VOICE_VERSION))
SINGULARITY_VOICE_LICENSE = GPL-3.0+
SINGULARITY_VOICE_LICENSE_FILES = LICENSE
SINGULARITY_VOICE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base json-glib

SINGULARITY_VOICE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_VOICE_DEPENDENCIES += host-iride
SINGULARITY_VOICE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
