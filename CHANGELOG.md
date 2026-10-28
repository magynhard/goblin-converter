# Changelog

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

## 0.0.1 - Development history

Unreleased development snapshots from 2026-10-01 through 2026-10-25, reconstructed
from Git history. No `0.0.1` release tag was published in this repository.

### Added

- Initial Crystal port with GTK4/libadwaita, document conversion through
  ImageMagick, conversion controls and metadata stripping.
- Native Windows MSVC build support and setup documentation alongside Linux.
- Open-containing-folder actions and file dialogs prefilled from current paths.
- Completed translations for the configured application languages.
- Headless specs for conversion arguments, target paths and process exit status.

### Fixed

- Run conversions through `Gio::SubprocessLauncher` without blocking GTK's main
  loop and collect conversion output through temporary log files.
- Unwrap dropped `GObject::Value` data correctly before reading local file paths.
- Repair locale generation and compilation, and make remaining UI strings
  translatable.

[0.1.1]: https://github.com/magynhard/goblin-converter.cr/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/magynhard/goblin-converter.cr/releases/tag/0.1.0
