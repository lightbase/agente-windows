program installcacic;

uses  Forms,
      uInstallCACIC in 'uInstallCACIC.pas' {frmInstallCACIC},
      CACIC_Comm in '..\CACIC_Comm.pas',
      CACIC_Library in '..\CACIC_Library.pas',
      CACIC_VerifyAndGetModules in '..\CACIC_VerifyAndGetModules.pas',
      CACIC_WMI in '..\CACIC_WMI.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'installcacic';
  Application.CreateForm(TfrmInstallCACIC, frmInstallCACIC);
  Application.Run;
end.
