################################################################################
#
# singularity-installer
#
################################################################################

# Local dev builds from buildroot-build/local.mk _OVERRIDE_SRCDIR (build dir -custom),
# which supersedes this github SITE. Keep the pin for RC/CI (no override present).
SINGULARITY_INSTALLER_VERSION = 064e32134f8a03a965a1df92ea586d711725946e
SINGULARITY_INSTALLER_SITE = $(call github,singularityos-lab,singularity-installer,$(SINGULARITY_INSTALLER_VERSION))
SINGULARITY_INSTALLER_LICENSE = GPL-3.0+
SINGULARITY_INSTALLER_LICENSE_FILES = LICENSE
SINGULARITY_INSTALLER_DEPENDENCIES = host-pkgconf host-vala libsingularity libgtk4 libgee json-glib libxml2

$(eval $(meson-package))
