"""Select Windows runtime files and resolve their PE DLL dependencies."""

import os
import re
import shutil
import subprocess
from pathlib import Path


def dll_imports(binary):
    # /IMPORTS includes ordinary and delay-loaded imports. Do not rely on the
    # build machine's PATH to silently supply redistributable DLLs.
    output = subprocess.check_output(
        ["dumpbin", "/nologo", "/imports", str(binary)], text=True, errors="replace")
    return re.findall(r"^\s+([^\s\\/]+\.dll)\s*$", output, re.MULTILINE | re.IGNORECASE)


def copy_dll_dependencies(seeds, destination, search_dirs, system_dir, imports=dll_imports):
    available = {}
    for directory in search_dirs:
        for dll in directory.glob("*.dll"):
            available.setdefault(dll.name.lower(), dll)
    system_names = {path.name.lower() for path in system_dir.glob("*.dll")}
    destination.mkdir(parents=True, exist_ok=True)
    pending = list(seeds)
    visited = set()
    while pending:
        binary = pending.pop()
        key = binary.name.lower()
        if key in visited:
            continue
        visited.add(key)
        for name in imports(binary):
            key = name.lower()
            if key.startswith(("api-ms-win-", "ext-ms-")):
                continue
            source = available.get(key)
            if source is None:
                # MSVC DLLs may be installed globally on the runner but are not
                # part of a clean Windows installation. Require an app-local
                # copy, including the OpenMP runtime used by ImageMagick.
                if key in system_names and not re.match(r"(?:msvcp|msvcr|vcruntime|vcomp|concrt)\d", key):
                    continue
                raise ValueError(f"Unresolved DLL dependency: {binary.name} -> {name}")
            target = destination / source.name
            if not target.exists():
                shutil.copy2(source, target)
            pending.append(target)


def copy_gtk_data(gtk, destination, languages):
    # Retain runtime schemas, icon themes and dynamically loaded modules. GIRs,
    # headers, tools, builder schemas and introspection data are not needed by
    # the compiled Crystal bindings.
    for directory in ("etc/fonts", "share/fontconfig", "share/icons", "share/glib-2.0/schemas",
                      "lib/gdk-pixbuf-2.0", "lib/gio", "lib/gtk-4.0", "share/licenses"):
        source = gtk / directory
        if source.exists():
            shutil.copytree(source, destination / directory, dirs_exist_ok=True,
                            ignore=shutil.ignore_patterns("*.pdb", "*.lib", "*.exp", "*.la"))
    # Some existing application locale IDs use jp/kr; GTK uses ja/ko instead.
    language_codes = {language.split("_")[0] for language in languages} | {"en"}
    if "jp" in language_codes:
        language_codes.add("ja")
    if "kr" in language_codes:
        language_codes.add("ko")
    for catalog in (gtk / "share/locale").glob("*/LC_MESSAGES/*.mo"):
        if (catalog.parents[1].name.split("_")[0] in language_codes
                and catalog.stem in {"gtk40", "glib20", "gdk-pixbuf", "libadwaita"}):
            target = destination / catalog.relative_to(gtk)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(catalog, target)
    for resource in (gtk / "share/gtk-4.0/emoji").glob("*.gresource"):
        if resource.stem in language_codes:
            target = destination / resource.relative_to(gtk)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(resource, target)
    # Preserve legal notices even when dropping development documentation.
    for notice in (gtk / "share/doc").rglob("*"):
        if notice.is_file() and (notice.name.upper().startswith(("COPYING", "LICENSE", "NOTICE", "COPYRIGHT"))
                                 or "licenses" in {part.lower() for part in notice.parts}):
            target = destination / "share/licenses/gtk" / notice.relative_to(gtk / "share/doc")
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(notice, target)


def copy_converters(tools, destination):
    magick = destination / "tools/imagemagick"
    magick.mkdir(parents=True)
    shutil.copy2(tools / "imagemagick/magick.exe", magick)
    # The portable build has its codecs built in; keep configuration, profiles
    # and notices, but none of the seven redundant command-line executables.
    for source in (tools / "imagemagick").iterdir():
        if source.is_file() and (source.suffix.lower() in {".xml", ".icc", ".icm"}
                                or source.name.upper().startswith(("LICENSE", "NOTICE", "COPYING"))):
            shutil.copy2(source, magick / source.name)
    ghostscript = destination / "tools/ghostscript"
    (ghostscript / "bin").mkdir(parents=True)
    for filename in ("gswin64c.exe", "gsdll64.dll"):
        shutil.copy2(tools / "ghostscript/bin" / filename, ghostscript / "bin" / filename)
    for directory in ("Resource", "lib", "iccprofiles"):
        shutil.copytree(tools / "ghostscript" / directory, ghostscript / directory)
    notice = destination / "share/licenses/ghostscript/COPYING"
    notice.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(tools / "ghostscript/doc/COPYING", notice)


def assemble_runtime(tools, executable, redist, destination, languages,
                     system_dir=None, imports=dll_imports):
    if system_dir is None:
        system_dir = Path(os.environ["SystemRoot"]) / "System32"
    gtk = tools / "gtk"
    runtime_dirs = [redist, redist.parent / "Microsoft.VC143.OpenMP"]
    copy_gtk_data(gtk, destination, languages)
    copy_converters(tools, destination)
    (destination / "bin").mkdir(parents=True)
    shutil.copy2(executable, destination / "bin/goblin-converter.exe")
    # Module imports are not necessarily reachable from the executable's PE
    # imports: seed them explicitly, including the SVG pixbuf loader.
    modules = list((destination / "lib").rglob("*.dll"))
    copy_dll_dependencies([destination / "bin/goblin-converter.exe", *modules],
                          destination / "bin", [gtk / "bin", tools / "crystal", *runtime_dirs],
                          system_dir, imports)
    copy_dll_dependencies([destination / "tools/imagemagick/magick.exe"],
                          destination / "tools/imagemagick", [tools / "imagemagick", *runtime_dirs],
                          system_dir, imports)
    copy_dll_dependencies([destination / "tools/ghostscript/bin/gswin64c.exe",
                           destination / "tools/ghostscript/bin/gsdll64.dll"],
                          destination / "tools/ghostscript/bin", [tools / "ghostscript/bin", *runtime_dirs],
                          system_dir, imports)
