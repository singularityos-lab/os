################################################################################
#
# singularity-widgets
#
################################################################################

SINGULARITY_WIDGETS_VERSION = 0eb4bfb39f490f231c4b3f42157ef4d281c588d6
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
