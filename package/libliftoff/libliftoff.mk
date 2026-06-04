################################################################################
#
# libliftoff
#
################################################################################

LIBLIFTOFF_VERSION = 0.5.0
LIBLIFTOFF_SITE = https://gitlab.freedesktop.org/emersion/libliftoff/-/archive/v$(LIBLIFTOFF_VERSION)
LIBLIFTOFF_SOURCE = libliftoff-v$(LIBLIFTOFF_VERSION).tar.gz
LIBLIFTOFF_LICENSE = MIT
LIBLIFTOFF_LICENSE_FILES = LICENSE
LIBLIFTOFF_INSTALL_STAGING = YES
LIBLIFTOFF_DEPENDENCIES = host-pkgconf libdrm

$(eval $(meson-package))
