#!/bin/sh
# Ejecutar dentro del Alpine de herramientas. No instala el bundle allí.
set -eu
BASE=/work/.work/trinity
BUILD=/root/mabos-trinity-packaging/mabos-trinity-experimental
mkdir -p "$BUILD" "$BASE/repository"
cp /work/experiments/trinity/packaging/APKBUILD \
    "$BUILD/APKBUILD"
export PACKAGER_PRIVKEY=/root/.abuild/mabos-live.rsa
export PACKAGER_PUBKEY=/root/.abuild/mabos-live.rsa.pub
[ -f "$PACKAGER_PRIVKEY" ]
export REPODEST="$BASE/repository"
scanelf --recursive --nobanner --format '%S|%n' "$BASE/rootfs/opt" \
    > "$BASE/runtime-elf.txt"
awk -F '|' '
    NR == FNR { if ($1 != "" && $1 != "-") internal[$1]=1; next }
    {
        split($2, fields, " "); n=split(fields[1], libs, ",")
        for (i=1; i<=n; i++)
            if (libs[i] != "" && libs[i] != "-" && libs[i] !~ /^\// && !internal[libs[i]])
                print "so:" libs[i]
    }
' "$BASE/runtime-elf.txt" "$BASE/runtime-elf.txt" | sort -u \
    > "$BASE/runtime-dependencies.txt"
# abuild necesita localizar también las bibliotecas externas para sus metadatos.
apk add $(cat "$BASE/runtime-dependencies.txt") \
    || echo "APK devolvió errores; abuild comprobará los enlaces disponibles." >&2
export SOURCE_DATE_EPOCH=1794873600
cd "$BUILD"
abuild -F -d -P "$REPODEST"
