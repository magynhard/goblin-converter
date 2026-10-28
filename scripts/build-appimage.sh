#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
[[ "$(uname -m)" == x86_64 ]] || { printf '%s\n' 'AppImage builds currently require an x86_64 host.' >&2; exit 1; }
version="$(python3 scripts/packaging.py version)"
mkdir -p dist
image=goblin-converter-appimage-builder
docker build --platform linux/amd64 --file packaging/appimage/Dockerfile --tag "$image" .
docker run --rm --platform linux/amd64 \
    --env OUTPUT_UID="$(id -u)" --env OUTPUT_GID="$(id -g)" \
    --volume "$root/dist:/output" "$image"

# Test the actual artifact without the builder's installed conversion libraries.
docker run --rm --network=none --workdir /tmp \
    --volume "$root/dist:/packages:ro" \
    --volume "$root/scripts/test-conversion.sh:/test-conversion.sh:ro" \
    --env PACKAGE_NAME="Goblin_Converter-${version}-x86_64.AppImage" \
    --entrypoint bash ubuntu:26.04 -c '
        set -euo pipefail
        "/packages/$PACKAGE_NAME" --appimage-extract > /dev/null
        export APPDIR="$PWD/squashfs-root" LD_LIBRARY_PATH="$PWD/squashfs-root/usr/lib"
        source "$APPDIR/apprun-hooks/linuxdeploy-plugin-gtk.sh"
        bash /test-conversion.sh
    '
