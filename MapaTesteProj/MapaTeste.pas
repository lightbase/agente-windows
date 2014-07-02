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
  CACIC_WMI,
  ComCtrls,
  Commctrl,
  ShellAPI,
  Types,
  IdIPWatch,
  Registry,
  Math,
  IdBaseComponent,
  IdComponent,
  Mask,
  ComObj,
  ldapsend,
  MultiMon;

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
    formSecondMonitor           : TForm;

type
  TfrmMapaCacic = class(TForm)
    edWebManagerAddress: TLabel;
    lbWebManagerAddress: TLabel;
    pnVersao: TPanel;
    timerMessageBoxShowOrHide: TTimer;
    timerMessageShowTime: TTimer;
    timerProcessos: TTimer;
    gbLeiaComAtencao: TGroupBox;
    lbLeiaComAtencao: TLabel;
    gbInformacoesSobreComputador: TGroupBox;
    lbEtiqueta3: TLabel;
    lbEtiqueta4: TLabel;
    lbEtiqueta2: TLabel;
    lbEtiqueta8: TLabel;
    lbEtiqueta9: TLabel;
    lbEtiqueta1: TLabel;
    lbEtiqueta5: TLabel;
    edTeInfoPatrimonio3: TEdit;
    edTeInfoPatrimonio4: TEdit;
    btCombosUpdate: TButton;
    edTeInfoPatrimonio2: TEdit;
    edTeInfoPatrimonio8: TEdit;
    edTeInfoPatrimonio9: TEdit;
    edTeInfoPatrimonio1: TEdit;
    edTeInfoPatrimonio5: TEdit;
    bgTermoResponsabilidade: TGroupBox;
    rdConcordaTermos: TRadioButton;
    btGravarInformacoes: TButton;
    lbEtiqueta6: TLabel;
    edTeInfoPatrimonio6: TEdit;
    lbEtiqueta7: TLabel;
    edTeInfoPatrimonio7: TEdit;
    btKonamiCode: TPanel;
    
    procedure FormCreate(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure mapa;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure btCombosUpdateClick(Sender: TObject);
    procedure timerProcessosTimer(Sender: TObject);
    procedure rdConcordaTermosClick(Sender: TObject);
    procedure EstadoBarraTarefa(EstadoBarra: Boolean);

    function getLastValue(S : String; separador, separador2 : string): string; 
    function LDAPName: string;
    function NomeComputador : String;
    function getConfigs : String;
//    function SetCpfUser : String;
//    function SetPatrimonioPC : String;
//    function FormatarCpf(strCpfUser : String) : String;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btKonamiCodeClick(Sender: TObject);


  private
    strTeInfoPatrimonio1,
    strTeInfoPatrimonio2,
    strTeInfoPatrimonio3,
    strTeInfoPatrimonio4,
    strTeInfoPatrimonio5,
    strTeInfoPatrimonio6,
    strTeInfoPatrimonio7,
    strTeInfoPatrimonio8,
    strTeInfoPatrimonio9    : String;
    psswd : String;
    foco : boolean;

    procedure FormSetFocus(VerificaFoco: Boolean);
    procedure MontaInterface;
    procedure RecuperaValoresAnteriores;
    procedure Sair;

  public
    boolAcessoOK                : boolean;
    strId_usuario,
    strChkSisInfFileName,
    strGerColsInfFileName       : String;

    procedure Finalizar;

  end;

const SENHA = 'uuddlrlrba';

var frmMapaCacic: TfrmMapaCacic;

implementation

{$R *.dfm}


procedure TfrmMapaCacic.Sair;
Begin
    Application.Terminate;
End;

procedure TfrmMapaCacic.Finalizar;
Begin
  Visible                               := false;

  reset(textFileAguarde);
  objCACIC.deleteFileOrFolder(objCacic.getLocalFolderName +
                   '\temp\aguarde_MAPACACIC.txt');
  Application.ProcessMessages;

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
//----------------------FUNÇÃO PARA RETORNAR O PATRIMONIO-----------------------
//------------------------------------------------------------------------------

//function TfrmMapaCacic.SetPatrimonioPC : String;
//var
//  strPatrimonioPc,
//  strNomePC        : String;
//begin
//  Result:='';
//  strNomePC:=NomeComputador;
//
//  if (pos('-',strNomePC) > 0) then
//    strPatrimonioPc:=copy(strNomePC, 0, (pos('-', strNomePC)-1));
//  Result:=strPatrimonioPC;
//end;

//------------------------------------------------------------------------------
//--------------------FUNÇÃO PARA FORMATAR O CPF--------------------------------
//------------------------------------------------------------------------------

//function TfrmMapaCacic.FormatarCpf(strCpfUser : String) : String;
//var
//  strCpfFormatado : String;
//begin
//  Result:='';
//  strCpfFormatado:= Copy(strCpfUser, 1,3)
//
//            + '.' + Copy(strCpfUser, 4,3)
//
//            + '.' + Copy(strCpfUser, 7,3)
//
//            + '-' + Copy(strCpfUser, 10,2);
//  Result:=strCpfFormatado;
//
//end;
//------------------------------------------------------------------------------
//--------------------FUNÇÃO PARA RETORNAR O CPF DO USUARIO---------------------
//------------------------------------------------------------------------------

//function TfrmMapaCacic.SetCpfUser : String;
//var
//  strCpfUser,
//  strUser        : String;
//begin
//  Result:='';
//  strUser:=strTeInfoPatrimonio3;
//
//  if (pos('-',strUser) > 0) then
//    strCpfUser:=copy(strUser, 0, (pos('-', strUser)-1));
//
//  Result:=strCpfUser;
//end;

//------------------------------------------------------------------------------
//--------------------FUNÇÃO PARA RETORNAR O ULTIMO VALOR-----------------------
//-----------------------APÓS O SEPARADOR SELECIONADO---------------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.getLastValue(S : String; separador, separador2 : string): string;
  var
  conta, tamanho_separador, tamanho_separador2 : integer;         // variáveis auxiliares
  resultado : TStringList; // variáveis auxiliares
  Saux, index : string;           // variáveis auxiliares
begin
    resultado := TStringList.Create;   // inicializa variavel
    tamanho_separador:= Length(separador);
    tamanho_separador2:= Length(separador2);
    index:=copy(separador2, 1, pos(#$D#$A, separador2)-1);
    conta := pos(separador,S)+tamanho_separador;         // pega posição do separador
    if conta <> 0 then begin           // verifica se existe o separador caso contrario trata apenas //como uma única linha
        while trim(S) <> '' do begin   // enquanto S não for nulo executa
            Saux := copy(S,1,conta-1); // Variável Saux recebe primeiro valor
            delete(S,1,conta);         // deleta primeiro valor
            if conta = 0 then begin    // se não ouver mais separador Saux equivale ao resto da //linha
                Saux := S;
                S := '';
            end;
            if pos(separador2, Saux)>0 then begin
              delete(Saux, 1, tamanho_separador2);
              resultado.values[index]:=
                copy(Saux,1,pos(#$D#$A, Saux));
              break;
            end;
            resultado.add(Saux);           // adiciona linhas na string lista
            conta := pos(separador,S);     //pega posição do separador
        end;
    end
    else begin
        Saux := S;
        resultado.Add(Saux);
    end;
    Result := trim(resultado.values[index]); // retorna resultado como uma lista indexada
end;

//------------------------------------------------------------------------------
//--------------------FUNÇÃO PARA PEGAR CONFIGURAÇÕES NO GERENTE----------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.getConfigs : String;
var
   teste : string;
Begin
  btCombosUpdate.Enabled := false;
  objCACIC.writeDailyLog('getConfigs: Invocando getConfigs...');
  Result := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);

  objCacic.setBoolCipher(not objCacic.isInDebugMode);
  objCacic.writeDebugLog('FormActivate: Retorno de getConfigs: "'+Result+'"');

  if (Result <> '0') then
    Begin
      objCACIC.writeDailyLog('getConfigs: Comunicação realizada com sucesso!');
      objCacic.setValueToFile('Configs' ,'modulo_patr'          , objCacic.getValueFromTags('modPatrimonio'                    , Result, '<>'), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'servidor_autenticacao', objCacic.getValueFromTags('dados_ldap'                  , Result), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Combos'    , objCacic.getValueFromTags('Configs_Patrimonio_Combos'   , Result), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Interface' , objCacic.getValueFromTags('Configs_Patrimonio_Interface', Result), strGerColsInfFileName);
    End
  else
    begin
      MessageDlg(#13#13+'Não foi possível realizar a conexão!',mtError, [mbOK], 0);
    end;
  btCombosUpdate.Enabled := true;
End;

//------------------------------------------------------------------------------
//--------------------PROCEDIMENTO UTILIZADO PARA PEGAR AS ULTIMAS--------------
//----------------------INFORMAÇÕES ENVIADAS PELO MAPACACIC---------------------

procedure TfrmMapaCacic.RecuperaValoresAnteriores;
var strCollectsPatrimonioLast : String;
begin
  objCACIC.writeDailyLog('RecuperaValoresAnteriores: Início.');
  btCombosUpdate.Enabled := false;

  strCollectsPatrimonioLast := objCacic.deCrypt( objCacic.GetValueFromFile
                                                ('Collects','col_patr_last',
                                                 strGerColsInfFileName));

  if (strCollectsPatrimonioLast <> '') then
    Begin

      if (strTeInfoPatrimonio1='') then
        strTeInfoPatrimonio1 := objCacic.getValueFromTags('IDPatrimonio',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio2='') then
        strTeInfoPatrimonio2 := objCacic.getValueFromTags('UserLogado',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio3='') then
        strTeInfoPatrimonio3 := objCacic.getValueFromTags('PatrimonioMonitor1',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio4='') then
        strTeInfoPatrimonio4 := objCacic.getValueFromTags('PatrimonioMonitor2',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio5='') then
        strTeInfoPatrimonio5 := objCacic.getValueFromTags('UserName',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio6='') then
        strTeInfoPatrimonio6 := objCacic.getValueFromTags('Sala',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio7='') then
        strTeInfoPatrimonio7 := objCacic.getValueFromTags('Coordenacao_Setor',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio8='') then
        strTeInfoPatrimonio8 := objCacic.getValueFromTags('ComputerName',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio9='') then
        strTeInfoPatrimonio9 := objCacic.getValueFromTags('IPComputer',
                                                          strCollectsPatrimonioLast);
    End;
  btCombosUpdate.Enabled := true;
  Application.ProcessMessages;
  objCACIC.writeDailyLog('RecuperaValoresAnteriores: Fim.');
end;

procedure TfrmMapaCacic.AtualizaPatrimonio(Sender: TObject);
var strColetaAtual,
    strRetorno: String;
begin
if edTeInfoPatrimonio5.text <> '' then
  begin
    btGravarInformacoes.Enabled := false;
    btGravarInformacoes.Caption := 'Enviando informações...';
    objCACIC.writeDailyLog('Preparando para o envio das informações...');
    strFieldsAndValuesToRequest := 'CollectType=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt('col_patr')) ;

    strColetaAtual := StringReplace('[IDPatrimonio]'         + edTeInfoPatrimonio1.Text   + '[/IDPatrimonio]'       +
                                    '[UserLogado]'           + edTeInfoPatrimonio2.Text   + '[/UserLogado]'         +
                                    '[PatrimonioMonitor1]'   + edTeInfoPatrimonio3.Text   + '[/PatrimonioMonitor1]' +
                                    '[PatrimonioMonitor2]'   + edTeInfoPatrimonio4.Text   + '[/PatrimonioMonitor2]' +
                                    '[UserName]'             + edTeInfoPatrimonio5.Text   + '[/UserName]'           +
                                    '[Sala]'                 + edTeInfoPatrimonio6.Text   + '[/Sala]'               +
                                    '[Coordenacao_Setor]'    + edTeInfoPatrimonio7.Text   + '[/Coordenacao_Setor]'  +
                                    '[ComputerName]'         + edTeInfoPatrimonio8.text   + '[/ComputerName]'       +
                                    '[IPComputer]'           + edTeInfoPatrimonio9.text   + '[/IPComputer]'
                                    , ',','[[COMMA]]',[rfReplaceAll]);

    strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Patrimonio='  +
                                   objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));

    strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName +
                        'gercols/set/collects', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);

    objCacic.setBoolCipher(not objCacic.isInDebugMode);

    if (strRetorno = '0') then
    begin
       btGravarInformacoes.caption := 'Problema ao enviar informações...';
       Application.messagebox(Pchar('Atenção!'+ #13#10 + 'Problema ao enviar as informações!'
               + #13#10 + 'Se o problema persistir contate o adminsitrador.'), 'Erro!',MB_ICONERROR + mb_ok);
    end
    else
    Begin
        objCACIC.writeDailyLog('Envio realizado com sucesso.');
        btGravarInformacoes.Caption := 'Informações enviadas com sucesso...';
        objCacic.setValueToFile('Collects','col_patr_last' ,
                                objCacic.enCrypt(strColetaAtual), strGerColsInfFileName);
        objCacic.setValueToFile('Configs','col_patr_exe', 's', strGerColsInfFileName);

    End;
    objCacic.writeDebugLog(#13#10 + 'AtualizaPatrimonio: Dados Enviados ao Servidor!');
    Application.ProcessMessages;

    Finalizar;
  end
  else
    Application.messagebox(Pchar('Por favor, é necessário digitar seu nome!'), 'Atenção!',MB_ICONEXCLAMATION + mb_ok);
end;


procedure TfrmMapaCacic.MontaInterface;
var strConfigsPatrimonioInterface,
    strNomeLDAP : String;
Begin
    btCombosUpdate.Enabled := false;

    strConfigsPatrimonioInterface := objCacic.deCrypt(objCacic.getValueFromFile
                                                      ('Configs','Patrimonio_Interface',
                                                      strGerColsInfFileName));

//-------------------------PATRIMONIO DA MAQUINA--------------------------------
{   edTePatrimonioPc.Text                     := SetPatrimonioPc;
   if edTePatrimonioPc.Text <> '' then
   Begin
      lbEtiquetaPatrimonioPc.Visible         := true;
      edTePatrimonioPc.Visible               := true;
   end;}
    edTeInfoPatrimonio1.Text        := strTeInfoPatrimonio1;
    edTeInfoPatrimonio1.Visible     := true;
    lbEtiqueta1.Visible             := true;

//-----------------------------USUARIO LOGADO-----------------------------------

//    edTeInfoUserLogado.Text                   := getUserLogon;
    strTeInfoPatrimonio2:=objCACIC.getValueFromTags('UserName',fetchWMIvalues('Win32_ComputerSystem',objCACIC.getLocalFolderName,'UserName'));
    strTeInfoPatrimonio2:=copy(strTeInfoPatrimonio2, pos('\', strTeInfoPatrimonio2)+1, length(strTeInfoPatrimonio2));
    edTeInfoPatrimonio2.Text:=strTeInfoPatrimonio2;
    if edTeInfoPatrimonio2.Text <> '' then
    begin
       lbEtiqueta2.Visible          := true;
       edTeInfoPatrimonio2.Visible  := true;
    end;

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta3 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta3',
//                                                   strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta3', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta3.Caption         := objCacic.getValueFromTags('te_etiqueta3', strConfigsPatrimonioInterface);
       lbEtiqueta3.Visible          := true;
       edTeInfoPatrimonio3.Hint     := objCacic.getValueFromTags('te_help_etiqueta3', strConfigsPatrimonioInterface);
       edTeInfoPatrimonio3.Text     := strTeInfoPatrimonio3;
       edTeInfoPatrimonio3.visible  := True;
//   end;

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta4 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta4',
//                                                    strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta4.Caption         := objCacic.getValueFromTags('te_etiqueta4', strConfigsPatrimonioInterface);
      lbEtiqueta4.Visible           := true;
      edTeInfoPatrimonio4.Hint      := objCacic.getValueFromTags('te_help_etiqueta4', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio4.Text      := strTeInfoPatrimonio4;
      edTeInfoPatrimonio4.visible   := True;
//   end;

    //-------------------------------NOME USUARIO-----------------------------------
    strNomeLDAP := getLastValue(LDAPName, 'Attribute:', 'cn'+#$D#$A);


    if (strNomeLDAP <> '') and (strNomeLDAP <> 'Results: 0') then
    begin
       edTeInfoPatrimonio5.Text     := strNomeLDAP;
       edTeInfoPatrimonio5.Visible  := true;
       lbEtiqueta5.Visible          := true;
       lbEtiqueta5.ShowHint         := true;
       lbEtiqueta5.hint             := 'Nome do usuário logado.';
    end
    else
    begin
       edTeInfoPatrimonio5.Visible  := true;
       edTeInfoPatrimonio5.Enabled  := true;
       lbEtiqueta5.Visible          := true;
       lbEtiqueta5.ShowHint         := true;
       lbEtiqueta5.hint             := 'Digite seu nome, não foi possível recuperá-lo.';
    end;

//---------------------------------PATRIMONIO MONITORES------------------------------

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta6 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta6',
//                                                    strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta6.Caption         := objCacic.getValueFromTags('te_etiqueta6', strConfigsPatrimonioInterface);
      lbEtiqueta6.Visible           := true;
      edTeInfoPatrimonio6.Hint      := objCacic.getValueFromTags('te_help_etiqueta6', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio6.Text      := strTeInfoPatrimonio6;
      edTeInfoPatrimonio6.visible   := True;
//   end;

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta7 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta7',
//                                                    strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta7', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta7.Caption         := objCacic.getValueFromTags('te_etiqueta7', strConfigsPatrimonioInterface);
      lbEtiqueta7.Visible           := true;
      edTeInfoPatrimonio7.Hint      := objCacic.getValueFromTags('te_help_etiqueta7', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio7.Text      := strTeInfoPatrimonio7;
      edTeInfoPatrimonio7.visible   := True;
//   end;

//-----------------------NOME DO COMPUTADOR PARA O EDTEXT-----------------------
    edTeInfoPatrimonio8.Text               := NomeComputador;
    if edTeInfoPatrimonio8.Text <> '' then
    begin
       lbEtiqueta8.Visible          := true;
       edTeInfoPatrimonio8.Visible  := true;
    end;
    lbEtiqueta8.Visible             := true;
    edTeInfoPatrimonio8.Visible     := true;

//-----------------------PUXA O IP DA MÁQUINA PARA O EDTEXT-------------------------------------
    strTeInfoPatrimonio9            := fetchWMIvalues('Win32_NetworkAdapterConfiguration', objCACIC.getLocalFolderName);
    edTeInfoPatrimonio9.Text        := objCACIC.getValueFromTags('IPAddress',strTeInfoPatrimonio9);
    if edTeInfoPatrimonio9.Text <> '' then
    begin
       lbEtiqueta9.Visible          := true;
       edTeInfoPatrimonio9.Visible  := true;
    end;

    btGravarInformacoes.Visible := true;
    btCombosUpdate.Enabled      := true;
    Application.ProcessMessages;
    objCACIC.writeDailyLog('Interface criada com sucesso.');
end;

procedure TfrmMapaCacic.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  If Not fechar Then //se a variavel de fechamento fecha estiver falsa
    Action := caNone // nao realizará  nenhuma operação
  Else
  begin
    Action := caFree;
    formSecondMonitor:=nil;
    objCacic.writeDebugLog('FormClose: ' + Sender.ClassName);
    Finalizar;
  end;
end;


procedure TfrmMapaCacic.mapa;
begin
  Try
    RecuperaValoresAnteriores;
    MontaInterface;
  Except
    on E:Exception do
       Begin
         Application.messagebox(Pchar('Problemas ao gerar formulário.'), 'Erro!',MB_ICONERROR + mb_ok);
//         EstadoBarraTarefa(TRUE);
         objCacic.writeExceptionLog(E.Message,e.ClassName);
         Finalizar;
       End;
  End;
End;

procedure TfrmMapaCacic.FormCreate(Sender: TObject);

begin
  psswd := '';
  KeyPreview := true;
  frmMapaCacic.boolAcessoOK := true;
//Definido TRUE, se não, mesmo que o foco seja falso, a aplicação não é fechada quando quiser.
  Fechar:=TRUE;
  foco:=true; //DEFINIDO COMO TRUE PARA QUE A JANELA NÃO SEJA FECHADA

  
  Try
    strFrmAtual  := 'Principal';
    objCacic     := TCACIC.Create();

    objCacic.setBoolCipher(true);
    objCacic.setLocalFolderName('Cacic');
    objCacic.setWebServicesFolderName('/ws');

    if IsUserAnAdmin then
    begin
      strChkSisInfFileName := objCacic.getWinDir + 'chksis.inf';

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

        AssignFile(textFileAguarde,objCacic.getLocalFolderName +
                   '\temp\aguarde_MAPACACIC.txt'); //Associa o arquivo a uma variável do tipo TextFile

        {$IOChecks off}

        reset(textFileAguarde);

        {$IOChecks on}
        if (IOResult <> 0) then // Arquivo não existe, será recriado.
            rewrite (textFileAguarde); //Abre o arquivo texto

        Append(textFileAguarde);
        Writeln(textFileAguarde,'Apenas um pseudo-cookie para o Agente Principal esperar o término de MapaCACIC');
        Append(textFileAguarde);

        frmMapaCacic.edWebManagerAddress.Caption := objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName);

        objCacic.writeDebugLog('FormActivate: Versão do MapaCacic...: '    +
                                pnVersao.Caption);
        ObjCacic.writeDebugLog('FormActivate: Hash-Code do MapaCacic: '    +
                                objCacic.getFileHash(ParamStr(0)));

        // Povoamento com dados de configurações da interface patrimonial
        // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
        objCacic.writeDebugLog('FormActivate: Requisitando informações de patrimônio da estação...');

        if getConfigs <> '0' then
        begin
          if (objCACIC.getValueFromFile('Configs',
                                        'modulo_patr',
                                        strGerColsInfFileName) = 'S') then
          begin
            objCACIC.writeDailyLog('Iniciando formulário.');
            mapa;
            FormSetFocus(foco)
          end
          else
          begin
            objCACIC.writeDailyLog('Modulo desabilitado.');
            Finalizar;
          end;
        end
        else
        begin
           objCACIC.writeDailyLog('Falha ao pegar informações!.');
           Finalizar;
        end;
      end
      else
      Begin
        frmMapaCacic.boolAcessoOK := false;
        MessageDLG(#13#10+'Atenção! É necessário reinstalar o CACIC nesta estação.' + #13#10     + #13#10 +
                          'A escctrutura encontra-se corrompida.'   + #13#10,mtError,[mbOK],0);
        Application.ProcessMessages;
        frmMapaCacic.Finalizar;
      End;
    end
    else
    Begin // Se NT/2000/XP/...
      Application.messagebox(Pchar('ATENÇÃO! Essa aplicação requer execução com nível administrativo.'), 'Erro!',MB_ICONERROR + mb_ok);
      objCacic.writeDailyLog('SEM PRIVILÉGIOS: Necessário ser administrador "local" ou de Domínio!');
      Finalizar;
    End;
  Finally
  End;
end;


procedure TfrmMapaCacic.FormActivate(Sender: TObject);

begin
  pnVersao.Caption := 'Versão: ' + objCacic.getVersionInfo(ParamStr(0));
  strFrmAtual := 'Principal';
  //ESCONDE APLICAÇÃO DA TASKBAR -- DEVE SER COLOCADA NO OnActivate
  Application.MainFormOnTaskBar:=FALSE;
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TfrmMapaCacic.btCombosUpdateClick(Sender: TObject);
begin

  getConfigs;
  RecuperaValoresAnteriores;
  MontaInterface;

end;

procedure TfrmMapaCacic.btKonamiCodeClick(Sender: TObject);
begin
  finalizar;
end;

//------------------------------------------------------------------------------
//PROCEDURE CRIADO PARA DEIXAR O FORM FULLSCREEN E FOCADO, SEM QUE SEJA POSSÍVEL
//FECHAR OU ALTERNAR ENTRE OUTRAS JANELAS ATÉ QUE ATUALIZE O PATRIMONIO.
procedure TfrmMapaCacic.FormSetFocus(VerificaFoco: Boolean);
var
  r : TRect;
begin
  if VerificaFoco then
  begin
    Fechar                    := False;
    BorderIcons               := BorderIcons - [biSystemMenu] - [biMinimize] - [biMaximize];
    BorderStyle               := bsNone;
    FormStyle                 := fsStayOnTop;
    Position                  := poOwnerFormCenter;
    timerProcessos.Enabled    := True;
    SystemParametersInfo(SPI_GETWORKAREA, 0, @r,0);
    SetBounds(r.Left, r.Top, r.Right-r.Left, r.Bottom-r.Top);
    Top := Screen.WorkAreaTop;
    Left := Screen.WorkAreaLeft;
    Width := Screen.WorkAreaWidth;
    Height := Screen.Height;
    {    if Screen.MonitorCount>1 then
    begin
      formSecondMonitor := TForm.Create(nil);
      for i := 0 to Screen.MonitorCount - 1 do
      begin
        if not Screen.Monitors[i].Primary then
          formSecondMonitor.WindowState := wsNormal;
          formSecondMonitor.BorderStyle := bsNone;
          formSecondMonitor.Width := Screen.Monitors[i].Width;
          formSecondMonitor.Height := Screen.Monitors[i].Height;
          formSecondMonitor.top := Screen.Monitors[i].top;
          formSecondMonitor.left := Screen.Monitors[i].left;
          formSecondMonitor.Enabled := true;
          formSecondMonitor.Visible:=true;
      end;
    end;
       }

//  EstadoBarraTarefa(FALSE);

  end;

end;

//CODE PRA FECHAR O MAPA SEM PRESSIONAR NADA. (up + up + down + down + <- + -> + <- + -> + B + A)
procedure TfrmMapaCacic.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  case Key of
    VK_Left : psswd:=psswd+'l';
    VK_Right : psswd:=psswd+'r';
    VK_Up : psswd:=psswd+'u';
    VK_Down : psswd:=psswd+'d';
    65 : psswd:=psswd+'a';
    66 : psswd:=psswd+'b';
    else
      psswd:='';
  end;
  if psswd = SENHA then begin
    FormStyle                 := fsNormal;
    MessageDlg('KONAMICODE ACTIVATED!',mtWarning, [mbOK], 0);
    btKonamiCode.Left    := width-btKonamiCode.Width;
    btKonamiCode.visible := true;
    btKonamiCode.enabled := true;
  end;
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
    if LowerCase(szTemp) = 'mapacacic.exe' then
      ListView_DeleteItem(h,i);

    //Libera os espaços de memória utilizados
    VirtualFree(pLocalShared, 0, MEM_RELEASE);
    VirtualFreeEx(hProc, pSysShared, 0, MEM_RELEASE);

    //Fecha o handle do processo
    CloseHandle(hProc);
  end;
end;

function TfrmMapaCacic.LDAPName: string;
var
  retorno: TStringList;
  i: integer;
  host, username, psswd, base, strDadosLDAP, aux, identificador : string;
  ldap: TLDAPsend;

begin
  result            := '';

//  PEGANDO OS DADOS DO POR MEIO DO GET/CONFIGS, ONDE SERÁ GRAVADO NO GERCOLS.INF
  strDadosLDAP := objCacic.deCrypt(objCacic.getValueFromFile('Configs','servidor_autenticacao',strGerColsInfFileName));
  if strDadosLDAP<>'' then
  begin
    ldap              := TLDAPsend.Create;
    retorno           := TStringList.Create;

    host         := objCacic.getValueFromTags('ip', strDadosLDAP);
    username     := objCacic.getValueFromTags('usuario', strDadosLDAP);
    psswd        := objCacic.getValueFromTags('senha', strDadosLDAP);
    base         := objCacic.getValueFromTags('base', strDadosLDAP);
    identificador:= objCacic.getValueFromTags('identificador', strDadosLDAP);
    for i := 0 to 2 do //Até 2 porque são no máxio 3 identificadores que serão passados.
    begin
      aux:=objCacic.getValueFromTags('retorno'+IntToStr(i+1), strDadosLDAP);
      if aux<>'' then
        retorno.Add(aux);
    end;
    if (host<>'') and (base<>'') and (retorno.count<>0) and (username<>'') then
    begin
      try
        try
         objCACIC.writeDailyLog('Nome Usuário: Estabelecendo conexão.');
         ldap.TargetHost := host;
         ldap.UserName   := username;
         ldap.Password   := psswd;
         ldap.Timeout    := 5000;
         if ldap.Login and ldap.Bind then    //Loga no LDAP e autentica no LDAP com Usuário e senha repassado. (BindSasl é mais seguro que Bind)
         begin
         // 41680200020

          ldap.Search(base, False, identificador+ '=' + strTeInfoPatrimonio2, retorno); //Faz a pesquisa, com o CPF repassado.
          result := LDAPResultdump(ldap.SearchResult);
          objCACIC.writeDailyLog('Nome Usuário: Conexão estabelecida, pesquisa realizada.');
          ldap.Logout;
         end;
        finally
         ldap.Free;
         retorno.Free;
        end;
      Except
        on E:Exception do
           Begin
             MessageDlg(#13#13+'Problemas para pegar nome do usuário.'+#13#13+
                        'Por favor, digite seu nome no campo solicitado',mtError, [mbOK], 0);
             objCacic.writeExceptionLog(E.Message,e.ClassName);
             objCACIC.writeDailyLog('Nome Usuário: Falha ao tentar recuperar o nome.');
           End; //on E:Exception do
      end; // Try
    end; // if (host<>'') or (base<>'') or (retorno.count=0) then
  end  //if strDadosLDAP<>'' then
  else
    objCACIC.writeDailyLog('Nome Usuário: Dados do servidor de autenticação inexistentes.');
end;




end.
