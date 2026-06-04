################################################################################
#
# singularity-plugins
#
################################################################################

SINGULARITY_PLUGINS_VERSION = e3d71b45a43971a434552539acfb7bfd57ccccd3
SINGULARITY_PLUGINS_SITE = $(call github,singularityos-lab,singularity-plugins,$(SINGULARITY_PLUGINS_VERSION))
SINGULARITY_PLUGINS_LICENSE = GPL-3.0+
SINGULARITY_PLUGINS_LICENSE_FILES = LICENSE
SINGULARITY_PLUGINS_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	libsingularity \
	libgtk4 \
	libpeas2 \
	libgee

$(eval $(meson-package))
