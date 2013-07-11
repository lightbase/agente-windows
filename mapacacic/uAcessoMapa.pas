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

unit uAcessoMapa;

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
  StdCtrls,
  ExtCtrls,
  dialogs;

type
  TfrmAcesso = class(TForm)
    btAcesso: TButton;
    btCancela: TButton;
    pnAcesso: TPanel;
    lbNomeUsuarioAcesso: TLabel;
    edNomeUsuarioAcesso: TEdit;
    lbSenhaAcesso: TLabel;
    edSenhaAcesso: TEdit;
    lbAviso: TLabel;
    pnMessageBox: TPanel;
    lbMensagens: TLabel;
    procedure btAcessoClick(Sender: TObject);
    procedure btCancelaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edNomeUsuarioAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    function  VerificaVersao : boolean;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAcesso: TfrmAcesso;

implementation
uses uMainMapa,
     CACIC_Comm;
{$R *.dfm}

procedure TfrmAcesso.btAcessoClick(Sender: TObject);
var strCommResponseAcesso,
    strLocalAux : String;
    boolAlert   : boolean;
begin
  frmMapaCacic.boolAcessoOK := false;
  boolAlert                 := false;

  // Autenticação de Programa e Usuário
  strFieldsAndValuesToRequest :=                               'nm_acesso='           + objCacicCOMM.replaceInvalidHTTPChars( objCacic.enCrypt(edNomeUsuarioAcesso.Text))          + ',';
  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'te_senha='            + objCacicCOMM.replaceInvalidHTTPChars( objCacic.enCrypt(edSenhaAcesso.Text,false))          + ',';
  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'te_operacao='         + 'Autentication';

  strCommResponseAcesso := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'mapacacic/acesso', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);
  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  if (strCommResponseAcesso <> '0') then
    Begin
      strLocalAux := trim(objCacic.deCrypt(objCacic.getValueFromTags('ID_USUARIO',strCommResponseAcesso)));
      if (strLocalAux <> '') then
        Begin
          frmMapaCacic.strId_usuario := strLocalAux;
          strLocalAux := '';
          frmMapaCacic.boolAcessoOK := true; // Acesso OK!
        End
      else
        Begin
          strLocalAux := 'Usuário/Senha incorretos ou Usuário sem Acesso Primário/Secundário a este local!';
          boolAlert := true;
        End
    End
  else
    Begin
      strLocalAux := 'Problemas na comunicação!';
      boolAlert := true;      
    End;

  frmMapaCacic.Mensagem(strLocalAux,boolAlert);

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      lbAviso.Caption := 'USUÁRIO AUTENTICADO: "' + trim(objCacic.deCrypt(objCacic.getValueFromTags('NM_USUARIO_COMPLETO',strCommResponseAcesso)))+'"';
      lbAviso.Font.Style := [fsBold];
      lbAviso.Font.Color := clGreen;
      Application.ProcessMessages;
      Sleep(3000);
    End
  else
    lbMensagens.Font.Color := clRed;

  frmMapaCacic.timerMessageShowTime.Enabled := true;

  objCacic.writeDailyLog(strLocalAux);

  Application.ProcessMessages;

  if (frmMapaCacic.boolAcessoOK) then
    Begin
      self.Close
    End
  else
    Begin
      objCacic.writeDebugLog('btAcessoClick: Acesso Não Efetuado! Comandando fechamento.');    
      edNomeUsuarioAcesso.AutoSelect := false;
      edNomeUsuarioAcesso.SetFocus;
    End;
end;

Function TfrmAcesso.VerificaVersao : boolean;
var strCommResponseVerVersao,
    strAUXvv      : String;
begin
  Result := false;

  // Envio dos dados ao DataBase...
  strFieldsAndValuesToRequest :=                               'te_operacao='         + 'CheckVersion' + ',';
  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'MAPACACIC.EXE_HASH='  + objCacic.getFileHash(ParamStr(0));

  strCommResponseVerVersao := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'mapacacic/acesso', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);
  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  objCacic.writeDebugLog('VerificaVersao: Analisando retorno...');
  if (strCommResponseVerVersao <> '0') then
    Begin
      objCacic.writeDebugLog('VerificaVersao: Retorno OK');
      strAUXvv := trim(objCacic.getValueFromTags('MAPACACIC.EXE_HASH',strCommResponseVerVersao));
      objCacic.writeDebugLog('VerificaVersao: MAPACACIC.EXE_HASH => ' + strAUXvv);
      if (strAUXvv = '') then
        Result := true
      else
        Begin
           ShowMessage('ATENÇÃO:' + #13#10 +
                       '-------'  + #13#10 + #13#10 +
                       'Encontra-se disponibilizada uma nova versão do MapaCACIC no servidor "' + objCacic.getWebManagerAddress + '"'+ #13#10 + #13#10 + #13#10 +
                       'Párâmetro Local.: "' + objCacic.getFileHash(ParamStr(0)) + '"' + #13#10 +
                       'Parâmetro Remoto: "' + objCacic.getValueFromTags('MAPACACIC.EXE_HASH',strCommResponseVerVersao) + '"' + #13#10 + #13#10 + #13#10 +
                       'Acesse ao servidor e baixe um novo executável através do link "Repositório" da página principal do Sistema CACIC.' + #13#10 + #13#10 + #13#10 +
                       'A execução está sendo finalizada!' + #13#10 + #13#10 + #13#10);
           btCancelaClick(nil);
        End;
    End
  else
    Begin
      objCacic.writeDebugLog('VerificaVersao: Problema de Comunicação!');
      MessageDLG(#13#10#13#10+'ATENÇÃO! Há problema na comunicação com o módulo Gerente WEB.'+#13#10#13#10,mtWarning,[mbOK],0);
    End;
  Application.ProcessMessages;
end;


procedure TfrmAcesso.btCancelaClick(Sender: TObject);
begin
  lbMensagens.Caption := 'Aguarde... Finalizando!';
  Self.Close;  
  Application.ProcessMessages;
end;

procedure TfrmAcesso.FormCreate(Sender: TObject);
begin
  frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autenticação no Módulo Gerente WEB Cacic';
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

procedure TfrmAcesso.edSenhaAcessoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not (trim(frmAcesso.edNomeUsuarioAcesso.Text) = '') and
     not (trim(frmAcesso.edSenhaAcesso.Text) = '')       then
     frmAcesso.btAcesso.Enabled := true
  else
     frmAcesso.btAcesso.Enabled := false;
end;

procedure TfrmAcesso.FormActivate(Sender: TObject);
begin
  strFrmAtual := 'Principal';
  lbAviso.Caption := 'Verificando Existência de Nova Versão.';
  frmMapaCacic.Mensagem(lbAviso.Caption);
  if (objCacic.getWebManagerAddress = '') then
    Begin
      frmMapaCacic.Mensagem('Favor verificar a instalação do Cacic.' +#13#10 + 'Não Existe Servidor de Aplicação configurado!',true,3);
      frmMapaCacic.Finalizar(true);
    End;

  if not VerificaVersao then
    frmMapaCacic.Finalizar(false)
  else
    Begin
      lbNomeUsuarioAcesso.Visible := true;
      edNomeUsuarioAcesso.Visible := true;
      lbSenhaAcesso.Visible       := true;
      edSenhaAcesso.Visible       := true;
      lbAviso.Caption             := 'ATENÇÃO: O usuário deve estar cadastrado no Gerente WEB e deve ter acesso PRIMÁRIO ou SECUNDÁRIO a este local';

      frmAcesso.edNomeUsuarioAcesso.SetFocus;
    End;
    
  frmMapaCacic.Mensagem('');
end;

procedure TfrmAcesso.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  IF (key = VK_RETURN) then
    Begin
      if (edNomeUsuarioAcesso.Focused) and (trim(edNomeUsuarioAcesso.Text) <> '') then
        edSenhaAcesso.SetFocus
      else if (edSenhaAcesso.Focused) and (trim(edSenhaAcesso.Text) <> '') then
        btAcessoClick(nil);
    End;
end;

end.
