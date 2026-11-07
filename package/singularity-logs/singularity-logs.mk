################################################################################
#
# singularity-logs
#
################################################################################

SINGULARITY_LOGS_VERSION = 340e9ed2375494290ad601797f81b7477543fd98
SINGULARITY_LOGS_SITE = $(call github,singularityos-lab,singularity-logs,$(SINGULARITY_LOGS_VERSION))
SINGULARITY_LOGS_LICENSE = GPL-3.0+
SINGULARITY_LOGS_LICENSE_FILES = LICENSE
SINGULARITY_LOGS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib

SINGULARITY_LOGS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
