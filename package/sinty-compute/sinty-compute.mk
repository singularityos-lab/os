################################################################################
#
# sinty-compute
#
################################################################################

SINTY_COMPUTE_VERSION = 97894b2d8bea242490ab9a43c628fe6c8cf8c3bd
SINTY_COMPUTE_SITE = $(call github,singularityos-lab,sinty-compute,$(SINTY_COMPUTE_VERSION))
SINTY_COMPUTE_LICENSE = GPL-2.0
SINTY_COMPUTE_LICENSE_FILES = LICENSE
SINTY_COMPUTE_MODULE_SUBDIRS = kmod
SINTY_COMPUTE_USERSPACE = sinty-compute-26A131-x86_64.tar.zst
SINTY_COMPUTE_EXTRA_DOWNLOADS = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131/$(SINTY_COMPUTE_USERSPACE)
SINTY_COMPUTE_DEPENDENCIES = host-zstd

define SINTY_COMPUTE_INSTALL_TARGET_CMDS
	$(HOST_DIR)/bin/zstd -dc $(SINTY_COMPUTE_DL_DIR)/$(SINTY_COMPUTE_USERSPACE) | \
		$(TAR) -x -f - --strip-components=1 -C $(TARGET_DIR)
endef

$(eval $(kernel-module))
$(eval $(generic-package))
