################################################################################
#
# singularity-passwords
#
################################################################################

SINGULARITY_PASSWORDS_VERSION = dd44eb8acf40d1a69ca887fb0276219bc09561ea
SINGULARITY_PASSWORDS_SITE = $(call github,singularityos-lab,singularity-passwords,$(SINGULARITY_PASSWORDS_VERSION))
SINGULARITY_PASSWORDS_LICENSE = GPL-3.0+
SINGULARITY_PASSWORDS_LICENSE_FILES = LICENSE
SINGULARITY_PASSWORDS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_PASSWORDS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
