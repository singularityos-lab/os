################################################################################
#
# sinty-board-firmware
#
################################################################################

SINTY_BOARD_FIRMWARE_VERSION = v2026.01
SINTY_BOARD_FIRMWARE_SOURCE = u-boot-$(SINTY_BOARD_FIRMWARE_VERSION).tar.gz
SINTY_BOARD_FIRMWARE_SITE = https://github.com/u-boot/u-boot/archive/$(SINTY_BOARD_FIRMWARE_VERSION)
SINTY_BOARD_FIRMWARE_LICENSE = GPL-2.0+, BSD-2-Clause-Patent
SINTY_BOARD_FIRMWARE_LICENSE_FILES = Licenses/gpl-2.0.txt
SINTY_BOARD_FIRMWARE_INSTALL_TARGET = NO
SINTY_BOARD_FIRMWARE_INSTALL_IMAGES = YES
SINTY_BOARD_FIRMWARE_DEPENDENCIES = host-bison host-flex host-openssl host-gnutls host-util-linux host-python3 host-python-setuptools

SINTY_BOARD_FIRMWARE_RK3588 = v1.1
SINTY_BOARD_FIRMWARE_RPI4 = v1.53
SINTY_BOARD_FIRMWARE_RPI5 = v0.3
SINTY_BOARD_FIRMWARE_EXTRA_DOWNLOADS = \
	https://github.com/edk2-porting/edk2-rk3588/releases/download/$(SINTY_BOARD_FIRMWARE_RK3588)/rock-5b_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RK3588).img \
	https://github.com/edk2-porting/edk2-rk3588/releases/download/$(SINTY_BOARD_FIRMWARE_RK3588)/rock-5bplus_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RK3588).img \
	https://github.com/pftf/RPi4/releases/download/$(SINTY_BOARD_FIRMWARE_RPI4)/RPi4_UEFI_Firmware_$(SINTY_BOARD_FIRMWARE_RPI4).zip \
	https://github.com/worproject/rpi5-uefi/releases/download/$(SINTY_BOARD_FIRMWARE_RPI5)/RPi5_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RPI5).zip

SINTY_BOARD_FIRMWARE_UBOOT_BOARDS = \
	jetson-nano:p3450-0000 \
	jetson-tx1:p2371-2180 \
	jetson-tx2:p2771-0000-500

SINTY_BOARD_FIRMWARE_OUT = $(BINARIES_DIR)/board-firmware
SINTY_BOARD_FIRMWARE_MAKE_OPTS = \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	ARCH=arm \
	HOSTCC="$(HOSTCC) $(subst -I/,-isystem /,$(subst -I /,-isystem /,$(HOST_CFLAGS)))" \
	HOSTLDFLAGS="$(HOST_LDFLAGS)"

define SINTY_BOARD_FIRMWARE_BUILD_CMDS
	$(foreach b,$(SINTY_BOARD_FIRMWARE_UBOOT_BOARDS),
		$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) O=$(@D)/out-$(firstword $(subst :, ,$(b))) \
			$(SINTY_BOARD_FIRMWARE_MAKE_OPTS) \
			$(lastword $(subst :, ,$(b)))_defconfig
		$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) O=$(@D)/out-$(firstword $(subst :, ,$(b))) \
			$(SINTY_BOARD_FIRMWARE_MAKE_OPTS) all
	)
endef

define SINTY_BOARD_FIRMWARE_INSTALL_IMAGES_CMDS
	rm -rf $(SINTY_BOARD_FIRMWARE_OUT)
	$(foreach b,$(SINTY_BOARD_FIRMWARE_UBOOT_BOARDS),
		$(INSTALL) -D -m 0644 $(@D)/out-$(firstword $(subst :, ,$(b)))/u-boot.bin \
			$(SINTY_BOARD_FIRMWARE_OUT)/$(firstword $(subst :, ,$(b)))/u-boot.bin
	)
	$(INSTALL) -D -m 0644 $(SINTY_BOARD_FIRMWARE_DL_DIR)/rock-5b_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RK3588).img \
		$(SINTY_BOARD_FIRMWARE_OUT)/rock-5b/rock-5b_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RK3588).img
	$(INSTALL) -D -m 0644 $(SINTY_BOARD_FIRMWARE_DL_DIR)/rock-5bplus_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RK3588).img \
		$(SINTY_BOARD_FIRMWARE_OUT)/rock-5b-plus/rock-5bplus_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RK3588).img
	mkdir -p $(SINTY_BOARD_FIRMWARE_OUT)/rpi4 $(SINTY_BOARD_FIRMWARE_OUT)/rpi5
	cd $(SINTY_BOARD_FIRMWARE_OUT)/rpi4 && unzip -q -o $(SINTY_BOARD_FIRMWARE_DL_DIR)/RPi4_UEFI_Firmware_$(SINTY_BOARD_FIRMWARE_RPI4).zip
	cd $(SINTY_BOARD_FIRMWARE_OUT)/rpi5 && unzip -q -o $(SINTY_BOARD_FIRMWARE_DL_DIR)/RPi5_UEFI_Release_$(SINTY_BOARD_FIRMWARE_RPI5).zip
endef

$(eval $(generic-package))
