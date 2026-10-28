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