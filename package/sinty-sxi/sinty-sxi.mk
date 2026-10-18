################################################################################
#
# sinty-sxi
#
################################################################################

SINTY_SXI_VERSION = 74d3625cede1d6f49fc9054e3106801ba5878ed0
SINTY_SXI_SITE = https://github.com/singularityos-lab/sinty-sxi.git
SINTY_SXI_SITE_METHOD = git
SINTY_SXI_LICENSE = BSD-2-Clause
SINTY_SXI_LICENSE_FILES = LICENSE
SINTY_SXI_GOMOD = github.com/singularityos-lab/sinty-sxi
SINTY_SXI_BUILD_TARGETS = cmd/sxi cmd/sxid

define SINTY_SXI_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_SXI_PRE_BUILD_HOOKS += SINTY_SXI_GO_VENDOR

define SINTY_SXI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sxi $(TARGET_DIR)/usr/bin/sxi
	$(INSTALL) -D -m 0755 $(@D)/bin/sxid $(TARGET_DIR)/usr/libexec/sxid
	$(INSTALL) -D -m 0644 $(@D)/packaging/sxid.service $(TARGET_DIR)/usr/lib/systemd/system/sxid.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.SXI1.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/dev.sinty.SXI1.conf
	$(INSTALL) -d $(TARGET_DIR)/usr/share/sinty/sxi/roots $(TARGET_DIR)/usr/share/sinty/sxi/sources.d
	$(INSTALL) -d $(TARGET_DIR)/etc/systemd/system/graphical.target.wants
	ln -sf ../../../../usr/lib/systemd/system/sxid.service $(TARGET_DIR)/etc/systemd/system/graphical.target.wants/sxid.service
endef

$(eval $(golang-package))
