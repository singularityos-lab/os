################################################################################
#
# sinty-it
#
################################################################################

SINTY_IT_VERSION = d2de365e20099eb761240f353c339c1c784d1f57
SINTY_IT_SITE = $(call github,singularityos-lab,sinty-it,$(SINTY_IT_VERSION))
SINTY_IT_LICENSE = GPL-3.0-only
SINTY_IT_LICENSE_FILES = LICENSE
SINTY_IT_GOMOD = github.com/singularityos-lab/sinty-it
SINTY_IT_BUILD_TARGETS = cmd/sinty-it

define SINTY_IT_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_IT_PRE_BUILD_HOOKS += SINTY_IT_GO_VENDOR

define SINTY_IT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-it $(TARGET_DIR)/usr/bin/sinty-it
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-it-agent.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-it-agent.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.ITAgent1.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.ITAgent1.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-it-agent.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/sinty-it-agent.conf
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.it.policy $(TARGET_DIR)/usr/share/polkit-1/actions/dev.sinty.it.policy
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants
	ln -sf ../sinty-it-agent.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/sinty-it-agent.service
endef

$(eval $(golang-package))
