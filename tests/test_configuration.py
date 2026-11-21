"""Comprobaciones estáticas: no sustituyen una prueba de arranque."""
import configparser
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ConfigurationTests(unittest.TestCase):
    def test_shell_syntax(self):
        files = list((ROOT / "scripts").glob("*.sh"))
        files += list((ROOT / "profiles").glob("*.sh"))
        files += [ROOT / "overlay/etc/init.d/mabos-live"]
        for path in files:
            shell = "bash" if path.read_text().splitlines()[0] == "#!/bin/bash" else "sh"
            with self.subTest(path=path):
                subprocess.run([shell, "-n", str(path)], check=True)

    def test_packages_unique_and_required(self):
        packages = [
            line.strip()
            for line in (ROOT / "config/packages.txt").read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        self.assertEqual(len(packages), len(set(packages)))
        for package in (
            "alpine-base", "mate-session-manager", "lightdm", "firefox-esr",
            "networkmanager-wifi", "pulseaudio", "elogind", "polkit-elogind",
            "evince", "celluloid", "dbus-x11", "openssl", "chrony",
        ):
            self.assertIn(package, packages)
        self.assertNotIn("openssh", packages)

    def test_autologin_matches_live_user(self):
        config = configparser.ConfigParser()
        config.read(ROOT / "overlay/etc/lightdm/lightdm.conf")
        self.assertEqual(config["Seat:*"]["autologin-user"], "live")
        self.assertEqual(config["Seat:*"]["autologin-session"], "mate")
        service = (ROOT / "overlay/etc/init.d/mabos-live").read_text()
        self.assertIn("before lightdm display-manager", service)
        self.assertIn("passwd -l root", service)

    def test_no_automatic_disk_writes(self):
        files = list((ROOT / "overlay").rglob("*"))
        files += list((ROOT / "profiles").glob("*.sh"))
        for path in files:
            if path.is_file():
                content = path.read_text()
                for forbidden in ("setup-disk", "mkfs.", "dd if=", "sfdisk /dev/"):
                    with self.subTest(path=path, forbidden=forbidden):
                        self.assertNotIn(forbidden, content)


if __name__ == "__main__":
    unittest.main()
