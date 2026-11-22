################################################################################
#
# singularity-files
#
################################################################################

SINGULARITY_FILES_VERSION = 6d4da10fd8d3dd2d0b01401d0b92b749082719a5
SINGULARITY_FILES_SITE = $(call github,singularityos-lab,singularity-files,$(SINGULARITY_FILES_VERSION))
SINGULARITY_FILES_LICENSE = GPL-3.0+
SINGULARITY_FILES_LICENSE_FILES = LICENSE
SINGULARITY_FILES_INSTALL_STAGING = YES
SINGULARITY_FILES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2 json-glib

SINGULARITY_FILES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_FILES_DEPENDENCIES += host-iride
SINGULARITY_FILES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
