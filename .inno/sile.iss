#define name "Simon's Improved Layout Engine"
#define shortname "SILE"
#define silregistryname "SILEDocument"

[Setup]
AppId={#shortname}
AppName={#name}
AppVersion={#version}
AppVerName="{#shortname} {#version}"
VersionInfoVersion={#version}
OutputBaseFilename={#shortname}-{#version}-windows-x86_64
LicenseFile="{#source_dir}\LICENSE"

DefaultDirName={pf}\{#shortname}
DefaultGroupName=SILE
OutputDir=output

SolidCompression=yes
Compression=lzma2

ChangesEnvironment=yes
ChangesAssociations = yes

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"
Name: desktopicon\common; Description: "For all users"; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\user; Description: "For the current user only"; GroupDescription: "Additional icons:"; Flags: exclusive unchecked
Name: modifypath; Description: "&Add SILE folder to PATH"; GroupDescription: "Other tasks:"
Name: associate; Description: "Associate *.sil with SILE"; GroupDescription: "Other tasks:"

[Run]
Filename: "{win}\explorer.exe"; Parameters: """{group}\SILE Command Prompt.lnk"""; Description: "Launch SILE Command Prompt"; Flags: postinstall runasoriginaluser

[Registry]
Root: HKCR; Subkey: ".sil";                                   ValueData: "{#silregistryname}";      Flags: uninsdeletevalue;  ValueType: string;  ValueName: ""
Root: HKCR; Subkey: "{#silregistryname}";                     ValueData: "{#name}";                 Flags: uninsdeletekey;    ValueType: string;  ValueName: ""
Root: HKCR; Subkey: "{#silregistryname}\DefaultIcon";         ValueData: "{app}\sile.exe,0";                                  ValueType: string;  ValueName: ""
Root: HKCR; Subkey: "{#silregistryname}\shell\open\command";  ValueData: """{app}\sile.exe"" ""%1""";                         ValueType: string;  ValueName: ""

[Files]
Source: "{#stage_dir}\*.*"; DestDir: "{app}"; Flags: recursesubdirs; Excludes: "{#shortname}-*-windows-x86_64.exe"
Source: "{#source_dir}\examples\*.*" ; DestDir: "{app}\examples"; Flags: recursesubdirs 
Source: "{#source_dir}\tests\*.*" ; DestDir: "{app}\tests"; Flags: recursesubdirs 

[Icons]
Name: "{group}\SILE Command Prompt"; Filename: "cmd.exe"; Parameters: "/k ""set PATH={app};%PATH%"""; IconFilename: "{app}\sile.exe"; WorkingDir: "{app}"
Name: "{group}\Open LUA Interactive Shell"; Filename: "{app}\luajit.exe"; WorkingDir: "{app}"
Name: "{group}\Open SILE Folder"; Filename: "{win}\explorer.exe"; Parameters: "{app}"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"
Name: "{commondesktop}\SILE"; Filename: "cmd.exe"; Parameters: "/k ""set PATH={app};%PATH%"""; IconFilename: "{app}\sile.exe"; WorkingDir: "{app}"; Tasks: desktopicon\common
Name: "{userdesktop}\SILE"; Filename: "cmd.exe"; Parameters: "/k ""set PATH={app};%PATH%"""; IconFilename: "{app}\sile.exe"; WorkingDir: "{app}"; Tasks: desktopicon\user

[Code]
const
	ModPathName = 'modifypath';
	ModPathType = 'system';

function ModPathDir(): TArrayOfString;
begin
	setArrayLength(Result, 1);
	Result[0] := ExpandConstant('{app}');
end;

#include "modpath.iss"
