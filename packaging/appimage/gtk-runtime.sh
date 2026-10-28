#!/usr/bin/env bash
# AppRun hook: preserve native Wayland and the system's Adwaita style.
export PATH="$APPDIR/usr/bin:$PATH"
export GTK_DATA_PREFIX="$APPDIR/usr"
export GTK_EXE_PREFIX="$APPDIR/usr"
export GTK_PATH="$APPDIR/usr/lib/gtk-4.0"
export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas"
export GI_TYPELIB_PATH="$APPDIR/usr/lib/girepository-1.0"
export GDK_PIXBUF_MODULE_FILE="$APPDIR/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export GDK_PIXBUF_MODULEDIR="$APPDIR/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders"
export GIO_MODULE_DIR="$APPDIR/usr/lib/gio/modules"
export XDG_DATA_DIRS="$APPDIR/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GOBLIN_LOCALE_DIR="$APPDIR/usr/share/locale"
export MAGICK_CONFIGURE_PATH="$APPDIR/usr/etc/ImageMagick-7"
for directory in "$APPDIR"/usr/share/ghostscript/*; do
    if [[ -d "$directory/lib" ]]; then
        export GS_LIB="$directory/Resource/Init:$directory/Resource/Font:$directory/lib"
    fi
done
