################################################################################
#
# singularity-git
#
################################################################################

SINGULARITY_GIT_VERSION = 677c2e2bb639a87870318bc356de0cc3062b9e15
SINGULARITY_GIT_SITE = $(call github,singularityos-lab,singularity-git,$(SINGULARITY_GIT_VERSION))
SINGULARITY_GIT_LICENSE = GPL-3.0+
SINGULARITY_GIT_LICENSE_FILES = LICENSE
SINGULARITY_GIT_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gtksourceview

SINGULARITY_GIT_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_GIT_DEPENDENCIES += host-iride
SINGULARITY_GIT_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
