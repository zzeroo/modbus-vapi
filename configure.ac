# This file is processed by autoconf to create a configure script
AC_INIT(modbus-vapi], 0.1.1, [co@zzeroo.com])
AM_INIT_AUTOMAKE([1.10 no-define foreign dist-xz no-dist-gzip])

AC_PROG_CC
AM_PROG_VALAC([0.28])
AM_PROG_CC_C_O

dnl ###########################################################################
dnl Dependencies
dnl ###########################################################################
LIBMODBUS_REQUIRED=3.1.2

PKG_CHECK_MODULES(MODBUS_VAPI, [
  libmodbus >= $LIBMODBUS_REQUIRED
])


AC_CONFIG_FILES([Makefile
                 tests/Makefile])

AC_OUTPUT
