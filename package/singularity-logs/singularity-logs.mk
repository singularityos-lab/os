################################################################################
#
# singularity-logs
#
################################################################################

SINGULARITY_LOGS_VERSION = f61b027cf4f01577684e75c760c8e7d3e7097246
SINGULARITY_LOGS_SITE = $(call github,singularityos-lab,singularity-logs,$(SINGULARITY_LOGS_VERSION))
SINGULARITY_LOGS_LICENSE = GPL-3.0+
SINGULARITY_LOGS_LICENSE_FILES = LICENSE
SINGULARITY_LOGS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_LOGS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_LOGS_DEPENDENCIES += host-iride
SINGULARITY_LOGS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
