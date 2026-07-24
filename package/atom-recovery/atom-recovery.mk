################################################################################
#
# atom-recovery
#
################################################################################

# SITE=local: build the recovery agent from the local sinty-recovery repo.
# buildroot-build/local.mk _OVERRIDE_SRCDIR supersedes this for dev builds.
ATOM_RECOVERY_VERSION = local
ATOM_RECOVERY_SITE = /home/mirko/Projects/personal/sinty-recovery
ATOM_RECOVERY_SITE_METHOD = local
ATOM_RECOVERY_LICENSE = GPL-3.0-only
ATOM_RECOVERY_LICENSE_FILES = LICENSE

ATOM_RECOVERY_GOMOD = github.com/singularityos-lab/sinty-recovery
ATOM_RECOVERY_BUILD_TARGETS = cmd/atom-recovery

define ATOM_RECOVERY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/atom-recovery $(TARGET_DIR)/usr/bin/atom-recovery
endef

$(eval $(golang-package))
