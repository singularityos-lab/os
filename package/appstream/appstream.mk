################################################################################
#
# appstream
#
################################################################################

APPSTREAM_VERSION = 1.0.4
APPSTREAM_SOURCE = AppStream-$(APPSTREAM_VERSION).tar.xz
APPSTREAM_SITE = https://www.freedesktop.org/software/appstream/releases
APPSTREAM_LICENSE = LGPL-2.1+
APPSTREAM_LICENSE_FILES = COPYING
APPSTREAM_CPE_ID_VENDOR = freedesktop
APPSTREAM_STRIP_COMPONENTS = 2
APPSTREAM_INSTALL_STAGING = YES
APPSTREAM_DEPENDENCIES = \
	host-pkgconf \
	host-gperf \
	host-gettext \
	libglib2 \
	libxml2 \
	libyaml \
	libxmlb \
	libcurl

APPSTREAM_CONF_OPTS = \
	-Dstemming=false \
	-Dsystemd=false \
	-Dqt=false \
	-Dcompose=false \
	-Dapt-support=false \
	-Dgir=false \
	-Dvapi=false \
	-Ddocs=false \
	-Dapidocs=false \
	-Dinstall-docs=false \
	-Dzstd-support=false

$(eval $(meson-package))
