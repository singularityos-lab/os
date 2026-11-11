################################################################################
#
# singularity-tour
#
################################################################################

SINGULARITY_TOUR_VERSION = 198adf1e00bee291d8258731ba32222c1308bf86
SINGULARITY_TOUR_SITE = $(call github,singularityos-lab,singularity-tour,$(SINGULARITY_TOUR_VERSION))
SINGULARITY_TOUR_LICENSE = GPL-3.0+
SINGULARITY_TOUR_LICENSE_FILES = LICENSE
SINGULARITY_TOUR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee pango json-glib

SINGULARITY_TOUR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
