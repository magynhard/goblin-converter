import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("windows_payload", ROOT / "scripts/windows_payload.py")
payload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(payload)


def fixture_file(root, name, contents="runtime"):
    path = root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(contents)
    return path


class WindowsPayloadTests(unittest.TestCase):
    def test_imports_include_delay_loaded_dlls(self):
        output = """Dump of file program.exe
  Section contains the following imports:
    GTK-4-1.dll
              Import Address Table
                        123 imported_function
  Section contains the following delay load imports:
    MSVCP140.dll
  Summary
"""
        with patch.object(subprocess, "check_output", return_value=output):
            self.assertEqual(payload.dll_imports(Path("program.exe")), ["GTK-4-1.dll", "MSVCP140.dll"])

    def test_dependency_closure_is_case_insensitive_and_excludes_unrelated_dlls(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = fixture_file(root, "app.exe")
            for name in ("gtk.dll", "helper.dll", "unused.dll"):
                fixture_file(root, "libraries/" + name)
            fixture_file(root, "system/kernel32.dll")
            dependencies = {
                "app.exe": ["GTK.DLL", "KERNEL32.dll", "api-ms-win-core-test.dll"],
                "gtk.dll": ["helper.dll"],
                "helper.dll": ["gtk.dll"],
            }
            payload.copy_dll_dependencies([executable], root / "output", [root / "libraries"],
                                          root / "system", lambda path: dependencies[path.name])
            self.assertEqual({path.name for path in (root / "output").iterdir()}, {"gtk.dll", "helper.dll"})

    def test_missing_dependency_fails_instead_of_using_build_host_path(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = fixture_file(root, "app.exe")
            with self.assertRaisesRegex(ValueError, "app.exe -> missing.dll"):
                payload.copy_dll_dependencies([executable], root / "output", [], root / "system",
                                              lambda path: ["missing.dll"])

    def test_msvc_runtime_is_not_assumed_to_be_part_of_windows(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = fixture_file(root, "magick.exe")
            fixture_file(root, "system/vcomp140.dll")
            with self.assertRaisesRegex(ValueError, "magick.exe -> VCOMP140.dll"):
                payload.copy_dll_dependencies([executable], root / "output", [], root / "system",
                                              lambda path: ["VCOMP140.dll"])

    def test_runtime_retains_modules_profiles_translations_and_notices_without_build_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tools = root / "tools"
            executable = fixture_file(root, "goblin-converter.exe")
            for name in (
                "gtk/bin/gtk.dll", "gtk/bin/rsvg.dll", "gtk/bin/unused-protobuf.dll",
                "gtk/lib/gdk-pixbuf-2.0/2.10.0/loaders/svg.dll",
                "gtk/lib/gdk-pixbuf-2.0/2.10.0/loaders/svg.pdb",
                "gtk/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache",
                "gtk/share/icons/Adwaita/index.theme",
                "gtk/share/glib-2.0/schemas/settings.gschema.xml",
                "gtk/share/locale/de/LC_MESSAGES/gtk40.mo",
                "gtk/share/locale/ja/LC_MESSAGES/gtk40.mo",
                "gtk/share/locale/ko/LC_MESSAGES/glib20.mo",
                "gtk/share/locale/zh_CN/LC_MESSAGES/libadwaita.mo",
                "gtk/share/locale/nl/LC_MESSAGES/gtk40.mo",
                "gtk/share/locale/de/LC_MESSAGES/gtksourceview-5.mo",
                "gtk/share/gir-1.0/Gtk.gir", "gtk/share/gtk-4.0/gtk4builder.rng",
                "gtk/share/gtk-4.0/emoji/de.gresource", "gtk/share/gtk-4.0/emoji/nl.gresource",
                "gtk/share/doc/gtk4/COPYING", "gtk/share/doc/gtk4/manual.pdf",
                "gtk/share/licenses/icons/COPYING", "gtk/etc/fonts/fonts.conf",
                "imagemagick/magick.exe", "imagemagick/identify.exe", "imagemagick/mogrify.exe",
                "imagemagick/sRGB.icc", "imagemagick/policy.xml", "imagemagick/delegates.xml",
                "imagemagick/LICENSE.txt", "imagemagick/NOTICE.txt", "imagemagick/ChangeLog.md",
                "ghostscript/bin/gswin64c.exe", "ghostscript/bin/gsdll64.dll",
                "ghostscript/bin/gsdll64.lib", "ghostscript/bin/gswin64.exe",
                "ghostscript/Resource/Init/gs_init.ps", "ghostscript/lib/Fontmap",
                "ghostscript/iccprofiles/default.icc", "ghostscript/doc/COPYING",
                "ghostscript/doc/manual.pdf", "ghostscript/examples/tiger.eps",
                "ghostscript/vcredist_x64.exe", "crystal/gc.dll", "crystal/LLVM-C.dll",
                "redist/vcruntime140.dll", "redist/unused.dll",
                "Microsoft.VC143.OpenMP/vcomp140.dll",
            ):
                fixture_file(tools, name)
            dependencies = {
                "goblin-converter.exe": ["GTK.DLL", "gc.dll"],
                "gtk.dll": ["vcruntime140.dll"],
                "svg.dll": ["rsvg.dll"],
                "magick.exe": ["vcruntime140.dll", "VCOMP140.dll"],
                "gswin64c.exe": ["gsdll64.dll"],
                "gsdll64.dll": ["vcruntime140.dll"],
            }
            target = root / "payload"
            payload.assemble_runtime(tools, executable, tools / "redist", target,
                                     ["de", "jp", "kr", "zh_CN"], root / "system",
                                     lambda path: dependencies.get(path.name, []))
            for name in ("bin/gtk.dll", "bin/gc.dll", "bin/rsvg.dll", "bin/vcruntime140.dll",
                         "lib/gdk-pixbuf-2.0/2.10.0/loaders/svg.dll",
                         "lib/gdk-pixbuf-2.0/2.10.0/loaders.cache",
                         "share/icons/Adwaita/index.theme", "etc/fonts/fonts.conf",
                         "share/glib-2.0/schemas/settings.gschema.xml",
                         "share/locale/de/LC_MESSAGES/gtk40.mo", "share/locale/ja/LC_MESSAGES/gtk40.mo",
                         "share/locale/ko/LC_MESSAGES/glib20.mo", "share/locale/zh_CN/LC_MESSAGES/libadwaita.mo",
                         "share/gtk-4.0/emoji/de.gresource", "share/licenses/gtk/gtk4/COPYING",
                         "share/licenses/icons/COPYING", "share/licenses/ghostscript/COPYING",
                         "tools/imagemagick/sRGB.icc", "tools/imagemagick/policy.xml",
                         "tools/imagemagick/delegates.xml", "tools/imagemagick/LICENSE.txt",
                         "tools/imagemagick/NOTICE.txt", "tools/ghostscript/Resource/Init/gs_init.ps",
                         "tools/imagemagick/vcomp140.dll",
                         "tools/ghostscript/lib/Fontmap", "tools/ghostscript/iccprofiles/default.icc",
                         "tools/ghostscript/bin/gsdll64.dll", "tools/ghostscript/bin/vcruntime140.dll"):
                self.assertTrue((target / name).is_file(), name)
            self.assertEqual({str(path.relative_to(target)).replace("\\", "/") for path in target.rglob("*.exe")},
                             {"bin/goblin-converter.exe", "tools/imagemagick/magick.exe", "tools/ghostscript/bin/gswin64c.exe"})
            for pattern in ("*.gir", "*.pdb", "*.lib", "*protobuf*", "LLVM*", "manual.pdf", "*.rng",
                            "gtksourceview-5.mo", "nl.gresource", "ChangeLog.md", "unused.dll"):
                self.assertFalse(list(target.rglob(pattern)), pattern)
            self.assertFalse((target / "share/locale/nl").exists())


if __name__ == "__main__":
    unittest.main()
