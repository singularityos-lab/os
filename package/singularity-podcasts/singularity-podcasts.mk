################################################################################
#
# singularity-podcasts
#
################################################################################

SINGULARITY_PODCASTS_VERSION = c78e240681ed09687094cb4ca227cba3c28375da
SINGULARITY_PODCASTS_SITE = $(call github,singularityos-lab,singularity-podcasts,$(SINGULARITY_PODCASTS_VERSION))
SINGULARITY_PODCASTS_LICENSE = GPL-3.0+
SINGULARITY_PODCASTS_LICENSE_FILES = LICENSE
SINGULARITY_PODCASTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 gdk-pixbuf libgee gstreamer1 json-glib libsoup3 libxml2

SINGULARITY_PODCASTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_PODCASTS_DEPENDENCIES += host-iride
SINGULARITY_PODCASTS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
