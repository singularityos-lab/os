################################################################################
#
# sinty-sdb
#
################################################################################

# SITE=local: build the debug bridge from the local sinty-sdb repo, which is
# private. buildroot-build/local.mk _OVERRIDE_SRCDIR supersedes this for dev
# builds.
SINTY_SDB_VERSION = local
SINTY_SDB_SITE = /home/mirko/Projects/personal/sinty-sdb
SINTY_SDB_SITE_METHOD = local
SINTY_SDB_LICENSE = GPL-3.0-only
SINTY_SDB_LICENSE_FILES = LICENSE

SINTY_SDB_GOMOD = github.com/singularityos-lab/sinty-sdb
SINTY_SDB_BUILD_TARGETS = cmd/sdbd cmd/sdb

# The unit carries the two ConditionPathExists gates; installing it does not by
# itself arm the bridge, and no target.wants symlink is created here. Enabling
# is a deliberate act on a development image, not a packaging side effect.
define SINTY_SDB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sdbd $(TARGET_DIR)/usr/bin/sdbd
	$(INSTALL) -D -m 0755 $(@D)/bin/sdb $(TARGET_DIR)/usr/bin/sdb
	$(INSTALL) -D -m 0644 $(@D)/packaging/sdbd.service \
		$(TARGET_DIR)/usr/lib/systemd/system/sdbd.service
endef

$(eval $(golang-package))
