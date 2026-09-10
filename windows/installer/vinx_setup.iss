; Inno Setup Script for VINX Desktop Video Downloader
; Generates a professional Windows installer (.exe) with Start Menu & Desktop shortcuts.

#define MyAppName "VINX"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "VINX"
#define MyAppURL "https://github.com/dan-seng/downloader"
#define MyAppExeName "video_downloader.exe"

[Setup]
; Unique application identifier
AppId={{E29B127C-7A12-421A-98C3-3E4C7A52B889}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes

; Allow installation without administrator elevation for standard user profiles
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Output file configuration
OutputDir=..\..
OutputBaseFilename=VINX-windows-setup-x64
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

; Compression settings
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Start Menu shortcut
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
; Desktop shortcut (selected by default)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
