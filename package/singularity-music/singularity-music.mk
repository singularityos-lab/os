################################################################################
#
# singularity-music
#
################################################################################

SINGULARITY_MUSIC_VERSION = 82af956d131567c6082ac7241c0856f16f105ff0
SINGULARITY_MUSIC_SITE = $(call github,singularityos-lab,singularity-music,$(SINGULARITY_MUSIC_VERSION))
SINGULARITY_MUSIC_LICENSE = GPL-3.0+
SINGULARITY_MUSIC_LICENSE_FILES = LICENSE
SINGULARITY_MUSIC_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base libsoup3

SINGULARITY_MUSIC_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
