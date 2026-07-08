################################################################################
#
# singularity-greeter
#
################################################################################

# SITE=local: build from the local desktop subproject so local UI changes (PIN label,
# recovery flow) reach the image. RC: bump _VERSION to the committed commit + restore
# the github SITE after Mirko commits.
SINGULARITY_GREETER_VERSION = local
SINGULARITY_GREETER_SITE = /home/mirko/Projects/personal/singularity-desktop/subprojects/singularity-greeter
SINGULARITY_GREETER_SITE_METHOD = local
SINGULARITY_GREETER_LICENSE = GPL-3.0+
SINGULARITY_GREETER_LICENSE_FILES = LICENSE
# Install to staging too, so the shipped dev.sinty.greeter GSettings schema lands
# in the staging schemas dir where Buildroot's glib-compile-schemas finalize step
# reads from. Otherwise the schema is never compiled into gschemas.compiled (and
# the source XML is stripped from target), so the greeter aborts at startup.
# Hacky? Yeah D:
SINGULARITY_GREETER_INSTALL_STAGING = YES
SINGULARITY_GREETER_DEPENDENCIES = \
	host-pkgconf \
	host-wayland \
	singularity-loginui \
	wayland \
	libxkbcommon \
	libglib2 \
	json-glib

$(eval $(meson-package))
