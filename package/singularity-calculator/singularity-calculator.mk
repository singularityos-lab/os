################################################################################
#
# singularity-calculator
#
################################################################################

SINGULARITY_CALCULATOR_VERSION = 6e8cd47505ed35e7ef64323c41fbbcfe54a04182
SINGULARITY_CALCULATOR_SITE = $(call github,singularityos-lab,singularity-calculator,$(SINGULARITY_CALCULATOR_VERSION))
SINGULARITY_CALCULATOR_LICENSE = GPL-3.0+
SINGULARITY_CALCULATOR_LICENSE_FILES = LICENSE
SINGULARITY_CALCULATOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CALCULATOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
