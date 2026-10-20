################################################################################
#
# singularity-git
#
################################################################################

SINGULARITY_GIT_VERSION = 5b0cb74377151bf4dc4a1851a3152e6252e7c581
SINGULARITY_GIT_SITE = $(call github,singularityos-lab,singularity-git,$(SINGULARITY_GIT_VERSION))
SINGULARITY_GIT_LICENSE = GPL-3.0+
SINGULARITY_GIT_LICENSE_FILES = LICENSE
SINGULARITY_GIT_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gtksourceview

SINGULARITY_GIT_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
