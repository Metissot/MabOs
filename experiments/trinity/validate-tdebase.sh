#!/bin/sh
# Revisión sin instalar tdebase ni abrir una sesión gráfica.
set -eu
BASE=/work/.work/trinity
BUILD="$BASE/build/tdebase"
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$BUILD/libkonq:$TQTDIR/lib:/opt/trinity-experiment/lib"
export HOME="$BASE/test-home-tdebase"
export TDEHOME="$HOME/.trinity"
mkdir -p "$HOME"
unset DISPLAY SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
set -x
for binary in twin/twin kdesktop/kdesktop kicker/kicker/kicker \
    konsole/src/konsole ksmserver/ksmserver; do
    file "$BUILD/$binary"
    ldd "$BUILD/$binary"
    timeout 15 "$BUILD/$binary" --version
done
ctest --test-dir "$BUILD" -N
