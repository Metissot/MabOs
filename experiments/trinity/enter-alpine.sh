#!/bin/sh
# Laboratorio TQt separado del constructor de ISO.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
ROOT="$PROJECT/.work/trinity/rootfs"
ARCHIVE="$PROJECT/.work/alpine-minirootfs-3.24.4-x86_64.tar.gz"
if [ "${1:-}" = "--inside" ] || [ "${1:-}" = "--inside-isolated" ]; then
    mode=$1
    shift
    mount --make-rprivate /
    mount --bind "$PROJECT" "$ROOT/work"
    mount --rbind /dev "$ROOT/dev"
    if [ "$mode" = "--inside-isolated" ]; then
        mount -t proc -o ro,nosuid,nodev,noexec proc "$ROOT/proc"
    else
        mount --rbind /proc "$ROOT/proc"
        mount -o remount,bind,ro "$ROOT/proc"
    fi
    exec chroot "$ROOT" /usr/bin/env -i HOME=/root \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        LC_ALL=C TERM="${TERM:-dumb}" \
        /bin/sh -c 'cd /work/.work/trinity; exec "$@"' sh "$@"
fi
[ "$(uname -m)" = x86_64 ]
printf '%s  %s\n' \
    cdaa38cb8de3537967ee5b6c9b6cd00cc962da2b018e6eea48696bb274923012 \
    "$ARCHIVE" | sha256sum -c -
if [ ! -x "$ROOT/bin/busybox" ]; then
    mkdir -p "$ROOT"
    tar --extract --gzip --no-same-owner --file "$ARCHIVE" --directory "$ROOT"
fi
mkdir -p "$ROOT/work" "$ROOT/dev" "$ROOT/proc"
cp /etc/resolv.conf "$ROOT/etc/resolv.conf"
if [ "${1:-}" = "--isolated-session" ]; then
    shift
    exec unshare --user --map-root-user --mount --pid --fork --kill-child --net \
        /bin/sh "$0" --inside-isolated "$@"
fi
exec unshare --user --map-root-user --mount /bin/sh "$0" --inside "$@"
