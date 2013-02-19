program CacicVersionsAndHashes;

uses
  Forms,
  uCacicVersionsAndHashes in 'uCacicVersionsAndHashes.pas' {frmCacicVersionsAndHashes},
  CACIC_Library in '..\CACIC_Library.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'CacicVersionsAndHashes';
  Application.CreateForm(TfrmCacicVersionsAndHashes, frmCacicVersionsAndHashes);
  Application.Run;
end.
