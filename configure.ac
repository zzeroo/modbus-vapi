AC_PREREQ([2.63])
AC_INIT([modbus-vapi],
        0.1.0,
        [co@zzeroo.com],
        [modbus-vapi],
        [https://github.com/zzeroo/modbus-vapi])

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


