################################################################################
#
# singularity-session
#
################################################################################

SINGULARITY_SESSION_VERSION = a475a5d70f0207cb569542348d1a964dd9902ebb
SINGULARITY_SESSION_SITE = $(call github,singularityos-lab,singularity-session,$(SINGULARITY_SESSION_VERSION))
SINGULARITY_SESSION_LICENSE = GPL-3.0+
SINGULARITY_SESSION_LICENSE_FILES = LICENSE
SINGULARITY_SESSION_DEPENDENCIES = host-pkgconf

define SINGULARITY_SESSION_POSIX_SHEBANG
	$(SED) '1s,^#!/bin/bash,#!/bin/sh,' \
		$(@D)/src/singularity-labwc-session \
		$(@D)/src/singularity-desktop-session
endef
SINGULARITY_SESSION_POST_PATCH_HOOKS += SINGULARITY_SESSION_POSIX_SHEBANG

define SINGULARITY_SESSION_RENDERER_OPTIN
	$(SED) 's,^export GSK_RENDERER=gl$$,export GSK_RENDERER=$${GSK_RENDERER:-gl},' \
		$(@D)/src/singularity-desktop-session
endef
SINGULARITY_SESSION_POST_PATCH_HOOKS += SINGULARITY_SESSION_RENDERER_OPTIN

$(eval $(meson-package))
