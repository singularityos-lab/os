################################################################################
#
# singularity-greeter
#
################################################################################

SINGULARITY_GREETER_VERSION = 3f380a89ff74f83f5c105f7c6135a702866f0598
SINGULARITY_GREETER_SITE = $(call github,singularityos-lab,singularity-greeter,$(SINGULARITY_GREETER_VERSION))
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
