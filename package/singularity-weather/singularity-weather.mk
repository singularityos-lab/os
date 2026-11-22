################################################################################
#
# singularity-weather
#
################################################################################

SINGULARITY_WEATHER_VERSION = 6b95d52d05309bf5f74cc7dee587dc3354fde181
SINGULARITY_WEATHER_SITE = $(call github,singularityos-lab,singularity-weather,$(SINGULARITY_WEATHER_VERSION))
SINGULARITY_WEATHER_LICENSE = GPL-3.0+
SINGULARITY_WEATHER_LICENSE_FILES = LICENSE
SINGULARITY_WEATHER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3

SINGULARITY_WEATHER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_WEATHER_DEPENDENCIES += host-iride
SINGULARITY_WEATHER_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
