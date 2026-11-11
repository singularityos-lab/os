################################################################################
# sinty-crypto (Zig 0.16)
################################################################################
SINTY_CRYPTO_VERSION = 1d35fcbfbfb0fb9741baab6292eb15a5a763ee02
SINTY_CRYPTO_SITE = $(call github,singularityos-lab,sinty-crypto,$(SINTY_CRYPTO_VERSION))
SINTY_CRYPTO_LICENSE = GPL-3.0-only
SINTY_CRYPTO_LICENSE_FILES = LICENSE
SINTY_CRYPTO_INSTALL_STAGING = YES
SINTY_CRYPTO_DEPENDENCIES = linux-pam linux-headers tpm2-tools

SINTY_CRYPTO_ZIG = zig
SINTY_CRYPTO_ZIG_TARGET = $(BR2_ARCH)-linux-gnu

define SINTY_CRYPTO_BUILD_CMDS
	cd $(@D) && $(SINTY_CRYPTO_ZIG) build -Doptimize=ReleaseSafe \
		-Dtarget=$(SINTY_CRYPTO_ZIG_TARGET) \
		-Dcpu=$(if $(BR2_x86_64),x86_64_v2,baseline) \
		-Denforce-tpm=false \
		-Denforce-fscrypt=true \
		--search-prefix $(STAGING_DIR)/usr
endef

define SINTY_CRYPTO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/zig-out/bin/sintykey $(TARGET_DIR)/usr/bin/sintykey
	$(INSTALL) -D -m 0755 $(@D)/zig-out/lib/libpam_sinty.so $(TARGET_DIR)/usr/lib/security/pam_sinty.so
	$(INSTALL) -D -m 0644 $(@D)/zig-out/lib/libsintykey.so $(TARGET_DIR)/usr/lib/libsintykey.so
	$(INSTALL) -D -m 0755 $(@D)/zig-out/bin/sintykey-tpm $(TARGET_DIR)/usr/libexec/sintykey-tpm
endef

define SINTY_CRYPTO_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/zig-out/lib/libsintykey.a $(STAGING_DIR)/usr/lib/libsintykey.a
	$(INSTALL) -D -m 0644 $(@D)/libsintykey/libsintykey.h $(STAGING_DIR)/usr/include/libsintykey.h
	$(INSTALL) -D -m 0644 $(@D)/libsintykey/sintykey.vapi $(STAGING_DIR)/usr/share/vala/vapi/sintykey.vapi
endef

$(eval $(generic-package))
