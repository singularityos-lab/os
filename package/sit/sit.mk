################################################################################
#
# sit
#
################################################################################

SIT_VERSION = $(LIBGTK4_VERSION)
SIT_SITE = $(call github,singularityos-lab,sit,$(SIT_VERSION))
SIT_LICENSE = LGPL-2.0+
SIT_LICENSE_FILES = COPYING

HOST_SIT_DEPENDENCIES = \
	host-cairo \
	host-gdk-pixbuf \
	host-graphene \
	host-harfbuzz \
	host-libdrm \
	host-libepoxy \
	host-libfribidi \
	host-libglib2 \
	host-libjpeg \
	host-libpng \
	host-pango \
	host-pkgconf \
	host-tiff

HOST_SIT_CONF_OPTS = \
	-Dx11-backend=false \
	-Dwayland-backend=false \
	-Dbroadway-backend=true \
	-Dvulkan=disabled \
	-Dmedia-gstreamer=disabled \
	-Dprint-cpdb=disabled \
	-Dprint-cups=disabled \
	-Dcloudproviders=disabled \
	-Dsysprof=disabled \
	-Dtracker=disabled \
	-Dcolord=disabled \
	-Diride=disabled \
	-Dintrospection=disabled \
	-Ddocumentation=false \
	-Dscreenshots=false \
	-Dman-pages=false \
	-Dbuild-demos=false \
	-Dbuild-examples=false \
	-Dbuild-tests=false \
	-Dbuild-testsuite=false

$(eval $(host-meson-package))
