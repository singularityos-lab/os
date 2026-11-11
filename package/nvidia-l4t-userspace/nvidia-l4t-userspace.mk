################################################################################
#
# nvidia-l4t-userspace
#
################################################################################

NVIDIA_L4T_USERSPACE_VERSION = 36.4.4-20250616085344
NVIDIA_L4T_USERSPACE_POOL = https://repo.download.nvidia.com/jetson/t234/pool/main/n
NVIDIA_L4T_USERSPACE_DEBS = core 3d-core gbm firmware wayland multimedia multimedia-utils cuda nvsci init
NVIDIA_L4T_USERSPACE_SOURCE = nvidia-l4t-core_$(NVIDIA_L4T_USERSPACE_VERSION)_arm64.deb
NVIDIA_L4T_USERSPACE_SITE = $(NVIDIA_L4T_USERSPACE_POOL)/nvidia-l4t-core
NVIDIA_L4T_USERSPACE_EXTRA_DOWNLOADS = $(foreach d,$(filter-out core,$(NVIDIA_L4T_USERSPACE_DEBS)),\
	$(NVIDIA_L4T_USERSPACE_POOL)/nvidia-l4t-$(d)/nvidia-l4t-$(d)_$(NVIDIA_L4T_USERSPACE_VERSION)_arm64.deb)
NVIDIA_L4T_USERSPACE_LICENSE = NVIDIA Jetson Software License
NVIDIA_L4T_USERSPACE_REDISTRIBUTE = NO
NVIDIA_L4T_USERSPACE_DEPENDENCIES = libglvnd mesa3d wayland libdrm xlib_libX11 xlib_libXext

NVIDIA_L4T_USERSPACE_LIB = usr/lib/aarch64-linux-gnu
NVIDIA_L4T_USERSPACE_FIRMWARE = nvidia tegra23x display-t234-dce.bin nvhost_nvdla010.fw nvhost_nvdla020.fw \
	nvhost_nvdla030.fw nvhost_ofa012.fw nvhost_vic042.fw nvpva_010.fw nvpva_020.fw

define NVIDIA_L4T_USERSPACE_EXTRACT_CMDS
	$(foreach d,$(NVIDIA_L4T_USERSPACE_DEBS),
		mkdir -p $(@D)/deb/$(d) $(@D)/root
		cd $(@D)/deb/$(d) && $(TARGET_AR) x $(NVIDIA_L4T_USERSPACE_DL_DIR)/nvidia-l4t-$(d)_$(NVIDIA_L4T_USERSPACE_VERSION)_arm64.deb
		$(TAR) -C $(@D)/root -xf $(@D)/deb/$(d)/data.tar.*
	)
	rm -rf $(@D)/deb
endef

define NVIDIA_L4T_USERSPACE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/$(NVIDIA_L4T_USERSPACE_LIB) $(TARGET_DIR)/usr/lib/gbm \
		$(TARGET_DIR)/usr/share/egl/egl_external_platform.d \
		$(TARGET_DIR)/usr/share/glvnd/egl_vendor.d \
		$(TARGET_DIR)/usr/share/vulkan/icd.d \
		$(TARGET_DIR)/lib/firmware \
		$(TARGET_DIR)/usr/lib/modprobe.d
	cp -a $(@D)/root/$(NVIDIA_L4T_USERSPACE_LIB)/nvidia $(@D)/root/$(NVIDIA_L4T_USERSPACE_LIB)/tegra-egl \
		$(@D)/root/$(NVIDIA_L4T_USERSPACE_LIB)/tegra $(@D)/root/$(NVIDIA_L4T_USERSPACE_LIB)/libv4l \
		$(TARGET_DIR)/$(NVIDIA_L4T_USERSPACE_LIB)/
	rm -f $(TARGET_DIR)/$(NVIDIA_L4T_USERSPACE_LIB)/nvidia/ld.so.conf \
		$(TARGET_DIR)/$(NVIDIA_L4T_USERSPACE_LIB)/tegra-egl/ld.so.conf \
		$(TARGET_DIR)/$(NVIDIA_L4T_USERSPACE_LIB)/tegra-egl/nvidia.json
	$(foreach b,nvidia-drm tegra tegra-udrm,
		ln -sf ../aarch64-linux-gnu/nvidia/libnvidia-allocator.so $(TARGET_DIR)/usr/lib/gbm/$(b)_gbm.so
	)
	$(INSTALL) -m 0644 $(@D)/root/usr/share/egl/egl_external_platform.d/*.json \
		$(TARGET_DIR)/usr/share/egl/egl_external_platform.d/
	$(INSTALL) -m 0644 $(@D)/root/usr/share/glvnd/egl_vendor.d/10_nvidia.json \
		$(TARGET_DIR)/usr/share/glvnd/egl_vendor.d/
	$(INSTALL) -m 0644 $(@D)/root/$(NVIDIA_L4T_USERSPACE_LIB)/nvidia/nvidia_icd.json $(TARGET_DIR)/usr/share/vulkan/icd.d/
	$(foreach f,$(NVIDIA_L4T_USERSPACE_FIRMWARE),
		cp -a $(@D)/root/lib/firmware/$(f) $(TARGET_DIR)/lib/firmware/
	)
	$(INSTALL) -D -m 0644 $(@D)/root/etc/nv_tegra_release $(TARGET_DIR)/etc/nv_tegra_release
	$(INSTALL) -D -m 0644 $(@D)/root/etc/nvsciipc.cfg $(TARGET_DIR)/etc/nvsciipc.cfg
	$(INSTALL) -D -m 0644 $(@D)/root/etc/sysctl.d/60-nvsciipc.conf $(TARGET_DIR)/usr/lib/sysctl.d/60-nvsciipc.conf
	$(INSTALL) -D -m 0644 $(@D)/root/etc/udev/rules.d/99-tegra-devices.rules \
		$(TARGET_DIR)/usr/lib/udev/rules.d/99-tegra-devices.rules
	printf 'options nvidia-drm modeset=1 fbdev=1\n' > $(TARGET_DIR)/usr/lib/modprobe.d/nvidia-l4t.conf
endef

$(eval $(generic-package))
