################################################################################
#
# libfprint
#
################################################################################

LIBFPRINT_VERSION = d25fa50748d6edf5be0f472f157a3b3020cb4113
LIBFPRINT_SITE = https://gitlab.freedesktop.org/3v1n0/libfprint.git
LIBFPRINT_SITE_METHOD = git
LIBFPRINT_LICENSE = LGPL-2.1+
LIBFPRINT_LICENSE_FILES = COPYING
LIBFPRINT_INSTALL_STAGING = YES
LIBFPRINT_DEPENDENCIES = host-pkgconf libglib2 libgusb libgudev pixman openssl udev
LIBFPRINT_CONF_OPTS = \
	-Dintrospection=false \
	-Ddoc=false \
	-Dgtk-examples=false \
	-Dinstalled-tests=false \
	-Dudev_rules=enabled \
	-Dudev_rules_dir=/lib/udev/rules.d \
	-Dudev_hwdb=enabled \
	-Dudev_hwdb_dir=/lib/udev/hwdb.d

$(eval $(meson-package))
