################################################################################
#
# singularity-podcasts
#
################################################################################

SINGULARITY_PODCASTS_VERSION = eacd9f3450d4901a7f790e7e7a01bfa4f0ed764c
SINGULARITY_PODCASTS_SITE = $(call github,singularityos-lab,singularity-podcasts,$(SINGULARITY_PODCASTS_VERSION))
SINGULARITY_PODCASTS_LICENSE = GPL-3.0+
SINGULARITY_PODCASTS_LICENSE_FILES = LICENSE
SINGULARITY_PODCASTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 gdk-pixbuf libgee gstreamer1 json-glib libsoup3 libxml2

SINGULARITY_PODCASTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
