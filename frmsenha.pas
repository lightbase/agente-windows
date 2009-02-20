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

unit frmSenha;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, Main, ExtCtrls;


type
  TformSenha = class(TForm)
    Lb_Texto_Senha: TLabel;
    Lb_Senha: TLabel;
    EditSenha: TEdit;
    Bt_OK_Senha: TButton;
    Bt_Cancelar_Senha: TButton;
    Lb_Msg_Erro_Senha: TLabel;
    Tm_Senha: TTimer;
    procedure Bt_Cancelar_SenhaClick(Sender: TObject);
    procedure Bt_OK_SenhaClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Tm_SenhaTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  formSenha: TformSenha;

implementation

{$R *.dfm}

procedure TformSenha.Bt_Cancelar_SenhaClick(Sender: TObject);
begin
  formSenha.Close;
  formSenha.Release;
end;

procedure TformSenha.Bt_OK_SenhaClick(Sender: TObject);
begin
if boolDebugs then FormularioGeral.log_DEBUG('Informação de Senha: "'+Trim(editSenha.Text)+'" contra "'+Trim(FormularioGeral.GetValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE',v_tstrCipherOpened))+'"');
  if (Trim(editSenha.Text) = Trim(FormularioGeral.GetValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE',v_tstrCipherOpened))) Then
    Begin
      FormularioGeral.SetValorDatMemoria('Configs.SJI','S',v_tstrCipherOpened);
      formSenha.Close;
      formSenha.Release;
    End
  else
    Begin
      Lb_Msg_Erro_Senha.Caption := 'Senha Inválida!';
      Tm_Senha.Enabled  := false;
      Tm_Senha.Interval := 3000; //3 segundos
      Tm_Senha.Enabled  := true;
    End;
end;

procedure TformSenha.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  formSenha.Close;
  formSenha.Release;
end;

procedure TformSenha.Tm_SenhaTimer(Sender: TObject);
begin
  Tm_Senha.Enabled:= false;
  Lb_Msg_Erro_Senha.Caption := '';
end;

end.
