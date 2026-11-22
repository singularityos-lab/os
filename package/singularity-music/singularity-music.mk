################################################################################
#
# singularity-music
#
################################################################################

SINGULARITY_MUSIC_VERSION = fb191dc71ef5fbf6c020b4afb30b5d9eb3a3e0bf
SINGULARITY_MUSIC_SITE = $(call github,singularityos-lab,singularity-music,$(SINGULARITY_MUSIC_VERSION))
SINGULARITY_MUSIC_LICENSE = GPL-3.0+
SINGULARITY_MUSIC_LICENSE_FILES = LICENSE
SINGULARITY_MUSIC_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base libsoup3

SINGULARITY_MUSIC_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MUSIC_DEPENDENCIES += host-iride
SINGULARITY_MUSIC_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
