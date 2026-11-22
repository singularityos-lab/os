################################################################################
#
# singularity-monitor
#
################################################################################

SINGULARITY_MONITOR_VERSION = 5c1fe36e72c0a511bb129e6ed5aca84d58ebb1a2
SINGULARITY_MONITOR_SITE = $(call github,singularityos-lab,singularity-monitor,$(SINGULARITY_MONITOR_VERSION))
SINGULARITY_MONITOR_LICENSE = GPL-3.0+
SINGULARITY_MONITOR_LICENSE_FILES = LICENSE
SINGULARITY_MONITOR_INSTALL_STAGING = YES
SINGULARITY_MONITOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_MONITOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_MONITOR_DEPENDENCIES += host-iride
SINGULARITY_MONITOR_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
