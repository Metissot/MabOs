#!/bin/sh
# Usar solo con QEMU detenido; debugfs abre el disco en modo de solo lectura.
set -eu
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
IMAGE="$PROJECT/.work/trinity/vm/test-root.ext4"
OUT="$PROJECT/logs/trinity/vm-results"
mkdir -p "$OUT"
/usr/sbin/debugfs -R 'ls -l /home/live/results' "$IMAGE" > "$OUT/files.txt" 2>&1
for name in session.log konsole.log pulse.log pulse-info.txt pulse-sinks.txt \
    typed-uid.txt windows.txt root-properties.txt processes.txt \
    dcop-clients.txt knotify-interface.txt desktop.xwd xvfb.log; do
    /usr/sbin/debugfs -R "dump /home/live/results/$name $OUT/$name" "$IMAGE" \
        >> "$OUT/extraction.log" 2>&1
done
