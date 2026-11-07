################################################################################
#
# singularity-plugins
#
################################################################################

SINGULARITY_PLUGINS_VERSION = ace60dbcbb06a7000ee4d9e972cc03531dbb3df3
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
