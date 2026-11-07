################################################################################
#
# sinty-agent-prebuilt
#
################################################################################

SINTY_AGENT_PREBUILT_VERSION = 26A131
SINTY_AGENT_PREBUILT_SOURCE = sinty-agent-$(SINTY_AGENT_PREBUILT_VERSION)-x86_64.tar.zst
SINTY_AGENT_PREBUILT_SITE = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131
SINTY_AGENT_PREBUILT_LICENSE = GPL-3.0
SINTY_AGENT_PREBUILT_DEPENDENCIES = host-zstd 

define SINTY_AGENT_PREBUILT_EXTRACT_CMDS
endef

define SINTY_AGENT_PREBUILT_INSTALL_TARGET_CMDS
	$(HOST_DIR)/bin/zstd -dc $(SINTY_AGENT_PREBUILT_DL_DIR)/$(SINTY_AGENT_PREBUILT_SOURCE) | \
		$(TAR) -x -f - --strip-components=1 -C $(TARGET_DIR)
endef

$(eval $(generic-package))
