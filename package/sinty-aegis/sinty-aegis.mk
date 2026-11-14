################################################################################
#
# sinty-aegis
#
################################################################################

SINTY_AEGIS_VERSION = 4b7d665c017a9cf5c307f07aa15a0a539ada8258
SINTY_AEGIS_SITE = $(call github,singularityos-lab,sinty-aegis,$(SINTY_AEGIS_VERSION))
SINTY_AEGIS_LICENSE = GPL-3.0-only
SINTY_AEGIS_LICENSE_FILES = LICENSE
SINTY_AEGIS_GOMOD = github.com/singularityos-lab/sinty-aegis
SINTY_AEGIS_BUILD_TARGETS = cmd/sinty-aegisd

define SINTY_AEGIS_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_AEGIS_PRE_BUILD_HOOKS += SINTY_AEGIS_GO_VENDOR

define SINTY_AEGIS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-aegisd $(TARGET_DIR)/usr/libexec/sinty-aegisd
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Aegis1.service $(TARGET_DIR)/usr/share/dbus-1/services/dev.sinty.Aegis1.service
endef

$(eval $(golang-package))
