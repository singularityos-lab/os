################################################################################
#
# sinty-logind
#
################################################################################

SINTY_LOGIND_VERSION = 0a06ba7a3bccfd881303f93d8936e711457f1960
SINTY_LOGIND_SITE = $(call github,singularityos-lab,sinty-logind,$(SINTY_LOGIND_VERSION))
SINTY_LOGIND_LICENSE = GPL-3.0-only
SINTY_LOGIND_LICENSE_FILES = LICENSE
SINTY_LOGIND_GOMOD = github.com/singularityos-lab/sinty-logind
SINTY_LOGIND_BUILD_TARGETS = cmd/sinty-logind
SINTY_LOGIND_DEPENDENCIES = linux-pam

define SINTY_LOGIND_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_LOGIND_PRE_BUILD_HOOKS += SINTY_LOGIND_GO_VENDOR

define SINTY_LOGIND_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-logind $(TARGET_DIR)/usr/libexec/sinty-logind
	$(INSTALL) -D -m 0644 $(@D)/packaging/sinty-logind.service $(TARGET_DIR)/usr/lib/systemd/system/sinty-logind.service
	$(INSTALL) -D -m 0644 $(@D)/packaging/org.freedesktop.login1.conf $(TARGET_DIR)/usr/share/dbus-1/system.d/org.freedesktop.login1.conf
endef

$(eval $(golang-package))
