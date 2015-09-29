libmodbus.vapi
===========

Vapi for libmodbus 3.0.X


Overview
--------

This repository contains Vala language bindings for the libmodbus library as
well as examples to show its use.

The libmodbus :
    <http://www.libmodbus.org/>

The Vala langeuage:
    <http://live.gnome.org/Vala/>

For bug reports, or enhancement requests:
    <https://github.com/geoffjay/modbus-vapi/issues>


Dependencies
-----------

You need the `valac` compiler, of course. On debian/ ubuntu do something like this:

    sudo apt-get install valac

Then you need libmodbus, I prefer installing from source:

    git clone https://github.com/stephane/libmodbus.git
    cd libmodbus
    ./autogen.sh
    ./configure --prefix=/usr
    make
    sudo make install

Usage
-----

To use libmodbus.vapi simply include the 'using Posix;' statement at the top of your
vala code and compile your application with '--pkg=libmodbus' and the vapi in
either the configured system vapidir or using the '--vapi-dir=/path/to/your/dir'
option.

Example:

    valac --pkg=libmodbus --vapidir=/path/to/vapi/dir mycode.vala

Licensing
---------

Please see the file called COPYING.

