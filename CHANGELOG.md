# Changelog

## [0.1.3] - 2026-10-29

### Changed

- Reduce the Windows installer to the runtime files used by Goblin Converter:
  keep ImageMagick's `magick.exe`, Ghostscript's console executable and DLL,
  configuration, fonts, profiles and required GTK resources.
- Resolve ordinary and delay-loaded DLL dependencies recursively instead of
  bundling every GTK library. Include dynamically loaded GTK modules explicitly.
- Omit redundant ImageMagick executables, nested redistributable installers,
  development/introspection files, examples and manuals. Keep license notices
  and limit GTK translations to the application's supported languages.
- Replace application-owned runtime directories when updating an existing
  installation so obsolete files from larger packages are removed.

### Fixed

- Bundle ImageMagick's required MSVC OpenMP runtime rather than relying on the
  copy already installed on the Windows build runner.

### Added

- Regression tests for DLL dependency selection, runtime resources and package
  exclusions, plus a Windows upgrade-cleanup smoke test and build-size logging.

## [0.1.2] - 2026-10-29

### Added

- A Windows x64 NSIS installer with bundled GTK/Adwaita, ImageMagick, Ghostscript
  and translations. Install for the current user without administrator privileges,
  with Start menu shortcuts, an optional desktop shortcut and an uninstaller.
- A Windows GitHub Actions workflow that builds and tests the installer and
  attaches it with a SHA-256 checksum to published GitHub releases.
- Windows package smoke tests for installation, GUI startup, PDF conversion modes,
  image codecs and uninstallation, plus local Windows packaging documentation.

### Fixed

- Handle versioned and unversioned Windows DLL names during binding generation,
  including HarfBuzz, and keep shard sources and patches in LF format.
- Compile bundled Windows translations from the existing locale directories.

## [0.1.1] - 2026-10-28

### Changed

- Grayscale conversion now uses lossy JPEG compression instead of lossless ZIP
  compression, so the quality slider controls the output quality.
- Remove the separate grayscale-quality mode from the interface, conversion
  logic and all translations. The available modes are Monochrome, Grayscale
  and Color.
- Apply these defaults whenever a mode is selected:

  | Mode | Resolution | Quality | Threshold |
  | --- | --- | --- | --- |
  | Monochrome | 300 dpi | 75 (unused by Fax compression) | 66 |
  | Grayscale | 170 dpi | 40 | 66 |
  | Color | 140 dpi | 50 | 66 |

- Keep the sliders adjustable after applying a preset and preserve the
  strip-metadata setting when switching modes.

### Fixed

- Keep the visible sliders and actual conversion options synchronized when
  changing modes. Unrelated mode-row notifications no longer overwrite settings.

### Added

- Regression specs for mode defaults and grayscale/color conversion arguments.
- A GUI integration check for presets, manual slider edits and restoring the
  monochrome defaults: `make test-conversion-modes`.

## [0.1.0] - 2026-10-28

First tagged GitHub release of the Crystal application.

### Added

- Docker-based AppImage and GNOME SDK 51 Flatpak builds, with versioned bundles
  and SHA-256 checksums. Both include pinned ImageMagick 7 and Ghostscript builds.
- GitHub Actions package builds and automatic attachment of packages to
  published GitHub releases.
- File-path and local `file://` URI arguments, one window per document, and
  forwarding of file-opening requests to an already running application.
- Conversion smoke tests, packaging checks and file-opening integration tests.

### Changed

- Refresh the application icon in the GNOME style.
- Install icons and translations in standard desktop locations and resolve
  translations relative to the installed executable.
- Update AppStream metadata and document Linux packaging and release commands.

### Fixed

- Keep About and folder-opening actions scoped to each document window.
- Use a relocatable desktop command while retaining file arguments, MIME
  associations and the original application categories.
