################################################################################
#
# singularity-help
#
################################################################################

SINGULARITY_HELP_VERSION = 7beb19c7164f148726243ff6e16d71d02c30a464
SINGULARITY_HELP_SITE = $(call github,singularityos-lab,singularity-help,$(SINGULARITY_HELP_VERSION))
SINGULARITY_HELP_LICENSE = GPL-3.0+
SINGULARITY_HELP_LICENSE_FILES = LICENSE
SINGULARITY_HELP_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libxml2 pango

SINGULARITY_HELP_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
