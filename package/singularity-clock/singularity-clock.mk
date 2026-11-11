################################################################################
#
# singularity-clock
#
################################################################################

SINGULARITY_CLOCK_VERSION = 27d44ba4886501e5e52c66d8c093beb3c64d838b
SINGULARITY_CLOCK_SITE = $(call github,singularityos-lab,singularity-clock,$(SINGULARITY_CLOCK_VERSION))
SINGULARITY_CLOCK_LICENSE = GPL-3.0+
SINGULARITY_CLOCK_LICENSE_FILES = LICENSE
SINGULARITY_CLOCK_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_CLOCK_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
