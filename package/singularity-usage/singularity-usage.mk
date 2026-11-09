################################################################################
#
# singularity-usage
#
################################################################################

SINGULARITY_USAGE_VERSION = 797fccdbc6b7fafbde3a69bed5921d3e50b2eec3
SINGULARITY_USAGE_SITE = $(call github,singularityos-lab,singularity-usage,$(SINGULARITY_USAGE_VERSION))
SINGULARITY_USAGE_LICENSE = GPL-3.0+
SINGULARITY_USAGE_LICENSE_FILES = LICENSE
SINGULARITY_USAGE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_USAGE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
