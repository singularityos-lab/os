ATOM_RECOVERY_VERSION = 8c9a02e593dbf1b01f9fc437d9195b38453be143
ATOM_RECOVERY_SITE = $(call github,singularityos-lab,sinty-recovery,$(ATOM_RECOVERY_VERSION))
ATOM_RECOVERY_LICENSE = GPL-3.0-only
ATOM_RECOVERY_LICENSE_FILES = LICENSE
ATOM_RECOVERY_GOMOD = github.com/singularityos-lab/sinty-recovery
ATOM_RECOVERY_BUILD_TARGETS = cmd/atom-recovery

define ATOM_RECOVERY_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
ATOM_RECOVERY_PRE_BUILD_HOOKS += ATOM_RECOVERY_GO_VENDOR

define ATOM_RECOVERY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/atom-recovery $(TARGET_DIR)/usr/bin/atom-recovery
	$(INSTALL) -D -m 0755 $(ATOM_RECOVERY_PKGDIR)/sinty-policy-setup $(TARGET_DIR)/usr/libexec/sinty-policy-setup
endef

$(eval $(golang-package))
