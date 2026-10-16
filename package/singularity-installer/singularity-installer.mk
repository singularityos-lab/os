################################################################################
#
# singularity-installer
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
SINGULARITY_INSTALLER_VERSION = 1dfe51a5d0246762dc5ad00031e8a38413cc7567
SINGULARITY_INSTALLER_SITE = $(call github,singularityos-lab,singularity-installer,$(SINGULARITY_INSTALLER_VERSION))
SINGULARITY_INSTALLER_LICENSE = GPL-3.0+
SINGULARITY_INSTALLER_LICENSE_FILES = LICENSE
SINGULARITY_INSTALLER_DEPENDENCIES = host-pkgconf host-vala libsingularity libgtk4 libgee json-glib libxml2

$(eval $(meson-package))
