################################################################################
#
# accountsservice
#
################################################################################

ACCOUNTSSERVICE_VERSION = 23.13.9
ACCOUNTSSERVICE_SITE = https://www.freedesktop.org/software/accountsservice
ACCOUNTSSERVICE_SOURCE = accountsservice-$(ACCOUNTSSERVICE_VERSION).tar.xz
ACCOUNTSSERVICE_LICENSE = GPL-3.0+
ACCOUNTSSERVICE_LICENSE_FILES = COPYING
ACCOUNTSSERVICE_INSTALL_STAGING = YES
ACCOUNTSSERVICE_DEPENDENCIES = \
	host-pkgconf \
	host-gettext \
	libglib2 \
	polkit \
	dbus \
	systemd

ACCOUNTSSERVICE_CONF_OPTS = \
	-Dintrospection=false \
	-Dvapi=false \
	-Dgtk_doc=false \
	-Dsystemdsystemunitdir=/usr/lib/systemd/system

define ACCOUNTSSERVICE_FIX_CROSS_RUN
	$(SED) "s|result = cc.run(code, name : 'value of WTMPX_FILENAME')|path_wtmp = 'WTMPX_FILENAME'|" $(@D)/meson.build
	$(SED) "s|result = cc.run(code, name : 'value of _PATH_WTMPX')|path_wtmp = '_PATH_WTMPX'|" $(@D)/meson.build
	$(SED) "/path_wtmp = result.stdout().strip()/d" $(@D)/meson.build
	$(SED) "/subdir('tests')/d" $(@D)/meson.build
endef
ACCOUNTSSERVICE_POST_PATCH_HOOKS += ACCOUNTSSERVICE_FIX_CROSS_RUN

$(eval $(meson-package))
