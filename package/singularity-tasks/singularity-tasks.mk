################################################################################
#
# singularity-tasks
#
################################################################################

SINGULARITY_TASKS_VERSION = ddaa58467b269e1f3daee1712a5b5dc9acc7eb2d
SINGULARITY_TASKS_SITE = $(call github,singularityos-lab,singularity-tasks,$(SINGULARITY_TASKS_VERSION))
SINGULARITY_TASKS_LICENSE = GPL-3.0+
SINGULARITY_TASKS_LICENSE_FILES = LICENSE
SINGULARITY_TASKS_INSTALL_STAGING = YES
SINGULARITY_TASKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_TASKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
