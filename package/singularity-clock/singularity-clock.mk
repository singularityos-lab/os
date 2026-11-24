################################################################################
#
# singularity-clock
#
################################################################################

SINGULARITY_CLOCK_VERSION = cf7fae24c0e82f59407830b4cded66521d1d4213
SINGULARITY_CLOCK_SITE = $(call github,singularityos-lab,singularity-clock,$(SINGULARITY_CLOCK_VERSION))
SINGULARITY_CLOCK_LICENSE = GPL-3.0+
SINGULARITY_CLOCK_LICENSE_FILES = LICENSE
SINGULARITY_CLOCK_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2

SINGULARITY_CLOCK_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_CLOCK_DEPENDENCIES += host-iride
SINGULARITY_CLOCK_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
