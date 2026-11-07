################################################################################
#
# polkit127-prebuilt
#
################################################################################

POLKIT127_PREBUILT_VERSION = 26A131
POLKIT127_PREBUILT_SOURCE = polkit127-$(POLKIT127_PREBUILT_VERSION)-x86_64.tar.zst
POLKIT127_PREBUILT_SITE = https://github.com/singularityos-lab/os/releases/download/prebuilt-26A131
POLKIT127_PREBUILT_LICENSE = LGPL-2.0+
POLKIT127_PREBUILT_DEPENDENCIES = host-zstd polkit

define POLKIT127_PREBUILT_EXTRACT_CMDS
endef

define POLKIT127_PREBUILT_INSTALL_TARGET_CMDS
	$(HOST_DIR)/bin/zstd -dc $(POLKIT127_PREBUILT_DL_DIR)/$(POLKIT127_PREBUILT_SOURCE) | \
		$(TAR) -x -f - --strip-components=1 -C $(TARGET_DIR)
endef

define POLKIT127_PREBUILT_PERMISSIONS
	/usr/lib/polkit-1/polkit-agent-helper-1 f 4755 0 0 - - - - -
endef

$(eval $(generic-package))
