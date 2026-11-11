################################################################################
#
# sinty-agent
#
################################################################################

SINTY_AGENT_VERSION = 91aee19313a675ed9e36e2364cab1aa5068c1346
SINTY_AGENT_SITE = $(call github,singularityos-lab,sinty-agent,$(SINTY_AGENT_VERSION))
SINTY_AGENT_LICENSE = GPL-3.0
SINTY_AGENT_DEPENDENCIES = host-pkgconf host-wayland libglib2 libsoup3 libsecret wayland zlib

SINTY_AGENT_ZIG = zig
SINTY_AGENT_GLIBC_VERSION = $(firstword $(subst -, ,$(GLIBC_VERSION)))
SINTY_AGENT_ZIG_TARGET = $(call qstrip,$(BR2_ARCH))-linux-gnu.$(SINTY_AGENT_GLIBC_VERSION)

define SINTY_AGENT_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) \
		PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" \
		PKG_CONFIG_SYSROOT_DIR="$(STAGING_DIR)" \
		PKG_CONFIG_LIBDIR="$(STAGING_DIR)/usr/lib/pkgconfig:$(STAGING_DIR)/usr/share/pkgconfig" \
		$(SINTY_AGENT_ZIG) build -Doptimize=ReleaseSafe \
			-Dtarget=$(SINTY_AGENT_ZIG_TARGET) \
			-Dcpu=$(if $(BR2_x86_64),x86_64_v2,baseline) \
			--search-prefix $(STAGING_DIR)/usr \
			--prefix $(@D)/out
endef

define SINTY_AGENT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/out/bin/sinty $(TARGET_DIR)/usr/bin/sinty
	$(INSTALL) -D -m 0755 $(@D)/out/bin/sinty-agent $(TARGET_DIR)/usr/bin/sinty-agent
	$(INSTALL) -D -m 0755 $(@D)/out/bin/sinty-agentd $(TARGET_DIR)/usr/libexec/sinty-agentd
	$(INSTALL) -D -m 0755 $(@D)/out/bin/sinty-agent-bridge $(TARGET_DIR)/usr/libexec/sinty-agent-bridge
	$(INSTALL) -D -m 0644 $(@D)/out/share/dbus-1/services/dev.sinty.Agent.service \
		$(TARGET_DIR)/usr/share/dbus-1/services/dev.sinty.Agent.service
	$(INSTALL) -d $(TARGET_DIR)/usr/share/singularity/tour
	$(INSTALL) -m 0644 $(@D)/out/share/singularity/tour/*.slide \
		$(TARGET_DIR)/usr/share/singularity/tour/
endef

$(eval $(generic-package))
