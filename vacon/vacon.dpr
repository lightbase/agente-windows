program vacon;

uses
  Forms,
  main_VACON in 'main_VACON.pas' {FormVACON};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormVACON, FormVACON);
  Application.Run;
end.
