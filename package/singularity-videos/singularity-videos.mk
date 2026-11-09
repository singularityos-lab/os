################################################################################
#
# singularity-videos
#
################################################################################

SINGULARITY_VIDEOS_VERSION = b468f6d2afc4b0962667daad0842daaa8df04d86
SINGULARITY_VIDEOS_SITE = $(call github,singularityos-lab,singularity-videos,$(SINGULARITY_VIDEOS_VERSION))
SINGULARITY_VIDEOS_LICENSE = GPL-3.0+
SINGULARITY_VIDEOS_LICENSE_FILES = LICENSE
SINGULARITY_VIDEOS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base

SINGULARITY_VIDEOS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
