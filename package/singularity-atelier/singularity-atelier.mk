################################################################################
#
# singularity-atelier
#
################################################################################

SINGULARITY_ATELIER_VERSION = cb0a9880313cce4e7864bed046fdc9da0b9af46e
SINGULARITY_ATELIER_SITE = $(call github,singularityos-lab,singularity-atelier,$(SINGULARITY_ATELIER_VERSION))
SINGULARITY_ATELIER_LICENSE = GPL-3.0+
SINGULARITY_ATELIER_LICENSE_FILES = LICENSE
SINGULARITY_ATELIER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee gstreamer1 json-glib lcms2 libpeas2 libxml2 pango zlib

SINGULARITY_ATELIER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
