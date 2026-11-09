################################################################################
#
# sinty-powerd
#
################################################################################

SINTY_POWERD_VERSION = 7cdfcdfef8e78a980edb1ea1b47ecef50ed83e08
SINTY_POWERD_SITE = $(call github,singularityos-lab,sinty-powerd,$(SINTY_POWERD_VERSION))
SINTY_POWERD_LICENSE = GPL-3.0-only
SINTY_POWERD_LICENSE_FILES = LICENSE
SINTY_POWERD_GOMOD = github.com/singularityos-lab/sinty-powerd
SINTY_POWERD_BUILD_TARGETS = cmd/sinty-powerd

define SINTY_POWERD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_POWERD_PRE_BUILD_HOOKS += SINTY_POWERD_GO_VENDOR

define SINTY_POWERD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-powerd $(TARGET_DIR)/usr/libexec/sinty-powerd
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-powerd.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-powerd.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-powerd.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-powerd.conf
	for n in org.freedesktop.UPower org.freedesktop.UPower.PowerProfiles net.hadess.PowerProfiles; do \
		$(INSTALL) -D -m 0644 $(@D)/packaging/$$n.service $(TARGET_DIR)/usr/share/dbus-1/system-services/$$n.service || exit 1; \
	done
endef

$(eval $(golang-package))
