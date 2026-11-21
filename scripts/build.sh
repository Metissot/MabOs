#!/bin/bash
set -euo pipefail
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$PROJECT"
mkdir -p .work logs dist
exec 9>.work/build.lock
flock -n 9 || { echo "Ya hay una compilación de MabOs en curso." >&2; exit 1; }
LOG="logs/build-$(date -u +%Y%m%dT%H%M%SZ).log"
scripts/enter-alpine.sh /bin/sh -c '
    apk add fakeroot ca-certificates
    exec fakeroot /bin/sh /work/scripts/build-alpine.sh
' 2>&1 | tee "$LOG"
printf '\nRegistro: %s\n' "$LOG"
