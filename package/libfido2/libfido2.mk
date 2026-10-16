################################################################################
#
# libfido2
#
################################################################################

LIBFIDO2_VERSION = 1.16.0
LIBFIDO2_SITE = https://developers.yubico.com/libfido2/Releases
LIBFIDO2_LICENSE = BSD-2-Clause
LIBFIDO2_LICENSE_FILES = LICENSE
LIBFIDO2_INSTALL_STAGING = YES
LIBFIDO2_DEPENDENCIES = host-pkgconf libcbor openssl zlib udev
LIBFIDO2_CONF_OPTS = \
	-DBUILD_TESTS=OFF \
	-DBUILD_EXAMPLES=OFF \
	-DBUILD_MANPAGES=OFF \
	-DBUILD_TOOLS=OFF \
	-DBUILD_STATIC_LIBS=OFF \
	-DNFC_LINUX=OFF

$(eval $(cmake-package))
