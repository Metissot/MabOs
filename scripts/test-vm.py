#!/usr/bin/env python3
"""Arranque aislado QEMU y captura; la captura requiere revisión humana.

No conecta discos del anfitrión. No considera un proceso QEMU activo como
prueba de que el escritorio funciona.
"""
import argparse
import configparser
import hashlib
import json
import pathlib
import socket
import subprocess
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]


class QMP:
    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.settimeout(10)
        self.sock.connect(str(path))
        self.stream = self.sock.makefile("rwb", buffering=0)
        self.stream.readline()  # saludo
        self.execute("qmp_capabilities")

    def execute(self, command, arguments=None):
        message = {"execute": command}
        if arguments:
            message["arguments"] = arguments
        self.stream.write(json.dumps(message).encode() + b"\n")
        while True:
            response = json.loads(self.stream.readline())
            if "error" in response:
                raise RuntimeError(response["error"])
            if "return" in response:
                return response["return"]

    def close(self):
        self.stream.close()
        self.sock.close()

    def key(self, code):
        self.execute("input-send-event", {"events": [
            {"type": "key", "data": {"down": True, "key": {"type": "qcode", "data": code}}},
            {"type": "key", "data": {"down": False, "key": {"type": "qcode", "data": code}}},
        ]})

    def type_text(self, text):
        punctuation = {
            " ": ("spc", False), "-": ("minus", False), "_": ("minus", True),
            "/": ("slash", False), ".": ("dot", False), ":": ("semicolon", True),
            ";": ("semicolon", False), "'": ("apostrophe", False),
            '"': ("apostrophe", True), ">": ("dot", True), "&": ("7", True),
            "|": ("backslash", True), "=": ("equal", False),
        }
        for char in text:
            if char.isascii() and char.isalnum():
                code, shift = char.lower(), char.isupper()
            else:
                code, shift = punctuation[char]
            if shift:
                self.execute("human-monitor-command", {"command-line": f"sendkey shift-{code} 1"})
                time.sleep(0.02)
            else:
                self.key(code)
            time.sleep(0.02)

    def run_application(self, command):
        # No depender del foco de la terminal ni de diálogos que aparezcan tarde.
        self.execute("human-monitor-command", {"command-line": "sendkey alt-f2"})
        time.sleep(1)
        self.execute("human-monitor-command", {"command-line": "sendkey ctrl-a 1"})
        time.sleep(0.05)
        self.type_text(command)
        self.key("ret")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("firmware", choices=["bios", "uefi"])
    parser.add_argument("--seconds", type=int, default=180)
    parser.add_argument("--memory", type=int, default=4096)
    parser.add_argument("--diagnostics", action="store_true",
                        help="Abrir terminal, recoger diagnóstico por serie y probar Firefox.")
    parser.add_argument("--branding", action="store_true",
                        help="Comprobar tema e iconos configurados y capturar la bienvenida.")
    parser.add_argument("--abiword", action="store_true",
                        help="Abrir AbiWord y escribir un documento de prueba en la VM.")
    parser.add_argument("--iso", type=pathlib.Path,
                        help="ISO dentro del proyecto; por defecto usa config/version.")
    parser.add_argument("--label", help="Etiqueta distinta para no sobrescribir otras evidencias.")
    parser.add_argument("--ventoy-disk", type=pathlib.Path,
                        help="Archivo regular de disco Ventoy dentro de .work, nunca un dispositivo.")
    parser.add_argument("--inspect-after", type=int,
                        help="Solo capturar tras N segundos; no declara que el sistema haya arrancado.")
    args = parser.parse_args()
    if args.branding or args.abiword:
        args.diagnostics = True
    name = args.label or f"vm-{args.firmware}"
    if not name or any(char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for char in name):
        parser.error("La etiqueta solo admite letras, números, guion y guion bajo.")
    work = ROOT / ".work"
    logs = ROOT / "logs"
    work.mkdir(exist_ok=True)
    logs.mkdir(exist_ok=True)
    qmp_path = work / f"{name}.qmp"
    if qmp_path.exists():
        raise SystemExit(f"Socket existente; comprobar la VM antes de retirarlo: {qmp_path}")
    version = (ROOT / "config/version").read_text().strip()
    iso = (args.iso or pathlib.Path(f"dist/mabos-{version}-x86_64.iso"))
    iso = (ROOT / iso).resolve()
    try:
        iso_relative = iso.relative_to(ROOT)
    except ValueError:
        parser.error("La ISO debe estar dentro del proyecto.")
    if not iso.is_file():
        raise SystemExit("Primero hay que compilar la ISO.")
    if args.inspect_after is not None and args.inspect_after <= 0:
        parser.error("--inspect-after debe ser positivo.")
    command = [
        str(ROOT / "scripts/enter-alpine.sh"), "qemu-system-x86_64",
        "-name", name, "-accel", "kvm", "-cpu", "host",
        "-m", str(args.memory), "-smp", "2",
        "-display", "none", "-vga", "std",
        "-boot", "order=d", "-cdrom", "/work/" + iso_relative.as_posix(),
        "-nic", "user,model=e1000",
        "-serial", f"file:/work/logs/{name}.serial.log",
        "-monitor", "none", "-no-reboot",
        "-qmp", f"unix:/work/.work/{name}.qmp,server=on,wait=off",
    ]
    if args.firmware == "uefi":
        command += ["-bios", "/usr/share/OVMF/OVMF.fd"]
    if args.ventoy_disk:
        disk = (ROOT / args.ventoy_disk).resolve()
        try:
            disk_relative = disk.relative_to(ROOT / ".work")
        except ValueError:
            parser.error("El disco virtual debe estar dentro de .work.")
        if not disk.is_file():
            parser.error("Se necesita un archivo regular, no un dispositivo.")
        # Retirar el CD: la ISO se lee exclusivamente desde el disco Ventoy.
        cdrom_index = command.index("-cdrom")
        del command[cdrom_index:cdrom_index + 2]
        command[command.index("order=d")] = "order=c"
        command += [
            "-drive", "file=/work/.work/" + disk_relative.as_posix() +
            ",format=raw,if=ide,snapshot=on",
        ]
    qmp = None
    with (logs / f"{name}.qemu.log").open("w") as log:
        started = time.monotonic()
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 30
            while not qmp_path.exists():
                if process.poll() is not None:
                    raise RuntimeError(f"QEMU terminó: revisar logs/{name}.qemu.log")
                if time.monotonic() >= deadline:
                    raise TimeoutError("QEMU no creó el socket QMP.")
                time.sleep(0.2)
            qmp = QMP(qmp_path)
            if args.inspect_after is not None:
                time.sleep(args.inspect_after)
                qmp.execute("screendump", {
                    "filename": f"/work/logs/{name}.png", "format": "png",
                })
                print(f"Inspección: logs/{name}.png; no es una validación de arranque.", flush=True)
                qmp.execute("quit")
                return
            print(f"VM {args.firmware}: esperando fin de OpenRC, máximo {args.seconds}s.", flush=True)
            serial = logs / f"{name}.serial.log"
            deadline = time.monotonic() + args.seconds
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f"QEMU terminó antes del arranque: revisar logs/{name}.qemu.log")
                if serial.exists() and "mabos login:" in serial.read_text(errors="replace"):
                    break
                time.sleep(1)
            else:
                qmp.execute("screendump", {
                    "filename": f"/work/logs/{name}-timeout.png", "format": "png",
                })
                raise TimeoutError(
                    "No apareció el prompt serie esperado; esto NO demuestra que el arranque "
                    "fallara (Ventoy puede omitirlo). Revisar la captura timeout."
                )
            login_seconds = time.monotonic() - started
            # El getty se inicia tras OpenRC; dar tiempo a LightDM y MATE.
            time.sleep(15)
            status = qmp.execute("query-status")
            qmp.execute("screendump", {
                "filename": f"/work/logs/{name}.png", "format": "png",
            })
            (logs / f"{name}.status.json").write_text(json.dumps(status, indent=2) + "\n")
            capture_seconds = time.monotonic() - started
            with iso.open("rb") as image:
                iso_sha256 = hashlib.file_digest(image, "sha256").hexdigest()
            timing = {
                "iso": iso_relative.as_posix(),
                "sha256": iso_sha256,
                "firmware": args.firmware,
                "memory_mib": args.memory,
                "vcpus": 2,
                "boot_medium": "ventoy-virtual-disk" if args.ventoy_disk else "virtual-cd",
                "ventoy_disk": str(args.ventoy_disk) if args.ventoy_disk else None,
                "openrc_login_seconds": round(login_seconds, 2),
                "capture_seconds": round(capture_seconds, 2),
                "note": "Tiempo hasta getty, no tiempo exacto de escritorio; incluye arranque QEMU y preparación del entorno.",
            }
            (logs / f"{name}.timing.json").write_text(json.dumps(timing, indent=2) + "\n")
            print(f"Captura: logs/{name}.png. Revisar antes de declarar éxito.", flush=True)
            if args.diagnostics:
                qmp.execute("human-monitor-command", {"command-line": "sendkey alt-f2"})
                time.sleep(1)
                qmp.type_text("mate-terminal")
                qmp.key("ret")
                time.sleep(3)
                command = (
                    "pactl info > /tmp/mabos-audio.log; "
                    "gsettings get org.mate.interface icon-theme > /tmp/mabos-appearance.log; "
                    "gsettings get org.mate.interface gtk-theme >> /tmp/mabos-appearance.log; "
                    "gsettings get org.mate.Marco.general theme >> /tmp/mabos-appearance.log; "
                    "gsettings get org.mate.panel toplevel-id-list >> /tmp/mabos-appearance.log; "
                    "gsettings get org.mate.panel object-id-list >> /tmp/mabos-appearance.log; "
                    "doas sh -c "
                    "'exec >/dev/ttyS0 2>&1; echo mabos-check-start; uname -r; "
                    "rc-status; free -h; nmcli device; ip route; "
                    "wget -q -O /dev/null https://alpinelinux.org && echo internet-ok; "
                    "cat /tmp/mabos-audio.log /tmp/mabos-appearance.log; firefox-esr --version; "
                    + ("abiword --version; " if args.abiword else "")
                    + "echo mabos-check-done'"
                )
                qmp.type_text(command)
                qmp.key("ret")
                deadline = time.monotonic() + 45
                serial = logs / f"{name}.serial.log"
                while time.monotonic() < deadline:
                    if serial.exists() and "mabos-check-done" in serial.read_text(errors="replace"):
                        break
                    time.sleep(1)
                else:
                    qmp.execute("screendump", {
                        "filename": f"/work/logs/{name}-diagnostic-error.png", "format": "png",
                    })
                    raise TimeoutError("No llegó el diagnóstico; revisar captura y registro serie.")
                if args.branding:
                    diagnostic = serial.read_text(errors="replace")
                    preferences = configparser.ConfigParser(interpolation=None)
                    preferences.read(ROOT / "overlay/etc/dconf/db/mabos.d/00-desktop")
                    interface = preferences["org/mate/desktop/interface"]
                    for expected in (interface["icon-theme"], interface["gtk-theme"],
                                     preferences["org/mate/marco/general"]["theme"]):
                        if expected not in diagnostic:
                            raise RuntimeError(f"La sesión no está usando la preferencia {expected}.")
                    if preferences.has_option("org/mate/panel/general", "default-layout"):
                        if "\n['top']\n" not in diagnostic.replace("\r", ""):
                            raise RuntimeError("La sesión no tiene solamente el panel superior.")
                    qmp.run_application("mabos-welcome")
                    time.sleep(10)
                    qmp.execute("screendump", {
                        "filename": f"/work/logs/{name}-welcome.png", "format": "png",
                    })
                    qmp.run_application("pkill -x zenity")
                    time.sleep(1)
                if args.abiword:
                    qmp.run_application("abiword")
                    time.sleep(10)
                    qmp.type_text("MabOs - prueba de documento")
                    qmp.key("ret")
                    qmp.type_text("Documento de prueba creado en AbiWord.")
                    qmp.execute("screendump", {
                        "filename": f"/work/logs/{name}-abiword.png", "format": "png",
                    })
                qmp.run_application("firefox-esr https://alpinelinux.org")
                time.sleep(20)
                qmp.execute("screendump", {
                    "filename": f"/work/logs/{name}-apps.png", "format": "png",
                })
                print(f"Diagnóstico: logs/{name}.serial.log; captura: logs/{name}-apps.png", flush=True)
            qmp.execute("quit")
        finally:
            if qmp:
                qmp.close()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=15)
            if qmp_path.exists():
                qmp_path.unlink()


if __name__ == "__main__":
    main()
