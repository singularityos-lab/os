################################################################################
#
# sinty-xwayland-prebuilt
#
################################################################################

SINTY_XWAYLAND_PREBUILT_VERSION = 26A131
SINTY_XWAYLAND_PREBUILT_SOURCE = sinty-xwayland-$(SINTY_XWAYLAND_PREBUILT_VERSION)-x86_64.tar.zst
SINTY_XWAYLAND_PREBUILT_SITE = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131
SINTY_XWAYLAND_PREBUILT_LICENSE = MIT
SINTY_XWAYLAND_PREBUILT_DEPENDENCIES = host-zstd xwayland

define SINTY_XWAYLAND_PREBUILT_EXTRACT_CMDS
endef

define SINTY_XWAYLAND_PREBUILT_INSTALL_TARGET_CMDS
	$(HOST_DIR)/bin/zstd -dc $(SINTY_XWAYLAND_PREBUILT_DL_DIR)/$(SINTY_XWAYLAND_PREBUILT_SOURCE) | \
		$(TAR) -x -f - --strip-components=1 -C $(TARGET_DIR)
endef

$(eval $(generic-package))
