################################################################################
#
# singularity-lettere
#
################################################################################

SINGULARITY_LETTERE_VERSION = 4997fdc2304af4d049458dc85049ca70387e62ca
SINGULARITY_LETTERE_SITE = $(call github,singularityos-lab,singularity-lettere,$(SINGULARITY_LETTERE_VERSION))
SINGULARITY_LETTERE_LICENSE = GPL-3.0+
SINGULARITY_LETTERE_LICENSE_FILES = LICENSE
SINGULARITY_LETTERE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 json-glib libsecret libsoup3 poppler sqlite $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_LETTERE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_LETTERE_DEPENDENCIES += host-iride
SINGULARITY_LETTERE_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
