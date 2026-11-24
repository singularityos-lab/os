################################################################################
#
# singularity-plugins
#
################################################################################

SINGULARITY_PLUGINS_VERSION = 0284a5f83904528d4c80819ddd197af3acdf8c27
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
