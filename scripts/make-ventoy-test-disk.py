#!/usr/bin/env python3
"""Crea Ventoy en un ARCHIVO regular de laboratorio, nunca en un dispositivo.

Usa boot/core.img y ventoy.disk.img de una distribución oficial verificada.
No ejecuta Ventoy2Disk ni utiliza loop devices, mount, sudo o discos físicos.
"""
import argparse
import json
import lzma
import pathlib
import struct
import subprocess
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
LAB = ROOT / ".work/ventoy-investigation"


def chs(lba):
    cylinder, remainder = divmod(lba, 255 * 63)
    head, sector = divmod(remainder, 63)
    if cylinder > 1023:
        return b"\xfe\xff\xff"
    return bytes((head, (sector + 1) | ((cylinder >> 2) & 0xC0), cylinder & 0xFF))


def partition(active, kind, start, length):
    return struct.pack("<B3sB3sII", active, chs(start), kind,
                       chs(start + length - 1), start, length)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", default="1.1.18")
    parser.add_argument("--default-iso", default="mabos-0.1.0-alpha2-x86_64.iso")
    args = parser.parse_args()
    if pathlib.Path(args.default_iso).name != args.default_iso:
        parser.error("--default-iso debe ser un nombre de archivo, sin directorios.")
    if not args.release or any(c not in "0123456789." for c in args.release):
        parser.error("Versión inválida.")
    source = LAB / f"ventoy-{args.release}"
    image = LAB / f"ventoy-{args.release}-test.img"
    if image.exists():
        parser.error(f"El archivo ya existe; no se sobrescribe: {image}")
    isos = [
        ROOT / "dist/mabos-0.1.0-alpha1-x86_64.iso",
        ROOT / "dist/mabos-0.1.0-alpha2-x86_64.iso",
    ]
    if not all(iso.is_file() for iso in isos):
        parser.error("Faltan las ISO alpha1/alpha2.")
    if args.default_iso not in {iso.name for iso in isos}:
        parser.error("La ISO predeterminada no está en la lista del laboratorio.")
    boot = bytearray((source / "boot/boot.img").read_bytes()[:512])
    core = lzma.decompress((source / "boot/core.img.xz").read_bytes())
    esp = lzma.decompress((source / "ventoy/ventoy.disk.img.xz").read_bytes())
    if len(boot) != 512 or len(esp) != 65536 * 512 or boot[-2:] != b"\x55\xaa":
        raise ValueError("Formato de los archivos oficiales inesperado.")
    sectors = 3 * 1024**3 // 512
    start1, length2 = 2048, 65536
    start2 = sectors - length2
    length1 = start2 - start1
    boot[384:400] = uuid.uuid4().bytes
    boot[440:444] = uuid.uuid4().bytes[:4]
    boot[446:462] = partition(0x80, 0x0C, start1, length1)
    boot[462:478] = partition(0, 0xEF, start2, length2)
    boot[478:510] = bytes(32)
    LAB.mkdir(exist_ok=True)
    with image.open("xb") as disk:
        disk.truncate(sectors * 512)
        disk.seek(0)
        disk.write(boot)
        disk.seek(512)
        disk.write(core[:2047 * 512])
        disk.seek(start2 * 512)
        disk.write(esp)
    config = LAB / "ventoy.json"
    config.write_text(json.dumps({"control": [
        {"VTOY_DEFAULT_IMAGE": "/" + args.default_iso},
        {"VTOY_MENU_TIMEOUT": "3"},
        {"VTOY_SECONDARY_BOOT_MENU": "0"},
    ]}, indent=2) + "\n")
    virtual_image = "/work/" + image.relative_to(ROOT).as_posix()
    fat = virtual_image + "@@" + str(start1 * 512)
    runner = str(ROOT / "scripts/enter-alpine.sh")
    subprocess.run([
        runner, "mformat", "-i", fat, "-F", "-h", "255", "-s", "63",
        "-T", str(length1), "-c", "64", "-H", str(start1), "-v", "Ventoy", "::",
    ], check=True)
    subprocess.run([runner, "mmd", "-i", fat, "::/ventoy"], check=True)
    subprocess.run([
        runner, "mcopy", "-i", fat, "/work/" + config.relative_to(ROOT).as_posix(),
        "::/ventoy/ventoy.json",
    ], check=True)
    for iso in isos:
        subprocess.run([
            runner, "mcopy", "-i", fat, "/work/" + iso.relative_to(ROOT).as_posix(), "::/",
        ], check=True)
    print(f"Disco VIRTUAL: {image}")
    print(f"Ventoy {args.release}, MBR/FAT32, modo normal, ISO {args.default_iso}")
    print("No se ha accedido a ningún dispositivo físico.")


if __name__ == "__main__":
    main()
