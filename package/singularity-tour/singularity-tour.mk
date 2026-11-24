################################################################################
#
# singularity-tour
#
################################################################################

SINGULARITY_TOUR_VERSION = a8bdf05fec0326fd1553b3808937acfb8f988c5b
SINGULARITY_TOUR_SITE = $(call github,singularityos-lab,singularity-tour,$(SINGULARITY_TOUR_VERSION))
SINGULARITY_TOUR_LICENSE = GPL-3.0+
SINGULARITY_TOUR_LICENSE_FILES = LICENSE
SINGULARITY_TOUR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee pango json-glib

SINGULARITY_TOUR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_TOUR_DEPENDENCIES += host-iride
SINGULARITY_TOUR_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
