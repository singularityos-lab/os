################################################################################
#
# sinty-scheduler
#
################################################################################

SINTY_SCHEDULER_VERSION = b7a4cee787ea792390f1ad840bde2c64b6c5e03e
SINTY_SCHEDULER_SITE = $(call github,singularityos-lab,sinty-scheduler,$(SINTY_SCHEDULER_VERSION))
SINTY_SCHEDULER_LICENSE = GPL-2.0
SINTY_SCHEDULER_LICENSE_FILES = LICENSE
SINTY_SCHEDULER_MODULE_SUBDIRS = kmod
SINTY_SCHEDULER_USERSPACE = sinty-scheduler-26A131-x86_64.tar.zst
SINTY_SCHEDULER_EXTRA_DOWNLOADS = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131/$(SINTY_SCHEDULER_USERSPACE)
SINTY_SCHEDULER_DEPENDENCIES = host-zstd

define SINTY_SCHEDULER_INSTALL_TARGET_CMDS
	$(HOST_DIR)/bin/zstd -dc $(SINTY_SCHEDULER_DL_DIR)/$(SINTY_SCHEDULER_USERSPACE) | \
		$(TAR) -x -f - --strip-components=1 -C $(TARGET_DIR)
endef

$(eval $(kernel-module))
$(eval $(generic-package))
