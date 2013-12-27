program MapaCACICpgfn;

uses
  Forms,
  Windows,
  MapaTeste in 'MapaTeste.pas' {frmMapaCacic},
  CACIC_Comm in '..\CACIC_Comm.pas',
  CACIC_Library in '..\CACIC_Library.pas';

{$R *.res}

const APP_NAME = 'MapaCACICpgfn.exe';

var   hwind:HWND;
      oCacic : TCACIC;

begin
   oCacic := TCACIC.Create();

   if( oCacic.isAppRunning( APP_NAME ) )
     then begin
        hwind := 0;
        repeat			// The string 'My app' must match your App Title (below)
           hwind:=Windows.FindWindowEx(0,hwind,'TApplication', APP_NAME );
        until (hwind<>Application.Handle);
        IF (hwind<>0) then
        begin
           Windows.ShowWindow(hwind,SW_SHOWNORMAL);
           Windows.SetForegroundWindow(hwind);
        end;
        FreeMemory(0);
     end
     else
        begin
          Application.Initialize;
          Application.Title := 'MapaCACICpgfn';
  Application.CreateForm(TfrmMapaCacic, frmMapaCacic);
  Application.Run;
        end;
     oCacic.Free();
end.
