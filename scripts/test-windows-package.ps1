# Exercise the installed payload without the compiler or GTK development PATH.
param([string]$Installer = "")
$ErrorActionPreference = 'Stop'
if (-not $Installer) {
  $installers = @(Get-ChildItem "$PSScriptRoot/../dist/*-windows-x86_64-setup.exe")
  if ($installers.Count -ne 1) { throw 'Expected exactly one Windows installer in dist/' }
  $Installer = $installers[0].FullName
}
$testRoot = Join-Path $env:TEMP ("Goblin package test ä " + [guid]::NewGuid())
$installDir = Join-Path $testRoot 'Installed Goblin ä'
New-Item -ItemType Directory -Path $testRoot | Out-Null
$oldPath = $env:PATH
$oldGhostscriptPath = $env:MAGICK_GHOSTSCRIPT_PATH
$oldMagickTemp = $env:MAGICK_TEMPORARY_PATH
$app = $null

function Wait-Checked($Process, [int]$Timeout = 120000) {
  if (-not $Process.WaitForExit($Timeout)) {
    $Process.Kill()
    throw 'Process timed out'
  }
  if ($Process.ExitCode -ne 0) { throw "Process failed: $($Process.ExitCode)" }
}

function Invoke-Magick {
  & "$installDir/tools/imagemagick/magick.exe" @args
  if ($LASTEXITCODE -ne 0) { throw "Bundled ImageMagick failed: $args" }
}

try {
  # NSIS requires /D to be the last argument, unquoted even with spaces.
  Wait-Checked (Start-Process -FilePath $Installer -ArgumentList "/S /D=$installDir" -PassThru)
  if (-not (Test-Path "$installDir/bin/goblin-converter.exe")) { throw 'Application not installed' }
  # Model obsolete files from the old full runtime and verify upgrade cleanup.
  'obsolete' | Set-Content "$installDir/bin/old-unused.dll"
  'obsolete' | Set-Content "$installDir/tools/imagemagick/identify.exe"
  Wait-Checked (Start-Process -FilePath $Installer -ArgumentList "/S /D=$installDir" -PassThru)
  if (Test-Path "$installDir/bin/old-unused.dll") { throw 'Upgrade retained obsolete DLLs' }
  $magickPrograms = @(Get-ChildItem "$installDir/tools/imagemagick/*.exe")
  if ($magickPrograms.Count -ne 1 -or $magickPrograms[0].Name -ne 'magick.exe') {
    throw 'Unexpected ImageMagick helper executables in runtime'
  }
  if ((Test-Path "$installDir/tools/ghostscript/vcredist_x64.exe") -or (Test-Path "$installDir/share/gir-1.0")) {
    throw 'Development files or nested installers included in runtime'
  }
  if (-not (Test-Path "$env:APPDATA/Microsoft/Windows/Start Menu/Programs/Goblin Converter/Goblin Converter.lnk")) {
    throw 'Start menu shortcut missing'
  }
  $env:PATH = "$env:SystemRoot/system32;$env:SystemRoot"
  # From an unrelated cwd, the application must locate its own bundled runtime.
  $app = Start-Process "$installDir/bin/goblin-converter.exe" -WorkingDirectory $testRoot -PassThru
  $deadline = (Get-Date).AddSeconds(45)
  do {
    Start-Sleep -Milliseconds 500
    $app.Refresh()
    if ($app.HasExited) { throw "Installed application exited: $($app.ExitCode)" }
  } until ($app.MainWindowHandle -ne 0 -or (Get-Date) -gt $deadline)
  if ($app.MainWindowHandle -eq 0) { throw 'Installed application did not open a window' }
  $app.Kill()
  $app.WaitForExit()
  $app = $null

  $env:MAGICK_GHOSTSCRIPT_PATH = "$installDir/tools/ghostscript/bin"
  $env:PATH = "$env:MAGICK_GHOSTSCRIPT_PATH;$env:PATH"
  # An ASCII path avoids the known ImageMagick Fax temporary-path limitation.
  $env:MAGICK_TEMPORARY_PATH = "$env:SystemRoot/Temp"
  $postscript = Join-Path $testRoot 'source document.ps'
  '%!PS
  /Helvetica findfont 24 scalefont setfont
  36 100 moveto (Goblin Windows package test) show
  showpage' | Set-Content -Encoding ascii $postscript
  $source = Join-Path $testRoot 'source document.pdf'
  & "$installDir/tools/ghostscript/bin/gswin64c.exe" -dBATCH -dNOPAUSE -sDEVICE=pdfwrite "-sOutputFile=$source" $postscript
  if ($LASTEXITCODE -ne 0) { throw 'Bundled Ghostscript failed' }
  Invoke-Magick -version
  foreach ($mode in @('monochrome', 'grayscale', 'color')) {
    $output = Join-Path $testRoot "$mode.pdf"
    switch ($mode) {
      'monochrome' { Invoke-Magick -density 300 $source -threshold '66%' -type bilevel -compress Fax -strip $output }
      'grayscale' { Invoke-Magick -density 170 $source -colorspace Gray -quality 40 -compress JPEG -strip $output }
      'color' { Invoke-Magick -density 140 $source -quality 50 -compress JPEG -strip $output }
    }
    if ((Get-Item $output).Length -eq 0) { throw "Empty conversion: $mode" }
    # Reading the produced PDF validates the Ghostscript delegate as well.
    Invoke-Magick -density 72 $output (Join-Path $testRoot "$mode.png")
  }
  foreach ($format in @('jpg', 'tiff', 'webp')) {
    $output = Join-Path $testRoot "codec.$format"
    Invoke-Magick (Join-Path $testRoot 'color.png') $output
    Invoke-Magick identify $output
  }
} finally {
  if ($app -and -not $app.HasExited) { $app.Kill(); $app.WaitForExit() }
  $env:PATH = $oldPath
  $env:MAGICK_GHOSTSCRIPT_PATH = $oldGhostscriptPath
  $env:MAGICK_TEMPORARY_PATH = $oldMagickTemp
  if (Test-Path "$installDir/Uninstall.exe") {
    # _?= runs the uninstaller in-place, allowing CI to wait for completion.
    Wait-Checked (Start-Process "$installDir/Uninstall.exe" -ArgumentList "/S _?=$installDir" -PassThru)
    if (Test-Path "$installDir/bin/goblin-converter.exe") { throw 'Uninstall left the application behind' }
    if (Test-Path 'HKCU:/Software/Microsoft/Windows/CurrentVersion/Uninstall/GoblinConverter') {
      throw 'Uninstall left its registry entry behind'
    }
  }
  Remove-Item -Recurse -Force $testRoot
}
Write-Host 'Windows setup, upgrade cleanup, GUI startup, PDF modes, image codecs and uninstall passed.'
