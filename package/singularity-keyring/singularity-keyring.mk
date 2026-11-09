################################################################################
#
# singularity-keyring
#
################################################################################

SINGULARITY_KEYRING_VERSION = e26b3c90d7ddf326b2eaa87d7c8344e88320d423
SINGULARITY_KEYRING_SITE = $(call github,singularityos-lab,singularity-keyring,$(SINGULARITY_KEYRING_VERSION))
SINGULARITY_KEYRING_LICENSE = GPL-3.0+
SINGULARITY_KEYRING_LICENSE_FILES = LICENSE
SINGULARITY_KEYRING_DEPENDENCIES = host-pkgconf host-vala host-gettext libsingularity libgtk4 json-glib libgcrypt libsodium

$(eval $(meson-package))
