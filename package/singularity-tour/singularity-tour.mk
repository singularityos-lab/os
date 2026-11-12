################################################################################
#
# singularity-tour
#
################################################################################

SINGULARITY_TOUR_VERSION = aa3d01148b6da858355de88b7f8b8e3d23d220e9
SINGULARITY_TOUR_SITE = $(call github,singularityos-lab,singularity-tour,$(SINGULARITY_TOUR_VERSION))
SINGULARITY_TOUR_LICENSE = GPL-3.0+
SINGULARITY_TOUR_LICENSE_FILES = LICENSE
SINGULARITY_TOUR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee pango json-glib

SINGULARITY_TOUR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
