################################################################################
#
# singularity-monitor
#
################################################################################

SINGULARITY_MONITOR_VERSION = ec83e7e173d21d42a3ee5fd76c86e2c95ba1eea8
SINGULARITY_MONITOR_SITE = $(call github,singularityos-lab,singularity-monitor,$(SINGULARITY_MONITOR_VERSION))
SINGULARITY_MONITOR_LICENSE = GPL-3.0+
SINGULARITY_MONITOR_LICENSE_FILES = LICENSE
SINGULARITY_MONITOR_INSTALL_STAGING = YES
SINGULARITY_MONITOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_MONITOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
