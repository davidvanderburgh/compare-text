; Inno Setup Script for Compare Text
; Compile with Inno Setup 6+: https://jrsoftware.org/isinfo.php

#define MyAppName "Compare Text"
#define MyAppVersion "1.0"
#define MyAppPublisher "David"

[Setup]
AppId={{B7A3F2D1-4E5C-4A8B-9D6E-1F2A3B4C5D6E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=Output
OutputBaseFilename=CompareText_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
SetupIconFile=compiler:SetupClassicIcon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "CompareText.ahk"; DestDir: "{app}"; Flags: ignoreversion
Source: "Lib\OCR.ahk"; DestDir: "{app}\Lib"; Flags: ignoreversion
Source: "Lib\Gdip_All.ahk"; DestDir: "{app}\Lib"; Flags: ignoreversion
Source: "ahk\AutoHotkey64.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "ahk\license.txt"; DestDir: "{app}"; DestName: "AutoHotkey_license.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\CompareText.ahk"""
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\CompareText.ahk"""; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Run]
Filename: "{app}\AutoHotkey64.exe"; Parameters: """{app}\CompareText.ahk"""; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
