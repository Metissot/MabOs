#!/bin/sh
# Dependencias previas a tdelibs; no construye el escritorio ni una ISO.
set -eu
[ -f /etc/alpine-release ]
BASE=/work/.work/trinity
export TQTDIR=/opt/tqt-experiment
export PATH="$TQTDIR/bin:/opt/trinity-experiment/bin:$PATH"
export LD_LIBRARY_PATH="$TQTDIR/lib:/opt/trinity-experiment/lib"
export PKG_CONFIG_PATH="$TQTDIR/lib/pkgconfig:/opt/trinity-experiment/lib/pkgconfig"
export CMAKE_PREFIX_PATH="/opt/trinity-experiment:$TQTDIR"
build_module() (
    set -eu
    module=$1
    shift
    cd "$BASE/sources"
    sha512sum -c "$module-trinity-14.1.7.tar.xz.sha512sum"
    set -x
    cmake -S "$BASE/sources/$module-trinity-14.1.7" \
        -B "$BASE/build/$module" -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/opt/trinity-experiment \
        -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release "$@"
    cmake --build "$BASE/build/$module" --parallel 1
    cmake --install "$BASE/build/$module"
)
if [ "${1:-}" = "--module" ]; then
    shift
    build_module "$@"
    exit
fi
failed=0
for module in arts dbus-tqt dbus-1-tqt tqca libart-lgpl; do
    case "$module" in
        arts) set -- -DBUILD_DOC=OFF -U '*MAD*' ;;
        libart-lgpl) set -- -DBUILD_DOC=OFF ;;
        *) set -- ;;
    esac
    # Ejecutar un shell separado mantiene set -e activo dentro del módulo.
    status=0
    /bin/sh "$0" --module "$module" "$@" \
        > "/work/logs/trinity/build-$module.log" 2>&1 || status=$?
    printf '%s: %s\n' "$module" "$status"
    [ "$status" -eq 0 ] || failed=1
done
exit "$failed"
