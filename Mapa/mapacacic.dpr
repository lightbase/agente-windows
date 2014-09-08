program mapacacic;

uses
  Forms,
  Windows,
  Mapa in 'Mapa.pas' {frmMapaCacic},
  CACIC_Comm in '..\CACIC_Comm.pas',
  CACIC_Library in '..\CACIC_Library.pas',
  ldapsend in 'Source\ldapsend.pas',
  ssl_openssl_lib in 'Source\ssl_openssl_lib.pas',
  synachar in 'Source\synachar.pas',
  synacode in 'Source\synacode.pas',
  synafpc in 'Source\synafpc.pas',
  synaicnv in 'Source\synaicnv.pas',
  synaip in 'Source\synaip.pas',
  synamisc in 'Source\synamisc.pas',
  synaser in 'Source\synaser.pas',
  synautil in 'Source\synautil.pas',
  synsock in 'Source\synsock.pas',
  asn1util in 'Source\asn1util.pas',
  blcksock in 'Source\blcksock.pas',
  cryptlib in 'Source\cryptlib.pas',
  CACIC_WMI in '..\CACIC_WMI.pas';

{$R *.res}

const APP_NAME = 'mapacacic.exe';

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
          Application.Title := 'Mapa Cacic';
          Application.CreateForm(TfrmMapaCacic, frmMapaCacic);
  Application.Run;
        end;
     oCacic.Free();
end.
