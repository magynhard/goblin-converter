import hashlib
import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import yaml

ROOT = Path(__file__).resolve().parent.parent
VERSION = str(yaml.safe_load((ROOT / "shard.yml").read_text())["version"])
spec = importlib.util.spec_from_file_location("packaging_tools", ROOT / "scripts/packaging.py")
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)


class PackagingTests(unittest.TestCase):
    def source_fixture(self, directory):
        root = Path(directory)
        (root / "data").mkdir()
        shutil.copyfile(ROOT / "shard.yml", root / "shard.yml")
        shutil.copyfile(ROOT / f"data/{packaging.APP_ID}.metainfo.xml", root / f"data/{packaging.APP_ID}.metainfo.xml")
        return root

    def test_fresh_clone_needs_no_ignored_lockfile(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.source_fixture(directory)
            self.assertEqual(packaging.verify(root), VERSION)

    def test_release_version_mismatch_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.source_fixture(directory)
            metadata = root / f"data/{packaging.APP_ID}.metainfo.xml"
            metadata.write_text(metadata.read_text().replace(f'version="{VERSION}"', 'version="9.9.9"'))
            with self.assertRaisesRegex(ValueError, "release version"):
                packaging.verify(root)

    def test_changed_local_lockfile_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.source_fixture(directory)
            lock = {name: {"git": source["url"], "version": source["version"]} for name, source in packaging.PINS["shards"].items()}
            lock["gi-crystal"]["version"] = "99.0.0"
            (root / "shard.lock").write_text(yaml.safe_dump({"shards": lock}))
            with self.assertRaisesRegex(ValueError, "gi-crystal"):
                packaging.verify(root)

    def test_corrupt_cached_download_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            digest = hashlib.sha256(b"correct").hexdigest()
            (cache / digest).write_bytes(b"corrupt")
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                packaging.download({"url": "https://example.invalid/source", "sha256": digest}, cache)

    def test_manifest_has_offline_tools_and_conversion_dependencies(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.source_fixture(directory)
            (root / "build").mkdir()
            (root / "build/recursive-artifact").write_text("must not be copied")
            destination = root / "build/flatpak"
            with patch.object(packaging, "ROOT", root):
                packaging.flatpak_manifest(destination)
            manifest = json.loads((destination / f"{packaging.APP_ID}.json").read_text())
            modules = {module["name"]: module for module in manifest["modules"]}
            self.assertTrue({"ghostscript", "imagemagick", "bdw-gc"}.issubset(modules))
            for name in ("ghostscript", "imagemagick"):
                self.assertRegex(modules[name]["sources"][0]["sha256"], r"^[a-f0-9]{64}$")
            app = modules["goblin-converter"]
            self.assertIn("bash scripts/test-conversion.sh", app["build-commands"])
            self.assertTrue(all("shards install" not in command for command in app["build-commands"]))
            self.assertFalse((destination / "source/build").exists())
            self.assertIn("--filesystem=host", manifest["finish-args"])
            self.assertNotIn("--share=network", manifest["finish-args"])
            self.assertNotIn("--socket=system-bus", manifest["finish-args"])


if __name__ == "__main__":
    unittest.main()
