unit AcessoMapaTeste;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmAcesso = class(TForm)
    btAcesso: TButton;
    btCancela: TButton;
    pnAcesso: TPanel;
    lbNomeUsuarioAcesso: TLabel;
    lbSenhaAcesso: TLabel;
    lbAviso: TLabel;
    edNomeUsuarioAcesso: TEdit;
    edSenhaAcesso: TEdit;
    pnMessageBox: TPanel;
    lbMensagens: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAcesso: TfrmAcesso;

implementation

{$R *.dfm}

end.
