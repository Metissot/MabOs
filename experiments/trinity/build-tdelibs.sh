#!/bin/sh
# Solo laboratorio: biblioteca central, sin tdebase ni integración en ISO.
set -eu
[ -f /etc/alpine-release ]
BASE=/work/.work/trinity
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib:/opt/trinity-experiment/lib"
export PKG_CONFIG_PATH="$TQTDIR/lib/pkgconfig:/opt/trinity-experiment/lib/pkgconfig"
export CMAKE_PREFIX_PATH="/opt/trinity-experiment:$TQTDIR"
cd "$BASE/sources"
sha512sum -c tdelibs-trinity-14.1.7.tar.xz.sha512sum
set -x
cmake -S "$BASE/sources/tdelibs-trinity-14.1.7" \
    -B "$BASE/build/tdelibs" -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/opt/trinity-experiment \
    -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
    -DWITH_LIBART=ON
cmake --build "$BASE/build/tdelibs" --parallel 1
