#!/bin/sh
set -eu
BASE=/work/.work/trinity
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib:/opt/trinity-experiment/lib"
export PKG_CONFIG_PATH="$TQTDIR/lib/pkgconfig:/opt/trinity-experiment/lib/pkgconfig"
set -x
cmake --build "$BASE/build/libart-lgpl" --target build-check --parallel 1
ctest --test-dir "$BASE/build/libart-lgpl" --output-on-failure --timeout 60
for lib in /opt/trinity-experiment/lib/*.so \
    /opt/tqt-experiment/plugins/crypto/*.so; do
    ldd "$lib"
done
g++ $(pkg-config --cflags tqt tqca) /work/experiments/trinity/smoke-tqca.cpp \
    $(pkg-config --libs tqt tqca) -o "$BASE/smoke-tqca"
timeout 15 "$BASE/smoke-tqca"
dbusxml2qt3 --help
