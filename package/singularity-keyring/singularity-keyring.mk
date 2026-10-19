################################################################################
#
# singularity-keyring
#
################################################################################

SINGULARITY_KEYRING_VERSION = 8f077fa3fff9e723d1a3ed625fcc104a033d9e85
SINGULARITY_KEYRING_SITE = $(call github,singularityos-lab,singularity-keyring,$(SINGULARITY_KEYRING_VERSION))
SINGULARITY_KEYRING_LICENSE = GPL-3.0+
SINGULARITY_KEYRING_LICENSE_FILES = LICENSE
SINGULARITY_KEYRING_DEPENDENCIES = host-pkgconf host-vala host-gettext libsingularity libgtk4 json-glib libgcrypt libsodium

$(eval $(meson-package))
