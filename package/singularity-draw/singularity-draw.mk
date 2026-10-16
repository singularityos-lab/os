################################################################################
#
# singularity-draw
#
################################################################################

SINGULARITY_DRAW_VERSION = fde293488fc3e307b42e771da5480362e643bd59
SINGULARITY_DRAW_SITE = $(call github,singularityos-lab,singularity-draw,$(SINGULARITY_DRAW_VERSION))
SINGULARITY_DRAW_LICENSE = GPL-3.0+
SINGULARITY_DRAW_LICENSE_FILES = LICENSE
SINGULARITY_DRAW_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee json-glib libxml2 pango sqlite zlib

SINGULARITY_DRAW_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
