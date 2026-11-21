#!/bin/sh
# Ejecutar desde el anfitrión, sin ninguna sesión de laboratorio activa.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
ROOT="$PROJECT/.work/trinity/rootfs"
IMAGE="$PROJECT/.work/trinity/vm/test-root.ext4"
[ -f "$PROJECT/.work/trinity/vm/initramfs-lts" ]
[ ! -e "$IMAGE" ] || { echo "Se conserva el disco existente: $IMAGE" >&2; exit 1; }
used=$(du -sk "$ROOT" | awk '{print $1}')
size=$((used + used / 2 + 524288))
truncate -s "${size}K" "$IMAGE"
# Mapea el propietario del rootfs a root para obtener propietarios reales en VM.
exec unshare --user --map-root-user /usr/sbin/mkfs.ext4 \
    -F -m 0 -L trinity-lab -d "$ROOT" "$IMAGE"
