################################################################################
#
# sinty-scheduler
#
################################################################################

SINTY_SCHEDULER_VERSION = 02f8078024ee2d248d06f1643b3c5f873b6b72e7
SINTY_SCHEDULER_SITE = $(call github,singularityos-lab,sinty-scheduler,$(SINTY_SCHEDULER_VERSION))
SINTY_SCHEDULER_LICENSE = GPL-2.0
SINTY_SCHEDULER_LICENSE_FILES = LICENSE
SINTY_SCHEDULER_MODULE_SUBDIRS = kmod
SINTY_SCHEDULER_DEPENDENCIES = libglib2 host-pkgconf
SINTY_SCHEDULER_CPU = $(if $(BR2_x86_64),x86_64_v2,baseline)

define SINTY_SCHEDULER_BUILD_CMDS
	cd $(@D) && $(TARGET_MAKE_ENV) PKG_CONFIG=$(PKG_CONFIG_HOST_BINARY) zig build -Doptimize=ReleaseSafe \
		-Dtarget=$(BR2_ARCH)-linux-gnu \
		-Dcpu=$(SINTY_SCHEDULER_CPU) \
		--search-prefix $(STAGING_DIR)/usr \
		--prefix $(@D)/out
endef

define SINTY_SCHEDULER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/out/libexec/sinty-schedd $(TARGET_DIR)/usr/libexec/sinty-schedd
	$(INSTALL) -D -m 0644 $(@D)/out/share/dbus-1/system.d/dev.sinty.Scheduler.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/dev.sinty.Scheduler.conf
	$(INSTALL) -D -m 0644 $(@D)/out/share/dbus-1/system-services/dev.sinty.Scheduler.service $(TARGET_DIR)/usr/share/dbus-1/system-services/dev.sinty.Scheduler.service
	$(INSTALL) -D -m 0644 $(@D)/out/share/polkit-1/actions/dev.sinty.scheduler.policy $(TARGET_DIR)/usr/share/polkit-1/actions/dev.sinty.scheduler.policy
	$(INSTALL) -D -m 0644 $(@D)/out/lib/systemd/system/sinty-schedd.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-schedd.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants
	ln -sf /usr/lib/systemd/system/sinty-schedd.service $(TARGET_DIR)/usr/lib/systemd/system/graphical.target.wants/sinty-schedd.service
endef

$(eval $(kernel-module))
$(eval $(generic-package))
