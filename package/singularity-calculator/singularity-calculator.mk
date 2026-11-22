################################################################################
#
# singularity-calculator
#
################################################################################

SINGULARITY_CALCULATOR_VERSION = 89f950131f02150a0f42a4782f2f43a271735960
SINGULARITY_CALCULATOR_SITE = $(call github,singularityos-lab,singularity-calculator,$(SINGULARITY_CALCULATOR_VERSION))
SINGULARITY_CALCULATOR_LICENSE = GPL-3.0+
SINGULARITY_CALCULATOR_LICENSE_FILES = LICENSE
SINGULARITY_CALCULATOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_CALCULATOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CALCULATOR_DEPENDENCIES += host-iride
SINGULARITY_CALCULATOR_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
