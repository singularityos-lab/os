################################################################################
#
# sinty-nmd
#
################################################################################

SINTY_NMD_VERSION = 2c2cd0b444658366052aef91a3e559a7cc33f154
SINTY_NMD_SITE = $(call github,singularityos-lab,sinty-nm,$(SINTY_NMD_VERSION))
SINTY_NMD_LICENSE = GPL-3.0-or-later
SINTY_NMD_LICENSE_FILES = LICENSE
SINTY_NMD_GOMOD = github.com/singularityos-lab/sinty-nm
SINTY_NMD_BUILD_TARGETS = cmd/sinty-nmd
SINTY_NMD_DEPENDENCIES = host-pkgconf libsingularity

define SINTY_NMD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_NMD_PRE_BUILD_HOOKS += SINTY_NMD_GO_VENDOR

define SINTY_NMD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-nmd $(TARGET_DIR)/usr/bin/sinty-nmd
endef

$(eval $(golang-package))
