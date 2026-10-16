################################################################################
#
# singularity-demo
#
################################################################################

SINGULARITY_DEMO_VERSION = f7961449a9b91115b0c131225216e14193679319
SINGULARITY_DEMO_SITE = $(call github,singularityos-lab,singularity-demo,$(SINGULARITY_DEMO_VERSION))
SINGULARITY_DEMO_LICENSE = GPL-3.0+
SINGULARITY_DEMO_LICENSE_FILES = LICENSE
SINGULARITY_DEMO_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee libsecret

SINGULARITY_DEMO_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
