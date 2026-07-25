################################################################################
# sinit
################################################################################
# Pin to a released commit/tag. B: set SITE to the real sinit repo (or use the
# local method against a vendored copy for a fully offline build).
SINIT_VERSION = 725c35c
SINIT_SITE = $(call github,singularityos-lab,atom,$(SINIT_VERSION))
SINIT_LICENSE = GPL-3.0-or-later

# Module path from go.mod. sinit has NO external dependencies (stdlib only), so
# the build is fully offline once the source is present.
SINIT_GOMOD = github.com/singularityos-lab/atom
SINIT_BUILD_TARGETS = cmd/sinit

# Install to /usr/lib/sinit/sinit and wire the multicall symlinks by argv[0].
# init= on the kernel cmdline points at /usr/lib/sinit/sinit; PID 1 is detected
# via getpid()==1. The client tools dispatch on their basename.
define SINIT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/sinit $(TARGET_DIR)/usr/lib/sinit/sinit
	mkdir -p $(TARGET_DIR)/sbin $(TARGET_DIR)/usr/bin
	ln -sf /usr/lib/sinit/sinit $(TARGET_DIR)/sbin/init
	ln -sf /usr/lib/sinit/sinit $(TARGET_DIR)/usr/bin/atomctl
	ln -sf /usr/lib/sinit/sinit $(TARGET_DIR)/usr/bin/systemctl
	ln -sf /usr/lib/sinit/sinit $(TARGET_DIR)/usr/bin/reboot
	ln -sf /usr/lib/sinit/sinit $(TARGET_DIR)/usr/bin/poweroff
	ln -sf /usr/lib/sinit/sinit $(TARGET_DIR)/usr/bin/halt
	# Base target skeleton systemd used to provide; sinit reads these and walks
	# the Requires/After chain (graphical->multi-user->basic->sysinit) plus each
	# target's .wants/ set. Vendor units live in /usr/lib/systemd/system.
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system
	cp -a $(SINIT_PKGDIR)/system/*.target $(TARGET_DIR)/usr/lib/systemd/system/
endef

$(eval $(golang-package))
