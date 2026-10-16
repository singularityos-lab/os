################################################################################
#
# singularity-tour
#
################################################################################

SINGULARITY_TOUR_VERSION = 5dfe27ae76907590fce25eab3c8a381e3c7b9797
SINGULARITY_TOUR_SITE = $(call github,singularityos-lab,singularity-tour,$(SINGULARITY_TOUR_VERSION))
SINGULARITY_TOUR_LICENSE = GPL-3.0+
SINGULARITY_TOUR_LICENSE_FILES = LICENSE
SINGULARITY_TOUR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee pango

SINGULARITY_TOUR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
