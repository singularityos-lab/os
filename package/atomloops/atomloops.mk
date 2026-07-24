################################################################################
#
# atomloops
#
################################################################################

# SITE=local: build the Atom Loops OTA daemons from the local AtomLoops repo.
# buildroot-build/local.mk _OVERRIDE_SRCDIR supersedes this for dev builds.
ATOMLOOPS_VERSION = local
ATOMLOOPS_SITE = /home/mirko/Projects/personal/AtomLoops
ATOMLOOPS_SITE_METHOD = local
ATOMLOOPS_LICENSE = GPL-3.0-only
ATOMLOOPS_LICENSE_FILES = LICENSE

ATOMLOOPS_GOMOD = github.com/mirkobrombin/atomloops
# All AtomLoops binaries are pure-Go (no cgo): build them static, like fw-verify
# already is for the initramfs.
ATOMLOOPS_GO_ENV = CGO_ENABLED=0
ATOMLOOPS_BUILD_TARGETS = cmd/atomd cmd/updated cmd/fw-verify

# buildroot's golang-package builds offline with -mod=vendor + GOPROXY=off, but the
# AtomLoops source ships no vendor/ dir. Populate one in the rsync'd build tree (NOT the
# source) with the host go, whose module cache already holds the single dependency, so the
# offline cross-build finds it. Runs before the buildroot go build.
define ATOMLOOPS_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local /usr/bin/go mod vendor
endef
ATOMLOOPS_PRE_BUILD_HOOKS += ATOMLOOPS_GO_VENDOR

# atomd + updated -> /usr/libexec (the units call them there); fw-verify -> /usr/bin
# (used by the firmware-probe device-aware check and available for diagnostics). The
# release root public key -> /etc/atom-fw-root.pub (the firmware anchor trust root; a
# TEST key for now, swapped for the real cold root in a production build). The initramfs
# mount also bakes this same root.pub via package.sh FW_ROOT_PUB.
define ATOMLOOPS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/atomd     $(TARGET_DIR)/usr/libexec/atomd
	$(INSTALL) -D -m 0755 $(@D)/bin/updated   $(TARGET_DIR)/usr/libexec/updated
	$(INSTALL) -D -m 0755 $(@D)/bin/fw-verify $(TARGET_DIR)/usr/bin/fw-verify
	$(INSTALL) -D -m 0644 $(ATOMLOOPS_PKGDIR)/root.pub $(TARGET_DIR)/etc/atom-fw-root.pub
	$(INSTALL) -D -m 0644 $(@D)/packaging/updated.service $(TARGET_DIR)/usr/lib/systemd/system/updated.service
endef

$(eval $(golang-package))
