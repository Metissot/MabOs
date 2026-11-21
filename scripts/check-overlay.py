#!/usr/bin/env python3
"""Valida la configuración empaquetada sin extraer archivos al sistema."""
import pathlib
import sys
import tarfile


def validate(archive):
    with tarfile.open(archive, "r:gz") as tar:
        members = {member.name.removeprefix("./"): member for member in tar}
        for name, member in members.items():
            path = pathlib.PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError(f"Ruta insegura: {name}")
            if member.uid != 0 or member.gid != 0:
                raise ValueError(f"Propietario incorrecto: {name}")
        for level, services in {
            "sysinit": ("modloop", "udev", "udev-trigger", "udev-settle"),
            "default": ("dbus", "elogind", "networkmanager", "mabos-live", "lightdm"),
        }.items():
            for service in services:
                member = members[f"etc/runlevels/{level}/{service}"]
                assert member.issym(), member.name
                assert member.linkname == f"/etc/init.d/{service}", member.name
        for forbidden in ("sshd", "networking", "dhcpcd"):
            assert f"etc/runlevels/default/{forbidden}" not in members
        service = members["etc/init.d/mabos-live"]
        assert service.mode & 0o111, "El servicio live no es ejecutable"
        assert members["etc/doas.d/live.conf"].mode & 0o022 == 0
        world = tar.extractfile(members["etc/apk/world"]).read().decode().splitlines()
        project = pathlib.Path(__file__).resolve().parents[1]
        version = (project / "config/version").read_text().strip()
        release = tar.extractfile(members["etc/os-release"]).read().decode()
        assert f'VERSION="{version}"' in release, "Versión incorrecta en os-release"
        for name in (
            "etc/mabos/artwork/oasis.svg", "etc/mabos/artwork/dandelion.svg",
            "etc/mabos/artwork/mabos-wordmark.svg", "etc/mabos/mabos.layout",
            "etc/mabos/mabos-welcome", "etc/lightdm/lightdm-gtk-greeter.conf",
        ):
            assert name in members, f"Falta identidad visual: {name}"
        for member in members.values():
            if member.isfile():
                assert b"@MABOS_VERSION@" not in tar.extractfile(member).read(), member.name
        expected = [
            line.strip()
            for line in (project / "config/packages.txt").read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        assert world == expected, "world no coincide con packages.txt"
    print(f"Overlay correcto: {archive}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Uso: python3 scripts/check-overlay.py ARCHIVO.apkovl.tar.gz")
    validate(sys.argv[1])
