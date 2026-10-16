################################################################################
#
# singularity-keyring
#
################################################################################

SINGULARITY_KEYRING_VERSION = 8001926d36b943780bebfba5f4686b0cdfafad15
SINGULARITY_KEYRING_SITE = $(call github,singularityos-lab,singularity-keyring,$(SINGULARITY_KEYRING_VERSION))
SINGULARITY_KEYRING_LICENSE = GPL-3.0+
SINGULARITY_KEYRING_LICENSE_FILES = LICENSE
SINGULARITY_KEYRING_DEPENDENCIES = host-pkgconf host-vala host-gettext libgtk4 json-glib libgcrypt libsodium

$(eval $(meson-package))
