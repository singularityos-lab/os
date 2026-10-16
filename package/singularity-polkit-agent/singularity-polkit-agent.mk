################################################################################
#
# singularity-polkit-agent
#
################################################################################

SINGULARITY_POLKIT_AGENT_VERSION = fa8379d8263b9198ab1e7441a7de63457133d771
SINGULARITY_POLKIT_AGENT_SITE = $(call github,singularityos-lab,singularity-polkit-agent,$(SINGULARITY_POLKIT_AGENT_VERSION))
SINGULARITY_POLKIT_AGENT_LICENSE = GPL-3.0+
SINGULARITY_POLKIT_AGENT_LICENSE_FILES = LICENSE
SINGULARITY_POLKIT_AGENT_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	libsingularity \
	libgtk4 \
	polkit

define SINGULARITY_POLKIT_AGENT_BIN_SYMLINK
	ln -sf ../libexec/singularity-polkit-agent $(TARGET_DIR)/usr/bin/singularity-polkit-agent
endef
SINGULARITY_POLKIT_AGENT_POST_INSTALL_TARGET_HOOKS += SINGULARITY_POLKIT_AGENT_BIN_SYMLINK

$(eval $(meson-package))
