################################################################################
#
# singularity-calendar
#
################################################################################

SINGULARITY_CALENDAR_VERSION = dd2d7c79fe46dc8fe9be0f115b886e74481828a6
SINGULARITY_CALENDAR_SITE = $(call github,singularityos-lab,singularity-calendar,$(SINGULARITY_CALENDAR_VERSION))
SINGULARITY_CALENDAR_LICENSE = GPL-3.0+
SINGULARITY_CALENDAR_LICENSE_FILES = LICENSE
SINGULARITY_CALENDAR_INSTALL_STAGING = YES
SINGULARITY_CALENDAR_DEPENDENCIES = host-pkgconf host-vala host-vetro host-gettext libsingularity libgtk4 libgee gnome-online-accounts libsoup3 json-glib

SINGULARITY_CALENDAR_NINJA_ENV = XDG_DATA_HOME=$(STAGING_DIR)/usr/share

# FIXME: Calendar's upstream has some missing deps
define SINGULARITY_CALENDAR_ADD_JSON_DEP
	$(SED) "s/soup_dep = dependency('libsoup-3.0')/&\njson_dep = dependency('json-glib-1.0')/" $(@D)/meson.build
	$(SED) 's/soup_dep, libsingularity_dep\]/soup_dep, json_dep, libsingularity_dep]/' $(@D)/meson.build
endef
SINGULARITY_CALENDAR_POST_PATCH_HOOKS += SINGULARITY_CALENDAR_ADD_JSON_DEP

$(eval $(meson-package))
