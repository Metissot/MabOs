#!/bin/sh
# Solo dentro del Alpine experimental: instala TQt y sus interfaces.
set -eu
[ -f /etc/alpine-release ]
[ -d /work/.work/trinity/rootfs ]
BASE=/work/.work/trinity
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib:/opt/trinity-experiment/lib"
export PKG_CONFIG_PATH="$TQTDIR/lib/pkgconfig:/opt/trinity-experiment/lib/pkgconfig"
set -x
cd "$BASE/sources"
sha512sum -c tde-cmake-trinity-14.1.7.tar.xz.sha512sum \
    tqtinterface-trinity-14.1.7.tar.xz.sha512sum
cd tqt-trinity-14.1.7
make -j1 install
cmake -S "$BASE/sources/tde-cmake-trinity-14.1.7" \
    -B "$BASE/build/tde-cmake" -G Ninja
cmake --build "$BASE/build/tde-cmake" --parallel 1
cmake --install "$BASE/build/tde-cmake"
cmake -S "$BASE/sources/tqtinterface-trinity-14.1.7" \
    -B "$BASE/build/tqtinterface" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/trinity-experiment \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DQT_PREFIX_DIR="$TQTDIR"
cmake --build "$BASE/build/tqtinterface" --parallel 1
cmake --install "$BASE/build/tqtinterface"
pkg-config --modversion tqt
ldd /opt/trinity-experiment/lib/libtqt.so
