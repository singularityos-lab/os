################################################################################
#
# singularity-photos
#
################################################################################

SINGULARITY_PHOTOS_VERSION = dd3ccb656bec1e91add9cc9ffc8539bc56b13e07
SINGULARITY_PHOTOS_SITE = $(call github,singularityos-lab,singularity-photos,$(SINGULARITY_PHOTOS_VERSION))
SINGULARITY_PHOTOS_LICENSE = GPL-3.0+
SINGULARITY_PHOTOS_LICENSE_FILES = LICENSE
SINGULARITY_PHOTOS_INSTALL_STAGING = YES
SINGULARITY_PHOTOS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libgphoto2 webp tiff

SINGULARITY_PHOTOS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
