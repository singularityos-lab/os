################################################################################
#
# singularity-tasks
#
################################################################################

SINGULARITY_TASKS_VERSION = 2f21248e7db7d241d6b1fa543349430b75c82e2f
SINGULARITY_TASKS_SITE = $(call github,singularityos-lab,singularity-tasks,$(SINGULARITY_TASKS_VERSION))
SINGULARITY_TASKS_LICENSE = GPL-3.0+
SINGULARITY_TASKS_LICENSE_FILES = LICENSE
SINGULARITY_TASKS_INSTALL_STAGING = YES
SINGULARITY_TASKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_TASKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

$(eval $(meson-package))
