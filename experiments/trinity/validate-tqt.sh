#!/bin/sh
set -eu
export TQTDIR=/work/.work/trinity/sources/tqt-trinity-14.1.7
export PATH="$TQTDIR/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib"
set -x
tqmake -v || echo "tqmake -v exit status: $?"
tqmoc -v || echo "tqmoc -v exit status: $?"
file "$TQTDIR/lib/libtqt-mt.so.3"
ldd "$TQTDIR/lib/libtqt-mt.so.3"
mkdir -p /work/.work/trinity/smoke-build
cd /work/.work/trinity/smoke-build
tqmake /work/experiments/trinity/smoke.pro -o Makefile
make -j1
file ./smoke
ldd ./smoke
timeout 15 ./smoke
