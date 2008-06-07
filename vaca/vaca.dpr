program vaca;

uses
  Forms,
  main_vaca in 'main_vaca.pas' {frmVACA};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'V.A.C.A.';
  Application.CreateForm(TfrmVACA, frmVACA);
  Application.Run;
end.
