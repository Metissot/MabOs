#!/usr/bin/env python3
"""Entradas separadas para ISO Trinity; no modifica la receta MATE."""
import pathlib
import shutil
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--variant", choices=("trinity1", "trinity2"), default="trinity1")
args = parser.parse_args()

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / ".work/trinity"
DEST = BASE / ("iso-project" if args.variant == "trinity1" else "iso-project-trinity2")
if DEST.exists():
    raise SystemExit(f"Se conserva el proyecto existente: {DEST}")
for name in ("config", "overlay", "profiles", "scripts"):
    shutil.copytree(ROOT / name, DEST / name, symlinks=True)
shutil.copytree(ROOT / "experiments/trinity/iso-overlay",
                DEST / "overlay", dirs_exist_ok=True)
shutil.copy2(BASE / "oasis.png", DEST / "overlay/etc/mabos/artwork/oasis.png")
(DEST / "config/version").write_text(f"0.1.0-{args.variant}\n")
packages = []
for line in (ROOT / "config/packages.txt").read_text().splitlines():
    name = line.strip()
    if not name or name.startswith("#"):
        continue
    if (name.startswith("mate-") and name not in ("mate-themes", "mate-polkit")):
        continue
    if name in ("caja", "marco", "dconf"):
        continue
    packages.append(name)
packages += ["mabos-trinity-experimental", "bash", "grep", "xrdb", "xsetroot", "iceauth"]
(DEST / "config/packages.txt").write_text("\n".join(dict.fromkeys(packages)) + "\n")
profile = DEST / "profiles/mkimg.mabos.sh"
text = profile.read_text().replace("Alpine, OpenRC y MATE", "Alpine, OpenRC y Trinity")
text = text.replace('title="MabOs"', 'title="MabOs Trinity experimental"')
text = text.replace(" - Oasis", " - Trinity experimental")
profile.write_text(text)
build = DEST / "scripts/build-alpine.sh"
text = build.read_text().replace(
    "apk add --simulate $packages",
    "apk --repository /work/repository add --simulate $packages")
text = text.replace(
    "--repository https://dl-cdn.alpinelinux.org/alpine/v3.24/community \\",
    "--repository https://dl-cdn.alpinelinux.org/alpine/v3.24/community \\\n"
    "    --repository /work/repository \\")
build.write_text(text)
repo = BASE / "repository/mabos-trinity-packaging/x86_64"
if not (repo / "APKINDEX.tar.gz").is_file():
    raise SystemExit("Falta el repositorio firmado del bundle Trinity")
shutil.copytree(repo, DEST / "repository/x86_64")
keys = ROOT / ".work/alpine/root/.abuild"
for name in ("mabos-live.rsa", "mabos-live.rsa.pub"):
    target = DEST / ".work/alpine/root/.abuild" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(keys / name, target)
public = DEST / "overlay/etc/apk/keys/mabos-live.rsa.pub"
public.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(keys / "mabos-live.rsa.pub", public)
archive = ".work/alpine-minirootfs-3.24.4-x86_64.tar.gz"
shutil.copy2(ROOT / archive, DEST / archive)
source = DEST / ".work/sources/aports.tar.gz"
source.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(ROOT / ".work/sources/aports.tar.gz", source)
for name in ("logs", "dist"):
    (DEST / name).mkdir()
for name in ("start-trinity", "mabos-welcome"):
    (DEST / "overlay/etc/mabos" / name).chmod(0o755)
(DEST / "overlay/etc/init.d/mabos-live").chmod(0o755)
print(DEST)
