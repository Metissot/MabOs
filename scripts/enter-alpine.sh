#!/bin/sh
# Ejecuta herramientas Alpine sin sudo, dentro de un namespace de usuario.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=3.24.4
SHA256=cdaa38cb8de3537967ee5b6c9b6cd00cc962da2b018e6eea48696bb274923012
ROOT="$PROJECT/.work/alpine"
ARCHIVE="$PROJECT/.work/alpine-minirootfs-$VERSION-x86_64.tar.gz"

if [ "${1:-}" = "--inside" ]; then
    shift
    mount --make-rprivate /
    mount --bind "$PROJECT" "$ROOT/work"
    mount --rbind /dev "$ROOT/dev"
    mount --rbind /proc "$ROOT/proc"
    mount -o remount,bind,ro "$ROOT/proc"
    exec chroot "$ROOT" /usr/bin/env -i \
        HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        LC_ALL=C TERM="${TERM:-dumb}" /bin/sh -c 'cd /work; exec "$@"' sh "$@"
fi

[ "$(uname -m)" = x86_64 ] || { echo "Se necesita un anfitrión x86_64." >&2; exit 1; }
mkdir -p "$PROJECT/.work" "$PROJECT/logs" "$PROJECT/dist"
if [ ! -f "$ARCHIVE" ]; then
    curl --fail --location --retry 3 \
        "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/$(basename "$ARCHIVE")" \
        --output "$ARCHIVE.part"
    mv "$ARCHIVE.part" "$ARCHIVE"
fi
printf '%s  %s\n' "$SHA256" "$ARCHIVE" | sha256sum -c -
if [ ! -x "$ROOT/bin/busybox" ]; then
    mkdir -p "$ROOT"
    tar --extract --gzip --no-same-owner --file "$ARCHIVE" --directory "$ROOT"
fi
mkdir -p "$ROOT/work" "$ROOT/dev" "$ROOT/proc"
cp /etc/resolv.conf "$ROOT/etc/resolv.conf"
exec unshare --user --map-root-user --mount "$0" --inside "$@"
