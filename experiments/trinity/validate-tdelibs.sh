#!/bin/sh
# Comprobaciones sin servidor gráfico; no instala tdelibs.
set -eu
BASE=/work/.work/trinity
BUILD="$BASE/build/tdelibs"
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$BUILD/tdecore:$BUILD/tdeui:$BUILD/dcop:$BUILD/tdefx:$TQTDIR/lib:/opt/trinity-experiment/lib"
export PKG_CONFIG_PATH="$TQTDIR/lib/pkgconfig:/opt/trinity-experiment/lib/pkgconfig"
export HOME="$BASE/test-home-tdelibs"
export TDEHOME="$HOME/.trinity"
mkdir -p "$HOME"
unset DISPLAY SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
set -x
ldd "$BUILD/tdecore/libtdecore.so"
ldd "$BUILD/tdeui/libtdeui.so"
ldd "$BUILD/tdeio/libtdeio.so"
cmake --build "$BUILD" --parallel 1 --target \
    kcharsetstest kglobaltest kmacroexpandertest krfcdatetest \
    kstringhandlertest kurltest
ctest --test-dir "$BUILD" --output-on-failure --timeout 60 \
    -R '^tdecore/(kcharsetstest|kglobaltest|kmacroexpandertest|krfcdatetest|kstringhandlertest|kurltest)$'
