################################################################################
#
# singularity-help
#
################################################################################

SINGULARITY_HELP_VERSION = 4c86a957a6898b503e74f108febcd1d00b09f407
SINGULARITY_HELP_SITE = $(call github,singularityos-lab,singularity-help,$(SINGULARITY_HELP_VERSION))
SINGULARITY_HELP_LICENSE = GPL-3.0+
SINGULARITY_HELP_LICENSE_FILES = LICENSE
SINGULARITY_HELP_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libxml2 pango

SINGULARITY_HELP_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_HELP_DEPENDENCIES += host-iride
SINGULARITY_HELP_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
