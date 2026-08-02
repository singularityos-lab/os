################################################################################
# ush -- USH permission broker + dsh developer shell (Go, singularityos-lab/ush).
# ush-broker is spawned from the SESSION launcher (singularity-labwc-session),
# NOT a systemd-user unit (Sinty has no systemd --user); this package installs
# only the binaries.
################################################################################
USH_VERSION = a5d1054e7895b01218932ef99f3496a63c4902a1
USH_SITE = $(call github,singularityos-lab,ush,$(USH_VERSION))
USH_LICENSE = GPL-3.0-or-later
USH_LICENSE_FILES = LICENSE

USH_LDFLAGS = -s -w -X github.com/singularityos-lab/ush/internal/config.AppVersion=nightly

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
	# Pre-bake the apt/dpkg tools tree into the image so the first `pkg install`
	# needs no download. Built with the just-compiled ush (native binary, runs on
	# the build host) via its --bake-tools path; ToolsDir() finds it read-only at
	# SystemToolsDir at runtime. Needs network at build time.
	cd $(@D) && CGO_ENABLED=0 $(HOST_DIR)/bin/go run -buildvcs=false ./cmd/ush --bake-tools $(TARGET_DIR)/usr/share/ush/tools
endef

$(eval $(golang-package))
