################################################################################
#
# singularity-tasks
#
################################################################################

SINGULARITY_TASKS_VERSION = dcb1836d494eccd6a34f16d851b32b087a1b59a2
SINGULARITY_TASKS_SITE = $(call github,singularityos-lab,singularity-tasks,$(SINGULARITY_TASKS_VERSION))
SINGULARITY_TASKS_LICENSE = GPL-3.0+
SINGULARITY_TASKS_LICENSE_FILES = LICENSE
SINGULARITY_TASKS_INSTALL_STAGING = YES
SINGULARITY_TASKS_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee json-glib libpeas2

SINGULARITY_TASKS_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

SINGULARITY_TASKS_DEPENDENCIES += host-iride
SINGULARITY_TASKS_CONF_OPTS += -Diride=enabled

$(eval $(meson-package))
