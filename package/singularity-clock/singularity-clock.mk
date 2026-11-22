################################################################################
#
# singularity-clock
#
################################################################################

SINGULARITY_CLOCK_VERSION = fa5bb6c20328dac1e746f5fae4eef865bed9c963
SINGULARITY_CLOCK_SITE = $(call github,singularityos-lab,singularity-clock,$(SINGULARITY_CLOCK_VERSION))
SINGULARITY_CLOCK_LICENSE = GPL-3.0+
SINGULARITY_CLOCK_LICENSE_FILES = LICENSE
SINGULARITY_CLOCK_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_CLOCK_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CLOCK_DEPENDENCIES += host-iride
SINGULARITY_CLOCK_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
