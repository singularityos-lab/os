################################################################################
#
# singularity-usage
#
################################################################################

SINGULARITY_USAGE_VERSION = 6b30415ce43fff6beadc5af117e582443621ad49
SINGULARITY_USAGE_SITE = $(call github,singularityos-lab,singularity-usage,$(SINGULARITY_USAGE_VERSION))
SINGULARITY_USAGE_LICENSE = GPL-3.0+
SINGULARITY_USAGE_LICENSE_FILES = LICENSE
SINGULARITY_USAGE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_USAGE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_USAGE_DEPENDENCIES += host-iride
SINGULARITY_USAGE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
