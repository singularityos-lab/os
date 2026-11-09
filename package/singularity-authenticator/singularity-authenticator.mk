################################################################################
#
# singularity-authenticator
#
################################################################################

SINGULARITY_AUTHENTICATOR_VERSION = 20ff37ac5d3ac69d5c78af8f3f1250a15d722df2
SINGULARITY_AUTHENTICATOR_SITE = $(call github,singularityos-lab,singularity-authenticator,$(SINGULARITY_AUTHENTICATOR_VERSION))
SINGULARITY_AUTHENTICATOR_LICENSE = GPL-3.0+
SINGULARITY_AUTHENTICATOR_LICENSE_FILES = LICENSE
SINGULARITY_AUTHENTICATOR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo gdk-pixbuf libgee json-glib libgcrypt libsecret libsoup3 zbar

SINGULARITY_AUTHENTICATOR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
