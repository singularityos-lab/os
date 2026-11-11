################################################################################
#
# cpak
#
################################################################################

CPAK_VERSION = 013dc3922ba693d98d0c7b1be1978356e8649046
CPAK_SITE = $(call github,containerpak,cpak,$(CPAK_VERSION))
CPAK_LICENSE = LGPL-2.1
CPAK_LICENSE_FILES = LICENSE
CPAK_GOMOD = github.com/mirkobrombin/cpak
CPAK_BUILD_TARGETS = cmd/cpak-storaged
CPAK_DEPENDENCIES = libgtk4 host-pkgconf
CPAK_RELEASE = 2.14.18
CPAK_TAGS = cpak_ui_gtk
CPAK_LDFLAGS = \
	-X main.version=$(CPAK_RELEASE) \
	-X main.selfUpdateMode=managed \
	-X github.com/mirkobrombin/cpak/pkg/desktopui.defaultBackend=gtk

CPAK_SLIRP_VERSION = v1.3.5
CPAK_EXTRA_DOWNLOADS = \
	https://github.com/rootless-containers/slirp4netns/releases/download/$(CPAK_SLIRP_VERSION)/slirp4netns-aarch64

define CPAK_GO_PREPARE
	sed -i 's/^go 1\.26\.[0-9]*$$/go 1.26/' $(@D)/go.mod
	cd $(@D) && env -u GOFLAGS GOPROXY=https://proxy.golang.org,direct GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
	mkdir -p $(@D)/.build/ui-adapters
	$(TARGET_CC) $(TARGET_CFLAGS) -O2 -Wall -Wextra $(@D)/ui/adapters/gtk/main.c \
		-o $(@D)/.build/ui-adapters/cpak-ui-gtk $(TARGET_LDFLAGS) \
		`$(PKG_CONFIG_HOST_BINARY) --cflags --libs gtk4`
	rm -f $(@D)/pkg/desktopui/adapter_embedded_*_generated.go
	cd $(@D) && env -u GOFLAGS GOTOOLCHAIN=local $(HOST_DIR)/bin/go run -mod=vendor ./cmd/cpak-ui-bundle \
		--output pkg/desktopui --gtk .build/ui-adapters/cpak-ui-gtk
endef
CPAK_PRE_BUILD_HOOKS += CPAK_GO_PREPARE

define CPAK_BUILD_MAIN
	cd $(@D) && $(HOST_GO_TARGET_ENV) $(CPAK_GO_ENV) $(GO_BIN) build -v $(CPAK_BUILD_OPTS) \
		-o $(@D)/bin/cpak $(CPAK_GOMOD)
endef
CPAK_POST_BUILD_HOOKS += CPAK_BUILD_MAIN

define CPAK_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/cpak $(TARGET_DIR)/usr/local/bin/cpak
	$(INSTALL) -D -m 0755 $(@D)/bin/cpak-storaged $(TARGET_DIR)/usr/local/bin/cpak-storaged
	$(INSTALL) -D -m 0755 $(CPAK_DL_DIR)/slirp4netns-aarch64 $(TARGET_DIR)/usr/local/bin/cpak-slirp4netns
	mkdir -p $(TARGET_DIR)/usr/bin
	ln -sf /usr/local/bin/cpak $(TARGET_DIR)/usr/bin/cpak
	sed 's|@SERVICEDIR@||' $(@D)/pkg/systemauthority/assets/it.cpak.SystemAuthority1.conf > $(@D)/authority.conf
	$(INSTALL) -D -m 0644 $(@D)/authority.conf $(TARGET_DIR)/etc/dbus-1/system.d/it.cpak.SystemAuthority1.conf
	sed 's|@BINARY@|/usr/local/bin/cpak|' $(@D)/pkg/systemauthority/assets/cpak-system-authority.service > $(@D)/authority.unit
	$(INSTALL) -D -m 0644 $(@D)/authority.unit $(TARGET_DIR)/etc/systemd/system/cpak-system-authority.service
	sed 's|@BINARY@|/usr/local/bin/cpak|' $(@D)/pkg/systemauthority/assets/it.cpak.SystemAuthority1.service > $(@D)/authority.service
	$(INSTALL) -D -m 0644 $(@D)/authority.service \
		$(TARGET_DIR)/usr/local/share/dbus-1/system-services/it.cpak.SystemAuthority1.service
	$(INSTALL) -D -m 0644 $(@D)/pkg/systemauthority/assets/it.cpak.system.policy \
		$(TARGET_DIR)/usr/share/polkit-1/actions/it.cpak.system.policy
endef

$(eval $(golang-package))
