#!/bin/sh
# Preparación dentro del Alpine experimental; no crea ni modifica una ISO.
set -eu
BASE=/work/.work/trinity
mkdir -p "$BASE/vm" /usr/local/libexec/trinity-lab
install -m755 /work/experiments/trinity/vm-init.sh \
    /usr/local/libexec/trinity-lab/vm-init.sh
install -m755 /work/experiments/trinity/vm-session.sh \
    /usr/local/libexec/trinity-lab/vm-session.sh
kernel=$(ls /lib/modules | sort -V | tail -n 1)
[ -n "$kernel" ]
cp /boot/vmlinuz-lts "$BASE/vm/vmlinuz-lts"
mkinitfs -F "base virtio ext4" -o "$BASE/vm/initramfs-lts" "$kernel"
printf '%s\n' "$kernel" > "$BASE/vm/kernel-version.txt"
