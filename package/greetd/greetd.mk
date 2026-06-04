################################################################################
#
# greetd
#
################################################################################

GREETD_VERSION = 0.10.3
GREETD_SITE = https://git.sr.ht/~kennylevinsen/greetd/archive
GREETD_SOURCE = $(GREETD_VERSION).tar.gz
GREETD_LICENSE = GPL-3.0
GREETD_LICENSE_FILES = LICENSE
GREETD_DOWNLOAD_POST_PROCESS = cargo

define GREETD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/greetd \
		$(TARGET_DIR)/usr/bin/greetd
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/agreety \
		$(TARGET_DIR)/usr/bin/agreety
endef

define GREETD_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/greetd.service \
		$(TARGET_DIR)/usr/lib/systemd/system/greetd.service
endef

GREETD_DEPENDENCIES = linux-pam

$(eval $(cargo-package))
