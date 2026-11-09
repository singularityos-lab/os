################################################################################
#
# singularity-lettere
#
################################################################################

SINGULARITY_LETTERE_VERSION = 993211757e628e955fc8a3bdf6a4102c6b665f46
SINGULARITY_LETTERE_SITE = $(call github,singularityos-lab,singularity-lettere,$(SINGULARITY_LETTERE_VERSION))
SINGULARITY_LETTERE_LICENSE = GPL-3.0+
SINGULARITY_LETTERE_LICENSE_FILES = LICENSE
SINGULARITY_LETTERE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 json-glib libsecret libsoup3 poppler sqlite $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_LETTERE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
