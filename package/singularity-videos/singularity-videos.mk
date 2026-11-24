################################################################################
#
# singularity-videos
#
################################################################################

SINGULARITY_VIDEOS_VERSION = 8716914066f83a0c35fac6d0cef7ae4fca476845
SINGULARITY_VIDEOS_SITE = $(call github,singularityos-lab,singularity-videos,$(SINGULARITY_VIDEOS_VERSION))
SINGULARITY_VIDEOS_LICENSE = GPL-3.0+
SINGULARITY_VIDEOS_LICENSE_FILES = LICENSE
SINGULARITY_VIDEOS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base

SINGULARITY_VIDEOS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_VIDEOS_DEPENDENCIES += host-iride
SINGULARITY_VIDEOS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
