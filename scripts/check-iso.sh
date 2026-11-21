#!/bin/bash
set -euo pipefail
PROJECT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$PROJECT"
VERSION=${1:-$(cat config/version)}
[[ "$VERSION" =~ ^[a-zA-Z0-9._-]+$ ]] || { echo "Versión inválida." >&2; exit 1; }
ISO="mabos-$VERSION-x86_64.iso"
(cd dist && sha256sum -c "$ISO.sha256")
mkdir -p ".work/iso-check/$VERSION" logs
scripts/enter-alpine.sh /bin/sh -c '
    set -e
    iso="$1"
    dest="$2"
    xorriso -indev "$iso" \
        -report_el_torito plain -report_system_area plain
    xorriso -osirrox on -overwrite on \
        -indev "$iso" \
        -extract /mabos.apkovl.tar.gz "$dest/mabos.apkovl.tar.gz" \
        -extract /apks/x86_64/APKINDEX.tar.gz "$dest/APKINDEX.tar.gz" \
        -extract /boot/grub/grub.cfg "$dest/grub.cfg" \
        -extract /boot/syslinux/syslinux.cfg "$dest/syslinux.cfg" \
        -extract /boot/initramfs-lts "$dest/initramfs-lts"
' sh "/work/dist/$ISO" "/work/.work/iso-check/$VERSION" \
    2>&1 | tee "logs/iso-structure-$VERSION.txt"
python3 scripts/check-overlay.py ".work/iso-check/$VERSION/mabos.apkovl.tar.gz"
python3 scripts/package-manifest.py ".work/iso-check/$VERSION/APKINDEX.tar.gz" \
    "dist/mabos-$VERSION-packages.tsv"
stat -c 'Initramfs: %s bytes' ".work/iso-check/$VERSION/initramfs-lts"
