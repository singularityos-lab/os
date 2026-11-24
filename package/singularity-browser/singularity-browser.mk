################################################################################
#
# singularity-browser
#
################################################################################

SINGULARITY_BROWSER_VERSION = 5948d1a62ef8ec04686bfd62c82f94f8aeeafaef
SINGULARITY_BROWSER_SITE = $(call github,singularityos-lab,singularity-browser,$(SINGULARITY_BROWSER_VERSION))
SINGULARITY_BROWSER_LICENSE = GPL-3.0+
SINGULARITY_BROWSER_LICENSE_FILES = LICENSE
SINGULARITY_BROWSER_INSTALL_STAGING = YES
SINGULARITY_BROWSER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnutls json-glib libfido2 libsecret libsoup3 libxml2 polkit poppler sqlite $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_BROWSER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_BROWSER_DEPENDENCIES += host-iride
SINGULARITY_BROWSER_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
