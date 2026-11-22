################################################################################
#
# singularity-drivewriter
#
################################################################################

SINGULARITY_DRIVEWRITER_VERSION = 41fadd3d59ddde5687a051d992edef3c762d6fec
SINGULARITY_DRIVEWRITER_SITE = $(call github,singularityos-lab,singularity-drivewriter,$(SINGULARITY_DRIVEWRITER_VERSION))
SINGULARITY_DRIVEWRITER_LICENSE = GPL-3.0+
SINGULARITY_DRIVEWRITER_LICENSE_FILES = LICENSE
SINGULARITY_DRIVEWRITER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee xz zstd

SINGULARITY_DRIVEWRITER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_DRIVEWRITER_DEPENDENCIES += host-iride
SINGULARITY_DRIVEWRITER_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
