################################################################################
#
# singularity-installer
#
################################################################################

SINGULARITY_INSTALLER_VERSION = f4d7b8f8b0d1018c2a4a8888c444f72aa03c607d
SINGULARITY_INSTALLER_SITE = $(call github,singularityos-lab,singularity-installer,$(SINGULARITY_INSTALLER_VERSION))
SINGULARITY_INSTALLER_LICENSE = GPL-3.0+
SINGULARITY_INSTALLER_LICENSE_FILES = LICENSE
SINGULARITY_INSTALLER_DEPENDENCIES = host-pkgconf host-vala libsingularity libgtk4 libgee json-glib libxml2

$(eval $(meson-package))
