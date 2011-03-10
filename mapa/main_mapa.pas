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

unit main_mapa;

interface

uses
  Windows,
  Sysutils,    // Deve ser colocado após o Windows acima, nunca antes
  strutils,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  IdBaseComponent,
  IdComponent,
  WinSock,
  NB30,
  StdCtrls,
  Controls,
  Classes,
  Forms,
  ExtCtrls,
  Graphics,
  Dialogs,
  CACIC_Library,
  LibXmlParser; // Usado em MontaCombos

var
  intPausaPadrao            : integer;

var v_Aguarde               : TextFile;

var
  boolDebugs,
  boolFinalizar             : boolean;

var
  g_oCacic                   : TCACIC;  

type
  TfrmMapaCacic = class(TForm)
    gbLeiaComAtencao: TGroupBox;
    lbLeiaComAtencao: TLabel;
    gbInformacoesSobreComputador: TGroupBox;
    lbEtiqueta1: TLabel;
    lbEtiqueta2: TLabel;
    lbEtiqueta3: TLabel;
    cb_id_unid_organizacional_nivel1: TComboBox;
    cb_id_unid_organizacional_nivel2: TComboBox;
    ed_te_localizacao_complementar: TEdit;
    btGravarInformacoes: TButton;
    lbEtiqueta4: TLabel;
    lbEtiqueta5: TLabel;
    lbEtiqueta6: TLabel;
    lbEtiqueta7: TLabel;
    lbEtiqueta8: TLabel;
    lbEtiqueta9: TLabel;
    ed_te_info_patrimonio1: TEdit;
    ed_te_info_patrimonio2: TEdit;
    ed_te_info_patrimonio3: TEdit;
    ed_te_info_patrimonio4: TEdit;
    ed_te_info_patrimonio5: TEdit;
    ed_te_info_patrimonio6: TEdit;
    pnMensagens: TPanel;
    lbMensagens: TLabel;
    lbEtiqueta1a: TLabel;
    cb_id_unid_organizacional_nivel1a: TComboBox;
    Panel1: TPanel;
    lbTeWebManagerAddress: TLabel;
    lbVersao: TLabel;
    edTeWebManagerAddress: TLabel;

    procedure mapa;
    procedure MontaCombos(p_strConfigs : String);
    procedure MontaInterface(p_strConfigs : String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cb_id_unid_organizacional_nivel1Change(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure RecuperaValoresAnteriores(p_strConfigs : String);
    procedure CriaFormSenha(Sender: TObject);
    Function  ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
    procedure Finalizar(p_pausa:boolean);
    procedure Sair;
    function  LastPos(SubStr, S: string): Integer;
    Function  Rat(OQue: String; Onde: String) : Integer;
    Function  RetornaValorVetorUON1(id1 : string) : String;
    Function  RetornaValorVetorUON1a(id1a : string) : String;
    Function  RetornaValorVetorUON2(id2,idLocal : string) : String;
    function  LetrasDrives: string;
    function  SearchFile(p_Drive,p_File:string) : boolean;
    procedure GetSubDirs(Folder:string; sList:TStringList);
    procedure Mensagem(p_strMsg : String; p_boolAlerta : boolean; p_intPausaSegundos : integer);
    procedure cb_id_unid_organizacional_nivel1aChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    strId_unid_organizacional_nivel1,
    strId_unid_organizacional_nivel1a,
    strId_unid_organizacional_nivel2,
    strId_Local,
    strTe_localizacao_complementar,
    strTe_info_patrimonio1,
    strTe_info_patrimonio2,
    strTe_info_patrimonio3,
    strTe_info_patrimonio4,
    strTe_info_patrimonio5,
    strTe_info_patrimonio6           : String;
  public
    boolAcessoOK               : boolean;
    strId_usuario              : String;
  end;

var
  frmMapaCacic: TfrmMapaCacic;

implementation

uses acesso, Math;

{$R *.dfm}


// Estruturas de dados para armazenar os itens das Unidades Organizacionais de Níveis 1, 1a e 2
type
  TRegistroUON1 = record
    id1 : String;
    nm1 : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON1a = record
    id1     : String;
    id1a    : String;
    nm1a    : String;
    id_local: String;
  end;

  TVetorUON1a = array of TRegistroUON1a;

  TRegistroUON2 = record
    id1a    : String;
    id2     : String;
    nm2     : String;
    id_local: String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1  : TVetorUON1;
    VetorUON1a : TVetorUON1a;
    VetorUON2  : TVetorUON2;

    // Esse array é usado apenas para saber a uon1a, após a filtragem pelo uon1
    VetorUON1aFiltrado : array of String;

    // Esse array é usado apenas para saber a uon2, após a filtragem pelo uon1a
    VetorUON2Filtrado : array of String;

// Baixada de http://www.geocities.com/SiliconValley/Bay/1058/fdelphi.html
Function TfrmMapaCacic.Rat(OQue: String; Onde: String) : Integer;
//  Procura uma string dentro de outra, da direita para esquerda
//  Retorna a posição onde foi encontrada ou 0 caso não seja encontrada
var
Pos   : Integer;
Tam1  : Integer;
Tam2  : Integer;
Achou : Boolean;
begin
Tam1   := Length(OQue);
Tam2   := Length(Onde);
Pos    := Tam2-Tam1+1;
Achou  := False;
while (Pos >= 1) and not Achou do
      begin
      if Copy(Onde, Pos, Tam1) = OQue then
         begin
         Achou := True
         end
      else
         begin
         Pos := Pos - 1;
         end;
      end;
Result := Pos;
end;

procedure TfrmMapaCacic.Mensagem(p_strMsg : String; p_boolAlerta : boolean; p_intPausaSegundos : integer);
Begin
  g_oCacic.writeDebugLog(p_strMsg);
  if p_boolAlerta then
    lbMensagens.Font.Color := clRed
  else
    lbMensagens.Font.Color := clBlack;

  lbMensagens.Caption := p_strMsg;
  g_oCacic.writeDailyLog(lbMensagens.Caption);
  Application.ProcessMessages;
  if (p_intPausaSegundos > 0) then
    sleep(p_intPausaSegundos);
End;

procedure TfrmMapaCacic.Sair;
Begin
    g_oCacic.Free();
    Application.Terminate;
End;

procedure TfrmMapaCacic.Finalizar(p_pausa:boolean);
Begin
  Mensagem('Finalizando MapaCacic...',false,0);

  g_oCacic.killFiles(g_oCacic.getLocalFolder + 'Temp','*.vbs');
  g_oCacic.killFiles(g_oCacic.getLocalFolder + 'Temp','*.txt');
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclusão de operações de arquivos.
  Sair;
End;
//
function TfrmMapaCacic.LastPos(SubStr, S: string): Integer;
var
  Found, Len, Pos: integer;
begin
  Pos := Length(S);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if Copy(S, Pos, Len) = SubStr then
      Found := Pos;
    Dec(Pos);
  end;
  LastPos := Found;
end;

Function TfrmMapaCacic.ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
var Response_CS     : TStringStream;
    strAddress,
    strTeWebManagerAddress,
    strTeWebServicesFolder : String;
    idHTTP1         : TIdHTTP;
    intAux          : integer;
    tStringListAuxRequest    : TStringList;
Begin
    tStringListAuxRequest := TStringList.Create;
    tStringListAuxRequest := Request;

    tStringListAuxRequest.Values['cs_cipher']   := '1';
    tStringListAuxRequest.Values['cs_compress'] := '0';


    strTeWebServicesFolder := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebServicesFolder', g_oCacic.getWinDir + 'chksis.ini'));
    strTeWebManagerAddress := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress', g_oCacic.getWinDir + 'chksis.ini'));

    if (trim(strTeWebServicesFolder)='') then
        strTeWebServicesFolder := '/ws/';

    if (trim(strTeWebManagerAddress)='') then
        strTeWebManagerAddress := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'GER_COLS.inf')));

    strAddress := 'http://' + strTeWebManagerAddress + strTeWebServicesFolder + URL;

    if (trim(MsgAcao)='') then
        MsgAcao := '>> Enviando informações iniciais ao Gerente WEB.';

    g_oCacic.writeDailyLog(MsgAcao);

    Application.ProcessMessages;

    Response_CS := TStringStream.Create('');

    g_oCacic.writeDebugLog('Iniciando comunicação com http://' + strTeWebManagerAddress + strTeWebServicesFolder + URL);

    Try
       idHTTP1 := TIdHTTP.Create(nil);
       idHTTP1.AllowCookies                     := true;
       idHTTP1.ASCIIFilter                      := false;
       idHTTP1.AuthRetries                      := 1;
       idHTTP1.BoundPort                        := 0;
       idHTTP1.HandleRedirects                  := false;
       idHTTP1.ProxyParams.BasicAuthentication  := false;
       idHTTP1.ProxyParams.ProxyPort            := 0;
       idHTTP1.ReadTimeout                      := 0;
       idHTTP1.RecvBufferSize                   := 32768;
       idHTTP1.RedirectMaximum                  := 15;
       idHTTP1.Request.UserAgent                := g_oCacic.enCrypt('AGENTE_CACIC');
       idHTTP1.Request.Username                 := g_oCacic.enCrypt('USER_CACIC');
       idHTTP1.Request.Password                 := g_oCacic.enCrypt('PW_CACIC');
       idHTTP1.Request.Accept                   := 'text/html, */*';
       idHTTP1.Request.BasicAuthentication      := true;
       idHTTP1.Request.ContentLength            := -1;
       idHTTP1.Request.ContentRangeStart        := 0;
       idHTTP1.Request.ContentRangeEnd          := 0;
       idHTTP1.Request.ContentType              := 'text/html';
       idHTTP1.SendBufferSize                   := 32768;
       idHTTP1.Tag                              := 0;

       if boolDebugs then
          Begin
            g_oCacic.writeDebugLog('Valores de REQUEST para envio ao Gerente WEB:');
            for intAux := 0 to tStringListAuxRequest.count -1 do
                g_oCacic.writeDebugLog('#'+inttostr(intAux)+': '+tStringListAuxRequest[intAux]);
          End;

       IdHTTP1.Post(strAddress, tStringListAuxRequest, Response_CS);
       idHTTP1.Free;
       g_oCacic.writeDebugLog('Retorno: "'+Response_CS.DataString+'"');
    Except
       Mensagem('ERRO! Comunicação impossível com o endereço ' + strAddress + ': '+Response_CS.DataString,true,intPausaPadrao);
       result := '0';
       Exit;
    end;

    Application.ProcessMessages;
    Try
      if (UpperCase(g_oCacic.xmlGetValue('Status', Response_CS.DataString)) <> 'OK') Then
        Begin
           Mensagem('PROBLEMAS DURANTE A COMUNICAÇÃO',true,intPausaPadrao);
           g_oCacic.writeDailyLog('Endereço: ' + strAddress);
           g_oCacic.writeDailyLog('Mensagem: ' + Response_CS.DataString);
           result := '0';
        end
      Else
        Begin
           result := Response_CS.DataString;
        end;
      Response_CS.Free;
    Except
      Begin
        Mensagem('PROBLEMAS DURANTE A COMUNICAÇÃO',true,intPausaPadrao);
        g_oCacic.writeDailyLog('Endereço: ' + strAddress);
        g_oCacic.writeDailyLog('Mensagem: ' + Response_CS.DataString);
        result := '0';
      End;
    End;
end;

Function TfrmMapaCacic.RetornaValorVetorUON1(id1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].id1 = id1) Then Result := VetorUON1[I].nm1;
end;

Function TfrmMapaCacic.RetornaValorVetorUON1a(id1a : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1a)-1)  Do
       If (VetorUON1a[I].id1a     = id1a) Then Result := VetorUON1a[I].nm1a;
end;

Function TfrmMapaCacic.RetornaValorVetorUON2(id2, idLocal: string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].id2      = id2) and
          (VetorUON2[I].id_local = idLocal) Then Result := VetorUON2[I].nm2;
end;

procedure TfrmMapaCacic.RecuperaValoresAnteriores(p_strConfigs : String);
begin
  Mensagem('Recuperando Valores Anteriores...',false,intPausaPadrao div 3);

  strId_unid_organizacional_nivel1 := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel1',g_oCacic.getLocalFolder + g_oCacic.getInfFileName) );
  if (strId_unid_organizacional_nivel1='') then
    strId_unid_organizacional_nivel1 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('ID_UON1', p_strConfigs));

  strId_unid_organizacional_nivel1a := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel1a',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strId_unid_organizacional_nivel1a='') then
    strId_unid_organizacional_nivel1a := g_oCacic.deCrypt(g_oCacic.xmlGetValue('ID_UON1a', p_strConfigs));

  strId_unid_organizacional_nivel2 := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel2',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strId_unid_organizacional_nivel2='') then
    strId_unid_organizacional_nivel2 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('ID_UON2', p_strConfigs));

  strId_Local := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_local',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strId_Local='') then
    strId_Local := g_oCacic.deCrypt(g_oCacic.xmlGetValue('ID_LOCAL', p_strConfigs));

  Try
    cb_id_unid_organizacional_nivel1.ItemIndex := cb_id_unid_organizacional_nivel1.Items.IndexOf(RetornaValorVetorUON1(strId_unid_organizacional_nivel1));
    cb_id_unid_organizacional_nivel1Change(Nil); // Para filtrar os valores do combo2 de acordo com o valor selecionado no combo1
    cb_id_unid_organizacional_nivel1a.ItemIndex := cb_id_unid_organizacional_nivel1a.Items.IndexOf(RetornaValorVetorUON1(strId_unid_organizacional_nivel1));
  Except
  end;

  Try
    cb_id_unid_organizacional_nivel1a.ItemIndex := cb_id_unid_organizacional_nivel1a.Items.IndexOf(RetornaValorVetorUON1a(strId_unid_organizacional_nivel1a));
    cb_id_unid_organizacional_nivel1aChange(Nil); // Para filtrar os valores do combo3 de acordo com o valor selecionado no combo2
    cb_id_unid_organizacional_nivel2.ItemIndex := cb_id_unid_organizacional_nivel2.Items.IndexOf(RetornaValorVetorUON2(strId_unid_organizacional_nivel2,strId_Local));
  Except
  end;

  lbEtiqueta1.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta1', p_strConfigs));
  lbEtiqueta1a.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta1a', p_strConfigs));

  strTe_localizacao_complementar   := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_localizacao_complementar',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strTe_localizacao_complementar='') then strTe_localizacao_complementar := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_LOC_COMPL', p_strConfigs));

  // Tentarei buscar informação gravada no Registry
  strTe_info_patrimonio1           := g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1');
  if (strTe_info_patrimonio1='') then strTe_info_patrimonio1 := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio1',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strTe_info_patrimonio1='') then strTe_info_patrimonio1 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_INFO1', p_strConfigs));

  strTe_info_patrimonio2           := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio2',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strTe_info_patrimonio2='') then strTe_info_patrimonio2 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_INFO2', p_strConfigs));

  strTe_info_patrimonio3           := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio3',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strTe_info_patrimonio3='') then strTe_info_patrimonio3 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_INFO3', p_strConfigs));

  // Tentarei buscar informação gravada no Registry
  strTe_info_patrimonio4           := g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4');
  if (strTe_info_patrimonio4='') then strTe_info_patrimonio4 := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio4',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

  if (strTe_info_patrimonio4='') then strTe_info_patrimonio4 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_INFO4', p_strConfigs));

  strTe_info_patrimonio5           := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio5',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strTe_info_patrimonio5='') then strTe_info_patrimonio5 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_INFO5', p_strConfigs));

  strTe_info_patrimonio6           := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio6',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
  if (strTe_info_patrimonio6='') then strTe_info_patrimonio6 := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_INFO6', p_strConfigs));
end;

procedure TfrmMapaCacic.MontaCombos(p_strConfigs : String);
var Parser   : TXmlParser;
    i        : integer;
    strAux,
    strAux1,
    strTagName,
    strItemName  : string;
begin
  Mensagem('Montando Listas para Seleção de Unidades Organizacionais...',false,intPausaPadrao div 3);

  Parser := TXmlParser.Create;
  Parser.Normalize := True;
  Parser.LoadFromBuffer(PAnsiChar(p_strConfigs));
  g_oCacic.writeDebugLog('p_strConfigs: '+p_strConfigs);
  Parser.StartScan;
  i := -1;
  strItemName := '';
  strTagName  := '';
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
          strTagName := 'IT1';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1')Then
       Begin
         strAux1 := g_oCacic.deCrypt(Parser.CurContent);
         if      (strItemName = 'ID1') then
           Begin
             VetorUON1[i].id1 := strAux1;
             g_oCacic.writeDebugLog('Gravei VetorUON1.id1: "'+strAux1+'"');
           End
         else if (strItemName = 'NM1') then
           Begin
             VetorUON1[i].nm1 := strAux1;
             g_oCacic.writeDebugLog('Gravei VetorUON1.nm1: "'+strAux1+'"');
           End;
       End;
    End;

  // Código para montar o combo 2
  Parser.StartScan;
  strTagName := '';
  strAux1    := '';

  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1A') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1a, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
          strTagName := 'IT1A';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1A') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1A')Then
        Begin
          strAux1 := g_oCacic.deCrypt(Parser.CurContent);
          if      (strItemName = 'ID1') then
            Begin
              VetorUON1a[i].id1 := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.id1: "'+strAux1+'"');
            End
          else if (strItemName = 'SG_LOC') then
            Begin
              strAux := ' ('+strAux1 + ')';
            End
          else if (strItemName = 'ID1A') then
            Begin
              VetorUON1a[i].id1a := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'NM1A') then
            Begin
              VetorUON1a[i].nm1a := strAux1+strAux;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.nm1a: "'+strAux1+strAux+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON1a[i].id_local := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.id_local: "'+strAux1+'"');
            End;

        End;
    end;

  // Código para montar o combo 3
  Parser.StartScan;
  strTagName := '';
  i := -1;

  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT2') Then
       Begin
          i := i + 1;
          SetLength(VetorUON2, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
          strTagName := 'IT2';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT2') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT2')Then
        Begin
          strAux1  := g_oCacic.deCrypt(Parser.CurContent);
          if      (strItemName = 'ID1A') then
            Begin
              VetorUON2[i].id1a := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'ID2') then
            Begin
              VetorUON2[i].id2 := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.id2: "'+strAux1+'"');
            End
          else if (strItemName = 'NM2') then
            Begin
              VetorUON2[i].nm2 := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.nm2: "'+strAux1+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON2[i].id_local := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.id_local: "'+strAux1+'"');
            End;

        End;
    end;
  Parser.Free;

  // Como os itens do combo1 nunca mudam durante a execução do programa (ao contrario dos combo2 e 3), posso colocar o seu preenchimento aqui mesmo.
  cb_id_unid_organizacional_nivel1.Items.Clear;
  For i := 0 to Length(VetorUON1) - 1 Do
     cb_id_unid_organizacional_nivel1.Items.Add(VetorUON1[i].nm1);

  if (Length(VetorUON1) = 0) then
    Begin
      frmMapaCacic.Mensagem('ATENÇÃO! Não encontrei Entidades, Linhas de Negócio ou Órgãos cadastrados para esta subrede.',true,intPausaPadrao * 2);
      Finalizar(true);
    End;

  For i := 0 to Length(VetorUON1) - 1 Do
    Begin
      g_oCacic.writeDebugLog('VetorUON1['+IntToStr(i)+'].id1='+VetorUON1[i].id1);
      g_oCacic.writeDebugLog('VetorUON1['+IntToStr(i)+'].nm1='+VetorUON1[i].nm1);
    End;

  For i := 0 to Length(VetorUON1a) - 1 Do
    Begin
      g_oCacic.writeDebugLog('VetorUON1a['+IntToStr(i)+'].id1='+VetorUON1a[i].id1);
      g_oCacic.writeDebugLog('VetorUON1a['+IntToStr(i)+'].id1a='+VetorUON1a[i].id1a);
      g_oCacic.writeDebugLog('VetorUON1a['+IntToStr(i)+'].nm1a='+VetorUON1a[i].nm1a);
      g_oCacic.writeDebugLog('VetorUON1a['+IntToStr(i)+'].id_local='+VetorUON1a[i].id_local);
    End;

  For i := 0 to Length(VetorUON2) - 1 Do
    Begin
      g_oCacic.writeDebugLog('VetorUON2['+IntToStr(i)+'].id1a='+VetorUON2[i].id1a);
      g_oCacic.writeDebugLog('VetorUON2['+IntToStr(i)+'].id2='+VetorUON2[i].id2);
      g_oCacic.writeDebugLog('VetorUON2['+IntToStr(i)+'].nm2='+VetorUON2[i].nm2);
      g_oCacic.writeDebugLog('VetorUON2['+IntToStr(i)+'].id_local='+VetorUON2[i].id_local);
    End;
end;


procedure TfrmMapaCacic.cb_id_unid_organizacional_nivel1Change(Sender: TObject);
var i, j: Word;
    strIdUON1 : String;
begin
      g_oCacic.writeDebugLog('Nível 1 CHANGE');
      // Filtro os itens do combo2, de acordo com o item selecionado no combo1
      strIdUON1 := VetorUON1[cb_id_unid_organizacional_nivel1.ItemIndex].id1;
      cb_id_unid_organizacional_nivel1a.Items.Clear;
      cb_id_unid_organizacional_nivel2.Items.Clear;
      cb_id_unid_organizacional_nivel1a.Enabled := false;
      cb_id_unid_organizacional_nivel2.Enabled  := false;
      SetLength(VetorUON1aFiltrado, 0);

      g_oCacic.writeDebugLog('Tamanho de VetorUON1..: '+IntToStr(Length(VetorUON1)));
      g_oCacic.writeDebugLog('ItemIndex de cb_nivel1: '+IntToStr(cb_id_unid_organizacional_nivel1.ItemIndex));
      g_oCacic.writeDebugLog('Tamanho de VetorUON1a.: '+IntToStr(Length(VetorUON1a)));
      For i := 0 to Length(VetorUON1a) - 1 Do
      Begin
          Try
            if VetorUON1a[i].id1 = strIdUON1 then
              Begin
                g_oCacic.writeDebugLog('Add em cb_nivel1a: '+VetorUON1a[i].nm1a);
                cb_id_unid_organizacional_nivel1a.Items.Add(VetorUON1a[i].nm1a);
                j := Length(VetorUON1aFiltrado);
                SetLength(VetorUON1aFiltrado, j + 1);
                VetorUON1aFiltrado[j] := VetorUON1a[i].id1a + '#' +VetorUON1a[i].id_local;
                g_oCacic.writeDebugLog('VetorUON1aFiltrado['+IntToStr(j)+']= '+VetorUON1aFiltrado[j]);
              end;
          Except
          End;
      end;
      if (cb_id_unid_organizacional_nivel1a.Items.Count > 0) then
        Begin
          cb_id_unid_organizacional_nivel1a.Enabled   := true;
          cb_id_unid_organizacional_nivel1a.ItemIndex := 0;
          g_oCacic.writeDebugLog('Provocando CHANGE em nivel1a');
          cb_id_unid_organizacional_nivel1aChange(nil);
        End;
end;

procedure TfrmMapaCacic.cb_id_unid_organizacional_nivel1aChange(
  Sender: TObject);
var i, j: Word;
    strIdUON1a,
    strIdLocal : String;
    intAux     : integer;
    tstrAux    : TStrings;
begin
      g_oCacic.writeDebugLog('Nível 1a CHANGE');
      // Filtro os itens do combo2, de acordo com o item selecionado no combo1
      //intAux := IfThen(cb_id_unid_organizacional_nivel1a.Items.Count > 1,cb_id_unid_organizacional_nivel1a.ItemIndex+1,0);
      intAux := cb_id_unid_organizacional_nivel1a.ItemIndex;
      g_oCacic.writeDebugLog('cb_id_unid_organizacional_nivel1a.ItemIndex = '+intToStr(cb_id_unid_organizacional_nivel1a.ItemIndex));

      g_oCacic.writeDebugLog('VetorUON1aFiltrado['+intToStr(cb_id_unid_organizacional_nivel1a.ItemIndex)+'] => '+VetorUON1aFiltrado[cb_id_unid_organizacional_nivel1a.ItemIndex]);
      tstrAux := TStrings.Create;
      tstrAux := g_oCacic.explode(VetorUON1aFiltrado[cb_id_unid_organizacional_nivel1a.ItemIndex],'#');

      strIdUON1a := tstrAux[0];
      strIdLocal := tstrAux[1];

      tstrAux.Free;

      g_oCacic.writeDebugLog('strIdLocal = '+strIdLocal);
      cb_id_unid_organizacional_nivel2.Items.Clear;
      cb_id_unid_organizacional_nivel2.Enabled  := false;
      SetLength(VetorUON2Filtrado, 0);

      g_oCacic.writeDebugLog('Tamanho de VetorUON1a..: '+IntToStr(Length(VetorUON1a)));
      g_oCacic.writeDebugLog('ItemIndex de cb_nivel1a: '+IntToStr(cb_id_unid_organizacional_nivel1a.ItemIndex));
      g_oCacic.writeDebugLog('Tamanho de VetorUON2...: '+IntToStr(Length(VetorUON2)));

      For i := 0 to Length(VetorUON2) - 1 Do
      Begin
          Try
            if (VetorUON2[i].id1a     = strIdUON1a) and
               (VetorUON2[i].id_local = strIdLocal) then
              Begin
                g_oCacic.writeDebugLog('Add em cb_nivel2: '+VetorUON2[i].nm2);
                cb_id_unid_organizacional_nivel2.Items.Add(VetorUON2[i].nm2);
                j := Length(VetorUON2Filtrado);
                SetLength(VetorUON2Filtrado, j + 1);
                VetorUON2Filtrado[j] := VetorUON2[i].id2 + '#' + VetorUON2[i].id_local;
                g_oCacic.writeDebugLog('VetorUON2Filtrado['+IntToStr(j)+']= '+VetorUON2Filtrado[j]);
              end;
          Except
          End;
      end;
      if (cb_id_unid_organizacional_nivel2.Items.Count > 0) then
        Begin
          cb_id_unid_organizacional_nivel2.Enabled := true;
          cb_id_unid_organizacional_nivel2.ItemIndex := 0;
        End;
end;


procedure TfrmMapaCacic.AtualizaPatrimonio(Sender: TObject);
var strIdUON1,
    strIdUON1a,
    strIdUON2,
    strIdLocal,
    strRetorno : String;
    tstrListAux    : TStringList;
    tstrAux    : TStrings;
begin
   tstrAux := TStrings.Create;
   tstrAux := g_oCacic.explode(VetorUON2Filtrado[cb_id_unid_organizacional_nivel2.ItemIndex],'#');
   Try
      strIdUON1  := VetorUON1[cb_id_unid_organizacional_nivel1.ItemIndex].id1;
      strIdUON2  := tstrAux[0];
      strIdLocal := tstrAux[1];
   Except
   end;

   tstrAux := g_oCacic.explode(VetorUON1aFiltrado[cb_id_unid_organizacional_nivel1a.ItemIndex],'#');
   Try
      strIdUON1a  := tstrAux[0];
   Except
   end;

   tstrAux.Free;
   Mensagem('Enviando Informações Coletadas ao Banco de Dados...',false,intPausaPadrao div 3);
    // Envio dos Dados Coletados ao Banco de Dados
    tstrListAux := TStringList.Create;
    tstrListAux.Values['te_node_address']               := g_oCacic.GetValueFromFile('TcpIp','TE_NODE_ADDRESS'                    , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    tstrListAux.Values['id_so']                         := g_oCacic.GetValueFromFile('Configs','ID_SO'                            , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    tstrListAux.Values['te_so']                         := g_oCacic.enCrypt(g_oCacic.getWindowsStrId());
    tstrListAux.Values['id_ip_rede']                    := g_oCacic.GetValueFromFile('TcpIp','ID_IP_REDE'                         , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    tstrListAux.Values['te_ip']                         := g_oCacic.GetValueFromFile('TcpIp','TE_IP'                              , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    tstrListAux.Values['te_nome_computador']            := g_oCacic.GetValueFromFile('TcpIp','TE_NOME_COMPUTADOR'                 , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    tstrListAux.Values['te_workgroup']                  := g_oCacic.GetValueFromFile('TcpIp','TE_WORKGROUP'                       , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    tstrListAux.Values['id_usuario']                    := g_oCacic.enCrypt(frmMapaCacic.strId_usuario);
    tstrListAux.Values['id_unid_organizacional_nivel1'] := g_oCacic.enCrypt(strIdUON1);
    tstrListAux.Values['id_unid_organizacional_nivel1a']:= g_oCacic.enCrypt(strIdUON1A);
    tstrListAux.Values['id_unid_organizacional_nivel2'] := g_oCacic.enCrypt(strIdUON2);
    tstrListAux.Values['te_localizacao_complementar'  ] := g_oCacic.enCrypt(ed_te_localizacao_complementar.Text);
    tstrListAux.Values['te_info_patrimonio1'          ] := g_oCacic.enCrypt(ed_te_info_patrimonio1.Text);
    tstrListAux.Values['te_info_patrimonio2'          ] := g_oCacic.enCrypt(ed_te_info_patrimonio2.Text);
    tstrListAux.Values['te_info_patrimonio3'          ] := g_oCacic.enCrypt(ed_te_info_patrimonio3.Text);
    tstrListAux.Values['te_info_patrimonio4'          ] := g_oCacic.enCrypt(ed_te_info_patrimonio4.Text);
    tstrListAux.Values['te_info_patrimonio5'          ] := g_oCacic.enCrypt(ed_te_info_patrimonio5.Text);
    tstrListAux.Values['te_info_patrimonio6'          ] := g_oCacic.enCrypt(ed_te_info_patrimonio6.Text);

    g_oCacic.writeDebugLog('Informações para contato com mapa_set_patrimonio:');
    g_oCacic.writeDebugLog('te_node_address: '+tstrListAux.Values['te_node_address']);
    g_oCacic.writeDebugLog('id_so: '+tstrListAux.Values['id_so']);
    g_oCacic.writeDebugLog('te_so: '+tstrListAux.Values['te_so']);
    g_oCacic.writeDebugLog('id_ip_rede: '+tstrListAux.Values['id_ip_rede']);
    g_oCacic.writeDebugLog('te_ip: '+tstrListAux.Values['te_ip']);
    g_oCacic.writeDebugLog('te_nome_computador: '+tstrListAux.Values['te_nome_computador']);
    g_oCacic.writeDebugLog('te_workgroup: '+tstrListAux.Values['te_workgroup']);

    strRetorno := frmMapaCacic.ComunicaServidor('mapa_set_patrimonio.php', tstrListAux, '');
    tstrListAux.Free;

    if not (g_oCacic.xmlGetValue('STATUS', strRetorno)='OK') then
        Mensagem('ATENÇÃO: PROBLEMAS NO ENVIO DAS INFORMAÇÕES COLETADAS AO BANCO DE DADOS...',true,intPausaPadrao)
    else
      Begin
        Mensagem('Salvando Informações Coletadas em Base Local...',false,intPausaPadrao div 3);
        g_oCacic.setValueToFile('Patrimonio','id_unid_organizacional_nivel1' , g_oCacic.enCrypt( strIdUON1), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','id_unid_organizacional_nivel1a', g_oCacic.enCrypt(strIdUON1a), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','id_unid_organizacional_nivel2' , g_oCacic.enCrypt(strIdUON2) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','id_local'                      , g_oCacic.enCrypt(strIdLocal), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_localizacao_complementar'   , g_oCacic.enCrypt(ed_te_localizacao_complementar.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio1'           , g_oCacic.enCrypt(ed_te_info_patrimonio1.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio2'           , g_oCacic.enCrypt(ed_te_info_patrimonio2.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio3'           , g_oCacic.enCrypt(ed_te_info_patrimonio3.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio4'           , g_oCacic.enCrypt(ed_te_info_patrimonio4.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio5'           , g_oCacic.enCrypt(ed_te_info_patrimonio5.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio6'           , g_oCacic.enCrypt(ed_te_info_patrimonio6.Text), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','ultima_rede_obtida'            , g_oCacic.GetValueFromFile('TcpIp','ID_IP_REDE',g_oCacic.getLocalFolder + 'GER_COLS.inf'),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Patrimonio','dt_ultima_renovacao'           , g_oCacic.enCrypt(FormatDateTime('yyyymmddhhnnss', Now)),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

        g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1', ed_te_info_patrimonio1.Text);
        g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4', ed_te_info_patrimonio4.Text);
      End;
    Finalizar(true);
end;

procedure TfrmMapaCacic.MontaInterface(p_strConfigs : String);
Begin
   Mensagem('Montando Interface para Coleta de Informações...',false,intPausaPadrao div 3);

   lbEtiqueta1.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta1', p_strConfigs));
   lbEtiqueta1.Visible := true;
   cb_id_unid_organizacional_nivel1.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta1', p_strConfigs));
   cb_id_unid_organizacional_nivel1.Visible := true;

   lbEtiqueta1a.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta1a', p_strConfigs));
   lbEtiqueta1a.Visible := true;
   cb_id_unid_organizacional_nivel1a.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta1a', p_strConfigs));
   cb_id_unid_organizacional_nivel1a.Visible := true;

   lbEtiqueta2.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta2', p_strConfigs));
   lbEtiqueta2.Visible := true;
   cb_id_unid_organizacional_nivel2.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta2', p_strConfigs));
   cb_id_unid_organizacional_nivel2.Visible := true;

   lbEtiqueta3.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta3', p_strConfigs));
   lbEtiqueta3.Visible := true;
   ed_te_localizacao_complementar.Text := strTe_localizacao_complementar;
   ed_te_localizacao_complementar.Visible := true;

   g_oCacic.writeDebugLog('in_exibir_etiqueta4 -> "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta4', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta4', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta4.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta4', p_strConfigs));
      lbEtiqueta4.Visible := true;
      ed_te_info_patrimonio1.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta4', p_strConfigs));
      ed_te_info_patrimonio1.Text          := strTe_info_patrimonio1;
      ed_te_info_patrimonio1.visible := True;
   end;

   g_oCacic.writeDebugLog('in_exibir_etiqueta5 -> "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta5', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta5', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta5.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta5', p_strConfigs));
      lbEtiqueta5.Visible := true;
      ed_te_info_patrimonio2.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta5', p_strConfigs));
      ed_te_info_patrimonio2.Text          := strTe_info_patrimonio2;
      ed_te_info_patrimonio2.visible := True;
   end;

   g_oCacic.writeDebugLog('in_exibir_etiqueta6 -> "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta6', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta6', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta6.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta6', p_strConfigs));
      lbEtiqueta6.Visible := true;
      ed_te_info_patrimonio3.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta6', p_strConfigs));
      ed_te_info_patrimonio3.Text          := strTe_info_patrimonio3;
      ed_te_info_patrimonio3.visible := True;
   end;

   g_oCacic.writeDebugLog('in_exibir_etiqueta7 -> "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta7', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta7', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta7.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta7', p_strConfigs));
      lbEtiqueta7.Visible := true;
      ed_te_info_patrimonio4.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta7', p_strConfigs));
      ed_te_info_patrimonio4.Text          := strTe_info_patrimonio4;
      ed_te_info_patrimonio4.visible := True;
   end;

   g_oCacic.writeDebugLog('in_exibir_etiqueta8 -> "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta8', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta8', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta8.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta8', p_strConfigs));
      lbEtiqueta8.Visible := true;
      ed_te_info_patrimonio5.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta8', p_strConfigs));
      ed_te_info_patrimonio5.Text          := strTe_info_patrimonio5;
      ed_te_info_patrimonio5.visible := True;
   end;

   g_oCacic.writeDebugLog('in_exibir_etiqueta9 -> "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta9', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta9', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta9.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta9', p_strConfigs));
      lbEtiqueta9.Visible := true;
      ed_te_info_patrimonio6.Hint := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_help_etiqueta9', p_strConfigs));
      ed_te_info_patrimonio6.Text          := strTe_info_patrimonio6;
      ed_te_info_patrimonio6.visible := True;
   end;

  Application.ProcessMessages;
  Mensagem('',false,0);
  btGravarInformacoes.Visible := true;
end;

procedure TfrmMapaCacic.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Finalizar(true);
end;

procedure TfrmMapaCacic.CriaFormSenha(Sender: TObject);
begin
    Application.CreateForm(TfrmAcesso, frmAcesso);
end;

// Baixada de http://www.infoeng.hpg.ig.com.br/borland_delphi_dicas_2.htm
function TfrmMapaCacic.LetrasDrives: string;
var
Drives: DWord;
I, Tipo: byte;
v_Unidade : string;
begin
Result := '';
Drives := GetLogicalDrives;
if Drives <> 0 then
for I := 65 to 90 do
  if ((Drives shl (31 - (I - 65))) shr 31) = 1 then
    Begin
      v_Unidade := Char(I) + ':\';
      Tipo := GetDriveType(PChar(v_Unidade));
      case Tipo of
        DRIVE_FIXED: Result := Result + Char(I);
      end;
    End;
end;
// By Muad Dib 2003
// at http://www.planet-source-code.com.
// Excelente!!!
function TfrmMapaCacic.SearchFile(p_Drive,p_File:string) : boolean;
var sr:TSearchRec;
    sDirList:TStringList;
    i:integer;
    strResSearch : String;
begin
   Result := false;
   strResSearch := '';
   if FindFirst(p_Drive+p_File,faAnyFile,sr) = 0 then
    Begin
      strResSearch := p_Drive+p_File;
      Result := true;
    End
   else
    Begin
     repeat
     until FindNext(sr)<>0;
        FindClose(sr);
        sDirList:= TStringList.Create;
        try
         GetSubDirs(p_Drive,sDirList);
         for i:=0 to sDirList.Count-1 do
            if (sDirList[i]<>'.') and (sDirList[i]<>'..') then
             begin
              //Application.ProcessMessages;
              if (SearchFile(IncludeTrailingPathDelimiter(p_Drive+sDirList[i]),p_File)) then
                Begin
                  Result := true;
                  Break;
                End;
             end;
         finally
         sDirList.Free;
    End;
   end;
end;
procedure TfrmMapaCacic.GetSubDirs(Folder:string; sList:TStringList);
 var
  sr:TSearchRec;
begin
  if FindFirst(Folder+'*.*',faDirectory,sr)=0 then
   try
    repeat
      if(sr.Attr and faDirectory)=faDirectory then
       sList.Add(sr.Name);
    until FindNext(sr)<>0;
   finally
    FindClose(sr);
   end;
end;

procedure TfrmMapaCacic.mapa;
var strConfigs : String;
    tstrAUX : TStrings;
begin
  tstrAUX := TStrings.Create;

  Try
    strConfigs                           := g_oCacic.GetValueFromFile('Patrimonio','Configs',g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    gbLeiaComAtencao.Visible             := true;
    gbInformacoesSobreComputador.Visible := true;
    MontaCombos(strConfigs);
    RecuperaValoresAnteriores(strConfigs);
    MontaInterface(strConfigs);
    Application.ProcessMessages;
  Except
  End;
End;

procedure TfrmMapaCacic.FormActivate(Sender: TObject);
var intAux            : integer;
    strLetrasDrives,
    strRetorno,
    v_strTeLocalFolder,
    strAux : String;
    Request_mapa       : TStringList;
begin
  if not boolFinalizar then
    Begin
      g_oCacic := TCACIC.Create();

      g_oCacic.setBoolCipher(true);
      frmMapaCacic.lbVersao.Caption          := 'Versão: ' + g_oCacic.GetVersionInfo(ParamStr(0));

      if (g_oCacic.isWindowsNTPlataform()) and (not g_oCacic.isWindowsAdmin()) then
        MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0)
      else
        Begin
          // Buscarei o caminho do Sistema em \WinDIR\chkSIS.ini
          v_strTeLocalFolder := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeLocalFolder',g_oCacic.getWinDir + 'chksis.ini'));

          if not (v_strTeLocalFolder = '') then
            Begin
              g_oCacic.setLocalFolder(v_strTeLocalFolder);

              // A existência e bloqueio do arquivo abaixo evitará que o Agente Principal entre em ação
              AssignFile(v_Aguarde,g_oCacic.getLocalFolder + '\temp\aguarde_MAPACACIC.txt'); {Associa o arquivo a uma variável do tipo TextFile}
              {$IOChecks off}
              Reset(v_Aguarde); {Abre o arquivo texto}
              {$IOChecks on}
              if (IOResult <> 0) then // Arquivo não existe, será recriado.
                Rewrite (v_Aguarde);

              Append(v_Aguarde);
              Writeln(v_Aguarde,'Apenas um pseudo-cookie para o Agente Principal esperar o término de MapaCACIC');
              Append(v_Aguarde);

              strAux := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_oCacic.getLocalFolder + 'GER_COLS.inf')));
              if not FileExists(g_oCacic.getLocalFolder + g_oCacic.getInfFileName) or
                 (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
                 (strAux <> '') and (StrToInt64(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) < StrToInt64(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_oCacic.getLocalFolder + 'GER_COLS.inf')))) then
                CopyFile(PChar(g_oCacic.getLocalFolder + 'GER_COLS.inf'), PChar(g_oCacic.getLocalFolder + g_oCacic.getInfFileName), true);

              frmMapaCacic.edTeWebManagerAddress.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

              frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autenticação no Módulo Gerente WEB Cacic';
              if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_NODE_ADDRESS' , g_oCacic.getLocalFolder + 'GER_COLS.inf'))='') then
                Begin
                  frmMapaCacic.boolAcessoOK := false;
                  MessageDLG(#13#10+'Atenção! É necessário executar as coletas do Sistema Cacic.' + #13#10     + #13#10 +
                                        'Caso o Sistema Cacic já esteja instalado, clique com botão direito'   + #13#10 +
                                        'sobre o ícone da bandeja, escolha a opção "Executar Agora" e aguarde' + #13#10 +
                                      'o fim do processo.',mtError,[mbOK],0);
                  frmMapaCacic.Finalizar(false);
                End
              else
                Begin

                  g_oCacic.checkDebugMode;
                  g_oCacic.writeDebugLog('Versão do MapaCacic: '+frmMapaCacic.lbVersao.Caption);

                  // Acessar...
                  CriaFormSenha(nil);
                  frmAcesso.ShowModal;

                  if boolFinalizar then
                    Finalizar(false)
                  else if boolAcessoOK then
                    Begin
                      pnMensagens.Visible := true;
                      Mensagem('Efetuando Comunicação com o Módulo Gerente WEB em "'+g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'GER_COLS.inf'))+'"...',false,intPausaPadrao div 3);
                      frmAcesso.Free;

                      // Povoamento com dados de configurações da interface patrimonial
                      // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
                      Request_mapa  :=  TStringList.Create;
                      Request_mapa.Values['te_node_address']   := g_oCacic.GetValueFromFile('TcpIp','TE_NODE_ADDRESS' , g_oCacic.getLocalFolder + 'GER_COLS.inf');
                      Request_mapa.Values['id_so']             := g_oCacic.GetValueFromFile('Configs','ID_SO'           , g_oCacic.getLocalFolder + 'GER_COLS.inf');
                      Request_mapa.Values['te_so']             := g_oCacic.enCrypt(g_oCacic.getWindowsStrId());
                      Request_mapa.Values['id_ip_rede']        := g_oCacic.GetValueFromFile('TcpIp','ID_IP_REDE'        , g_oCacic.getLocalFolder + 'GER_COLS.inf');
                      Request_mapa.Values['te_ip']             := g_oCacic.GetValueFromFile('TcpIp','TE_IP'             , g_oCacic.getLocalFolder + 'GER_COLS.inf');
                      Request_mapa.Values['te_nome_computador']:= g_oCacic.GetValueFromFile('TcpIp','TE_NOME_COMPUTADOR', g_oCacic.getLocalFolder + 'GER_COLS.inf');
                      Request_mapa.Values['te_workgroup']      := g_oCacic.GetValueFromFile('TcpIp','TE_WORKGROUP'      , g_oCacic.getLocalFolder + 'GER_COLS.inf');
                      Request_mapa.Values['id_usuario']        := g_oCacic.enCrypt(frmMapaCacic.strId_usuario);

                      strRetorno := frmMapaCacic.ComunicaServidor('mapa_get_patrimonio.php', Request_mapa, '.');

                      g_oCacic.writeDebugLog('Retorno: "'+strRetorno+'"');

                      if (g_oCacic.xmlGetValue('STATUS', strRetorno)='OK') then
                        Begin
                          Mensagem('Comunicação Efetuada com Sucesso! Salvando as Configurações Obtidas...',false,intPausaPadrao div 3);
                          g_oCacic.setValueToFile('Patrimonio','Configs', strRetorno, g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                        End
                      else
                        Begin
                          Mensagem('PROBLEMAS NA COMUNICAÇÃO COM O MÓDULO GERENTE WEB...',true,intPausaPadrao);
                          Finalizar(true);
                        End;

                      Request_mapa.Free;

                      mapa;
                    End;
                End;
            End
          else
            Begin
              frmMapaCacic.boolAcessoOK := false;
              MessageDLG(#13#10+'Atenção! É necessário reinstalar o CACIC nesta estação.' + #13#10     + #13#10 +
                                'A estrutura encontra-se corrompida.'   + #13#10,mtError,[mbOK],0);
              frmMapaCacic.Finalizar(false);
            End;
        End;
  End;
end;

procedure TfrmMapaCacic.FormCreate(Sender: TObject);
begin
  boolFinalizar := false;
end;

end.
