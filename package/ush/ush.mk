################################################################################
# ush -- USH permission broker + dsh developer shell (Go, singularityos-lab/ush).
# ush-broker is spawned from the SESSION launcher (singularity-labwc-session),
# NOT a systemd-user unit (Sinty has no systemd --user); this package installs
# only the binaries.
################################################################################
USH_VERSION = local
USH_SITE_METHOD = local
USH_SITE = /home/mirko/Projects/personal/ush
USH_LICENSE = GPL-3.0-or-later
USH_LICENSE_FILES = LICENSE

USH_LDFLAGS = -s -w -X github.com/singularityos-lab/ush/internal/config.AppVersion=0.1.0

define USH_BUILD_CMDS
	cd $(@D) && CGO_ENABLED=0 $(HOST_DIR)/bin/go build -buildvcs=false -ldflags '$(USH_LDFLAGS)' -o ush ./cmd/ush
	cd $(@D) && CGO_ENABLED=0 $(HOST_DIR)/bin/go build -buildvcs=false -ldflags '$(USH_LDFLAGS)' -o ush-broker ./cmd/ush-broker
	$(TARGET_CC) -shared -fPIC -O2 -o $(@D)/ush-chown-shim.so $(@D)/internal/preload/csrc/ush-chown-shim.c
endef

define USH_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/ush              $(TARGET_DIR)/usr/bin/ush
	$(INSTALL) -D -m 0755 $(@D)/ush-broker       $(TARGET_DIR)/usr/bin/ush-broker
	$(INSTALL) -D -m 0644 $(@D)/ush-chown-shim.so $(TARGET_DIR)/usr/lib/ush/ush-chown-shim.so
	ln -sf ush $(TARGET_DIR)/usr/bin/dsh
endef

$(eval $(golang-package))
