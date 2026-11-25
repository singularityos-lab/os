################################################################################
#
# sinty-identity
#
################################################################################

SINTY_IDENTITY_VERSION = 03b36ea9c8de2cac131f4042d573c0e618dada96
SINTY_IDENTITY_SITE = $(call github,singularityos-lab,sinty-identity,$(SINTY_IDENTITY_VERSION))
SINTY_IDENTITY_LICENSE = GPL-3.0-only
SINTY_IDENTITY_LICENSE_FILES = LICENSE
SINTY_IDENTITY_GOMOD = github.com/singularityos-lab/sinty-identity
SINTY_IDENTITY_BUILD_TARGETS = cmd/sinty-identity

define SINTY_IDENTITY_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_IDENTITY_PRE_BUILD_HOOKS += SINTY_IDENTITY_GO_VENDOR

define SINTY_IDENTITY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-identity $(TARGET_DIR)/usr/bin/sinty-identity
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-identity-agent.desktop $(TARGET_DIR)/etc/xdg/autostart/sinty-identity-agent.desktop
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.IdentityAgent1.service $(TARGET_DIR)/usr/share/dbus-1/services/dev.sinty.IdentityAgent1.service
endef

$(eval $(golang-package))
