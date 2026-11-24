################################################################################
#
# sinty-it
#
################################################################################

SINTY_IT_VERSION = e179f08d35e58bd24a7380f78dbfe4baf72bde66
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
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants
	ln -sf ../sinty-it-agent.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/sinty-it-agent.service
endef

$(eval $(golang-package))
