#!/bin/sh
set -eu
hostname=${1:?Falta el hostname}
inputs=${MABOS_INPUTS:-/work}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/etc/apk"
cp -a "$inputs/overlay/." "$tmp/"
version=$(cat "$inputs/config/version")
case "$version" in *[!a-zA-Z0-9._-]*|'') echo "Versión inválida" >&2; exit 1;; esac
for file in etc/os-release etc/issue etc/motd etc/init.d/mabos-live etc/mabos/mabos-welcome; do
    sed -i "s/@MABOS_VERSION@/$version/g" "$tmp/$file"
done
printf '%s\n' "$hostname" > "$tmp/etc/hostname"
sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$inputs/config/packages.txt" > "$tmp/etc/apk/world"
printf '%s\n' \
    https://dl-cdn.alpinelinux.org/alpine/v3.24/main \
    https://dl-cdn.alpinelinux.org/alpine/v3.24/community > "$tmp/etc/apk/repositories"
rc_add() {
    mkdir -p "$tmp/etc/runlevels/$2"
    ln -s "/etc/init.d/$1" "$tmp/etc/runlevels/$2/$1"
}
for service in devfs dmesg modloop udev udev-trigger udev-settle; do rc_add "$service" sysinit; done
for service in hwclock modules sysctl hostname bootmisc syslog; do
    rc_add "$service" boot
done
for service in dbus elogind wpa_supplicant networkmanager chronyd mabos-live lightdm; do rc_add "$service" default; done
for service in mount-ro killprocs; do rc_add "$service" shutdown; done
chmod 755 "$tmp/etc/init.d/mabos-live"
chmod 644 "$tmp/etc/doas.d/live.conf"
chown -R root:root "$tmp"
tar -c -C "$tmp" etc | gzip -9n > "$hostname.apkovl.tar.gz"
