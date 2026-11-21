import configparser
import hashlib
import pathlib
import re
import subprocess
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


class OasisTests(unittest.TestCase):
    def test_background_unchanged_from_alpha2(self):
        background = ROOT / "overlay/etc/mabos/artwork/oasis.svg"
        self.assertEqual(
            hashlib.sha256(background.read_bytes()).hexdigest(),
            "3687eb5dadc2561f3667b4d9c3c45ad748185fcd731c98502f885c2f8b6af01f",
        )

    def test_artwork_is_local_svg(self):
        for name in ("oasis.svg", "dandelion.svg", "mabos-wordmark.svg"):
            path = ROOT / "overlay/etc/mabos/artwork" / name
            tree = ET.parse(path)
            with self.subTest(name=name):
                self.assertTrue(tree.getroot().tag.endswith("svg"))
                for node in tree.iter():
                    self.assertNotIn(node.tag.split("}")[-1], ("script", "foreignObject", "image"))
                    for key, value in node.attrib.items():
                        if key.endswith("href"):
                            self.assertTrue(value.startswith("#"), value)

    def test_theme_and_menu_use_dedicated_logo(self):
        settings = configparser.ConfigParser(interpolation=None)
        settings.read(ROOT / "overlay/etc/dconf/db/mabos.d/00-desktop")
        # Ruta verificada en org.mate.interface.gschema.xml de Alpine/MATE.
        self.assertEqual(settings["org/mate/desktop/interface"]["icon-theme"], "'Papirus-Light'")
        self.assertEqual(settings["org/mate/desktop/interface"]["gtk-theme"], "'YaruOk'")
        self.assertEqual(settings["org/mate/marco/general"]["theme"], "'YaruOk'")
        self.assertNotIn("org/mate/interface", settings)
        self.assertEqual(settings["org/mate/panel/menubar"]["icon-name"], "'mabos-logo'")
        self.assertEqual(
            settings["org/mate/desktop/background"]["picture-filename"],
            "'/etc/mabos/artwork/oasis.svg'",
        )
        self.assertIn("papirus-icon-theme", (ROOT / "config/packages.txt").read_text().splitlines())
        service = (ROOT / "overlay/etc/init.d/mabos-live").read_text()
        self.assertIn("/usr/share/icons/hicolor/scalable/places/mabos-logo.svg", service)
        self.assertNotIn("/start-here.svg", service)
        self.assertIn("/etc/mabos/artwork/dandelion.svg", service)
        self.assertNotIn("/etc/mabos/artwork/cactus.svg", service)

    def test_single_panel_with_window_list(self):
        layout = configparser.ConfigParser(interpolation=None)
        layout.read(ROOT / "overlay/etc/mabos/mabos.layout")
        panels = [section for section in layout.sections() if section.startswith("Toplevel ")]
        self.assertEqual(panels, ["Toplevel top"])
        self.assertEqual(layout["Object window-list"]["applet-iid"], "WnckletFactory::WindowListApplet")
        for section in layout.sections():
            if section.startswith("Object "):
                self.assertEqual(layout[section]["toplevel-id"], "top")
        settings = configparser.ConfigParser(interpolation=None)
        settings.read(ROOT / "overlay/etc/dconf/db/mabos.d/00-desktop")
        self.assertEqual(settings["org/mate/panel/general"]["default-layout"], "'mabos'")

    def test_abiword_without_extra_office_suite(self):
        packages = (ROOT / "config/packages.txt").read_text().splitlines()
        self.assertIn("abiword", packages)
        self.assertNotIn("libreoffice", packages)
        self.assertNotIn("gnumeric", packages)

    def test_version_is_safe(self):
        version = (ROOT / "config/version").read_text().strip()
        self.assertRegex(version, r"^[a-zA-Z0-9._-]+$")
        self.assertNotEqual(version, "0.1.0-alpha1")

    def test_boot_menus_keep_verification_and_diagnostics(self):
        script = (
            '. ./profiles/mkimg.mabos.sh; MABOS_VERSION=test; '
            'initfs_cmdline="modules=loop,squashfs quiet"; kernel_cmdline="hostname=mabos"; '
        )
        for function in ("syslinux_gen_config", "grub_gen_config"):
            with self.subTest(function=function):
                result = subprocess.run(
                    ["sh", "-c", script + function], cwd=ROOT,
                    text=True, capture_output=True, check=True,
                ).stdout
                self.assertIn("MabOs", result)
                self.assertIn("diagnostico", result)
                self.assertIn("debug_init", result)
                self.assertIn("/boot/intel-ucode.img", result)
                self.assertNotIn("modloop_verify=no", result)
        profile = (ROOT / "profiles/mkimg.mabos.sh").read_text()
        self.assertNotRegex(profile, re.escape('initfs_features="$initfs_features kms"'))

    def test_welcome_shell_syntax(self):
        self.assertIn(
            "GSK_RENDERER=cairo zenity",
            (ROOT / "overlay/etc/mabos/mabos-welcome").read_text(),
        )
        subprocess.run(
            ["sh", "-n", str(ROOT / "overlay/etc/mabos/mabos-welcome")], check=True,
        )
