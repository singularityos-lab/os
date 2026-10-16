################################################################################
#
# singularity-publish
#
################################################################################

SINGULARITY_PUBLISH_VERSION = d39c582617ec32e306dcb25f4b6bf2b4ad4afe8c
SINGULARITY_PUBLISH_SITE = $(call github,singularityos-lab,singularity-publish,$(SINGULARITY_PUBLISH_VERSION))
SINGULARITY_PUBLISH_LICENSE = GPL-3.0+
SINGULARITY_PUBLISH_LICENSE_FILES = LICENSE
SINGULARITY_PUBLISH_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo fontconfig gdk-pixbuf libgee lcms2 librsvg libxml2 pango poppler sqlite zlib

SINGULARITY_PUBLISH_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
