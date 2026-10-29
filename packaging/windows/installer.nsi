Unicode true
!include "MUI2.nsh"
!include "x64.nsh"

!ifndef VERSION
  !error "Pass /DVERSION, /DPAYLOAD and /DOUTPUT to makensis"
!endif
!define APP "Goblin Converter"
!define KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\GoblinConverter"
Name "${APP}"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\Goblin Converter"
InstallDirRegKey HKCU "${KEY}" "InstallLocation"
RequestExecutionLevel user
SetCompressor /SOLID lzma
VIProductVersion "${NUMERIC_VERSION}.0"
VIAddVersionKey /LANG=1033 "ProductName" "${APP}"
VIAddVersionKey /LANG=1033 "FileDescription" "${APP} Setup"
VIAddVersionKey /LANG=1033 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Matthäus J. N. Beyrle"
Icon "${PAYLOAD}\app.ico"
UninstallIcon "${PAYLOAD}\app.ico"

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "German"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "Goblin Converter requires 64-bit Windows."
    Abort
  ${EndIf}
  SetRegView 64
  SetShellVarContext current
FunctionEnd

Section "${APP}" Main
  SectionIn RO
  ; Replace application-owned runtime directories on upgrades, so files removed
  ; from the slim payload do not remain from older installations.
  IfFileExists "$INSTDIR\Uninstall.exe" 0 install_files
  IfFileExists "$INSTDIR\bin\goblin-converter.exe" 0 install_files
  ClearErrors
  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\lib"
  RMDir /r "$INSTDIR\etc"
  RMDir /r "$INSTDIR\share"
  RMDir /r "$INSTDIR\tools"
  IfErrors 0 install_files
  MessageBox MB_OK|MB_ICONSTOP "Could not replace the previous installation. Close Goblin Converter and try again." /SD IDOK
  Abort
install_files:
  SetOutPath "$INSTDIR"
  File /r "${PAYLOAD}\*"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\${APP}"
  CreateShortcut "$SMPROGRAMS\${APP}\${APP}.lnk" "$INSTDIR\bin\goblin-converter.exe" "" "$INSTDIR\app.ico"
  CreateShortcut "$SMPROGRAMS\${APP}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "${KEY}" "DisplayName" "${APP}"
  WriteRegStr HKCU "${KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${KEY}" "Publisher" "Matthäus J. N. Beyrle"
  WriteRegStr HKCU "${KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${KEY}" "DisplayIcon" "$INSTDIR\app.ico"
  WriteRegStr HKCU "${KEY}" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
  WriteRegStr HKCU "${KEY}" "QuietUninstallString" '$\"$INSTDIR\Uninstall.exe$\" /S'
  WriteRegDWORD HKCU "${KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${KEY}" "NoRepair" 1
SectionEnd

Section /o "Desktop shortcut"
  CreateShortcut "$DESKTOP\${APP}.lnk" "$INSTDIR\bin\goblin-converter.exe" "" "$INSTDIR\app.ico"
SectionEnd

Section "Uninstall"
  SetRegView 64
  SetShellVarContext current
  Delete "$DESKTOP\${APP}.lnk"
  Delete "$SMPROGRAMS\${APP}\${APP}.lnk"
  Delete "$SMPROGRAMS\${APP}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${APP}"
  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\lib"
  RMDir /r "$INSTDIR\etc"
  RMDir /r "$INSTDIR\share"
  RMDir /r "$INSTDIR\tools"
  Delete "$INSTDIR\app.ico"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "${KEY}"
SectionEnd
