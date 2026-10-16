################################################################################
#
# singularity-clock
#
################################################################################

SINGULARITY_CLOCK_VERSION = 087dc31c47c69dae9d26ed5b64e713edd6f6f03f
SINGULARITY_CLOCK_SITE = $(call github,singularityos-lab,singularity-clock,$(SINGULARITY_CLOCK_VERSION))
SINGULARITY_CLOCK_LICENSE = GPL-3.0+
SINGULARITY_CLOCK_LICENSE_FILES = LICENSE
SINGULARITY_CLOCK_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_CLOCK_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
