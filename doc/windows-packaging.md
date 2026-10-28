# Windows packaging

The `Windows packages` GitHub Actions workflow builds an x64 NSIS setup on
`windows-2022` using the VS2022 MSVC toolchain. It runs for pull requests, pushes
to `master`, manual dispatches and published releases. The Linux packaging
workflow runs independently.

## Package contents

`Goblin_Converter-<version>-windows-x86_64-setup.exe` includes:

- Goblin Converter, compiled in release mode for baseline x86-64 CPUs.
- The gvsbuild GTK4/Adwaita runtime, schemas, icons and translations.
- Crystal's GC DLL and the app-local MSVC runtime DLLs.
- Portable ImageMagick 7 and Ghostscript 10, including their notices.
- Application translations for every language in `po/LINGUAS`.
- Dependency source URLs and revisions under `share/licenses/`.

The installer supports English and German, installs for the current user under
`%LOCALAPPDATA%\Programs\Goblin Converter`, creates Start menu shortcuts and
offers an optional desktop shortcut. Administrator privileges are not required.
The installation appears in Windows **Installed apps** and supports silent
installation (`/S`) and uninstallation (`Uninstall.exe /S`). Close the application
before installing an update into the same directory.

Conversion tools are private to the application. The executable locates them
relative to its own installation directory, sets its child-process search path
and points ImageMagick directly at the bundled Ghostscript. The installer does
not modify the global `PATH` or register a system-wide Ghostscript installation.

## Pinned inputs

`packaging/windows/sources.json` pins the Windows Crystal, gvsbuild, ImageMagick
and Ghostscript downloads by URL and SHA-256. Cached downloads are verified on
every build. The initial toolchain uses Crystal 1.21.1 and gvsbuild 2026.8.0,
matching the previously verified local Windows development environment.
NSIS 3.11 is installed through Chocolatey in CI.

Shard revisions come from the shared `packaging/sources.json`, just like Linux.
The build validates versions and AppStream metadata with `scripts/packaging.py`.
An ignored `shard.lock` is not required in a fresh checkout. If present locally,
it must agree with the committed packaging pins.

The release builder makes a fresh source copy under `build/windows/source` and
fetches the pinned shards there. It applies the offline-version patch and
`packaging/patches/gi-crystal-windows.patch` before generating bindings. The
Windows patch handles DLL names without a `lib` prefix, unsigned enum values in
signed typelib storage and opaque by-value struct fields. These are the Windows
compatibility fixes previously maintained only in a developer's ignored `lib/`.
The build sets an explicit shared shard search path, so it does not require
symlinks or Windows Developer Mode. The original checkout's `lib/` is not modified.

## Build locally

Use x64 Windows 10/11 with:

- VS2022 Build Tools or Visual Studio 2022, with **Desktop development with C++**,
  MSVC v143 and a Windows SDK.
- Python 3.12+ and `PyYAML==6.0.2`.
- Git, curl and 7-Zip (`7z`) on `PATH`.
- NSIS 3.11 (`makensis` on `PATH`, or the default NSIS installation directory).

From the repository root in PowerShell:

```powershell
python -m pip install PyYAML==6.0.2
python scripts/windows-packaging.py prepare
if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
. ./scripts/goblin-env.ps1 -GtkDir "$PWD/build/windows/tools/gtk" -CrystalDir "$PWD/build/windows/tools/crystal"
python scripts/windows-packaging.py build
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
./scripts/test-windows-package.ps1
```

`prepare` downloads the verified archives into `build/windows/downloads` and
extracts them under `build/windows/tools`. Ghostscript's NSIS archive is extracted
with 7-Zip; its installer is not executed on the build host or the user's machine.
`build` compiles the bindings, checks Crystal formatting, runs the headless specs,
builds the release executable, assembles `build/windows/payload` and invokes NSIS.
The setup and its `.exe.sha256` checksum are written to `dist/`.

If `dist/` contains multiple installer versions, select one explicitly:

```powershell
./scripts/test-windows-package.ps1 -Installer "$PWD/dist/Goblin_Converter-0.1.1-windows-x86_64-setup.exe"
```

The smoke test installs into a temporary path with spaces and a non-ASCII
character, opens the actual GUI from another working directory using only the
Windows system `PATH`, checks all three PDF conversion modes and PNG/JPEG/TIFF/
WebP codecs, then uninstalls and checks registry cleanup. It requires an
interactive Windows session and should run on a disposable build machine: it
uses the application's normal per-user shortcut and uninstall registry entry.

ImageMagick's known Fax-output limitation with non-ASCII temporary paths still
applies. For affected Windows user profiles, set `MAGICK_TEMPORARY_PATH` to a
writable ASCII-only directory. The conversion smoke test uses an ASCII temporary
path for ImageMagick while retaining Unicode source and installation paths.

## Releases

1. Update `shard.yml` and the first AppStream release entry to the same version.
2. Push the matching version tag and publish its GitHub release.
3. The workflow checks that the tag (with optional `v` prefix) matches the version,
   builds and smoke-tests the installer, then uploads the setup and checksum to
   that release.

PR, branch and manual builds publish downloadable Actions artifacts instead.
No extra repository secrets are needed; the release-upload job uses the built-in
`GITHUB_TOKEN` with `contents: write`. Setup executables are currently unsigned.

## Cross-compilation

Crystal's Linux `--cross-compile --target x86_64-windows-msvc` mode emits an object
file and a command for the final Windows linker. It is useful for typechecking
Windows-specific branches, but does not provide the MSVC SDK/import libraries,
generate GTK bindings against the Windows typelibs, or execute Windows smoke
tests. The release workflow therefore builds and links natively on Windows.
NSIS itself also runs on Linux, but needs the already-built Windows payload.
