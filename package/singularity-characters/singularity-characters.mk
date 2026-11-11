################################################################################
#
# singularity-characters
#
################################################################################

SINGULARITY_CHARACTERS_VERSION = 1816805310f9ad312b4b6edf0477fcc0dad28b75
SINGULARITY_CHARACTERS_SITE = $(call github,singularityos-lab,singularity-characters,$(SINGULARITY_CHARACTERS_VERSION))
SINGULARITY_CHARACTERS_LICENSE = GPL-3.0+
SINGULARITY_CHARACTERS_LICENSE_FILES = LICENSE
SINGULARITY_CHARACTERS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CHARACTERS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
