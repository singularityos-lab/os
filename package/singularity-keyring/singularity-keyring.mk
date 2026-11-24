################################################################################
#
# singularity-keyring
#
################################################################################

SINGULARITY_KEYRING_VERSION = 4b9b1f35957ab1ea6151e1a897c2ac67559a439e
SINGULARITY_KEYRING_SITE = $(call github,singularityos-lab,singularity-keyring,$(SINGULARITY_KEYRING_VERSION))
SINGULARITY_KEYRING_LICENSE = GPL-3.0+
SINGULARITY_KEYRING_LICENSE_FILES = LICENSE
SINGULARITY_KEYRING_DEPENDENCIES = host-pkgconf host-vala host-gettext libsingularity libgtk4 json-glib libgcrypt libsodium

$(eval $(meson-package))
