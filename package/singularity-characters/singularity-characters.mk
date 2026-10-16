################################################################################
#
# singularity-characters
#
################################################################################

SINGULARITY_CHARACTERS_VERSION = 61b013331ab78a574f57ab13307ebe675f5c6c14
SINGULARITY_CHARACTERS_SITE = $(call github,singularityos-lab,singularity-characters,$(SINGULARITY_CHARACTERS_VERSION))
SINGULARITY_CHARACTERS_LICENSE = GPL-3.0+
SINGULARITY_CHARACTERS_LICENSE_FILES = LICENSE
SINGULARITY_CHARACTERS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CHARACTERS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
