################################################################################
#
# singularity-fonts
#
################################################################################

SINGULARITY_FONTS_VERSION = 7dd7fec966c4f577215ad52cbd7fc82961cafaa7
SINGULARITY_FONTS_SITE = $(call github,singularityos-lab,singularity-fonts,$(SINGULARITY_FONTS_VERSION))
SINGULARITY_FONTS_LICENSE = GPL-3.0+
SINGULARITY_FONTS_LICENSE_FILES = LICENSE
SINGULARITY_FONTS_INSTALL_STAGING = YES
SINGULARITY_FONTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libpeas2 pango

SINGULARITY_FONTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
