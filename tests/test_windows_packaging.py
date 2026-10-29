import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


@unittest.skipUnless(shutil.which("crystal"), "Crystal is required to test the patched generator")
class WindowsGeneratorTests(unittest.TestCase):
    def test_patched_generator_resolves_versioned_and_unversioned_libraries(self):
        # The pinned gi-crystal LibGen entry point, without GTK-dependent methods.
        # Apply the real release patch and execute it in Crystal, not a Python
        # approximation of its regular expressions.
        original = """module Generator
  class LibGen < FileGen
    def filename : String
      "lib_#{namespace.name.underscore}.cr"
    end

    private def libraries : Array(String)
      namespace.shared_libraries.map do |library|
        library[/lib([^\\/]+)(?:\\.so|-.+?\\.dll|\\..+?\\.dylib).*/, 1]
      end
    end
  end
end
"""
        expected = {
            "harfbuzz.dll": "harfbuzz",
            "harfbuzz-gobject.dll": "harfbuzz-gobject",
            "gio-2.0-0.dll": "gio-2.0",
            "gobject-2.0-0.dll": "gobject-2.0",
            "glib-2.0-0.dll": "glib-2.0",
            "gmodule-2.0-0.dll": "gmodule-2.0",
            "girepository-1.0-1.dll": "girepository-1.0",
            "girepository-2.0-0.dll": "girepository-2.0",
            "adwaita-1-0.dll": "adwaita-1",
            "cairo-gobject-2.dll": "cairo-gobject",
            "gtk-4-1.dll": "gtk-4",
            "gdk_pixbuf-2.0-0.dll": "gdk_pixbuf-2.0",
            "graphene-1.0-0.dll": "graphene-1.0",
            "gtksourceview-5-0.dll": "gtksourceview-5",
            "pango-1.0-0.dll": "pango-1.0",
            "pangocairo-1.0-0.dll": "pangocairo-1.0",
            "pangoft2-1.0-0.dll": "pangoft2-1.0",
            "rsvg-2-2.dll": "rsvg-2",
            "libgio-2.0-0.dll": "gio-2.0",
            "libgtk-4.so.1": "gtk-4",
            "libharfbuzz-gobject.so.0": "harfbuzz-gobject",
            "libgtk-4.1.dylib": "gtk-4",
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src/generator/lib_gen.cr"
            source.parent.mkdir(parents=True)
            source.write_text(original, newline="\n")
            subprocess.run([
                "git", "apply", "--unidiff-zero", "--include=src/generator/lib_gen.cr",
                str(ROOT / "packaging/patches/gi-crystal-windows.patch"),
            ], cwd=root, check=True)
            harness = root / "check.cr"
            harness.write_text("""class NamespaceFixture
  getter shared_libraries : Array(String)
  def initialize(@shared_libraries)
  end
end
module Generator
  class FileGen
    getter namespace : NamespaceFixture
    def initialize(@namespace)
    end
  end
end
require "./src/generator/lib_gen"
class Generator::LibGen
  def library_names
    libraries
  end
end
""" + f"names = {json.dumps(list(expected))}\n"
                + "puts Generator::LibGen.new(NamespaceFixture.new(names)).library_names.join(\"\\n\")\n")
            result = subprocess.run(["crystal", "run", str(harness)], cwd=root,
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), list(expected.values()))


if __name__ == "__main__":
    unittest.main()
