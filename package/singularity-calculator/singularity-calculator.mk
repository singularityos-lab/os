################################################################################
#
# singularity-calculator
#
################################################################################

SINGULARITY_CALCULATOR_VERSION = 91346542b3f0561b77054abe1f6f4dacc53b19a3
SINGULARITY_CALCULATOR_SITE = $(call github,singularityos-lab,singularity-calculator,$(SINGULARITY_CALCULATOR_VERSION))
SINGULARITY_CALCULATOR_LICENSE = GPL-3.0+
SINGULARITY_CALCULATOR_LICENSE_FILES = LICENSE
SINGULARITY_CALCULATOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CALCULATOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CALCULATOR_DEPENDENCIES += host-iride
SINGULARITY_CALCULATOR_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
