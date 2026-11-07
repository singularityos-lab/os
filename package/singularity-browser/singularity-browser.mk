################################################################################
#
# singularity-browser
#
################################################################################

SINGULARITY_BROWSER_VERSION = e0ce3c9463fce77c548b1597a0f22bf2f208f4b1
SINGULARITY_BROWSER_SITE = $(call github,singularityos-lab,singularity-browser,$(SINGULARITY_BROWSER_VERSION))
SINGULARITY_BROWSER_LICENSE = GPL-3.0+
SINGULARITY_BROWSER_LICENSE_FILES = LICENSE
SINGULARITY_BROWSER_INSTALL_STAGING = YES
SINGULARITY_BROWSER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnutls json-glib libfido2 libsecret libsoup3 libxml2 polkit poppler sqlite $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_BROWSER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
