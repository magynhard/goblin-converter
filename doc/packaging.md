# Linux packages

`make appimage` and `make flatpak` produce versioned packages and SHA-256 files
in `dist/`. Both packages include ImageMagick 7 and Ghostscript, application
translations, icons and third-party licenses. The conversion tools are built
from pinned sources; no host `magick` or `gs` installation is required to run
the packages.

## AppImage

Install Docker, Python 3.12+, PyYAML and Make. On Arch/Manjaro these packages are
`docker`, `python`, `python-yaml` and `make`. Start Docker and ensure your user
can access it, then run:

```sh
make appimage
./dist/Goblin_Converter-0.0.1-x86_64.AppImage
```

The builder targets x86_64 and uses Ubuntu 26.04. The app needs its newer
libadwaita for `Adw::ButtonRow`; Ubuntu 24.04's libadwaita is too old. The resulting
AppImage requires a compatible glibc (Ubuntu 26.04/glibc 2.43 or newer). GTK,
libadwaita, conversion libraries, configuration, fonts and Ghostscript resources
are bundled. Wayland and the desktop's light/dark style remain enabled.

Without a usable FUSE installation:

```sh
./dist/Goblin_Converter-0.0.1-x86_64.AppImage --appimage-extract-and-run
```

## Local Flatpak

Install Flatpak, flatpak-builder, OSTree, AppStream with `appstreamcli compose`,
Python 3.12+, PyYAML and Make. Install the GNOME runtime and SDK:

```sh
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.gnome.Platform//51 org.gnome.Sdk//51
make flatpak
flatpak install --user dist/Goblin_Converter-0.0.1-x86_64.flatpak
flatpak run de.magynhard.GoblinConverter
```

The generated manifest and source snapshot live in `build/flatpak/`. All
downloads are declared sources. The actual compiler, binding-generator and app
build is offline; it does not run `shards install`. All app translations are
included without requiring a separate Locale bundle. AppStream is composed with
64- and 128-pixel PNG icons before export.

The Flatpak requests Wayland, fallback X11, IPC and DRI for GTK rendering.
Read/write host-filesystem access supports drag and drop, typed source/target
paths, and saving converted files alongside their originals. It does not request
network access or host-command execution. ImageMagick and Ghostscript run inside
the sandbox.

The source pins include x86_64 and aarch64 Crystal archives; CI targets x86_64.
`FLATPAK_REPO_DIR` can select a different dedicated generated OSTree export
directory. Generated build trees, caches, export repositories and bundles are
ignored by Git.

These manifests are AI-assisted local build inputs. They are not Flathub
submission manifests; the workflow creates downloadable bundles and does not
submit or publish an application to Flathub.

## Verification and releases

```sh
make validate-metadata
make test-packaging
make test
make appimage
make flatpak
```

Each packaging build also runs a conversion smoke test: PNG to PDF, PDF to
monochrome Group4 PDF, and PDF back to PNG, JPEG, TIFF and WebP. This checks the
actual Ghostscript delegate and bundled codecs, not just executable availability.
The AppImage artifact is additionally extracted and conversion-tested inside a
clean Ubuntu container without ImageMagick, Ghostscript or GTK installed. This
ensures the builder's development libraries do not hide missing bundled files.

`packaging/sources.json` pins Crystal, the shards, ImageMagick, Ghostscript,
Boehm GC and AppImage tools. Downloads are verified against SHA-256 or immutable
Git commits. The ignored local `shard.lock` is checked when present; a fresh clone
uses the committed packaging pins directly. Keep those pins in sync when updating
dependencies. System libraries follow Ubuntu/SDK updates, so builds are not
guaranteed to be bit-identical.

`.github/workflows/linux-packages.yml` builds both formats on pull requests,
pushes to `master`, manual workflow runs and published GitHub releases. Ordinary
builds upload workflow artifacts; published releases also receive both packages
and checksums. Only the release-upload job has repository write permission.

Before a release, update `shard.yml` and the first release entry in
`data/de.magynhard.GoblinConverter.metainfo.xml`, run the checks above, and commit
the changes. Tag that commit with the same version (an optional `v` prefix is
accepted), push it, and publish the GitHub release. The tagged commit must contain
the workflow. Replace `0.0.1` in the examples with the current version.
