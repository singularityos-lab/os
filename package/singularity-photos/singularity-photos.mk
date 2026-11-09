################################################################################
#
# singularity-photos
#
################################################################################

SINGULARITY_PHOTOS_VERSION = a5f7ff7dac10a35fe53a054d134443a137ee98bf
SINGULARITY_PHOTOS_SITE = $(call github,singularityos-lab,singularity-photos,$(SINGULARITY_PHOTOS_VERSION))
SINGULARITY_PHOTOS_LICENSE = GPL-3.0+
SINGULARITY_PHOTOS_LICENSE_FILES = LICENSE
SINGULARITY_PHOTOS_INSTALL_STAGING = YES
SINGULARITY_PHOTOS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libgphoto2 webp tiff

SINGULARITY_PHOTOS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
