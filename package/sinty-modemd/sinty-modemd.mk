################################################################################
#
# sinty-modemd
#
################################################################################

SINTY_MODEMD_VERSION = 1383ff7ec792ee2d8bc7677f659d1ce1db74a280
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
