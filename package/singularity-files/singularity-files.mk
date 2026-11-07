################################################################################
#
# singularity-files
#
################################################################################

SINGULARITY_FILES_VERSION = 43e34c3c6bc2a9ff0e85a1af10b137423e2d344b
SINGULARITY_FILES_SITE = $(call github,singularityos-lab,singularity-files,$(SINGULARITY_FILES_VERSION))
SINGULARITY_FILES_LICENSE = GPL-3.0+
SINGULARITY_FILES_LICENSE_FILES = LICENSE
SINGULARITY_FILES_INSTALL_STAGING = YES
SINGULARITY_FILES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2 json-glib

SINGULARITY_FILES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
