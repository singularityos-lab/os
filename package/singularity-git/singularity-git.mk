################################################################################
#
# singularity-git
#
################################################################################

SINGULARITY_GIT_VERSION = b72a2e3fbbf7e81e0b23d602f99a138536eec030
SINGULARITY_GIT_SITE = $(call github,singularityos-lab,singularity-git,$(SINGULARITY_GIT_VERSION))
SINGULARITY_GIT_LICENSE = GPL-3.0+
SINGULARITY_GIT_LICENSE_FILES = LICENSE
SINGULARITY_GIT_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gtksourceview

SINGULARITY_GIT_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
