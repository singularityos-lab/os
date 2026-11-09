################################################################################
#
# singularity-camera
#
################################################################################

SINGULARITY_CAMERA_VERSION = d16d29e0571ca83543442c01908f8a72c29187e1
SINGULARITY_CAMERA_SITE = $(call github,singularityos-lab,singularity-camera,$(SINGULARITY_CAMERA_VERSION))
SINGULARITY_CAMERA_LICENSE = GPL-3.0+
SINGULARITY_CAMERA_LICENSE_FILES = LICENSE
SINGULARITY_CAMERA_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base libpeas2

SINGULARITY_CAMERA_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
