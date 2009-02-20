unit WinVNC;

interface

uses
  Windows, Classes;

type
  WinVNCThread = class(TThread)
  private
    HND : THandle;
    StartTID : THandle;
    StartID : DWORD;
    StartServer : procedure;
    StopServer : procedure;
  protected
    procedure Execute; override;
  public
    procedure Finish;
    procedure Start;
  end;

implementation

uses SysUtils;

procedure WinVNCThread.Execute;
begin
  Synchronize(Start);
end;

procedure WinVNCThread.Finish;
begin
  HND := LoadLibrary('modulos\cacicrc.dll');
  if (HND <> 0) then
  begin
    StopServer := GetProcAddress(HND,'StopServer');
    if Assigned(StopServer) then
    begin
      StopServer;
    end;
    FreeLibrary(HND);
  end;
end;

procedure WinVNCThread.Start;
begin
  HND := LoadLibrary('modulos\cacicrc.dll');
  if (HND <> 0) then
  begin
    StartServer := GetProcAddress(HND,'StartServer');
    if Assigned(StartServer) then
    begin
      StartTID := CreateThread(nil, 0, @StartServer, nil, 0, StartID);
      if StartTID = 0 then
        { O servidor não pôde ser inicializado. }
    end;
  end;
end;

end.
