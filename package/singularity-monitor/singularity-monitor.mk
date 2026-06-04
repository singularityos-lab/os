################################################################################
#
# singularity-monitor
#
################################################################################

SINGULARITY_MONITOR_VERSION = ca859f36634029d6d4256caade721cc0d7b71980
SINGULARITY_MONITOR_SITE = $(call github,singularityos-lab,singularity-monitor,$(SINGULARITY_MONITOR_VERSION))
SINGULARITY_MONITOR_LICENSE = GPL-3.0+
SINGULARITY_MONITOR_LICENSE_FILES = LICENSE
SINGULARITY_MONITOR_INSTALL_STAGING = YES
SINGULARITY_MONITOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_MONITOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
