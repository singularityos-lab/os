################################################################################
#
# singularity-podcasts
#
################################################################################

SINGULARITY_PODCASTS_VERSION = 03d3cc61db53677029490423b832302c7f216ad4
SINGULARITY_PODCASTS_SITE = $(call github,singularityos-lab,singularity-podcasts,$(SINGULARITY_PODCASTS_VERSION))
SINGULARITY_PODCASTS_LICENSE = GPL-3.0+
SINGULARITY_PODCASTS_LICENSE_FILES = LICENSE
SINGULARITY_PODCASTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 gdk-pixbuf libgee gstreamer1 json-glib libsoup3 libxml2

SINGULARITY_PODCASTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_PODCASTS_DEPENDENCIES += host-iride
SINGULARITY_PODCASTS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
