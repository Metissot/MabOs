#!/bin/sh
set -eu
cd /work
APORTS_COMMIT=e15f85eaef7839e4970f79a067b818a266529c0b
APORTS_SHA256=6e9f5ffe2802ddb4ac49959ecead0ac267e2d23faf4e1b5ba827a58a5e18bd67
export MKSQUASHFS_OPTS="-processors 2 -mem 256M"
export SOURCE_DATE_EPOCH=1794614400
apk add abuild alpine-conf xorriso syslinux squashfs-tools mtools \
    grub-efi mkinitfs kmod openssl git curl tar
mkdir -p /usr/local/bin
install -m755 /work/scripts/scanelf-unwrapped.sh /usr/local/bin/scanelf
mkdir -p /work/.work/sources /root/.mkimage /root/.abuild
if [ ! -f /work/.work/sources/aports.tar.gz ]; then
    curl -fL --retry 3 \
        "https://codeload.github.com/alpinelinux/aports/tar.gz/$APORTS_COMMIT" \
        -o /work/.work/sources/aports.tar.gz.part
    mv /work/.work/sources/aports.tar.gz.part /work/.work/sources/aports.tar.gz
fi
printf '%s  %s\n' "$APORTS_SHA256" /work/.work/sources/aports.tar.gz | sha256sum -c -
if [ ! -f /work/.work/sources/aports/scripts/mkimage.sh ]; then
    mkdir -p /work/.work/sources/aports
    tar -xzf /work/.work/sources/aports.tar.gz --strip-components=1 \
        -C /work/.work/sources/aports "aports-$APORTS_COMMIT/scripts"
fi
# apk-tools 3 rechaza --no-chown/--usermode al inicializar una BD como root.
# En nuestro namespace somos root y fakeroot conserva los metadatos.
# Ajuste único sobre la copia local; no se alteran comprobaciones de firmas.
sed -i 's/add --initdb --no-chown/add --initdb/' \
    /work/.work/sources/aports/scripts/mkimage.sh
# Toda la construcción ya está bajo fakeroot; la llamada anidada del overlay
# no está soportada por esta versión.
sed -i 's/fakeroot "\$_script"/"\$_script"/' \
    /work/.work/sources/aports/scripts/mkimg.base.sh
if [ ! -f /root/.abuild/mabos-live.rsa ]; then
    openssl genrsa -out /root/.abuild/mabos-live.rsa 2048
    openssl rsa -in /root/.abuild/mabos-live.rsa -pubout \
        -out /root/.abuild/mabos-live.rsa.pub
    chmod 600 /root/.abuild/mabos-live.rsa
fi
export PACKAGER_PRIVKEY=/root/.abuild/mabos-live.rsa
export PACKAGER_PUBKEY=/root/.abuild/mabos-live.rsa.pub
cp "$PACKAGER_PUBKEY" /etc/apk/keys/
# Congelar las entradas: editar el proyecto no cambia una compilación activa.
input_digest=$(find config overlay profiles -type f -exec sha256sum {} \; \
    | LC_ALL=C sort | sha256sum | cut -d ' ' -f 1)
export MABOS_INPUTS="/work/.work/inputs/$input_digest"
if [ ! -f "$MABOS_INPUTS/.complete" ]; then
    mkdir -p "$MABOS_INPUTS"
    cp -a config overlay profiles "$MABOS_INPUTS/"
    # mkimage solo calcula el hash del generador: incluir también sus entradas.
    printf '\n# inputs-sha256: %s\n' "$input_digest" >> "$MABOS_INPUTS/profiles/genapkovl-mabos.sh"
    touch "$MABOS_INPUTS/.complete"
fi
version=$(cat "$MABOS_INPUTS/config/version")
case "$version" in *[!a-zA-Z0-9._-]*|'') echo "Versión inválida" >&2; exit 1;; esac
export MABOS_VERSION="$version"
cp "$MABOS_INPUTS/profiles/mkimg.mabos.sh" /root/.mkimage/
chmod +x "$MABOS_INPUTS/profiles/genapkovl-mabos.sh" \
    "$MABOS_INPUTS/overlay/etc/init.d/mabos-live"

# Fallar pronto si algún nombre de paquete no existe.
packages=$(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$MABOS_INPUTS/config/packages.txt")
apk update
apk add --simulate $packages > /work/logs/package-resolution.txt
apk --version > dist/build-info.txt
printf 'Alpine: %s\nAports: %s\n' "$(cat /etc/alpine-release)" "$APORTS_COMMIT" >> dist/build-info.txt
printf 'Inputs SHA-256: %s\n' "$input_digest" >> dist/build-info.txt
sha256sum "$MABOS_INPUTS/config/packages.txt" >> dist/build-info.txt
/bin/sh /work/.work/sources/aports/scripts/mkimage.sh \
    --tag "$version" --arch x86_64 --profile mabos \
    --outdir /work/dist --workdir /work/.work/mkimage \
    --repository https://dl-cdn.alpinelinux.org/alpine/v3.24/main \
    --repository https://dl-cdn.alpinelinux.org/alpine/v3.24/community \
    --hostkeys --checksum
cp dist/build-info.txt "dist/mabos-$version-build-info.txt"
