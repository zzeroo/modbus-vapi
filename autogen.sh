#!/bin/sh

set -e # exit on errors

test -n "$srcdir" || srcdir=`dirname "$0"`
test -n "$srcdir" || srcdir=.

olddir=`pwd`
cd "$srcdir"

ln -f README.md README

# This will run autoconf, automake, etc. for us
autoreconf --force --install

cd "$olddir"

if test -z "$NOCONFIGURE"; then
  "$srcdir"/configure --enable-maintainer-mode --enable-debug  "$@"
fi
