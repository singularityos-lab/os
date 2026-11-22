################################################################################
#
# singularity-slides
#
################################################################################

SINGULARITY_SLIDES_VERSION = 2fd575b5357d85601b1e4e7fd822ab7e4ca86b59
SINGULARITY_SLIDES_SITE = $(call github,singularityos-lab,singularity-slides,$(SINGULARITY_SLIDES_VERSION))
SINGULARITY_SLIDES_LICENSE = GPL-3.0+
SINGULARITY_SLIDES_LICENSE_FILES = LICENSE
SINGULARITY_SLIDES_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 gst1-plugins-base json-glib libsoup3 libxml2 pango zlib

SINGULARITY_SLIDES_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_SLIDES_DEPENDENCIES += host-iride
SINGULARITY_SLIDES_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
