################################################################################
# atom-install
################################################################################
# The disk installer the graphical installer spawns by name. Built from the local
# source in this directory: every disk operation is an exact argv, so a device path
# can never be re-split or interpreted by a shell.
ATOM_INSTALL_VERSION = local
ATOM_INSTALL_SITE = $(BR2_EXTERNAL_SINGULARITY_PATH)/package/atom-install
ATOM_INSTALL_SITE_METHOD = local
ATOM_INSTALL_LICENSE = GPL-3.0-or-later

ATOM_INSTALL_GOMOD = atom-install
ATOM_INSTALL_GO_ENV = CGO_ENABLED=0

# buildroot's golang-package builds offline with -mod=vendor, which needs a vendor
# dir even for a module with no dependencies. Create it in the rsync'd build tree
# (never the source) so the offline cross-build has one. Use buildroot's own host go,
# already installed by the time this hook runs, instead of one from the build machine:
# a builder without /usr/bin/go stopped here with exit 127.
define ATOM_INSTALL_GO_VENDOR
	cd $(@D) && env -u GOFLAGS -u GOPROXY GOTOOLCHAIN=local $(HOST_DIR)/bin/go mod vendor
	mkdir -p $(@D)/vendor && touch $(@D)/vendor/modules.txt
endef
ATOM_INSTALL_PRE_BUILD_HOOKS += ATOM_INSTALL_GO_VENDOR

define ATOM_INSTALL_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/atom-install $(TARGET_DIR)/usr/bin/atom-install
endef

$(eval $(golang-package))
