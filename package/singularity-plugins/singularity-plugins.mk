################################################################################
#
# singularity-plugins
#
################################################################################

SINGULARITY_PLUGINS_VERSION = 34a6a9ce0f6ec159c1169290313932b387668b1d
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
