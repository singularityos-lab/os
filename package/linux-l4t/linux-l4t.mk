################################################################################
#
# linux-l4t
#
################################################################################

LINUX_L4T_VERSION = 36.4.4
LINUX_L4T_SOURCE = public_sources.tbz2
LINUX_L4T_SITE = https://developer.download.nvidia.com/embedded/L4T/r36_Release_v4.4/sources
LINUX_L4T_LICENSE = GPL-2.0, MIT, BSD-3-Clause
LINUX_L4T_DEPENDENCIES = linux host-kmod host-openssl host-bison host-flex
LINUX_L4T_FAMILY = l4t

LINUX_L4T_SRC = $(@D)/Linux_for_Tegra/source
LINUX_L4T_KERNEL = $(LINUX_L4T_SRC)/kernel/kernel-jammy-src
LINUX_L4T_OUT = $(@D)/out

LINUX_L4T_MAKE_FLAGS = \
	-C $(LINUX_L4T_KERNEL) O=$(LINUX_L4T_OUT) \
	ARCH=arm64 \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	HOSTCC="$(HOSTCC)" \
	LOCALVERSION=-tegra \
	WERROR=0 \
	INSTALL_MOD_PATH=$(TARGET_DIR) \
	INSTALL_MOD_STRIP=1 \
	DEPMOD=$(HOST_DIR)/sbin/depmod

LINUX_L4T_OOT_FLAGS = \
	-C $(LINUX_L4T_SRC) \
	ARCH=arm64 \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	KERNEL_HEADERS=$(LINUX_L4T_KERNEL) \
	KERNEL_OUTPUT=$(LINUX_L4T_OUT) \
	NPROC=$(PARALLEL_JOBS) \
	INSTALL_MOD_PATH=$(TARGET_DIR) \
	INSTALL_MOD_STRIP=1

define LINUX_L4T_EXTRACT_CMDS
	$(call suitable-extractor,$(LINUX_L4T_SOURCE)) $(LINUX_L4T_DL_DIR)/$(LINUX_L4T_SOURCE) | \
		$(TAR) -C $(@D) $(TAR_OPTIONS) - \
		Linux_for_Tegra/source/kernel_src.tbz2 \
		Linux_for_Tegra/source/kernel_oot_modules_src.tbz2 \
		Linux_for_Tegra/source/nvidia_kernel_display_driver_source.tbz2
	$(TAR) -C $(LINUX_L4T_SRC) -xjf $(LINUX_L4T_SRC)/kernel_src.tbz2
	$(TAR) -C $(LINUX_L4T_SRC) -xjf $(LINUX_L4T_SRC)/kernel_oot_modules_src.tbz2
	$(TAR) -C $(LINUX_L4T_SRC) -xjf $(LINUX_L4T_SRC)/nvidia_kernel_display_driver_source.tbz2
	rm -f $(LINUX_L4T_SRC)/*.tbz2
endef

define LINUX_L4T_RELAX_WERROR
	find $(addprefix $(LINUX_L4T_SRC)/,nvidia-oot nvgpu hwpm nvdisplay nvethernetrm) \
		\( -name 'Makefile*' -o -name '*.mk' -o -name Kbuild \) \
		-exec sed -i -E 's/-Werror([=-][A-Za-z0-9_=-]+)?//g' {} +
	sed -i 's/-Wno-strict-prototypes"/-Wno-strict-prototypes -fshort-wchar -fpermissive"/' \
		$(LINUX_L4T_SRC)/nvdisplay/kernel-open/conftest.sh
endef
LINUX_L4T_POST_EXTRACT_HOOKS += LINUX_L4T_RELAX_WERROR

define LINUX_L4T_CONFIGURE_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(LINUX_L4T_MAKE_FLAGS) defconfig
	KCONFIG_CONFIG=$(LINUX_L4T_OUT)/.config $(LINUX_L4T_KERNEL)/scripts/kconfig/merge_config.sh -m -O $(LINUX_L4T_OUT) \
		$(LINUX_L4T_OUT)/.config $(BR2_EXTERNAL_SINGULARITY_PATH)/buildroot-config/kernel-aarch64.fragment
	$(TARGET_MAKE_ENV) $(MAKE) $(LINUX_L4T_MAKE_FLAGS) olddefconfig
endef

define LINUX_L4T_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(LINUX_L4T_MAKE_FLAGS) Image modules
	$(TARGET_MAKE_ENV) $(MAKE) $(LINUX_L4T_OOT_FLAGS) modules
endef

define LINUX_L4T_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(LINUX_L4T_MAKE_FLAGS) modules_install
	$(TARGET_MAKE_ENV) $(MAKE) $(LINUX_L4T_OOT_FLAGS) modules_install
	find $(TARGET_DIR)/lib/modules/$$(cat $(LINUX_L4T_OUT)/include/config/kernel.release)/updates -name '*.ko' \
		-exec $(LINUX_L4T_OUT)/scripts/sign-file sha512 $(LINUX_L4T_OUT)/certs/signing_key.pem \
		$(LINUX_L4T_OUT)/certs/signing_key.x509 {} \;
	$(HOST_DIR)/sbin/depmod -a -b $(TARGET_DIR) $$(cat $(LINUX_L4T_OUT)/include/config/kernel.release)
	$(INSTALL) -D -m 0644 $(LINUX_L4T_OUT)/arch/arm64/boot/Image \
		$(BINARIES_DIR)/families/$(LINUX_L4T_FAMILY)/Image
	cp $(LINUX_L4T_OUT)/include/config/kernel.release $(BINARIES_DIR)/families/$(LINUX_L4T_FAMILY)/kernel.release
endef

$(eval $(generic-package))
