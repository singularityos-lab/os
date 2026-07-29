################################################################################
#
# libdbusmenu
#
################################################################################

LIBDBUSMENU_VERSION = 7546d37abb436a6025af3217865841717fb199ff
LIBDBUSMENU_SITE = $(call github,singularityos-lab,libdbusmenu,$(LIBDBUSMENU_VERSION))
LIBDBUSMENU_LICENSE = LGPL-2.1, LGPL-3.0, GPL-3.0
LIBDBUSMENU_LICENSE_FILES = COPYING COPYING.2.1 COPYING-GPL3
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

define LIBDBUSMENU_GTK_DOC_HOOK
	echo "EXTRA_DIST =" > $(@D)/gtk-doc.make
	echo "CLEANFILES =" >> $(@D)/gtk-doc.make
endef
LIBDBUSMENU_PRE_CONFIGURE_HOOKS += LIBDBUSMENU_GTK_DOC_HOOK

define LIBDBUSMENU_FIX_VALGRIND_CONDITIONAL
	$(SED) '/AM_CONDITIONAL(\[HAVE_VALGRIND\]/d' $(@D)/configure.ac
	$(SED) '/AM_CONDITIONAL(\[WANT_TESTS\]/a\have_valgrind=no' $(@D)/configure.ac
	$(SED) '/AM_CONDITIONAL(\[WANT_TESTS\]/a\AM_CONDITIONAL([HAVE_VALGRIND], [test "x$$have_valgrind" = "xyes"])' $(@D)/configure.ac
endef
LIBDBUSMENU_POST_PATCH_HOOKS += LIBDBUSMENU_FIX_VALGRIND_CONDITIONAL

$(eval $(autotools-package))
