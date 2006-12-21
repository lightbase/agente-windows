unit ShellLinker;

interface
uses ActiveX, Windows, ShlObj;

//uses
//  Windows, ShlObj;
//uses
//  SysUtils, ComObj, ActiveX, ShellApi, Classes, Menus;

type
  TShowState = (ssNormal, ssMinimized, ssMaximized, ssHide);

  TLinkInfo = record
    Target: String;          // Path to link target file   - empty for virtual folders
    ClsID: PItemIDList;      // Absolute CLSID (PIDL) of target
    WorkDir: String;         // Working directory          - empty for virtual folders
    Parameters: String;      // Parameters sent to path    - empty for virtual folders
    Description: String;     // Description of link
    IconPath: String;        // File containing icon       - often same as Target
    IconIndex: Integer;      // Index of icon in the icon file
    HotKey: Word;            // HotKey (like Alt+Shift+F)  - numeric
    ShowState: TShowState;   // Normal, minimized, or maximized
  end;

  TLinkHotKey = record
    Modifiers: Word;
    Key: Word;
  end;
function CreateShellLink(FileName, Target, Description, StartIn, Parameters,
  IconPath: String; IconIndex: Integer; HotKey: Word; ShowState: TShowState;
  ItemIDList: PItemIDList): Boolean;


implementation

function ShowStateToCmdShow(ShowState: TShowState): Integer;
begin
  case ShowState of
    ssMinimized: Result := SW_SHOWMINNOACTIVE;
    ssMaximized: Result := SW_SHOWMAXIMIZED;
    ssHide: Result := SW_HIDE;
  else
    Result := SW_SHOWNORMAL;
  end;
end;

function CreateShellLink(FileName, Target, Description, StartIn, Parameters,
  IconPath: String; IconIndex: Integer; HotKey: Word; ShowState: TShowState;
  ItemIDList: PItemIDList): Boolean;
var
  sl: IShellLink;
  ppf: IPersistFile;
  wcLinkName: array[0..MAX_PATH] of WideChar;
begin
  CoInitialize(nil);         // Initialize COM
  CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLinkA, sl);
  sl.QueryInterface(IPersistFile, ppf);
  sl.SetPath(PChar(Target));
  if ItemIDList <> nil then
    sl.SetIDList(ItemIDList);
  sl.SetDescription(PChar(Description));
  sl.SetWorkingDirectory(PChar(StartIn));
  sl.SetArguments(PChar(Parameters));
  sl.SetIconLocation(PChar(IconPath), IconIndex);
  if HotKey <> 0 then
    sl.SetHotkey(HotKey);
  sl.SetShowCmd(ShowStateToCmdShow(ShowState));
  // Save shell link
  MultiByteToWideChar(CP_ACP, 0, PChar(FileName), -1, wcLinkName, MAX_PATH);
  Result := (ppf.Save(wcLinkName, true) = S_OK);
  CoUninitialize;
end;

end.

