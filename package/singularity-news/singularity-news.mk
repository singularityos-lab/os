################################################################################
#
# singularity-news
#
################################################################################

SINGULARITY_NEWS_VERSION = d5a658a29336969147889f16362e82abe8bad48a
SINGULARITY_NEWS_SITE = $(call github,singularityos-lab,singularity-news,$(SINGULARITY_NEWS_VERSION))
SINGULARITY_NEWS_LICENSE = GPL-3.0+
SINGULARITY_NEWS_LICENSE_FILES = LICENSE
SINGULARITY_NEWS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libsoup3 libxml2

SINGULARITY_NEWS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_NEWS_DEPENDENCIES += host-iride
SINGULARITY_NEWS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
