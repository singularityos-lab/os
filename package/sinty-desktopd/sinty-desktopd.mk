################################################################################
#
# sinty-desktopd
#
################################################################################

SINTY_DESKTOPD_VERSION = 8cd5687334b17f8ddf199aa673dddebde316d2d9
SINTY_DESKTOPD_SITE = $(call github,singularityos-lab,sinty-desktopd,$(SINTY_DESKTOPD_VERSION))
SINTY_DESKTOPD_LICENSE = GPL-3.0-only
SINTY_DESKTOPD_LICENSE_FILES = LICENSE
SINTY_DESKTOPD_GOMOD = github.com/singularityos-lab/sinty-desktopd
SINTY_DESKTOPD_BUILD_TARGETS = cmd/sinty-desktopd

define SINTY_DESKTOPD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_DESKTOPD_PRE_BUILD_HOOKS += SINTY_DESKTOPD_GO_VENDOR

define SINTY_DESKTOPD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-desktopd $(TARGET_DIR)/usr/libexec/sinty-desktopd
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-desktopd.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-desktopd.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.LoginScreen1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.LoginScreen1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.FingerprintDriver1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.FingerprintDriver1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Logs1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.Logs1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.desktopd.policy $(TARGET_DIR)/usr/share/polkit-1/actions/dev.sinty.desktopd.policy
endef

$(eval $(golang-package))
