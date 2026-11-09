################################################################################
#
# singularity-lettere
#
################################################################################

SINGULARITY_LETTERE_VERSION = 8727f0f8d4b938a6c9875352c38b992d33cad9b8
SINGULARITY_LETTERE_SITE = $(call github,singularityos-lab,singularity-lettere,$(SINGULARITY_LETTERE_VERSION))
SINGULARITY_LETTERE_LICENSE = GPL-3.0+
SINGULARITY_LETTERE_LICENSE_FILES = LICENSE
SINGULARITY_LETTERE_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gstreamer1 json-glib libsecret libsoup3 poppler sqlite $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_LETTERE_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
