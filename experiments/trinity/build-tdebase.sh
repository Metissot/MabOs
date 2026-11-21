#!/bin/sh
# Escritorio experimental; no instala ni genera una ISO.
set -eu
[ -f /etc/alpine-release ]
BASE=/work/.work/trinity
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib:/opt/trinity-experiment/lib"
export PKG_CONFIG_PATH="$TQTDIR/lib/pkgconfig:/opt/trinity-experiment/lib/pkgconfig"
export CMAKE_PREFIX_PATH="/opt/trinity-experiment:$TQTDIR"
cd "$BASE/sources"
sha512sum -c tdebase-trinity-14.1.7.tar.xz.sha512sum
set -x
cmake -S "$BASE/sources/tdebase-trinity-14.1.7" \
    -B "$BASE/build/tdebase" -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/opt/trinity-experiment \
    -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_ALL=ON -DBUILD_TDM=OFF -DBUILD_DOC=OFF \
    -DWITH_ARTS=ON -DWITH_LIBART=ON -DWITH_TDEHWLIB=ON \
    -DWITH_XRENDER=ON -DWITH_XRANDR=ON -DWITH_XCURSOR=ON \
    -DWITH_XINERAMA=ON -DWITH_XCOMPOSITE=ON -DWITH_XFIXES=ON \
    -DWITH_XTEST=ON -DWITH_XSCREENSAVER=OFF -DWITH_PAM=ON
cmake --build "$BASE/build/tdebase" --parallel 1
