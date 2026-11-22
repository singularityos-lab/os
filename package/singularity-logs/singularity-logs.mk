################################################################################
#
# singularity-logs
#
################################################################################

SINGULARITY_LOGS_VERSION = 77c056d352e339d9e069b203edbd515d4967f3a0
SINGULARITY_LOGS_SITE = $(call github,singularityos-lab,singularity-logs,$(SINGULARITY_LOGS_VERSION))
SINGULARITY_LOGS_LICENSE = GPL-3.0+
SINGULARITY_LOGS_LICENSE_FILES = LICENSE
SINGULARITY_LOGS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_LOGS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_LOGS_DEPENDENCIES += host-iride
SINGULARITY_LOGS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
