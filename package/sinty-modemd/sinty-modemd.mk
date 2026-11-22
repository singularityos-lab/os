################################################################################
#
# sinty-modemd
#
################################################################################

SINTY_MODEMD_VERSION = fbad355d4185d82007a60af31677d635c38a38aa
SINTY_MODEMD_SITE = $(call github,singularityos-lab,sinty-modem,$(SINTY_MODEMD_VERSION))
SINTY_MODEMD_LICENSE = GPL-3.0-or-later
SINTY_MODEMD_LICENSE_FILES = LICENSE NOTICE
SINTY_MODEMD_GOMOD = github.com/singularityos-lab/sinty-modem
SINTY_MODEMD_BUILD_TARGETS = cmd/sinty-modemd

define SINTY_MODEMD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_MODEMD_PRE_BUILD_HOOKS += SINTY_MODEMD_GO_VENDOR

define SINTY_MODEMD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-modemd $(TARGET_DIR)/usr/bin/sinty-modemd
endef

$(eval $(golang-package))
