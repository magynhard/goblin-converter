#!/usr/bin/env python3
"""Build the Windows x64 NSIS installer (run with Python 3.12+ on Windows)."""

import argparse
import hashlib
import json
import os
import re
import stat
import shutil
import subprocess
import zipfile
from pathlib import Path

import packaging as inputs
from windows_payload import assemble_runtime

ROOT = inputs.ROOT
WORK = ROOT / "build/windows"
TOOLS = WORK / "tools"
SOURCE = WORK / "source"
PAYLOAD = WORK / "payload"
PINS = json.loads((ROOT / "packaging/windows/sources.json").read_text())


def run(*args, cwd=SOURCE, env=None):
    subprocess.run([str(arg) for arg in args], cwd=cwd, env=env, check=True)


def prepare():
    inputs.verify()
    TOOLS.mkdir(parents=True, exist_ok=True)
    for name in ("crystal", "gtk", "imagemagick", "ghostscript"):
        archive = inputs.download(PINS[name], WORK / "downloads")
        destination = TOOLS / name
        marker = destination / ".source-sha256"
        if marker.exists() and marker.read_text().strip() == PINS[name]["sha256"]:
            continue
        if destination.exists():
            shutil.rmtree(destination)
        destination.mkdir()
        if name in ("crystal", "gtk"):
            with zipfile.ZipFile(archive) as bundle:
                bundle.extractall(destination)
        else:
            run("7z", "x", "-y", f"-o{destination}", archive, cwd=ROOT)
        marker.write_text(PINS[name]["sha256"] + "\n")


def remove_tree(path):
    # Git's fetched objects can be read-only on Windows, including on rebuilds.
    def writable_retry(function, target, error):
        if not isinstance(error, PermissionError):
            raise error
        os.chmod(target, stat.S_IWRITE)
        function(target)

    shutil.rmtree(path, onexc=writable_retry)


def build():
    version = inputs.verify()
    tag = os.environ.get("RELEASE_TAG", "")
    if tag and tag.removeprefix("v") != version:
        raise ValueError("Release tag differs from shard.yml")
    # Build a fresh, isolated source tree; never patch the developer's lib/.
    if SOURCE.exists():
        remove_tree(SOURCE)
    shutil.copytree(ROOT, SOURCE, ignore=shutil.ignore_patterns(
        ".git", ".idea", "lib", "bin", "build", "dist", ".flatpak-builder",
        "__pycache__", "*.mo", "*.gresource", "shard.lock"))
    inputs.fetch_shards(SOURCE / "lib")
    for patch in ("gi-crystal-offline-version.patch", "gi-crystal-windows.patch"):
        run("git", "apply", "--unidiff-zero", ROOT / "packaging/patches" / patch,
            cwd=SOURCE / "lib/gi-crystal")
    # Share shard lookup across nested builds without symlinks/Developer Mode.
    default_path = subprocess.check_output(["crystal", "env", "CRYSTAL_PATH"], text=True).strip()
    os.environ["CRYSTAL_PATH"] = str(SOURCE / "lib") + os.pathsep + default_path
    (SOURCE / "bin").mkdir()
    run("crystal", "build", "src/generator/main.cr",
        "-o", SOURCE / "bin/gi-crystal.exe", cwd=SOURCE / "lib/gi-crystal")
    run(SOURCE / "bin/gi-crystal.exe", env=dict(os.environ, DEBUG="1"))
    run("crystal", "tool", "format", "--check", "src/", "spec/")
    run("crystal", "spec")
    run("crystal", "build", "src/goblin-converter.cr", "--release", "--no-debug",
        "--mcpu", "x86-64", "-o", SOURCE / "bin/goblin-converter.exe")

    if PAYLOAD.exists():
        shutil.rmtree(PAYLOAD)
    gtk = TOOLS / "gtk"
    redist = Path(os.environ["VCToolsRedistDir"]) / "x64/Microsoft.VC143.CRT"
    if not redist.is_dir():
        raise ValueError(f"MSVC x64 redistributable directory missing: {redist}")
    languages = (ROOT / "po/LINGUAS").read_text().split()
    assemble_runtime(TOOLS, SOURCE / "bin/goblin-converter.exe", redist, PAYLOAD, languages)
    run(gtk / "bin/glib-compile-schemas.exe", PAYLOAD / "share/glib-2.0/schemas")
    for language in languages:
        target = PAYLOAD / "share/locale" / language / "LC_MESSAGES/de.magynhard.GoblinConverter.mo"
        target.parent.mkdir(parents=True, exist_ok=True)
        source = ROOT / "po" / language / "LC_MESSAGES/de.magynhard.GoblinConverter.po"
        run(gtk / "bin/msgfmt.exe", source, "-o", target)
    icon = PAYLOAD / "share/icons/hicolor/scalable/apps/de.magynhard.GoblinConverter.svg"
    icon.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "data/icons/app-icon.svg", icon)
    run(TOOLS / "imagemagick/magick.exe", ROOT / "data/icons/app-icon-512.png",
        "-define", "icon:auto-resize=256,64,48,32,16", PAYLOAD / "app.ico")
    # Use the same notices as Linux, with the actual pinned shard sources.
    original_root = inputs.ROOT
    try:
        inputs.ROOT = SOURCE
        inputs.licenses(PAYLOAD)
    finally:
        inputs.ROOT = original_root
    shutil.copy2(ROOT / "packaging/windows/sources.json",
                 PAYLOAD / "share/licenses/de.magynhard.GoblinConverter/windows-sources.json")

    size = sum(path.stat().st_size for path in PAYLOAD.rglob("*") if path.is_file())
    print(f"Windows runtime payload: {size / 1024 ** 2:.1f} MiB", flush=True)

    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    output = dist / f"Goblin_Converter-{version}-windows-x86_64-setup.exe"
    nsis = shutil.which("makensis") or r"C:\Program Files (x86)\NSIS\makensis.exe"
    numeric = re.match(r"\d+\.\d+\.\d+", version)[0]
    run(nsis, f"/DVERSION={version}", f"/DNUMERIC_VERSION={numeric}",
        f"/DPAYLOAD={PAYLOAD}", f"/DOUTPUT={output}", ROOT / "packaging/windows/installer.nsi")
    with output.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    output.with_suffix(".exe.sha256").write_text(f"{digest}  {output.name}\n")
    print(f"Windows installer: {output.stat().st_size / 1024 ** 2:.1f} MiB", flush=True)
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("prepare", "build"))
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("Use a Windows x64 machine with VS2022, Python, 7-Zip and NSIS")
    {"prepare": prepare, "build": build}[args.command]()
