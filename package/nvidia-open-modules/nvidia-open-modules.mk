################################################################################
#
# nvidia-open-modules
#
################################################################################

NVIDIA_OPEN_MODULES_VERSION = 595.112.07
NVIDIA_OPEN_MODULES_SITE = $(call github,NVIDIA,open-gpu-kernel-modules,$(NVIDIA_OPEN_MODULES_VERSION))
NVIDIA_OPEN_MODULES_LICENSE = MIT or GPL-2.0
NVIDIA_OPEN_MODULES_LICENSE_FILES = COPYING
NVIDIA_OPEN_MODULES_DEPENDENCIES = linux

NVIDIA_OPEN_MODULES_MAKE_OPTS = \
	$(LINUX_MAKE_FLAGS) \
	CC="$(TARGET_CC)" \
	CXX="$(TARGET_CXX)" \
	LD="$(TARGET_LD)" \
	AR="$(TARGET_AR)" \
	OBJCOPY="$(TARGET_OBJCOPY)" \
	TARGET_ARCH=x86_64 \
	SYSSRC=$(LINUX_DIR) \
	SYSOUT=$(LINUX_DIR)

define NVIDIA_OPEN_MODULES_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(LINUX_MAKE_ENV) $(MAKE) -C $(@D) $(NVIDIA_OPEN_MODULES_MAKE_OPTS) modules
endef

define NVIDIA_OPEN_MODULES_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(LINUX_MAKE_ENV) $(MAKE) -C $(LINUX_DIR) $(LINUX_MAKE_FLAGS) \
		M=$(@D)/kernel-open INSTALL_MOD_PATH=$(TARGET_DIR) \
		INSTALL_MOD_DIR=extra/nvidia INSTALL_MOD_STRIP=1 DEPMOD=true modules_install
	echo $(NVIDIA_OPEN_MODULES_VERSION) > $(TARGET_DIR)/usr/lib/nvidia-open-modules.version
endef

$(eval $(generic-package))
