ATOM_RECOVERY_VERSION = v0.1.0
ATOM_RECOVERY_SITE = https://github.com/singularityos-lab/sinty-recovery/releases/download/$(ATOM_RECOVERY_VERSION)
ATOM_RECOVERY_SOURCE = atom-recovery-$(ATOM_RECOVERY_VERSION)-x86_64.tar.gz
ATOM_RECOVERY_LICENSE = GPL-3.0-only
# Flat release tarball (payload at the top level, no wrapping directory): the default
# --strip-components=1 would strip the payload itself and leave the build dir empty.
ATOM_RECOVERY_STRIP_COMPONENTS = 0

define ATOM_RECOVERY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/atom-recovery $(TARGET_DIR)/usr/bin/atom-recovery
endef

$(eval $(generic-package))
