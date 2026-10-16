################################################################################
#
# singularity-monitor
#
################################################################################

SINGULARITY_MONITOR_VERSION = 1b1c930a43e7aa90320b995f57cc5998eb4570e7
SINGULARITY_MONITOR_SITE = $(call github,singularityos-lab,singularity-monitor,$(SINGULARITY_MONITOR_VERSION))
SINGULARITY_MONITOR_LICENSE = GPL-3.0+
SINGULARITY_MONITOR_LICENSE_FILES = LICENSE
SINGULARITY_MONITOR_INSTALL_STAGING = YES
SINGULARITY_MONITOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_MONITOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
