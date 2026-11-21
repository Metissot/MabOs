#!/bin/sh
# Descarga exclusivamente fuentes oficiales de las dependencias indicadas.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$PROJECT/.work/trinity/sources"
BASE=https://mirror.ppa.trinitydesktop.org/trinity/releases/R14.1.7/main/dependencies
for module in "$@"; do
    case "$module" in
        tde-cmake|tqtinterface|arts|dbus-tqt|dbus-1-tqt|tqca|libart-lgpl) ;;
        *) echo "Dependencia no prevista: $module" >&2; exit 1 ;;
    esac
    archive="$module-trinity-14.1.7.tar.xz"
    for suffix in '' .sha512sum; do
        if [ ! -f "$archive$suffix" ]; then
            curl -fLsS --retry 3 "$BASE/$archive$suffix" -o "$archive$suffix.part"
            mv "$archive$suffix.part" "$archive$suffix"
        fi
    done
    sha512sum -c "$archive.sha512sum"
    if [ ! -d "$module-trinity-14.1.7" ]; then
        tar -xJf "$archive" --no-same-owner
    fi
done
