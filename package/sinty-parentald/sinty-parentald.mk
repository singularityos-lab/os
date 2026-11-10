################################################################################
#
# sinty-parentald
#
################################################################################

SINTY_PARENTALD_VERSION = 8a157908a1597310933519ac68c575b82e9b969a
SINTY_PARENTALD_SITE = $(call github,singularityos-lab,sinty-parentald,$(SINTY_PARENTALD_VERSION))
SINTY_PARENTALD_LICENSE = GPL-3.0-only
SINTY_PARENTALD_LICENSE_FILES = LICENSE
SINTY_PARENTALD_GOMOD = github.com/singularityos-lab/sinty-parentald
SINTY_PARENTALD_BUILD_TARGETS = cmd/sinty-parentald

define SINTY_PARENTALD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_PARENTALD_PRE_BUILD_HOOKS += SINTY_PARENTALD_GO_VENDOR

define SINTY_PARENTALD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-parentald $(TARGET_DIR)/usr/libexec/sinty-parentald
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-parentald.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-parentald.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Parental1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.Parental1.service
endef

$(eval $(golang-package))
