################################################################################
#
# singularity-passwords
#
################################################################################

SINGULARITY_PASSWORDS_VERSION = c7ebeebde2f3ff0935f3d0559735525cd56b5615
SINGULARITY_PASSWORDS_SITE = $(call github,singularityos-lab,singularity-passwords,$(SINGULARITY_PASSWORDS_VERSION))
SINGULARITY_PASSWORDS_LICENSE = GPL-3.0+
SINGULARITY_PASSWORDS_LICENSE_FILES = LICENSE
SINGULARITY_PASSWORDS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee

SINGULARITY_PASSWORDS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_PASSWORDS_DEPENDENCIES += host-iride
SINGULARITY_PASSWORDS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
