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

unit MapaTeste;

interface

uses
  Windows,
  SysUtils,    // Deve ser colocado após o Windows acima, nunca antes
  StrUtils,
  StdCtrls,
  Controls,
  Classes,
  Forms,
  ExtCtrls,
  Graphics,
  Dialogs,
  CACIC_Library,
  CACIC_Comm,
  ComCtrls,
  Commctrl,
  ShellAPI,
  AcessoMapaTeste,
  Types,
  IdIPWatch,
  Registry,
  Math,
  IdBaseComponent,
  IdComponent,
  Mask,
  ComObj;

function IsUserAnAdmin() : boolean; external shell32;

var strCollectsPatrimonioLast,
    strConfigsPatrimonioCombos,
    strFieldsAndValuesToRequest,
    strIdUON1,
    strFrmAtual,
    strShowOrHide               : string;
    textFileAguarde             : TextFile;
    boolFinalizando             : boolean;
    objCacic                    : TCACIC;
    Fechar                      : boolean;
    Dummy                       : integer;
    OldValue                    : LongBool;

type
  TfrmMapaCacic = class(TForm)
    edWebManagerAddress: TLabel;
    lbWebManagerAddress: TLabel;
    pnVersao: TPanel;
    timerMessageBoxShowOrHide: TTimer;
    timerMessageShowTime: TTimer;
    timerProcessos: TTimer;
    IdIPWatch1: TIdIPWatch;
    pnMessageBox: TPanel;
    lbMensagens: TLabel;
    gbLeiaComAtencao: TGroupBox;
    lbLeiaComAtencao: TLabel;
    gbInformacoesSobreComputador: TGroupBox;
    lbEtiqueta5: TLabel;
    lbEtiqueta6: TLabel;
    lbEtiquetaUserLogado: TLabel;
    lbEtiquetaNomeComputador: TLabel;
    lbEtiquetaIpComputador: TLabel;
    lbEtiquetaPatrimonioPc: TLabel;
    lbEtiquetaNome: TLabel;
    edTeInfoPatrimonio5: TEdit;
    edTeInfoPatrimonio6: TEdit;
    btCombosUpdate: TButton;
    edTeInfoUserLogado: TEdit;
    edTeInfoNomeComputador: TEdit;
    edTeInfoIpComputador: TEdit;
    edTePatrimonioPc: TEdit;
    edTeInfoNome: TEdit;
    bgTermoResponsabilidade: TGroupBox;
    rdConcordaTermos: TRadioButton;
    btGravarInformacoes: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure mapa;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure btCombosUpdateClick(Sender: TObject);
    procedure timerMessageShowTimeTimer(Sender: TObject);
    procedure timerProcessosTimer(Sender: TObject);
    procedure rdConcordaTermosClick(Sender: TObject);
    procedure EstadoBarraTarefa(EstadoBarra: Boolean);

    function NomeComputador : String;
    function UserName : String;
    function getConfigs : String;
    function SetCpfUser : String;
    function SetPatrimonioPC : String;
    function FormatarCpf(strCpfUser : String) : String;


  private
    strTeInfoPatrimonio1,
    strTeInfoPatrimonio2,
    strTeInfoPatrimonio3,
    strTeInfoPatrimonio4,
    strTeInfoPatrimonio5,
    strTeInfoPatrimonio6,
    strTeInfoPatrimonio7    : String;

    procedure FormSetFocus;
    procedure MontaInterface;
    procedure RecuperaValoresAnteriores;
    procedure Sair;

  public
    foco,
    boolAcessoOK                : boolean;
    strId_usuario,
    strChkSisInfFileName,
    strGerColsInfFileName       : String;

    procedure Finalizar(p_pausa:boolean);
    procedure Mensagem(p_strMsg : String; p_boolAlerta : boolean = false; p_intPausaSegundos : integer = 0);

  end;

var frmMapaCacic: TfrmMapaCacic;

implementation

{$R *.dfm}

procedure TfrmMapaCacic.Mensagem(p_strMsg : String; p_boolAlerta : boolean; p_intPausaSegundos : integer);
Begin
  strShowOrHide := 'Show';

  objCacic.writeDebugLog('Mensagem: ' + p_strMsg);

  if p_boolAlerta then
    lbMensagens.Font.Color := clRed
  else
    lbMensagens.Font.Color := clBlack;

  lbMensagens.Caption := p_strMsg;

  objCacic.writeDailyLog(lbMensagens.Caption);
  Application.ProcessMessages;

  if (p_intPausaSegundos > 0) then
    timerMessageShowTime.Interval := p_intPausaSegundos * 1000;

  timerMessageBoxShowOrHide.Enabled := true;

  Application.ProcessMessages;
End;

procedure TfrmMapaCacic.Sair;
Begin
    Application.Terminate;
End;

procedure TfrmMapaCacic.Finalizar(p_pausa:boolean);
Begin
  gbLeiaComAtencao.Visible              := false;
  gbInformacoesSobreComputador.Visible  := false;
  btGravarInformacoes.Visible           := false;

  Mensagem('Finalizando o MapaCacic...');

  Application.ProcessMessages;

  Sleep(1000);

  Sair;
End;

procedure TfrmMapaCacic.rdConcordaTermosClick(Sender: TObject);
begin
  btGravarInformacoes.Enabled:= true;
end;

//------------------------------------------------------------------------------
//------------------FUNÇÃO PARA RETORNAR O NOME DO COMPUTADOR.------------------
//------------------------------------------------------------------------------

Function TfrmMapaCacic.NomeComputador : String;
var
  lpBuffer : PChar;
  nSize : DWord;
const Buff_Size = MAX_COMPUTERNAME_LENGTH + 1;
begin
  nSize := Buff_Size;
  lpBuffer := StrAlloc(Buff_Size);
  GetComputerName(lpBuffer,nSize);
  Result := String(lpBuffer);
  StrDispose(lpBuffer);
end;

//------------------------------------------------------------------------------
//------------------FUNÇÃO PARA RETORNAR O NOME DO USUARIO.---------------------
//------------------------------------------------------------------------------

Function TfrmMapaCacic.UserName : String;
var
  lpBuffer : PChar;
  nSize : DWord;
const Buff_Size = MAX_COMPUTERNAME_LENGTH + 1;
begin
  nSize := Buff_Size;
  lpBuffer := StrAlloc(Buff_Size);
  GetUserName(lpBuffer,nSize);
  Result := String(lpBuffer);
  StrDispose(lpBuffer);
end;

//------------------------------------------------------------------------------
//----------------------FUNÇÃO PARA RETORNAR O PATRIMONIO-----------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.SetPatrimonioPC : String;
var
  strPatrimonioPc,
  strNomePC        : String;
begin
  Result:='';
  strNomePC:=NomeComputador;

  if (pos('-',strNomePC) > 0) then
    strPatrimonioPc:=copy(strNomePC, 0, (pos('-', strNomePC)-1));
  Result:=strPatrimonioPC;
end;

//------------------------------------------------------------------------------
//--------------------FUNÇÃO PARA FORMATAR O CPF--------------------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.FormatarCpf(strCpfUser : String) : String;
var
  strCpfFormatado : String;
begin
  Result:='';
  strCpfFormatado:= Copy(strCpfUser, 1,3)

            + '.' + Copy(strCpfUser, 4,3)

            + '.' + Copy(strCpfUser, 7,3)

            + '-' + Copy(strCpfUser, 10,2);
  Result:=strCpfFormatado;

end;
//------------------------------------------------------------------------------
//--------------------FUNÇÃO PARA RETORNAR O CPF DO USUARIO---------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.SetCpfUser : String;
var
  strCpfUser,
  strUser        : String;
begin
  Result:='';
  strUser:=UserName;

  if (pos('-',strUser) > 0) then
    strCpfUser:=copy(strUser, 0, (pos('-', strUser)-1));

  Result:=strCpfUser;
end;

function TfrmMapaCacic.getConfigs : String;

Begin
  btCombosUpdate.Enabled := false;

  Result := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);

  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  objCacic.writeDebugLog('FormActivate: Retorno de getConfigs: "'+Result+'"');

  if (Result <> '0') then
    Begin
      Mensagem('Comunicação Efetuada com Sucesso! Salvando as Configurações Obtidas...',false,1);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Combos'    , objCacic.getValueFromTags('Configs_Patrimonio_Combos'   , Result), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Interface' , objCacic.getValueFromTags('Configs_Patrimonio_Interface', Result), strGerColsInfFileName);
//Linha comentada, pois gerente não está mandando as configurações adequadas.
      //objCacic.setValueToFile('Collects','Patrimonio_Last'      , objCacic.getValueFromTags('Collects_Patrimonio_Last'    , Result), strGerColsInfFileName);
    End
  else
    begin
      MessageDlg(#13#13+'Não foi possível realizar a conexão!',mtError, [mbOK], 0);
    end;
  btCombosUpdate.Enabled := true;
End;

procedure TfrmMapaCacic.RecuperaValoresAnteriores;
var strCollectsPatrimonioLast : String;
begin
  btCombosUpdate.Enabled := false;

  Mensagem('Recuperando Valores Anteriores...',false,1);

  strCollectsPatrimonioLast := objCacic.deCrypt( objCacic.GetValueFromFile
                                                ('Collects','Patrimonio_Last',
                                                 strGerColsInfFileName));

  if (strCollectsPatrimonioLast <> '') then
    Begin

      if (strTeInfoPatrimonio1='') then
        strTeInfoPatrimonio1 := objCacic.getValueFromTags('TeInfoPatrimonio1',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio2='') then
        strTeInfoPatrimonio2 := objCacic.getValueFromTags('TeInfoPatrimonio2',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio3='') then
        strTeInfoPatrimonio3 := objCacic.getValueFromTags('TeInfoPatrimonio3',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio4='') then
        strTeInfoPatrimonio4 := objCacic.getValueFromTags('TeInfoPatrimonio4',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio5='') then
        strTeInfoPatrimonio5 := objCacic.getValueFromTags('TeInfoPatrimonio5',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio6='') then
        strTeInfoPatrimonio6 := objCacic.getValueFromTags('TeInfoPatrimonio6',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio7='') then
        strTeInfoPatrimonio7 := objCacic.getValueFromTags('TeInfoPatrimonio7',
                                                          strCollectsPatrimonioLast);
    End;
  btCombosUpdate.Enabled := true;
  Application.ProcessMessages;
end;

procedure TfrmMapaCacic.AtualizaPatrimonio(Sender: TObject);
var strColetaAtual,
    strRetorno: String;
begin

  Mensagem('Enviando Informações Coletadas ao Banco de Dados...',false,1);

  strFieldsAndValuesToRequest := 'CollectType=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt('col_patr')) ;

  strColetaAtual := StringReplace('[TeInfoPatrimonio1]'   + edTePatrimonioPc.Text      + '[/TeInfoPatrimonio1]'           +
                                  '[TeInfoPatrimonio2]'   + edTeInfoUserLogado.Text    + '[/TeInfoPatrimonio2]'                 +
                                  '[TeInfoPatrimonio3]'   + edTeInfoNome.Text          + '[/TeInfoPatrimonio3]'                 +
                                  '[TeInfoPatrimonio4]'   + edTeInfoIpComputador.Text  + '[/TeInfoPatrimonio4]'                   +
                                  '[TeInfoPatrimonio5]'   + edTeInfoNomeComputador.Text+ '[/TeInfoPatrimonio5]'         +
                                  '[TeInfoPatrimonio6]'   + edTeInfoPatrimonio5.Text   + '[/TeInfoPatrimonio6]'          +
                                  '[TeInfoPatrimonio7]'   + edTeInfoPatrimonio6.Text   + '[/TeInfoPatrimonio7]',',','[[COMMA]]',[rfReplaceAll]);

  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',col_patr='  +
                                 objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));

  strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'gercols/set/collects', strFieldsAndValuesToRequest,
                     objCacic.getLocalFolderName);

  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  if (strRetorno = '0') then
      Mensagem('ATENÇÃO: PROBLEMAS NO ENVIO DAS INFORMAÇÕES COLETADAS AO BANCO DE DADOS...',true,1)
  else
    Begin
      Mensagem('Salvando Informações Coletadas em Base Local...',false,1);
      objCacic.setValueToFile('Collects','Patrimonio_Last' ,
                              objCacic.enCrypt(strColetaAtual), strGerColsInfFileName);

    End;
  objCacic.writeDebugLog(#13#10 + 'AtualizaPatrimonio: Dados Enviados ao Servidor!');
  Application.ProcessMessages;

  EstadoBarraTarefa(TRUE);
  Finalizar(true);

end;


procedure TfrmMapaCacic.MontaInterface;
var strConfigsPatrimonioInterface : String;
Begin
   btCombosUpdate.Enabled := false;

   Mensagem('Montando Interface para Coleta de Informações...',false,1);


 //-------------------------------NOME USUARIO-----------------------------------
   edTeInfoNome.Text                         := 'Nome';
   if edTeInfoNome.Text <> '' then
   begin
      edTeInfoNome.Visible                   := true;
      lbEtiquetaNome.Visible                 := true;
   end;

//-----------------------NOME DO COMPUTADOR PARA O EDTEXT-----------------------
   edTeInfoNomeComputador.Text               := NomeComputador;
   if edTeInfoNomeComputador.Text <> '' then
   begin
      lbEtiquetaNomeComputador.Visible       := true;
      edTeInfoNomeComputador.Visible         := true;
   end;
   lbEtiquetaNomeComputador.Visible          := true;
   edTeInfonomeComputador.Visible            := true;

//-----------------------------USUARIO LOGADO-----------------------------------

   edTeInfoUserLogado.Text                   := UserName;
   if edTeInfoUserLogado.Text <> '' then
   begin
      lbEtiquetaUserLogado.Visible           := true;
      edTeInfoUserLogado.Visible             := true;
   end;

//-------------------------------CPF USUARIO------------------------------------

{   edTeInfoCpfUser.Text                      := FormatarCpf(SetCpfUser);
   if edTeInfoCpfUser.Text <> '' then
   begin
      lbEtiquetaCpfUser.Visible              := true;
      edTeInfoCpfUser.Visible                := true;
   end;}

//-----------------------PUXA O IP DA MÁQUINA PARA O EDTEXT-------------------------------------
   edTeInfoIpComputador.Text                 := idipwatch1.LocalIP;
   if edTeInfoIpComputador.Text <> '' then
   begin
      lbEtiquetaIpComputador.Visible         := true;
      edTeInfoIpComputador.Visible           := true;
   end;

//-------------------------PATRIMONIO DA MAQUINA--------------------------------
{   edTePatrimonioPc.Text                     := SetPatrimonioPc;
   if edTePatrimonioPc.Text <> '' then
   Begin
      lbEtiquetaPatrimonioPc.Visible         := true;
      edTePatrimonioPc.Visible               := true;
   end;}
   edTePatrimonioPc.Text                     := strTeInfoPatrimonio1;
   edTePatrimonioPc.Visible                  := true;
   lbEtiquetaPatrimonioPc.Visible            := true;


   //----------VALOR DE strGerColsInfFileName ALTERADO PARA ARQUIVO TESTE-----------------------------
   strConfigsPatrimonioInterface := objCacic.deCrypt(objCacic.getValueFromFile('Configs','Patrimonio_Interface',strGerColsInfFileName));

  { objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueobjCacic.enCta1 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta1',
                                                    strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta1', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta1.Caption         := objCacic.getValueFromTags('te_etiqueta1', strConfigsPatrimonioInterface);
      lbEtiqueta1.Visible         := true;
      edTeInfoPatrimonio1.Hint    := objCacic.getValueFromTags('te_help_etiqueta1', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio1.Text    := strTeInfoPatrimonio1;
      edTeInfoPatrimonio1.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta2 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta2',
                                                   strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta2', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta2.Caption         := objCacic.getValueFromTags('te_etiqueta2', strConfigsPatrimonioInterface);
      lbEtiqueta2.Visible         := true;
      edTeInfoPatrimonio2.Hint    := objCacic.getValueFromTags('te_help_etiqueta2', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio2.Text    := strTeInfoPatrimonio2;
      edTeInfoPatrimonio2.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta3 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta3',
                                                     strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta3', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta3.Caption         := objCacic.getValueFromTags('te_etiqueta3', strConfigsPatrimonioInterface);
      lbEtiqueta3.Visible         := true;
      edTeInfoPatrimonio3.Hint    := objCacic.getValueFromTags('te_help_etiqueta3', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio3.Text    := strTeInfoPatrimonio3;
      edTeInfoPatrimonio3.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta4 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta4',
                                                    strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta4.Caption         := objCacic.getValueFromTags('te_etiqueta4', strConfigsPatrimonioInterface);
      lbEtiqueta4.Visible         := true;
      edTeInfoPatrimonio4.Hint    := objCacic.getValueFromTags('te_help_etiqueta4', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio4.Text    := strTeInfoPatrimonio4;
      edTeInfoPatrimonio4.visible := True;
   end;  }

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta5 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta5',
//                                                   strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta5', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta5.Caption         := objCacic.getValueFromTags('te_etiqueta5', strConfigsPatrimonioInterface);
      lbEtiqueta5.Visible         := true;
      edTeInfoPatrimonio5.Hint    := objCacic.getValueFromTags('te_help_etiqueta5', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio5.Text    := strTeInfoPatrimonio6;
      edTeInfoPatrimonio5.visible := True;
//   end;

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta6 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta6',
//                                                    strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta6.Caption         := objCacic.getValueFromTags('te_etiqueta6', strConfigsPatrimonioInterface);
      lbEtiqueta6.Visible         := true;
      edTeInfoPatrimonio6.Hint    := objCacic.getValueFromTags('te_help_etiqueta6', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio6.Text    := strTeInfoPatrimonio7;
      edTeInfoPatrimonio6.visible := True;
//   end;

   Mensagem('',false,1);
   btGravarInformacoes.Visible := true;
   btCombosUpdate.Enabled      := true;

   Application.ProcessMessages;
end;

procedure TfrmMapaCacic.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  If Not fechar Then //se a variavel de fechamento fecha estiver falsa
    Action := caNone // nao realizará  nenhuma operação
  Else
  begin
    Action := caFree;
    objCacic.writeDebugLog('FormClose: ' + Sender.ClassName);
    Finalizar(true);
  end;
end;


procedure TfrmMapaCacic.mapa;
begin
  Try
    MontaInterface;
    RecuperaValoresAnteriores;
  Except
    on E:Exception do
       Begin
         objCacic.writeExceptionLog(E.Message,e.ClassName);
       End;
  End;
End;

procedure TfrmMapaCacic.FormCreate(Sender: TObject);

begin


  frmMapaCacic.boolAcessoOK := true;
  Fechar:=TRUE; //Definido TRUE para que a aplicação possa ser fechada normalmente
  foco:=True; //DEFINIDO COMO TRUE PARA QUE A JANELA NÃO SEJA FECHADA
  Try
    strFrmAtual  := 'Principal';
    objCacic     := TCACIC.Create();

    objCacic.setBoolCipher(true);
    objCacic.setLocalFolderName('Cacic');
    objCacic.setWebServicesFolderName('/ws');

    //Se foco for verdadeiro, executar procedimento SetFocus, o qual modifica
    //propriedades do form e starta o timer para esconder o processo no gerenciador.
    if foco then
    begin
        //TfrmMapaCacic.OnChange := FormSetFocus;
        FormSetFocus;
    end;

    if IsUserAnAdmin then
      Begin
        strChkSisInfFileName := objCacic.getWinDir + 'chksis.inf';

        Mensagem('Caminho local para a aplicação CACIC: "' +
                  objCacic.GetValueFromFile('Configs','LocalFolderName',
                                            strChkSisInfFileName)+'"');
        if not (objCacic.GetValueFromFile('Configs','LocalFolderName',
                                          strChkSisInfFileName) = '') then

          Begin

            objCacic.setLocalFolderName(objCacic.GetValueFromFile
                                        ('Configs', 'LocalFolderName',
                                        strChkSisInfFileName));

            objCacic.setWebServicesFolderName(objCacic.GetValueFromFile
                                              ('Configs','WebServicesFolderName',
                                               strChkSisInfFileName));

            objCacic.setWebManagerAddress(objCacic.GetValueFromFile
                                          ('Configs','WebManagerAddress',
                                          strChkSisInfFileName));


            strGerColsInfFileName := objCacic.getLocalFolderName + 'GerCols.inf';

            // A existência e bloqueio do arquivo abaixo evitará que o Agente Principal entre em ação

//ATENÇÃO-> O caminho do arquivo "aguarde_MAPACACIC.txt" foi modificado, pois o
//agente instalado estava excluíndo sempre que o mesmo era criado, dando conflito
//com o Mapa.

            AssignFile(textFileAguarde,objCacic.getLocalFolderName +
                      '\temp\aguarde_MAPACACIC.txt'); //Associa o arquivo a uma variável do tipo TextFile

            AssignFile(textFileAguarde, 'C:\Documents and Settings\adriano\Desktop\TesteLerArquivo\aguarde_MAPACACIC.txt');

            //$IOChecks off
            Reset(textFileAguarde); //Abre o arquivo texto
            //$IOChecks on
            if (IOResult <> 0) then // Arquivo não existe, será recriado.
              Rewrite (textFileAguarde);

            Append(textFileAguarde);
            Writeln(textFileAguarde,'Apenas um pseudo-cookie para o Agente Principal esperar o término de MapaCACIC');
            Append(textFileAguarde);

            frmMapaCacic.edWebManagerAddress.Caption := objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName);

            frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autenticação no Módulo Gerente WEB Cacic';
            objCacic.writeDebugLog('FormActivate: Versão do MapaCacic...: '    +
                                    pnVersao.Caption);
            objCacic.writeDebugLog('FormActivate: Hash-Code do MapaCacic: '    +
                                    objCacic.getFileHash(ParamStr(0)));

            pnMessageBox.Visible := true;
            Mensagem('Efetuando Comunicação com o Módulo Gerente WEB em "'+objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName)+'"...',false,1);
            // Povoamento com dados de configurações da interface patrimonial
            // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
            pnMessageBox.Visible := false;
            objCacic.writeDebugLog('FormActivate: Requisitando informações de patrimônio da estação...');

            if (getConfigs <> '0') then
              mapa
            else
              Sair;
        end
        else
          Begin
            frmMapaCacic.boolAcessoOK := false;
            MessageDLG(#13#10+'Atenção! É necessário reinstalar o CACIC nesta estação.' + #13#10     + #13#10 +
                              'A estrutura encontra-se corrompida.'   + #13#10,mtError,[mbOK],0);
            Application.ProcessMessages;
            frmMapaCacic.Finalizar(false);
          End;
      End
      else
      Begin // Se NT/2000/XP/...
        MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);
        objCacic.writeDailyLog('SEM PRIVILÉGIOS: Necessário ser administrador "local" ou de Domínio!');
        Sair;
      End      
  Finally
  End;
end;

procedure TfrmMapaCacic.FormActivate(Sender: TObject);
begin
  pnVersao.Caption := 'Versão: ' + objCacic.getVersionInfo(ParamStr(0));
  strFrmAtual := 'Principal';
end;

procedure TfrmMapaCacic.btCombosUpdateClick(Sender: TObject);
begin

  getConfigs;
  MontaInterface;
  RecuperaValoresAnteriores;

end;

procedure TfrmMapaCacic.timerMessageShowTimeTimer(Sender: TObject);
begin
  timerMessageShowTime.Enabled      := false;
  timerMessageShowTime.Interval     := 0;
  strShowOrHide                     := 'Hide';
  timerMessageBoxShowOrHide.Enabled := true;
end;


//------------------------------------------------------------------------------
//PROCEDURE CRIADO PARA DEIXAR O FORM FULLSCREEN E FOCADO, SEM QUE SEJA POSSÍVEL
//FECHAR OU ALTERNAR ENTRE OUTRAS JANELAS ATÉ QUE ATUALIZE O PATRIMONIO.
procedure TfrmMapaCacic.FormSetFocus;
var
  r : TRect;
begin
  Fechar                    := False;
  BorderIcons               := BorderIcons - [biSystemMenu] - [biMinimize] - [biMaximize];
  BorderStyle               := bsNone;
  FormStyle                 := fsStayOnTop;
  timerProcessos.Enabled    := True;
  SystemParametersInfo(SPI_GETWORKAREA, 0, @r,0);
  SetBounds(r.Left, r.Top, r.Right-r.Left, r.Bottom-r.Top);
  Top := 0;
  Left := 0;
  Width := Screen.Width;
  Height := Screen.Height;
  EstadoBarraTarefa(FALSE);

end;

//------------------------------------------------------------------------------
//----------------ESCONDE BARRA DE TAREFAS--------------------------------------
//------------------------------------------------------------------------------

procedure TfrmMapaCacic.EstadoBarraTarefa(EstadoBarra: Boolean);

var wndHandle : THandle;
    wndClass  : array[0..50] of Char;

begin

  StrPCopy(@wndClass[0],'Shell_TrayWnd');
  wndHandle := FindWindow(@wndClass[0], nil);

  If EstadoBarra=True Then
    ShowWindow(wndHandle, SW_RESTORE) {Mostra a barra de tarefas}

  Else
    ShowWindow(wndHandle, SW_HIDE); {Esconde a barra de tarefas}

end;

//------------------------------------------------------------------------------
//-----------------BEGIN-----RETIRA PROCESSO DO GERENCIADOR---------------------
//------------------------------------------------------------------------------

procedure TfrmMapaCacic.timerProcessosTimer(Sender: TObject);
var
  dwSize,dwNumBytes,PID,hProc: Cardinal;
  PLocalShared,PSysShared: PlvItem;
  h: THandle;
  iCount,i: integer;
  szTemp: string;
begin
  //Pega o Handle da ListView
  h:=FindWindow('#32770',nil);
  h:=FindWindowEx(h,0,'#32770',nil);
  h:=FindWindowEx(h,0,'SysListView32',nil);

  //Pega o número de itens da ListView
  iCount:=SendMessage(h, LVM_GETITEMCOUNT,0,0);
  for i:=0 to iCount-1 do
    begin
    //Define o tamanho de cada item da ListView
    dwSize:=sizeof(LV_ITEM) + sizeof(CHAR) * MAX_PATH;

    //Abre um espaço na memória do NOSSO programa para o PLocalShared
    PLocalShared:=VirtualAlloc(nil, dwSize, MEM_RESERVE + MEM_COMMIT, PAGE_READWRITE);

    //Pega o PID do processo taskmgr
    GetWindowThreadProcessId(h,@PID);

    //Abre o processo taskmgr
    hProc:=OpenProcess(PROCESS_ALL_ACCESS,false,PID);

    //Abre um espaço na memória do taskmgr para o PSysShared
    PSysShared:=VirtualAllocEx(hProc, nil, dwSize, MEM_RESERVE OR MEM_COMMIT, PAGE_READWRITE);

    //Define as propriedades do PLocalShared
    PLocalShared.mask:=LVIF_TEXT;
    PLocalShared.iItem:=0;
    PLocalShared.iSubItem:=0;
    PLocalShared.pszText:=LPTSTR(dword(PSysShared) + sizeof(LV_ITEM));
    PLocalShared.cchTextMax:=20;

    //Escreve PLocalShared no espaço de memória que abriu no taskmgr
    WriteProcessMemory(hProc,PSysShared,PLocalShared,1024,dwNumBytes);

    //Pega o texto to item i e passa pro PSysShared
    SendMessage(h,LVM_GETITEMTEXT,i,LPARAM(PSysShared));

    //Passa o PSysShared para o PLocalShared
    ReadProcessMemory(hProc,PSysShared,PLocalShared,1024,dwNumBytes);

    //Passa o texto do Item para szTemp
    szTemp:=pchar(dword(PLocalShared)+sizeof(LV_ITEM));

    //Se esse texto contiver a string proc deleta o item
    if LowerCase(szTemp) = 'mapacacicpgfn.exe' then
      ListView_DeleteItem(h,i);

    //Libera os espaços de memória utilizados
    VirtualFree(pLocalShared, 0, MEM_RELEASE);
    VirtualFreeEx(hProc, pSysShared, 0, MEM_RELEASE);

    //Fecha o handle do processo
    CloseHandle(hProc);
  end;
end;

{raiz ldap
ou=bsa,ou=regbsa,ou=pgfn,dc=mf,dc=gov,dc=br

usuário: ldap
senha: nova4275

host: 10.72.160.21
host: 10.72.160.20

--
 }
{
function connectLDAP(sADForestName, sADUserName, sADGroupName: string);
var ADOConnection, ADOCmd, Res: Variant;
    sBase,
    sFilter,
    sAttributes,
    user: string;

Begin
  ADOConnection := CreateOleObject('ADODB.Connection');
  ADOCmd := CreateOleObject('ADODB.Command');
  try
    ADOConnection.Provider := 'ADsDSOObject';
    ADOConnection.Open('Active Directory Provider');
    ADOCmd.ActiveConnection := ADOConnection;
    ADOCmd.Properties('Page Size')     := 100;
    ADOCmd.Properties('Timeout')       := 30;
    ADOCmd.Properties('Cache Results') := False;
//'SELECT Name, whenCreated FROM \'''LDAP://' + raiz + '''' WHERE objectClass='''user''''
    sBase       := '<GC://' + sADForestName+ '>';
    sFilter     := '(&(objectCategory=person)(objectClass=user)' +
                     '(distinguishedName=' + sADUserName + ')' +
                     '(memberOf:1.2.840.113556.1.4.1941:=' + sADGroupName + '))';
    sAttributes := 'sAMAccountName';

    //ADOCmd.CommandText := sBase + ';' + sFilter + ';' + sAttributes + ';subtree';
    ADOCmd.CommandText := 'SELECT Name, whenCreated FROM \''''LDAP://' + raiz + '''' WHERE objectClass='''user''';
    Res := AdoCmd.Execute;

    if Res.EOF then
        User := ''
    else
        User := Res.Fields[0].Value;
  finally
    ADOCmd := Nil;
    ADOConnection.Close;
    ADOConnection := Nil;
  end;
end;
     }
end.
