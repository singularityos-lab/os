################################################################################
#
# singularity-monitor
#
################################################################################

SINGULARITY_MONITOR_VERSION = 40c720bdd6987f04e30f9af498a0cdfcbfa1e645
SINGULARITY_MONITOR_SITE = $(call github,singularityos-lab,singularity-monitor,$(SINGULARITY_MONITOR_VERSION))
SINGULARITY_MONITOR_LICENSE = GPL-3.0+
SINGULARITY_MONITOR_LICENSE_FILES = LICENSE
SINGULARITY_MONITOR_INSTALL_STAGING = YES
SINGULARITY_MONITOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_MONITOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MONITOR_DEPENDENCIES += host-iride
SINGULARITY_MONITOR_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
