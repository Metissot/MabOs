#!/bin/sh
# Ejecutar mediante enter-alpine.sh; no instala nada en la distribución.
set -eu
cd /work/.work/trinity/sources
sha512sum -c tqt-trinity-14.1.7.tar.xz.sha512sum
cd tqt-trinity-14.1.7
export TQTDIR="$PWD"
export PATH="$TQTDIR/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib"
set -x
./configure -prefix /opt/tqt-experiment -platform linux-g++ \
    -release -shared -thread -no-pch -fast \
    -system-zlib -system-libpng -system-libjpeg \
    -no-imgfmt-mng -disable-opengl -no-nis -no-cups \
    -nomake examples -nomake tutorial
make -j1 sub-tools
