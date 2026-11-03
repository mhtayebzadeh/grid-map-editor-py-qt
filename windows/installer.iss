; Inno Setup script for Grid Map Editor (run via build.ps1)
; Input:  ..\build\pyinstaller\dist\GridMapEditor\  (PyInstaller output)
; Output: ..\dist-installer\GridMapEditor-Setup-<version>.exe

#define MyAppName "Grid Map Editor"
#define MyAppExeName "GridMapEditor.exe"
#ifndef MyAppVersion
  #define MyAppVersion "0.2.0"
#endif

[Setup]
; AppId identifies the app for upgrades/uninstall - never change it
AppId={{4D104E7D-D3F1-43F2-BAEF-5B66885C592D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=AAW
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Installs for the current user without admin rights; the user may choose "all users"
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\dist-installer
OutputBaseFilename=GridMapEditor-Setup-{#MyAppVersion}
SetupIconFile=..\src\grid_map_editor\resources\images\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\pyinstaller\dist\GridMapEditor\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; Remove files of the previous version (PyInstaller file names change between builds)
Type: filesandordirs; Name: "{app}\_internal"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; Graphics are chosen automatically (GPU, then CPU fallback); this forces CPU rendering
Name: "{autoprograms}\{#MyAppName} (Safe graphics mode)"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--renderer cpu"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
