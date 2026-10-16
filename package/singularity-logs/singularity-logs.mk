################################################################################
#
# singularity-logs
#
################################################################################

SINGULARITY_LOGS_VERSION = b6a7af3ce234b28f0ad0c936b7311442cb4b2d4d
SINGULARITY_LOGS_SITE = $(call github,singularityos-lab,singularity-logs,$(SINGULARITY_LOGS_VERSION))
SINGULARITY_LOGS_LICENSE = GPL-3.0+
SINGULARITY_LOGS_LICENSE_FILES = LICENSE
SINGULARITY_LOGS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_LOGS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
