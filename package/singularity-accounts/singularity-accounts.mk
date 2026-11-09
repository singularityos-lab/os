################################################################################
#
# singularity-accounts
#
################################################################################

SINGULARITY_ACCOUNTS_VERSION = e7f5d38f4da6e1e037241eccd1b87380adfff6c7
SINGULARITY_ACCOUNTS_SITE = $(call github,singularityos-lab,singularity-accounts,$(SINGULARITY_ACCOUNTS_VERSION))
SINGULARITY_ACCOUNTS_LICENSE = GPL-3.0+
SINGULARITY_ACCOUNTS_LICENSE_FILES = LICENSE
SINGULARITY_ACCOUNTS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libfuse3 libgee json-glib libsecret libsoup3 $(if $(BR2_PACKAGE_WEBKITGTK_PREBUILT),webkitgtk-prebuilt,webkitgtk)

ifneq ($(SINGULARITY_OAUTH_CLIENTS_FILE),)
SINGULARITY_ACCOUNTS_CONF_OPTS += -Doauth_clients_file=$(SINGULARITY_OAUTH_CLIENTS_FILE)
endif

SINGULARITY_ACCOUNTS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
