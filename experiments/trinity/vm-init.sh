#!/bin/sh
# PID 1 únicamente en el disco de prueba QEMU, nunca en el anfitrión.
export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/opt/trinity-experiment/bin:/opt/tqt-experiment/bin
export LD_LIBRARY_PATH=/opt/trinity-experiment/lib:/opt/tqt-experiment/lib
mount -o remount,rw /
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts /run /tmp
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /tmp
chmod 1777 /tmp
mkdir -p /var/tmp /tmp/.X11-unix /tmp/.ICE-unix
chmod 1777 /var/tmp /tmp/.X11-unix /tmp/.ICE-unix
exec > /dev/ttyS0 2>&1
echo MABOS_VM_INIT
hostname trinity-lab
modprobe virtio_net
modprobe snd_hda_intel
mdev -s
for group in audio video plugdev; do
    grep -q "^$group:" /etc/group || addgroup -S "$group"
done
id live >/dev/null 2>&1 || adduser -D -u 1000 -s /bin/sh live
addgroup live audio
addgroup live video
mkdir -p /home/live/results /run/user/1000
chown -R live:live /home/live /run/user/1000
chmod 700 /run/user/1000
if [ -d /dev/snd ]; then
    chgrp audio /dev/snd/*
    chmod 660 /dev/snd/*
fi
dbus-uuidgen --ensure=/etc/machine-id
# La instalación sin privilegios no pudo conservar este grupo del paquete.
chown root:messagebus /usr/libexec/dbus-daemon-launch-helper
chmod 4750 /usr/libexec/dbus-daemon-launch-helper
mkdir -p /run/dbus
dbus-daemon --system --fork
echo MABOS_SYSTEM_BUS
dbus-send --system --print-reply --dest=org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus.ListNames
ip link set lo up
ip link set eth0 up
timeout 30 udhcpc -i eth0 -n -q -t 5
echo MABOS_NETWORK
ip addr show eth0
ip route
curl --fail --location --max-time 30 https://alpinelinux.org/ -o /tmp/alpine.html \
    && echo MABOS_HTTPS_OK
echo MABOS_SOUND_CARD
cat /proc/asound/cards
su live -c '/bin/sh /usr/local/libexec/trinity-lab/vm-session.sh'
result=$?
echo "MABOS_SESSION_RESULT=$result"
sync
echo MABOS_VM_TEST_COMPLETE
# Apaga solo la máquina virtual; el anfitrión no comparte su PID namespace.
poweroff -f
