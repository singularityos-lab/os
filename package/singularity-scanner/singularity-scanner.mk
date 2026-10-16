################################################################################
#
# singularity-scanner
#
################################################################################

SINGULARITY_SCANNER_VERSION = 918bb22aaf88ca5a96fa0a0bbabb031306fb9b79
SINGULARITY_SCANNER_SITE = $(call github,singularityos-lab,singularity-scanner,$(SINGULARITY_SCANNER_VERSION))
SINGULARITY_SCANNER_LICENSE = GPL-3.0+
SINGULARITY_SCANNER_LICENSE_FILES = LICENSE
SINGULARITY_SCANNER_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 cairo libgee sane-backends

SINGULARITY_SCANNER_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
