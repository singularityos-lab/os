################################################################################
#
# singularity-camera
#
################################################################################

SINGULARITY_CAMERA_VERSION = 33f2f294244a6b87793681e8da9cc231b287eee3
SINGULARITY_CAMERA_SITE = $(call github,singularityos-lab,singularity-camera,$(SINGULARITY_CAMERA_VERSION))
SINGULARITY_CAMERA_LICENSE = GPL-3.0+
SINGULARITY_CAMERA_LICENSE_FILES = LICENSE
SINGULARITY_CAMERA_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base libpeas2

SINGULARITY_CAMERA_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
