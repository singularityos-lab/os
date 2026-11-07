################################################################################
#
# sinty-speechd
#
################################################################################

SINTY_SPEECHD_VERSION = 64fd53839701b3a6e74486c98ed0981d4cb4e927
SINTY_SPEECHD_SITE = $(call github,singularityos-lab,sinty-speechd,$(SINTY_SPEECHD_VERSION))
SINTY_SPEECHD_LICENSE = GPL-3.0-only
SINTY_SPEECHD_LICENSE_FILES = LICENSE
SINTY_SPEECHD_GOMOD = github.com/singularityos-lab/sinty-speechd
SINTY_SPEECHD_BUILD_TARGETS = cmd/sinty-speechd

define SINTY_SPEECHD_GO_VENDOR
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
endef
SINTY_SPEECHD_PRE_BUILD_HOOKS += SINTY_SPEECHD_GO_VENDOR

define SINTY_SPEECHD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinty-speechd $(TARGET_DIR)/usr/libexec/sinty-speechd
	$(INSTALL) -d $(TARGET_DIR)/usr/libexec/sinty-speech $(TARGET_DIR)/usr/share/sinty-speech/voices
	ln -sf ../sinty-speechd $(TARGET_DIR)/usr/libexec/sinty-speech/speech-dispatcher
	$(INSTALL) -D -m 0644 $(@D)/packaging/dev.sinty.Speech1.service $(TARGET_DIR)/usr/share/dbus-1/services/dev.sinty.Speech1.service
endef

$(eval $(golang-package))
