################################################################################
#
# singularity-characters
#
################################################################################

SINGULARITY_CHARACTERS_VERSION = 8dfc950a9e2caa677c2fbfbb0f415fd622db7d4c
SINGULARITY_CHARACTERS_SITE = $(call github,singularityos-lab,singularity-characters,$(SINGULARITY_CHARACTERS_VERSION))
SINGULARITY_CHARACTERS_LICENSE = GPL-3.0+
SINGULARITY_CHARACTERS_LICENSE_FILES = LICENSE
SINGULARITY_CHARACTERS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CHARACTERS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CHARACTERS_DEPENDENCIES += host-iride
SINGULARITY_CHARACTERS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
