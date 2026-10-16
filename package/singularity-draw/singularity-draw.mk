################################################################################
#
# singularity-draw
#
################################################################################

SINGULARITY_DRAW_VERSION = 2a3bf004bbb21712426d26715271281a35b90ac8
SINGULARITY_DRAW_SITE = $(call github,singularityos-lab,singularity-draw,$(SINGULARITY_DRAW_VERSION))
SINGULARITY_DRAW_LICENSE = GPL-3.0+
SINGULARITY_DRAW_LICENSE_FILES = LICENSE
SINGULARITY_DRAW_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee json-glib libxml2 pango sqlite zlib

SINGULARITY_DRAW_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
