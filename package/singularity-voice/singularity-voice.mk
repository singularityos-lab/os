################################################################################
#
# singularity-voice
#
################################################################################

SINGULARITY_VOICE_VERSION = 8fcf7d32ba8fe9be6489cbb5fca054deed1c3410
SINGULARITY_VOICE_SITE = $(call github,singularityos-lab,singularity-voice,$(SINGULARITY_VOICE_VERSION))
SINGULARITY_VOICE_LICENSE = GPL-3.0+
SINGULARITY_VOICE_LICENSE_FILES = LICENSE
SINGULARITY_VOICE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base json-glib

SINGULARITY_VOICE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
