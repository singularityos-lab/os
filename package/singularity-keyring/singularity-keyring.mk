################################################################################
#
# singularity-keyring
#
################################################################################

SINGULARITY_KEYRING_VERSION = 3c7d7a3d13148ec394fdcd59295941a2f6fe0824
SINGULARITY_KEYRING_SITE = $(call github,singularityos-lab,singularity-keyring,$(SINGULARITY_KEYRING_VERSION))
SINGULARITY_KEYRING_LICENSE = GPL-3.0+
SINGULARITY_KEYRING_LICENSE_FILES = LICENSE
SINGULARITY_KEYRING_DEPENDENCIES = host-pkgconf host-vala host-gettext libgtk4 json-glib libgcrypt libsodium

$(eval $(meson-package))
