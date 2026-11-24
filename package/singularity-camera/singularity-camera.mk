################################################################################
#
# singularity-camera
#
################################################################################

SINGULARITY_CAMERA_VERSION = 15f6a59d084326626cc22dc612e0b9dbea02906c
SINGULARITY_CAMERA_SITE = $(call github,singularityos-lab,singularity-camera,$(SINGULARITY_CAMERA_VERSION))
SINGULARITY_CAMERA_LICENSE = GPL-3.0+
SINGULARITY_CAMERA_LICENSE_FILES = LICENSE
SINGULARITY_CAMERA_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base libpeas2

SINGULARITY_CAMERA_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CAMERA_DEPENDENCIES += host-iride
SINGULARITY_CAMERA_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
