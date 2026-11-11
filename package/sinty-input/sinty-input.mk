################################################################################
#
# sinty-input
#
################################################################################

SINTY_INPUT_VERSION = 0967c6ab652fbe705643edf7ddf99e95637a9aef
SINTY_INPUT_SITE = $(call github,singularityos-lab,sinty-input,$(SINTY_INPUT_VERSION))
SINTY_INPUT_LICENSE = GPL-3.0-only, GPL-2.0+ (Japanese dictionary), CC-BY-SA-4.0 and CC-BY-4.0 (Chinese dictionaries), LGPL-3.0-only (Wubi tables), Apache-2.0 (conversion tables), public domain (Cantonese and code tables)
SINTY_INPUT_LICENSE_FILES = LICENSE dict/NOTICE
SINTY_INPUT_GOMOD = github.com/singularityos-lab/sinty-input
SINTY_INPUT_BUILD_TARGETS = cmd/sinty-input

define SINTY_INPUT_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_INPUT_PRE_BUILD_HOOKS += SINTY_INPUT_GO_VENDOR

define SINTY_INPUT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-input $(TARGET_DIR)/usr/libexec/sinty-input
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Input1.service $(TARGET_DIR)/usr/share/dbus-1/services/dev.sinty.Input1.service
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/share/sinty-input/dict
	$(INSTALL) -m 0644 $(@D)/dict/*.sdict.gz $(@D)/dict/NOTICE $(TARGET_DIR)/usr/share/sinty-input/dict/
endef

$(eval $(golang-package))
