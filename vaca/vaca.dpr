program vaca;

uses
  Forms,
  main_vaca in 'main_vaca.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'MSI Demo';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
