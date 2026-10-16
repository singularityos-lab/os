################################################################################
#
# singularity-drivewriter
#
################################################################################

SINGULARITY_DRIVEWRITER_VERSION = c453e5db509c5ee52997432e9b35307ae750037a
SINGULARITY_DRIVEWRITER_SITE = $(call github,singularityos-lab,singularity-drivewriter,$(SINGULARITY_DRIVEWRITER_VERSION))
SINGULARITY_DRIVEWRITER_LICENSE = GPL-3.0+
SINGULARITY_DRIVEWRITER_LICENSE_FILES = LICENSE
SINGULARITY_DRIVEWRITER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee xz zstd

SINGULARITY_DRIVEWRITER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
