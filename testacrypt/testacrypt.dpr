program testacrypt;

uses
  Forms,
  main_testacrypt in 'main_testacrypt.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
