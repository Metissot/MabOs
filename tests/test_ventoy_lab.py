import pathlib
import runpy
import struct
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
LAB = runpy.run_path(str(ROOT / "scripts/make-ventoy-test-disk.py"))


class VentoyLabTests(unittest.TestCase):
    def test_mbr_partition_encoding(self):
        entry = LAB["partition"](0x80, 0x0C, 2048, 100000)
        self.assertEqual(len(entry), 16)
        values = struct.unpack("<B3sB3sII", entry)
        self.assertEqual(values[0], 0x80)
        self.assertEqual(values[2], 0x0C)
        self.assertEqual(values[-2:], (2048, 100000))

    def test_chs_bounds(self):
        self.assertEqual(LAB["chs"](0), bytes((0, 1, 0)))
        self.assertEqual(LAB["chs"](100000000), b"\xfe\xff\xff")

    def test_disk_creation_does_not_use_physical_installer(self):
        source = (ROOT / "scripts/make-ventoy-test-disk.py").read_text()
        self.assertIn('image.open("xb")', source)
        self.assertNotIn('subprocess.run(["Ventoy2Disk', source)
        self.assertNotIn('"/dev/', source)
