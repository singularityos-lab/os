################################################################################
#
# singularity-videos
#
################################################################################

SINGULARITY_VIDEOS_VERSION = f9a44b51a4fece38b1b5fd2869d7d2a08ce50c52
SINGULARITY_VIDEOS_SITE = $(call github,singularityos-lab,singularity-videos,$(SINGULARITY_VIDEOS_VERSION))
SINGULARITY_VIDEOS_LICENSE = GPL-3.0+
SINGULARITY_VIDEOS_LICENSE_FILES = LICENSE
SINGULARITY_VIDEOS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base

SINGULARITY_VIDEOS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_VIDEOS_DEPENDENCIES += host-iride
SINGULARITY_VIDEOS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
