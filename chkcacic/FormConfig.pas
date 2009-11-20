(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

unit FormConfig;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  main,
  PJVersionInfo,
  NTFileSecurity,
  Buttons,
  ExtCtrls;

type
  TConfigs = class(TForm)
    Edit_ip_serv_cacic: TEdit;
    Edit_cacic_dir: TEdit;
    gbObrigatorio: TGroupBox;
    Label_ip_serv_cacic: TLabel;
    Label_cacic_dir: TLabel;
    gbOpcional: TGroupBox;
    lbMensagemNaoAplicavel: TLabel;
    Label_te_instala_informacoes_extras: TLabel;
    Button_Gravar: TButton;
    Memo_te_instala_informacoes_extras: TMemo;
    PJVersionInfo1: TPJVersionInfo;
    ckboxExibeInformacoes: TCheckBox;
    btSair: TButton;
    pnVersao: TPanel;
    lbVersao: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button_GravarClick(Sender: TObject);
    procedure ckboxExibeInformacoesClick(Sender: TObject);
    procedure btSairClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Configs: TConfigs;

implementation

{$R *.dfm}

procedure TConfigs.Button_GravarClick(Sender: TObject);
begin
  if trim(Edit_cacic_dir.Text) = '' then
    Edit_cacic_dir.Text := 'Cacic';

  if trim(Edit_ip_serv_cacic.Text)  = '' then
    Edit_ip_serv_cacic.SetFocus
  else
    Begin
      main.GravaConfiguracoes;
      Close;
      Application.terminate;
    End;
end;

procedure TConfigs.ckboxExibeInformacoesClick(Sender: TObject);
begin
  if ckboxExibeInformacoes.Checked then
    Begin
      Memo_te_instala_informacoes_extras.Enabled := true;
      Memo_te_instala_informacoes_extras.Color   := clWindow;
      v_exibe_informacoes := 'S';
    End
  else
    Begin
      Memo_te_instala_informacoes_extras.Enabled := false;
      Memo_te_instala_informacoes_extras.Color   := clInactiveBorder;
      v_exibe_informacoes := 'N';
    End;
end;

procedure TConfigs.btSairClick(Sender: TObject);
begin
  Close;
  Application.Terminate;
end;

end.
