#!/usr/bin/env bash
set -euo pipefail
cd /src
version="$(python3 scripts/packaging.py version)"
export DESTDIR=/work/AppDir
bash scripts/offline-build.sh /usr
desktop="$DESTDIR/usr/share/applications/de.magynhard.GoblinConverter.desktop"
icon="$DESTDIR/usr/share/icons/hicolor/scalable/apps/de.magynhard.GoblinConverter.svg"
desktop-file-validate "$desktop"
appstreamcli validate --no-net "$DESTDIR/usr/share/metainfo/de.magynhard.GoblinConverter.metainfo.xml"
install -m755 /usr/bin/magick /usr/bin/gs "$DESTDIR/usr/bin/"
cp -a /usr/etc "$DESTDIR/usr/"
cp -a /usr/share/ghostscript "$DESTDIR/usr/share/"
# Ghostscript embeds its initialization files, but its relocated resource search
# also needs a real Resource directory to resolve fonts without host paths.
cp -a /opt/goblin-converter/build/converters/ghostscript/Resource \
    "$DESTDIR/usr/share/ghostscript/$(gs --version)/"
cp -a /usr/share/ImageMagick-7 "$DESTDIR/usr/share/"
cp -a /usr/share/licenses/de.magynhard.GoblinConverter/. "$DESTDIR/usr/share/licenses/de.magynhard.GoblinConverter/"
export APPIMAGE_EXTRACT_AND_RUN=1 DEPLOY_GTK_VERSION=4
# Recent GTK packages no longer ship the optional gtk-4.0 module directory.
patch --forward --batch /opt/tools/linuxdeploy-plugin-gtk.sh < packaging/patches/gtk-plugin-optional-modules.patch
# linuxdeploy normally leaves these to the host. Bundle the matching text/font
# stack and conversion dependencies, including on minimal desktop installations.
extra_libraries=()
for library in libfontconfig.so.1 libfreetype.so.6 libharfbuzz.so.0 libfribidi.so.0 \
    libexpat.so.1 libz.so.1 libstdc++.so.6 libgcc_s.so.1 libcom_err.so.2 libgmp.so.10 \
    libX11.so.6 libX11-xcb.so.1 libxcb.so.1 libwayland-client.so.0; do
    extra_libraries+=(--library "/usr/lib/x86_64-linux-gnu/$library")
done
linuxdeploy.AppImage --appdir "$DESTDIR" --desktop-file "$desktop" --icon-file "$icon" \
    --executable "$DESTDIR/usr/bin/magick" --executable "$DESTDIR/usr/bin/gs" "${extra_libraries[@]}" --plugin gtk
install -m755 packaging/appimage/gtk-runtime.sh "$DESTDIR/apprun-hooks/linuxdeploy-plugin-gtk.sh"
mkdir -p "$DESTDIR/usr/lib/gio/modules" "$DESTDIR/usr/share/icons" /output
install -m755 /usr/lib/x86_64-linux-gnu/gio/modules/libdconfsettings.so "$DESTDIR/usr/lib/gio/modules/"
gio-querymodules "$DESTDIR/usr/lib/gio/modules"
cp -a /usr/share/icons/Adwaita "$DESTDIR/usr/share/icons/"
for language in $(<po/LINGUAS); do
    for domain in gtk40 libadwaita glib20; do
        catalog="/usr/share/locale/$language/LC_MESSAGES/$domain.mo"
        if [[ -f "$catalog" ]]; then
            install -Dm644 "$catalog" "$DESTDIR/usr/share/locale/$language/LC_MESSAGES/$domain.mo"
        fi
    done
done
for directory in /usr/share/doc/*; do
    if [[ -f "$directory/copyright" ]]; then
        install -Dm644 "$directory/copyright" "$DESTDIR/usr/share/licenses/de.magynhard.GoblinConverter/system/$(basename "$directory").copyright"
    fi
done
dpkg-query -W > "$DESTDIR/usr/share/licenses/de.magynhard.GoblinConverter/build-packages.txt"
# Check relocated conversion resources before assembling the single-file image.
(export APPDIR="$DESTDIR" LD_LIBRARY_PATH="$DESTDIR/usr/lib"; source packaging/appimage/gtk-runtime.sh; bash scripts/test-conversion.sh)
export LDAI_OUTPUT="/output/Goblin_Converter-${version}-x86_64.AppImage"
export LDAI_RUNTIME_FILE=/opt/tools/runtime-x86_64
linuxdeploy.AppImage --appdir "$DESTDIR" --library "$DESTDIR/usr/lib/gio/modules/libdconfsettings.so" --output appimage
cd /output
sha256sum "Goblin_Converter-${version}-x86_64.AppImage" > "Goblin_Converter-${version}-x86_64.AppImage.sha256"
chown -R "${OUTPUT_UID:-0}:${OUTPUT_GID:-0}" /output
