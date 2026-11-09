################################################################################
#
# singularity-drivewriter
#
################################################################################

SINGULARITY_DRIVEWRITER_VERSION = 39fea27a441c1f24af1215dec05929fe2617d9f9
SINGULARITY_DRIVEWRITER_SITE = $(call github,singularityos-lab,singularity-drivewriter,$(SINGULARITY_DRIVEWRITER_VERSION))
SINGULARITY_DRIVEWRITER_LICENSE = GPL-3.0+
SINGULARITY_DRIVEWRITER_LICENSE_FILES = LICENSE
SINGULARITY_DRIVEWRITER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee xz zstd

SINGULARITY_DRIVEWRITER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
