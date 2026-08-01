ATOM_RECOVERY_VERSION = v0.2.1
ATOM_RECOVERY_SITE = $(call github,singularityos-lab,sinty-recovery,$(ATOM_RECOVERY_VERSION))
ATOM_RECOVERY_LICENSE = GPL-3.0-only
ATOM_RECOVERY_LICENSE_FILES = LICENSE
ATOM_RECOVERY_GOMOD = github.com/singularityos-lab/sinty-recovery
ATOM_RECOVERY_BUILD_TARGETS = cmd/atom-recovery

define ATOM_RECOVERY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/atom-recovery $(TARGET_DIR)/usr/bin/atom-recovery
	$(INSTALL) -D -m 0755 $(ATOM_RECOVERY_PKGDIR)/sinty-policy-setup $(TARGET_DIR)/usr/libexec/sinty-policy-setup
endef

$(eval $(golang-package))
