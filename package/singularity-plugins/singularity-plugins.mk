################################################################################
#
# singularity-plugins
#
################################################################################

SINGULARITY_PLUGINS_VERSION = 6d989ea5176921647fa427bd95b0b18ce81341a4
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
