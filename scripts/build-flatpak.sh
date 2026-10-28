#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
version="$(python3 scripts/packaging.py version)"
python3 scripts/packaging.py flatpak-manifest "$root/build/flatpak"
mkdir -p dist
repo="${FLATPAK_REPO_DIR:-$root/build/flatpak/repo}"
if [[ ! -f "$repo/config" ]]; then
    mkdir -p "$repo"
    ostree --repo="$repo" init --mode=archive
fi
# Avoid a percentage-based reserve on large, mostly full developer disks.
ostree --repo="$repo" config set core.min-free-space-percent 0
ostree --repo="$repo" config set core.min-free-space-size 512MB
flatpak-builder --user --force-clean --disable-rofiles-fuse \
    "$root/build/flatpak/app" "$root/build/flatpak/de.magynhard.GoblinConverter.json"
bash scripts/flatpak-compose.sh "$root/build/flatpak/app/files"
flatpak build-export "$repo" "$root/build/flatpak/app"
flatpak build-bundle --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo "$repo" \
    "$root/dist/Goblin_Converter-${version}-$(uname -m).flatpak" de.magynhard.GoblinConverter
cd dist
sha256sum "Goblin_Converter-${version}-$(uname -m).flatpak" > "Goblin_Converter-${version}-$(uname -m).flatpak.sha256"
