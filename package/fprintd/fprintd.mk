################################################################################
#
# fprintd
#
################################################################################

FPRINTD_VERSION = 1.94.4
FPRINTD_SOURCE = fprintd-v$(FPRINTD_VERSION).tar.gz
FPRINTD_SITE = https://gitlab.freedesktop.org/libfprint/fprintd/-/archive/v$(FPRINTD_VERSION)
FPRINTD_LICENSE = GPL-2.0+
FPRINTD_LICENSE_FILES = COPYING
FPRINTD_DEPENDENCIES = host-pkgconf libglib2 libfprint polkit dbus
FPRINTD_CONF_OPTS = \
	-Dpam=false \
	-Dman=false \
	-Dsystemd=false \
	-Dgtk_doc=false \
	-Ddbus_service_dir=/usr/share/dbus-1/system-services

$(eval $(meson-package))
