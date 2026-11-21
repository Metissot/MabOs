import gzip
import io
import pathlib
import runpy
import tarfile
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
manifest = runpy.run_path(str(ROOT / "scripts/package-manifest.py"))["manifest"]
validate = runpy.run_path(str(ROOT / "scripts/check-overlay.py"))["validate"]


def archive_member(name, content):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w") as tar:
        member = tarfile.TarInfo(name)
        member.size = len(content)
        tar.addfile(member, io.BytesIO(content))
    return gzip.compress(buffer.getvalue())


class ArtifactTests(unittest.TestCase):
    def test_manifest_reads_signed_concatenated_index(self):
        signature = archive_member(".SIGN.RSA.test.pub", b"test")
        index = archive_member(
            "APKINDEX",
            b"P:zeta\nV:1-r0\nA:x86_64\nL:MIT\n\n"
            b"P:alpha\nV:2-r1\nA:noarch\nL:GPL-2.0-only\n",
        )
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "APKINDEX.tar.gz"
            path.write_bytes(signature + index)
            self.assertEqual(manifest(path), [
                ("alpha", "2-r1", "noarch", "GPL-2.0-only"),
                ("zeta", "1-r0", "x86_64", "MIT"),
            ])

    def test_overlay_rejects_parent_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "bad.apkovl.tar.gz"
            path.write_bytes(archive_member("../bad", b"bad"))
            with self.assertRaisesRegex(ValueError, "Ruta insegura"):
                validate(path)

    def test_overlay_rejects_absolute_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "bad.apkovl.tar.gz"
            path.write_bytes(archive_member("/etc/bad", b"bad"))
            with self.assertRaisesRegex(ValueError, "Ruta insegura"):
                validate(path)
