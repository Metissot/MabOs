#!/usr/bin/env python3
"""Convierte el índice real de la ISO en un manifiesto de paquetes y licencias."""
import pathlib
import sys
import tarfile


def manifest(index):
    with tarfile.open(index, "r:gz", ignore_zeros=True) as tar:
        data = tar.extractfile("APKINDEX").read().decode()
    packages = []
    for record in data.strip().split("\n\n"):
        fields = dict(line.split(":", 1) for line in record.splitlines() if ":" in line)
        if "P" in fields:
            packages.append(tuple(fields.get(key, "") for key in ("P", "V", "A", "L")))
    if not packages:
        raise ValueError("El índice no contiene paquetes.")
    return sorted(packages)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Uso: package-manifest.py APKINDEX.tar.gz DESTINO.tsv")
    rows = manifest(sys.argv[1])
    project = pathlib.Path(__file__).resolve().parents[1]
    required = {
        line.strip()
        for line in (project / "config/packages.txt").read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    missing = required - {row[0] for row in rows}
    if missing:
        sys.exit("Faltan paquetes del perfil en la ISO: " + ", ".join(sorted(missing)))
    target = pathlib.Path(sys.argv[2])
    target.write_text("paquete\tversion\tarquitectura\tlicencia\n" +
                      "".join("\t".join(row) + "\n" for row in rows))
    print(f"Manifiesto: {target} ({len(rows)} paquetes)")
