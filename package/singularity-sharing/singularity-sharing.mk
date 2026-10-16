################################################################################
#
# singularity-sharing
#
################################################################################

SINGULARITY_SHARING_VERSION = 0dfe080cbe1fded3179484024766e38c8088e1b8
SINGULARITY_SHARING_SITE = $(call github,singularityos-lab,singularity-sharing,$(SINGULARITY_SHARING_VERSION))
SINGULARITY_SHARING_LICENSE = LGPL-2.1+
SINGULARITY_SHARING_LICENSE_FILES = LICENSE
SINGULARITY_SHARING_DEPENDENCIES = host-pkgconf host-vala host-gettext libsingularity libgee json-glib libsoup3 libsecret

SINGULARITY_SHARING_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

define SINGULARITY_SHARING_LIBSINGULARITY_SUBPROJECT
	mkdir -p $(@D)/subprojects
	rsync -a --delete --exclude=/build --exclude=/build-* --exclude=.git $(or $(LIBSINGULARITY_OVERRIDE_SRCDIR),$(LIBSINGULARITY_DIR))/ $(@D)/subprojects/libsingularity/
endef
SINGULARITY_SHARING_PRE_CONFIGURE_HOOKS += SINGULARITY_SHARING_LIBSINGULARITY_SUBPROJECT

define SINGULARITY_SHARING_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(SINGULARITY_SHARING_NINJA_ENV) \
		$(HOST_DIR)/bin/meson install -C $(@D)/buildroot-build --no-rebuild --skip-subprojects --destdir $(TARGET_DIR)
endef

$(eval $(meson-package))
