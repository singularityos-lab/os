################################################################################
#
# libdbusmenu
#
################################################################################

LIBDBUSMENU_VERSION = 16.04.0
LIBDBUSMENU_SOURCE = libdbusmenu-$(LIBDBUSMENU_VERSION).tar.gz
# Upstream is https://launchpad.net/libdbusmenu/16.04/$(LIBDBUSMENU_VERSION)/+download,
# which times out from a CI runner, and buildroot's own mirror answers 404 for this
# tarball -- so a build with a cold download cache could not fetch it at all. Serve the
# byte-identical tarball from this project's own release and check it against the hash
# in libdbusmenu.hash, so the substitution cannot go unnoticed.
LIBDBUSMENU_SITE = https://github.com/singularityos-lab/os/releases/download/third-party-sources
LIBDBUSMENU_LICENSE = LGPL-2.1, LGPL-3.0, GPL-3.0
LIBDBUSMENU_LICENSE_FILES = COPYING COPYING.LGPL.2.1 COPYING.LGPL.3 COPYING.GPL.3
LIBDBUSMENU_INSTALL_STAGING = YES
LIBDBUSMENU_AUTORECONF = YES
LIBDBUSMENU_DEPENDENCIES = \
	host-pkgconf \
	host-vala \
	gobject-introspection \
	libglib2

LIBDBUSMENU_CONF_ENV = CFLAGS="$(TARGET_CFLAGS) -Wno-error"

LIBDBUSMENU_CONF_OPTS = \
	--disable-static \
	--disable-tests \
	--disable-dumper \
	--disable-gtk \
	--disable-gtk-doc \
	--disable-gtk-doc-html \
	--disable-werror \
	--enable-compile-warnings=no \
	--with-gtk=none

define LIBDBUSMENU_FIX_VALGRIND_CONDITIONAL
	$(SED) '/AM_CONDITIONAL(\[HAVE_VALGRIND\]/d' $(@D)/configure.ac
	$(SED) '/AM_CONDITIONAL(\[WANT_TESTS\]/a\have_valgrind=no' $(@D)/configure.ac
	$(SED) '/AM_CONDITIONAL(\[WANT_TESTS\]/a\AM_CONDITIONAL([HAVE_VALGRIND], [test "x$$have_valgrind" = "xyes"])' $(@D)/configure.ac
endef
LIBDBUSMENU_POST_PATCH_HOOKS += LIBDBUSMENU_FIX_VALGRIND_CONDITIONAL

$(eval $(autotools-package))
