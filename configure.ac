AC_INIT([modbus-vapi],
        0.1.0,
        [co@zzeroo.com],
        [modbus-vapi],
        [https://github.com/zzeroo/modbus-vapi])
AM_INIT_AUTOMAKE([foreign dist-xz])
#AM_INIT_AUTOMAKE([subdir-objects])

AC_PROG_CC
AM_PROG_VALAC([0.28])

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################
GLIB_REQUIRED=2.12.0
LIBMODBUS_REQUIRED=3.1.2

PKG_CHECK_MODULES(LIBMODBUS, [
                              libmodbus >= $LIBMODBUS_REQUIRED
                              glib-2.0 >= $GLIB_REQUIRED
                              gobject-2.0 >= $GLIB_REQUIRED
])
VALA_PACKAGES="--pkg libmodbus"
VALA_PACKAGES="$VALA_PACKAGES --pkg posix"
AC_SUBST(VALA_PACKAGES)

AC_CONFIG_FILES([Makefile
                 tests/Makefile])

AC_OUTPUT

