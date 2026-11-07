################################################################################
#
# sinty-sh
#
################################################################################

SINTY_SH_VERSION = 9c453baab06f50421b459fce94a13eb44da5de19
SINTY_SH_SITE = $(call github,singularityos-lab,sinty-sh,$(SINTY_SH_VERSION))
SINTY_SH_LICENSE = GPL-3.0-only, BSD-3-Clause (interpreter)
SINTY_SH_LICENSE_FILES = LICENSE internal/interp/LICENSE
SINTY_SH_GOMOD = github.com/singularityos-lab/sinty-sh
SINTY_SH_BUILD_TARGETS = cmd/sinty-sh

define SINTY_SH_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_SH_PRE_BUILD_HOOKS += SINTY_SH_GO_VENDOR

define SINTY_SH_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-sh $(TARGET_DIR)/usr/bin/sinty-sh
endef

$(eval $(golang-package))
