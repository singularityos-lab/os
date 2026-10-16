################################################################################
#
# singularity-weather
#
################################################################################

SINGULARITY_WEATHER_VERSION = 350e5264433038de67c3c4c640df4a3199491145
SINGULARITY_WEATHER_SITE = $(call github,singularityos-lab,singularity-weather,$(SINGULARITY_WEATHER_VERSION))
SINGULARITY_WEATHER_LICENSE = GPL-3.0+
SINGULARITY_WEATHER_LICENSE_FILES = LICENSE
SINGULARITY_WEATHER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3

SINGULARITY_WEATHER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
