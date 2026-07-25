ATOM_FIRSTBOOT_VERSION = local
ATOM_FIRSTBOOT_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/package/atom-firstboot/src
ATOM_FIRSTBOOT_SITE_METHOD = local
ATOM_FIRSTBOOT_LICENSE = GPL-3.0-or-later
ATOM_FIRSTBOOT_DEPENDENCIES = host-go

define ATOM_FIRSTBOOT_BUILD_CMDS
	cd $(@D) && CGO_ENABLED=0 $(HOST_DIR)/bin/go build -buildvcs=false -ldflags '-s -w' -o atom-firstboot .
endef

define ATOM_FIRSTBOOT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/atom-firstboot $(TARGET_DIR)/usr/bin/atom-firstboot
endef

$(eval $(generic-package))
