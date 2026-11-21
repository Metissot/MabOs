#!/bin/sh
# Se ejecuta mediante el Alpine que ya contiene QEMU; no escribe sus recetas.
set -eu
BASE=/work/.work/trinity/vm
[ -f "$BASE/test-root.ext4" ]
exec timeout 360 qemu-system-x86_64 \
    -enable-kvm -m 1536 -smp 2 -display none -monitor none \
    -serial stdio -no-reboot \
    -kernel "$BASE/vmlinuz-lts" -initrd "$BASE/initramfs-lts" \
    -append "root=/dev/vda rootfstype=ext4 rw console=ttyS0 init=/usr/local/libexec/trinity-lab/vm-init.sh" \
    -drive "file=$BASE/test-root.ext4,format=raw,if=virtio" \
    -netdev user,id=net0,ipv6=off -device virtio-net-pci,netdev=net0 \
    -audiodev driver=none,id=audio0 \
    -device ich9-intel-hda -device hda-duplex,audiodev=audio0
