################################################################################
#
# singularity-widgets
#
################################################################################

SINGULARITY_WIDGETS_VERSION = 800db794d7de2a6de2f60f88d31f826012011fba
SINGULARITY_WIDGETS_SITE = $(call github,singularityos-lab,singularity-widgets,$(SINGULARITY_WIDGETS_VERSION))
SINGULARITY_WIDGETS_LICENSE = GPL-3.0+
SINGULARITY_WIDGETS_LICENSE_FILES = LICENSE
SINGULARITY_WIDGETS_INSTALL_STAGING = YES
SINGULARITY_WIDGETS_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	libsingularity \
	libgtk4 \
	libgee

$(eval $(meson-package))
