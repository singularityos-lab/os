################################################################################
#
# singularity-polkit-agent
#
################################################################################

SINGULARITY_POLKIT_AGENT_VERSION = 5b170ecdbbf8358dfab69fd1331e370c36827cc8
SINGULARITY_POLKIT_AGENT_SITE = $(call github,singularityos-lab,singularity-polkit-agent,$(SINGULARITY_POLKIT_AGENT_VERSION))
SINGULARITY_POLKIT_AGENT_LICENSE = GPL-3.0+
SINGULARITY_POLKIT_AGENT_LICENSE_FILES = LICENSE
SINGULARITY_POLKIT_AGENT_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gtk4-layer-shell \
	libsingularity \
	libgtk4 \
	polkit

define SINGULARITY_POLKIT_AGENT_BIN_SYMLINK
	ln -sf ../libexec/singularity-polkit-agent $(TARGET_DIR)/usr/bin/singularity-polkit-agent
endef
SINGULARITY_POLKIT_AGENT_POST_INSTALL_TARGET_HOOKS += SINGULARITY_POLKIT_AGENT_BIN_SYMLINK

$(eval $(meson-package))
