#!/bin/sh
# Solo para el disco de pruebas propio y con QEMU detenido.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
IMAGE="$PROJECT/.work/trinity/vm/test-root.ext4"
[ -f "$IMAGE" ]
# Reproduce el diario antes de modificar offline un disco apagado con -f.
status=0
/usr/sbin/e2fsck -f -p "$IMAGE" || status=$?
[ "$status" -le 1 ] || exit "$status"
for script in vm-init.sh vm-session.sh; do
    target="/usr/local/libexec/trinity-lab/$script"
    /usr/sbin/debugfs -w -R "rm $target" "$IMAGE"
    /usr/sbin/debugfs -w -R "write $PROJECT/experiments/trinity/$script $target" "$IMAGE"
    /usr/sbin/debugfs -w -R "set_inode_field $target mode 0100755" "$IMAGE"
done
