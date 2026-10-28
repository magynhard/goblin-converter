#!/usr/bin/env python3
"""Pinned inputs for AppImage and local Flatpak builds (Python 3.12+, PyYAML)."""

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import tarfile
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_ID = "de.magynhard.GoblinConverter"
PINS = json.loads((ROOT / "packaging/sources.json").read_text())
GS_OPTIONS = ["--disable-cups", "--disable-gtk", "--disable-dbus", "--without-x", "--without-tesseract", "--without-libidn"]
IM_OPTIONS = ["--disable-static", "--disable-openmp", "--without-modules", "--without-perl", "--without-x", "--without-magick-plus-plus", "--with-gslib=no", "--with-jpeg=yes", "--with-png=yes", "--with-tiff=yes", "--with-webp=yes"]


def verify(root=None):
    import yaml

    root = ROOT if root is None else root
    shard = yaml.safe_load((root / "shard.yml").read_text())
    for name, dependency in shard["dependencies"].items():
        url = dependency.get("git") or f"https://github.com/{dependency['github']}.git"
        if url.lower() != PINS["shards"][name]["url"].lower():
            raise ValueError(f"Packaging source for {name} differs from shard.yml")
    # shard.lock is deliberately ignored in this repository. CI and fresh clones
    # use the committed packaging pins without needing a local shards install.
    lock_path = root / "shard.lock"
    if lock_path.exists():
        lock = yaml.safe_load(lock_path.read_text())["shards"]
        if set(lock) != set(PINS["shards"]):
            raise ValueError("Packaging shard set differs from shard.lock")
        for name, source in PINS["shards"].items():
            if str(lock[name]["version"]) != source["version"] or lock[name]["git"].lower() != source["url"].lower():
                raise ValueError(f"Packaging pin for {name} differs from shard.lock")
    for source in PINS["shards"].values():
        if not re.fullmatch(r"[a-f0-9]{40}", source["commit"]):
            raise ValueError("Invalid immutable shard commit")
    version = str(shard["version"])
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?", version):
        raise ValueError("Expected a semantic application version")
    component = ET.parse(root / f"data/{APP_ID}.metainfo.xml").getroot()
    release = component.find("releases/release")
    if component.findtext("id") != APP_ID or release is None or release.get("version") != version:
        raise ValueError("AppStream ID/release version differs from the application")
    return version


def download(source, cache):
    cache.mkdir(parents=True, exist_ok=True)
    path = cache / source["sha256"]
    if not path.exists():
        temporary = path.with_suffix(".part")
        subprocess.run(["curl", "--fail", "--location", "--retry", "3", "--silent", "--show-error", source["url"], "-o", str(temporary)], check=True)
        with temporary.open("rb") as stream:
            if hashlib.file_digest(stream, "sha256").hexdigest() != source["sha256"]:
                temporary.unlink()
                raise ValueError(f"SHA-256 mismatch: {source['url']}")
        temporary.replace(path)
    with path.open("rb") as stream:
        if hashlib.file_digest(stream, "sha256").hexdigest() != source["sha256"]:
            raise ValueError(f"SHA-256 mismatch: {source['url']}")
    return path


def extract(source, destination, cache):
    if destination.exists():
        marker = destination / ".source-sha256"
        if not marker.exists() or marker.read_text().strip() != source["sha256"]:
            raise ValueError(f"Remove the outdated generated directory: {destination}")
        return
    archive = download(source, cache)
    with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
        with tarfile.open(archive) as tar:
            tar.extractall(temporary, filter="data")
        roots = list(Path(temporary).iterdir())
        if len(roots) != 1 or not roots[0].is_dir():
            raise ValueError("Unexpected source archive layout")
        shutil.move(str(roots[0]), destination)
    (destination / ".source-sha256").write_text(source["sha256"] + "\n")


def fetch_tools(destination):
    if platform.machine() != "x86_64":
        raise ValueError("AppImage builds currently target native x86_64 only")
    destination.mkdir(parents=True, exist_ok=True)
    cache = destination / ".downloads"
    extract(PINS["crystal"]["x86_64"], destination / "crystal", cache)
    for key, filename in (("linuxdeploy", "linuxdeploy.AppImage"), ("gtk_plugin", "linuxdeploy-plugin-gtk.sh"), ("appimage_runtime", "runtime-x86_64")):
        target = destination / filename
        shutil.copyfile(download(PINS[key], cache), target)
        target.chmod(0o755)


def fetch_shards(destination):
    verify()
    destination.mkdir(parents=True, exist_ok=True)
    for name, source in PINS["shards"].items():
        target = destination / name
        if target.exists():
            revision = subprocess.check_output(["git", "-C", str(target), "rev-parse", "HEAD"], text=True).strip()
            if revision != source["commit"]:
                raise ValueError(f"Unexpected revision in {target}; use an empty generated directory")
            continue
        target.mkdir()
        subprocess.run(["git", "init", "--quiet", str(target)], check=True)
        subprocess.run(["git", "-C", str(target), "fetch", "--quiet", "--depth=1", source["url"], source["commit"]], check=True)
        subprocess.run(["git", "-C", str(target), "checkout", "--quiet", "--detach", "FETCH_HEAD"], check=True)


def build_converters(destination):
    """Build pinned conversion tools inside the AppImage builder image."""
    sources = ROOT / "build/converters"
    sources.mkdir(parents=True, exist_ok=True)
    for name, options, license_file in (("ghostscript", GS_OPTIONS, "LICENSE"), ("imagemagick", IM_OPTIONS, "LICENSE")):
        directory = sources / name
        extract(PINS[name], directory, sources / ".downloads")
        env = dict(os.environ, ac_cv_path_PSDelegate="gs")
        subprocess.run(["./configure", f"--prefix={destination}", *options], cwd=directory, env=env, check=True)
        subprocess.run(["make", f"-j{min(os.cpu_count() or 2, 8)}"], cwd=directory, check=True)
        subprocess.run(["make", "install"], cwd=directory, check=True)
        target = destination / f"share/licenses/{APP_ID}/{name}/{license_file}"
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(directory / license_file, target)
        if name == "ghostscript":
            shutil.copyfile(directory / "doc/COPYING", target.with_name("COPYING"))


def flatpak_manifest(destination):
    verify()
    destination.mkdir(parents=True, exist_ok=True)
    snapshot = destination / "source"
    if snapshot.exists():
        shutil.rmtree(snapshot)
    shutil.copytree(ROOT, snapshot, ignore=shutil.ignore_patterns(".git", ".idea", "lib", "bin", "build", "dist", ".flatpak-builder", "*.mo", "*.gresource", "__pycache__"))
    sources = [{"type": "dir", "path": str(snapshot)}]
    for architecture in ("x86_64", "aarch64"):
        sources.append({"type": "archive", **PINS["crystal"][architecture], "dest": "crystal", "strip-components": 2, "only-arches": [architecture]})
    for name, source in PINS["shards"].items():
        sources.append({"type": "git", "url": source["url"], "commit": source["commit"], "dest": f"lib/{name}"})
    modules = []
    for name, options, license_file in (("ghostscript", GS_OPTIONS, "LICENSE"), ("imagemagick", IM_OPTIONS, "LICENSE")):
        modules.append({
            "name": name, "buildsystem": "autotools", "no-autogen": True,
            "config-opts": options,
            "build-options": {"env": {"ac_cv_path_PSDelegate": "gs"}},
            "post-install": [f"install -Dm644 {license_file} /app/share/licenses/{APP_ID}/{name}/{license_file}"] + ([f"install -Dm644 doc/COPYING /app/share/licenses/{APP_ID}/{name}/COPYING"] if name == "ghostscript" else []),
            "sources": [{"type": "archive", **PINS[name]}],
        })
    manifest = {
        "app-id": APP_ID, "runtime": "org.gnome.Platform", "runtime-version": "51",
        "sdk": "org.gnome.Sdk", "separate-locales": False, "appstream-compose": False,
        "command": "goblin-converter",
        "x-local-development-only": "AI-assisted local packaging; not a Flathub submission manifest.",
        "finish-args": ["--socket=wayland", "--socket=fallback-x11", "--share=ipc", "--device=dri", "--filesystem=host"],
        "cleanup": ["/include", "/lib/pkgconfig", "/lib/*.la", "/share/man", "/share/doc"],
        "modules": [
            {"name": "bdw-gc", "buildsystem": "autotools", "config-opts": ["--disable-static"], "post-install": [f"install -Dm644 README.QUICK /app/share/licenses/{APP_ID}/bdw-gc/README.QUICK"], "sources": [{"type": "archive", **PINS["gc"]}]},
            *modules,
            {"name": "goblin-converter", "buildsystem": "simple", "build-options": {"prepend-path": "/run/build/goblin-converter/crystal/bin"}, "build-commands": ["bash scripts/offline-build.sh /app", "bash scripts/test-conversion.sh"], "sources": sources},
        ],
    }
    path = destination / f"{APP_ID}.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    print(path)


def licenses(prefix):
    destination = prefix / "share/licenses" / APP_ID
    for name in PINS["shards"]:
        for pattern in ("LICENSE*", "COPYING*"):
            for path in (ROOT / "lib" / name).glob(pattern):
                if path.is_file():
                    target = destination / "shards" / name / path.name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(path, target)
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / "packaging/sources.json", destination / "sources.json")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["verify", "version", "fetch-tools", "fetch-shards", "build-converters", "flatpak-manifest", "licenses"])
    parser.add_argument("destination", nargs="?", type=Path)
    args = parser.parse_args()
    if args.command in ("verify", "version"):
        print(verify())
    else:
        if args.destination is None:
            parser.error("destination is required")
        {"fetch-tools": fetch_tools, "fetch-shards": fetch_shards, "build-converters": build_converters, "flatpak-manifest": flatpak_manifest, "licenses": licenses}[args.command](args.destination.resolve())


if __name__ == "__main__":
    main()
