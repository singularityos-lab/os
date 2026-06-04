################################################################################
#
# singularity-loginui
#
################################################################################

SINGULARITY_LOGINUI_VERSION = fe0b4cd0d2c806c8aa502ad92389adc61b086f13
SINGULARITY_LOGINUI_SITE = $(call github,singularityos-lab,singularity-loginui,$(SINGULARITY_LOGINUI_VERSION))
SINGULARITY_LOGINUI_LICENSE = LGPL-2.1
SINGULARITY_LOGINUI_LICENSE_FILES = LICENSE
SINGULARITY_LOGINUI_INSTALL_STAGING = YES
SINGULARITY_LOGINUI_DEPENDENCIES = \
	host-pkgconf \
	cairo \
	pango \
	gdk-pixbuf \
	wayland

$(eval $(meson-package))
