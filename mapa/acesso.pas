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

unit acesso;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, dialogs;

type
  TfrmAcesso = class(TForm)
    btAcesso: TButton;
    btCancela: TButton;
    pnAcesso: TPanel;
    lbNomeUsuarioAcesso: TLabel;
    edNomeUsuarioAcesso: TEdit;
    lbSenhaAcesso: TLabel;
    edSenhaAcesso: TEdit;
    pnMensagens: TPanel;
    lbMsg_Erro_Senha: TLabel;
    lbAviso: TLabel;
    tm_Mensagem: TTimer;
    lbNomeServidorWEB: TLabel;
    lbVersao: TLabel;
    procedure btAcessoClick(Sender: TObject);
    procedure btCancelaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edNomeUsuarioAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tm_MensagemTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var frmAcesso: TfrmAcesso;

implementation
uses main_mapa;
{$R *.dfm}

procedure TfrmAcesso.btAcessoClick(Sender: TObject);
var Request_mapa : TStringList;
    strRetorno,
    str_local_Aux : String;
begin
  frmMapaCacic.boolAcessoOK := false;
  Request_mapa:=TStringList.Create;

  lbMsg_Erro_Senha.Caption := str_local_Aux;

  // Envio dos dados ao DataBase...
  Request_mapa.Values['nm_acesso']      := frmMapaCacic.EnCrypt(edNomeUsuarioAcesso.Text);
  Request_mapa.Values['te_senha']       := frmMapaCacic.EnCrypt(edSenhaAcesso.Text);
  Request_mapa.Values['cs_MapaCacic']   := frmMapaCacic.EnCrypt('S');
  Request_mapa.Values['te_versao_mapa'] := frmMapaCacic.EnCrypt(frmMapaCacic.getVersionInfo(ParamStr(0)));

  strRetorno := frmMapaCacic.ComunicaServidor('mapa_acesso.php', Request_mapa, 'Autenticando o Acesso...');
  Request_mapa.free;

  if (frmMapaCacic.XML_RetornaValor('STATUS', strRetorno)='OK') then
    Begin
      str_local_Aux := trim(frmMapaCacic.DeCrypt(frmMapaCacic.XML_RetornaValor('TE_VERSAO_MAPA',strRetorno)));
      if (str_local_Aux <> '') then
        Begin
          MessageDLG(#13#10#13#10+'ATENÇÃO! Foi disponibilizada a versão "'+str_local_Aux+'".'+#13#10#13#10#13#10+'Efetue o download acessando http://www-cacic, na opção Repositório.'+#13#10#13#10,mtInformation,[mbOK],0);
          btCancela.Click;
        End;

      str_local_Aux := trim(frmMapaCacic.DeCrypt(frmMapaCacic.XML_RetornaValor('ID_USUARIO',strRetorno)));
      if (str_local_Aux <> '') then
        Begin
          frmMapaCacic.strId_usuario := str_local_Aux;
          str_local_Aux := '';
          frmMapaCacic.boolAcessoOK := true; // Acesso OK!
        End
      else
        Begin
          str_local_Aux := 'Usuário/Senha Incorretos ou Nível de Acesso Não Permitido!';
        End
    End
  else
    Begin
      str_local_Aux := 'Problemas na Comunicação!';
    End;

  lbMsg_Erro_Senha.Caption := str_local_Aux;

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      lbAviso.Caption := 'USUÁRIO AUTENTICADO: "' + trim(frmMapaCacic.DeCrypt(frmMapaCacic.XML_RetornaValor('NM_USUARIO_COMPLETO',strRetorno)))+'"';
      lbAviso.Font.Style := [fsBold];
      lbAviso.Font.Color := clGreen;
      Application.ProcessMessages;
      Sleep(3000);
    End
  else
    lbMsg_Erro_Senha.Font.Color := clRed;

  tm_Mensagem.Enabled := true;

  frmMapaCacic.log_diario(str_local_Aux);

  Application.ProcessMessages;

  if (frmMapaCacic.boolAcessoOK) then
    Close
  else
    Begin
      edNomeUsuarioAcesso.AutoSelect := false;
      edNomeUsuarioAcesso.SetFocus;
    End
end;


procedure TfrmAcesso.btCancelaClick(Sender: TObject);
begin
  lbMsg_Erro_Senha.Caption := 'Aguarde... Finalizando!';
  Application.ProcessMessages;
  frmMapaCacic.Finalizar(true);
end;

procedure TfrmAcesso.FormCreate(Sender: TObject);
begin
  intPausaPadrao                    := 3000; //(3 mil milisegundos = 3 segundos)
  frmAcesso.lbVersao.Caption        := 'Versão: ' + frmMapaCacic.GetVersionInfo(ParamStr(0));
  frmMapaCacic.tStringsCipherOpened := frmMapaCacic.CipherOpen(frmMapaCacic.strDatFileName);
  frmMapaCacic.lbNomeServidorWEB.Caption := 'Servidor: '+frmMapaCacic.GetValorDatMemoria('Configs.EnderecoServidor', frmMapaCacic.tStringsCipherOpened);
  frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autenticação no Módulo Gerente WEB Cacic';
  if (frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS' , frmMapaCacic.tStringsCipherOpened)='') then
    Begin
      frmMapaCacic.boolAcessoOK := false;
      MessageDLG(#13#10+'Atenção! É necessário executar as coletas do Sistema Cacic.' + #13#10     + #13#10 +
                            'Caso o Sistema Cacic já esteja instalado, clique com botão direito'   + #13#10 +
                            'sobre o ícone da bandeja, escolha a opção "Executar Agora" e aguarde' + #13#10 +
                            'o fim do processo.',mtError,[mbOK],0);
      frmMapaCacic.Finalizar(false);
    End;
end;

procedure TfrmAcesso.edNomeUsuarioAcessoKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not (trim(frmAcesso.edNomeUsuarioAcesso.Text) = '') and
     not (trim(frmAcesso.edSenhaAcesso.Text) = '')       then
     frmAcesso.btAcesso.Enabled := true
  else
     frmAcesso.btAcesso.Enabled := false;
end;

procedure TfrmAcesso.FormShow(Sender: TObject);
begin
  frmAcesso.edNomeUsuarioAcesso.SetFocus;
end;

procedure TfrmAcesso.edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not (trim(frmAcesso.edNomeUsuarioAcesso.Text) = '') and
     not (trim(frmAcesso.edSenhaAcesso.Text) = '')       then
     frmAcesso.btAcesso.Enabled := true
  else
     frmAcesso.btAcesso.Enabled := false;
end;

procedure TfrmAcesso.tm_MensagemTimer(Sender: TObject);
begin
  tm_Mensagem.Enabled := false;
  lbMsg_Erro_Senha.Caption := '';
  lbMsg_Erro_Senha.Font.Color := clBlack;
end;

procedure TfrmAcesso.FormActivate(Sender: TObject);
var strAux : String;
begin
  strAux := 'Servidor: ' + frmMapaCacic.GetValorDatMemoria('Configs.EnderecoServidor', frmMapaCacic.tStringsCipherOpened);
  if not (strAux = '') then
    Begin
      frmAcesso.lbNomeServidorWEB.Caption := strAux;
    End
  else
    Begin
      frmMapaCacic.Mensagem('Favor verificar a instalação do Cacic.' +#13#10 + 'Não Existe Servidor de Aplicação configurado!',true,intPausaPadrao);
      frmMapaCacic.Finalizar(true);
    End;
end;

end.
