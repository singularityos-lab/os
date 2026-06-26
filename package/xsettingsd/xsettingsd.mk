################################################################################
#
# xsettingsd
#
################################################################################

XSETTINGSD_VERSION = 1.0.2
XSETTINGSD_SITE = $(call github,derat,xsettingsd,v$(XSETTINGSD_VERSION))
XSETTINGSD_LICENSE = BSD-3-Clause
XSETTINGSD_LICENSE_FILES = COPYING
XSETTINGSD_DEPENDENCIES = host-pkgconf xlib_libX11
XSETTINGSD_CONF_OPTS = -DBUILD_TESTING=OFF

$(eval $(cmake-package))
