################################################################################
#
# singularity-accounts
#
################################################################################

SINGULARITY_ACCOUNTS_VERSION = dba72ec721a9caee8ad5b91d26ad92a5af133aae
SINGULARITY_ACCOUNTS_SITE = $(call github,singularityos-lab,singularity-accounts,$(SINGULARITY_ACCOUNTS_VERSION))
SINGULARITY_ACCOUNTS_LICENSE = GPL-3.0+
SINGULARITY_ACCOUNTS_LICENSE_FILES = LICENSE
SINGULARITY_ACCOUNTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libfuse3 libgee json-glib libsecret libsoup3 $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

SINGULARITY_ACCOUNTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
