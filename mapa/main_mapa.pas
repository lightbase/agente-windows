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
  IniFiles,
  Windows,
  Sysutils,    // Deve ser colocado após o Windows acima, nunca antes
  strutils,
  Registry,
  LibXmlParser,
  XML,
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
  PJVersionInfo,
  ExtCtrls,
  Graphics,
  Dialogs,
  CACIC_Library;

var
  strCipherClosed,
  strCipherOpened           : string;

var
  intPausaPadrao            : integer;

var
  boolDebugs                : boolean;

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
    lbNomeServidorWEB: TLabel;
    lbVersao: TLabel;

    procedure mapa;
    procedure Grava_Debugs(strMsg : String);
    function  SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
    function  GetValorChaveRegEdit(Chave: String): Variant;
    function  GetRootKey(strRootKey: String): HKEY;
    Function  RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
    Function  CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
    Function  CipherOpen(p_DatFileName : string) : TStrings;
    Function  GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
    procedure MontaCombos(p_strConfigs : String);
    procedure MontaInterface(p_strConfigs : String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cb_id_unid_organizacional_nivel1Change(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure RecuperaValoresAnteriores(p_strConfigs : String);
    procedure log_diario(strMsg : String);
    procedure log_DEBUG(p_msg:string);
    Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
    function  GetVersionInfo(p_File: string):string;
    function  VerFmt(const MS, LS: DWORD): string;
    function  GetFolderDate(Folder: string): TDateTime;
    procedure CriaFormSenha(Sender: TObject);
    Function  ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
    Function  XML_RetornaValor(Tag : String; Fonte : String): String;
    function  Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
    procedure Matar(v_dir,v_files: string);
    procedure Finalizar(p_pausa:boolean);
    procedure Apaga_Temps;
    procedure Sair;
    function  LastPos(SubStr, S: string): Integer;
    Function  Rat(OQue: String; Onde: String) : Integer;
    Function  RemoveZerosFimString(Texto : String) : String;
    function  GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    Function  RetornaValorVetorUON1(id1 : string) : String;
    Function  RetornaValorVetorUON1a(id1a : string) : String;
    Function  RetornaValorVetorUON2(id2,idLocal : string) : String;
    function  LetrasDrives: string;
    function  SearchFile(p_Drive,p_File:string) : boolean;
    procedure GetSubDirs(Folder:string; sList:TStringList);
    procedure Mensagem(p_strMsg : String; p_boolAlerta : boolean; p_intPausaSegundos : integer);
    procedure FormActivate(Sender: TObject);
    procedure cb_id_unid_organizacional_nivel1aChange(Sender: TObject);
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
    g_oCacic                   : TCACIC;
    tStringsDadosPatrimonio,
    tStringsCipherOpened,
    tStringsTripa1             : TStrings;
  end;

var
  frmMapaCacic: TfrmMapaCacic;

implementation

uses acesso, Math;

{$R *.dfm}


// Estruturas de dados para armazenar os itens da uon1 e uon2
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
  log_DEBUG(p_strMsg);
  if p_boolAlerta then
    lbMensagens.Font.Color := clRed
  else
    lbMensagens.Font.Color := clBlack;

  lbMensagens.Caption := p_strMsg;
  log_diario(lbMensagens.Caption);
  Application.ProcessMessages;
  if (p_intPausaSegundos > 0) then
    sleep(p_intPausaSegundos);
End;

procedure TfrmMapaCacic.log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (g_oCacic.getCacicPath + 'MapaCacic.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,g_oCacic.getCacicPath + 'MapaCacic.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(g_oCacic.getCacicPath + 'MapaCacic.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[MapaCacic] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
   end;
end;
function TfrmMapaCacic.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function TfrmMapaCacic.GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

procedure TfrmMapaCacic.log_DEBUG(p_msg:string);
Begin
  if boolDebugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;
procedure TfrmMapaCacic.Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := g_oCacic.getCacicPath + '\debug_mapa.txt';
       FileSetAttr (v_file_debugs,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(DebugsFile,v_file_debugs); {Associa o arquivo a uma variável do tipo TextFile}

       {$IOChecks off}
       Reset(DebugsFile); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite(DebugsFile);
            Append(DebugsFile);
            Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Debug <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(v_file_debugs)));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);

       if (strDataAtual <> strDataArqLocal) then // Se o arquivo não é da data atual...
          begin
            Rewrite(DebugsFile); //Cria/Recria o arquivo
            Append(DebugsFile);
            Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Debug <=======================');
          end;

       Append(DebugsFile);
       Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(DebugsFile); {Fecha o arquivo texto}
   except
     log_diario('Erro na gravação do Debug!');
   end;
end;

// Função criada devido a divergências entre os valores retornados pelos métodos dos componentes MSI e seus Reports.
function TfrmMapaCacic.Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
var intClasses, intSections, intDatas, v_achei_SectionName, v_array_SectionName_Count : integer;
    v_ClassName, v_DataName, v_string_consulta : string;
    v_array_SectionName : tstrings;
begin
    Result              := '';
    if (p_SectionName <> '') then
      Begin
        v_array_SectionName := g_oCacic.explode(p_SectionName,'/');
        v_array_SectionName_Count := v_array_SectionName.Count;
      End
    else v_array_SectionName_Count := 0;
    v_achei_SectionName := 0;
    v_ClassName         := 'classname="' + p_ClassName + '">';
    v_DataName          := '<data name="' + p_DataName + '"';

    intClasses          := 0;
    try
      While intClasses < p_Report.Count Do
        Begin
          if (pos(v_ClassName,p_Report[intClasses])>0) then
            Begin
              intSections := intClasses;
              While intSections < p_Report.Count Do
                Begin
                  if (p_SectionName<>'') then
                    Begin
                      v_string_consulta := '<section name="' + v_array_SectionName[v_achei_SectionName]+'">';
                      if (pos(v_string_consulta,p_Report[intSections])>0) then v_achei_SectionName := v_achei_SectionName+1;
                    End;

                  if (v_achei_SectionName = v_array_SectionName_Count) then
                    Begin

                      intDatas := intSections;
                      While intDatas < p_Report.Count Do
                        Begin

                          if (pos(v_DataName,p_Report[intDatas])>0) then
                            Begin
                              Result := Copy(p_Report[intDatas],pos('>',p_Report[intDatas])+1,length(p_Report[intDatas]));
                              Result := StringReplace(Result,'</data>','',[rfReplaceAll]);
                              intClasses  := p_Report.Count;
                              intSections := p_Report.Count;
                              intDatas    := p_Report.Count;
                            End;
                            intDatas := intDatas + 1;
                        End; //for intDatas...
                    End; // if pos(v_SectionName...
                    intSections := intSections + 1;
                End; // for intSections...
            End; // if pos(v_ClassName...
            intClasses := intClasses + 1;
        End; // for intClasses...
    except
          frmMapaCacic.Mensagem('ERRO! Problema na rotina parse',true,intPausaPadrao);
    end;
end;

procedure TfrmMapaCacic.Matar(v_dir,v_files: string);
var SearchRec: TSearchRec;
    Result: Integer;
begin
  Result:=FindFirst(v_dir+v_files, faAnyFile, SearchRec);
  while result=0 do
    begin
      log_DEBUG('Excluindo: "'+v_dir+SearchRec.Name+'"');
      DeleteFile(PChar(v_dir+SearchRec.Name));
      Result:=FindNext(SearchRec);
    end;
end;

procedure TfrmMapaCacic.Sair;
Begin
    g_oCacic.Free();
    Application.Terminate;
End;

procedure TfrmMapaCacic.Finalizar(p_pausa:boolean);
Begin
  Mensagem('Finalizando MapaCacic...',false,0);

  CipherClose(g_oCacic.getCacicPath + g_oCacic.getDatFileName, tStringsCipherOpened);
  Apaga_Temps;
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclusão de operações de arquivos.
  Sair;
End;

procedure TfrmMapaCacic.Apaga_Temps;
begin
  Matar(g_oCacic.getCacicPath + 'temp\','*.vbs');
  Matar(g_oCacic.getCacicPath + 'temp\','*.txt');
end;
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


Function TfrmMapaCacic.XML_RetornaValor(Tag : String; Fonte : String): String;
VAR
  Parser : TXmlParser;
begin
  Parser := TXmlParser.Create;
  Parser.Normalize := TRUE;
  Parser.LoadFromBuffer(PAnsiChar(Fonte));
  Parser.StartScan;
  WHILE Parser.Scan DO
  Begin
    if (Parser.CurPartType in [ptContent, ptCData]) Then  // Process Parser.CurContent field here
    begin
         if (UpperCase(Parser.CurName) = UpperCase(Tag)) then
            Result := RemoveZerosFimString(Parser.CurContent);
     end;
  end;
  Parser.Free;
  log_DEBUG('XML Parser retornando: "'+Result+'" para Tag "'+Tag+'"');
end;

Function TfrmMapaCacic.RemoveZerosFimString(Texto : String) : String;
var I : Integer;
    str_local_Aux : String;
Begin
   str_local_Aux := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         str_local_Aux := Texto[I] + str_local_Aux;
   Result := trim(str_local_Aux);
end;

Function TfrmMapaCacic.ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
var Response_CS     : TStringStream;
    strEndereco,
    strEnderecoServidor,
    strEnderecoWS   : String;
    idHTTP1         : TIdHTTP;
    intAux          : integer;
    tStringListAuxRequest    : TStringList;
Begin
    tStringListAuxRequest := TStringList.Create;
    tStringListAuxRequest := Request;

    tStringListAuxRequest.Values['cs_cipher']   := '1';
    tStringListAuxRequest.Values['cs_compress'] := '0';


    strEnderecoWS       := GetValorDatMemoria('Configs.Endereco_WS', tStringsCipherOpened);
    strEnderecoServidor := GetValorDatMemoria('Configs.EnderecoServidor', tStringsCipherOpened);

    if (trim(strEnderecoWS)='') then
        strEnderecoWS := '/cacic2/ws/';

    if (trim(strEnderecoServidor)='') then
        strEnderecoServidor := Trim(GetValorChaveRegIni('Cacic2','ip_serv_cacic',g_oCacic.getCacicPath + 'MapaCacic.ini'));

    strEndereco := 'http://' + strEnderecoServidor + strEnderecoWS + URL;

    if (trim(MsgAcao)='') then
        MsgAcao := '>> Enviando informações iniciais ao Gerente WEB.';

    log_diario(MsgAcao);

    Application.ProcessMessages;

    Response_CS := TStringStream.Create('');

    log_DEBUG('Iniciando comunicação com http://' + strEnderecoServidor + strEnderecoWS + URL);

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
            Log_Debug('Valores de REQUEST para envio ao Gerente WEB:');
            for intAux := 0 to tStringListAuxRequest.count -1 do
                Log_Debug('#'+inttostr(intAux)+': '+tStringListAuxRequest[intAux]);
          End;

       IdHTTP1.Post(strEndereco, tStringListAuxRequest, Response_CS);
       idHTTP1.Free;
       log_DEBUG('Retorno: "'+Response_CS.DataString+'"');
    Except
       Mensagem('ERRO! Comunicação impossível com o endereço ' + strEndereco + ': '+Response_CS.DataString,true,intPausaPadrao);
       result := '0';
       Exit;
    end;

    Application.ProcessMessages;
    Try
      if (UpperCase(XML_RetornaValor('Status', Response_CS.DataString)) <> 'OK') Then
        Begin
           Mensagem('PROBLEMAS DURANTE A COMUNICAÇÃO',true,intPausaPadrao);
           log_diario('Endereço: ' + strEndereco);
           log_diario('Mensagem: ' + Response_CS.DataString);
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
        log_diario('Endereço: ' + strEndereco);
        log_diario('Mensagem: ' + Response_CS.DataString);
        result := '0';
      End;
    End;
end;

//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function TfrmMapaCacic.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var

  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
    v_SectionName := '[' + p_SectionName + ']';
    v_Size_Section := strLen(PChar(v_SectionName));
    v_KeyName := p_KeyName + '=';
    v_Size_Key     := strLen(PChar(v_KeyName));

    FileText := TStringList.Create;

    try
      FileText.LoadFromFile(p_IniFileName);
      For i := 0 To FileText.Count - 1 Do
        Begin
          if (LowerCase(Trim(PChar(Copy(FileText[i],1,v_Size_Section)))) = LowerCase(Trim(PChar(v_SectionName)))) then
            Begin
              For j := i to FileText.Count - 1 Do
                Begin
                  if (LowerCase(Trim(PChar(Copy(FileText[j],1,v_Size_Key)))) = LowerCase(Trim(PChar(v_KeyName)))) then
                    Begin
                      Result := PChar(Copy(FileText[j],v_Size_Key + 1,strLen(PChar(FileText[j]))-v_Size_Key));
                      Break;
                    End;
                End;
            End;
          if (Result <> '') then break;
        End;
    finally
      FileText.Free;
    end;
  end;

function TfrmMapaCacic.GetFolderDate(Folder: string): TDateTime;
var
  Rec: TSearchRec;
  Found: Integer;
  Date: TDateTime;
begin
  if Folder[Length(folder)] = '\' then
    Delete(Folder, Length(folder), 1);
  Result := 0;
  Found  := FindFirst(Folder, faDirectory, Rec);
  try
    if Found = 0 then
    begin
      Date   := FileDateToDateTime(Rec.Time);
      Result := Date;
    end;
  finally
    FindClose(Rec);
  end;
end;

Function TfrmMapaCacic.CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
var strCipherOpenImploded : string;
    txtFileDatFile               : TextFile;
begin
 try
   FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
   AssignFile(txtFileDatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

   // Criação do arquivo .DAT
   Rewrite (txtFileDatFile);
   Append(txtFileDatFile);

   strCipherOpenImploded := g_oCacic.implode(p_tstrCipherOpened,'=CacicIsFree=');
   log_DEBUG('Rotina de Fechamento do arquivo DAT ATIVANDO criptografia.');
   strCipherClosed := g_oCacic.enCrypt(strCipherOpenImploded);
   log_DEBUG('Rotina de Fechamento do arquivo DAT RESTAURANDO estado da criptografia.');

   Writeln(txtFileDatFile,strCipherClosed); {Grava a string Texto no arquivo texto}

   CloseFile(txtFileDatFile);
 except
 end;
end;

Function TfrmMapaCacic.CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
    intLoop           : integer;
begin
  v_strCipherOpened    := '';
  if FileExists(p_DatFileName) then
    begin
      AssignFile(v_DatFile,p_DatFileName);
      {$IOChecks off}
      Reset(v_DatFile);
      {$IOChecks on}
      if (IOResult <> 0) then // Arquivo não existe, será recriado.
         begin
           Rewrite (v_DatFile);
           Append(v_DatFile);
         end;

      Readln(v_DatFile,v_strCipherClosed);
      while not EOF(v_DatFile) do Readln(v_DatFile,v_strCipherClosed);
      CloseFile(v_DatFile);
      strCipherOpened:= g_oCacic.deCrypt(v_strCipherClosed);
    end;
    if (trim(strCipherOpened)<>'') then
      Result := g_oCacic.explode(strCipherOpened,'=CacicIsFree=')
    else
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey+g_oCacic.getWindowsStrId() +g_oCacic.getSeparatorKey+'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);

    if Result.Count mod 2 = 0 then
        Result.Add('');

    log_DEBUG('MemoryDAT aberto com sucesso!');
    if boolDebugs then
      for intLoop := 0 to (Result.Count-1) do
        log_DEBUG('Posição ['+inttostr(intLoop)+'] do MemoryDAT: '+Result[intLoop]);

end;

Procedure TfrmMapaCacic.SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
begin
    log_DEBUG('Gravando Chave: "'+p_Chave+ '" => "'+p_Valor+'"');
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[tStringsCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(p_Valor);
      End;
end;
Function TfrmMapaCacic.GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
begin
    log_DEBUG('Resgatando Chave: "'+p_Chave+ '" => "'+Result+'"');
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := trim(p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1])
    else
      Result := '';
end;

function TfrmMapaCacic.SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
var RegEditSet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue : String;
    ListaAuxSet : TStrings;
    I : Integer;
begin
    ListaAuxSet := g_oCacic.explode(Chave, '\');
    strRootKey := ListaAuxSet[0];
    For I := 1 To ListaAuxSet.Count - 2 Do strKey := strKey + ListaAuxSet[I] + '\';
    strValue := ListaAuxSet[ListaAuxSet.Count - 1];

    RegEditSet := TRegistry.Create;
    try
        RegEditSet.Access := KEY_WRITE;
        RegEditSet.Rootkey := GetRootKey(strRootKey);

        if RegEditSet.OpenKey(strKey, True) then
        Begin
            RegDataType := RegEditSet.GetDataType(strValue);
            if RegDataType = rdString then
              begin
                RegEditSet.WriteString(strValue, Dado);
              end
            else if RegDataType = rdExpandString then
              begin
                RegEditSet.WriteExpandString(strValue, Dado);
              end
            else if RegDataType = rdInteger then
              begin
                RegEditSet.WriteInteger(strValue, Dado);
              end
            else
              begin
                RegEditSet.WriteString(strValue, Dado);
              end;

        end;
    finally
      RegEditSet.CloseKey;
    end;
    ListaAuxSet.Free;
    RegEditSet.Free;
end;

function TfrmMapaCacic.GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
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

    strId_unid_organizacional_nivel1 := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1',tStringsCipherOpened);
    if (strId_unid_organizacional_nivel1='') then
      strId_unid_organizacional_nivel1 := g_oCacic.deCrypt(XML.XML_RetornaValor('ID_UON1', p_strConfigs));

    strId_unid_organizacional_nivel1a := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1a',tStringsCipherOpened);
    if (strId_unid_organizacional_nivel1a='') then
      strId_unid_organizacional_nivel1a := g_oCacic.deCrypt(XML.XML_RetornaValor('ID_UON1a', p_strConfigs));

    strId_unid_organizacional_nivel2 := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2',tStringsCipherOpened);
    if (strId_unid_organizacional_nivel2='') then
      strId_unid_organizacional_nivel2 := g_oCacic.deCrypt(XML.XML_RetornaValor('ID_UON2', p_strConfigs));

    strId_Local := GetValorDatMemoria('Patrimonio.id_local',tStringsCipherOpened);
    if (strId_Local='') then
      strId_Local := g_oCacic.deCrypt(XML.XML_RetornaValor('ID_LOCAL', p_strConfigs));

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

    lbEtiqueta1.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta1', p_strConfigs));
    lbEtiqueta1a.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta1a', p_strConfigs));

    strTe_localizacao_complementar   := GetValorDatMemoria('Patrimonio.te_localizacao_complementar',tStringsCipherOpened);
    if (strTe_localizacao_complementar='') then strTe_localizacao_complementar := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_LOC_COMPL', p_strConfigs));

    // Tentarei buscar informação gravada no Registry
    strTe_info_patrimonio1           := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1');
    if (strTe_info_patrimonio1='') then
      Begin
        strTe_info_patrimonio1           := GetValorDatMemoria('Patrimonio.te_info_patrimonio1',tStringsCipherOpened);
      End;
    if (strTe_info_patrimonio1='') then strTe_info_patrimonio1 := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_INFO1', p_strConfigs));

    strTe_info_patrimonio2           := GetValorDatMemoria('Patrimonio.te_info_patrimonio2',tStringsCipherOpened);
    if (strTe_info_patrimonio2='') then strTe_info_patrimonio2 := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_INFO2', p_strConfigs));

    strTe_info_patrimonio3           := GetValorDatMemoria('Patrimonio.te_info_patrimonio3',tStringsCipherOpened);
    if (strTe_info_patrimonio3='') then strTe_info_patrimonio3 := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_INFO3', p_strConfigs));

    // Tentarei buscar informação gravada no Registry
    strTe_info_patrimonio4           := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4');
    if (strTe_info_patrimonio4='') then
      Begin
        strTe_info_patrimonio4           := GetValorDatMemoria('Patrimonio.te_info_patrimonio4',tStringsCipherOpened);
      End;
    if (strTe_info_patrimonio4='') then strTe_info_patrimonio4 := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_INFO4', p_strConfigs));

    strTe_info_patrimonio5           := GetValorDatMemoria('Patrimonio.te_info_patrimonio5',tStringsCipherOpened);
    if (strTe_info_patrimonio5='') then strTe_info_patrimonio5 := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_INFO5', p_strConfigs));

    strTe_info_patrimonio6           := GetValorDatMemoria('Patrimonio.te_info_patrimonio6',tStringsCipherOpened);
    if (strTe_info_patrimonio6='') then strTe_info_patrimonio6 := g_oCacic.deCrypt(XML.XML_RetornaValor('TE_INFO6', p_strConfigs));
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
  log_DEBUG('p_strConfigs: '+p_strConfigs);
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
             log_DEBUG('Gravei VetorUON1.id1: "'+strAux1+'"');
           End
         else if (strItemName = 'NM1') then
           Begin
             VetorUON1[i].nm1 := strAux1;
             log_DEBUG('Gravei VetorUON1.nm1: "'+strAux1+'"');
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
              log_DEBUG('Gravei VetorUON1a.id1: "'+strAux1+'"');
            End
          else if (strItemName = 'SG_LOC') then
            Begin
              strAux := ' ('+strAux1 + ')';
            End
          else if (strItemName = 'ID1A') then
            Begin
              VetorUON1a[i].id1a := strAux1;
              log_DEBUG('Gravei VetorUON1a.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'NM1A') then
            Begin
              VetorUON1a[i].nm1a := strAux1+strAux;
              log_DEBUG('Gravei VetorUON1a.nm1a: "'+strAux1+strAux+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON1a[i].id_local := strAux1;
              log_DEBUG('Gravei VetorUON1a.id_local: "'+strAux1+'"');
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
              log_DEBUG('Gravei VetorUON2.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'ID2') then
            Begin
              VetorUON2[i].id2 := strAux1;
              log_DEBUG('Gravei VetorUON2.id2: "'+strAux1+'"');
            End
          else if (strItemName = 'NM2') then
            Begin
              VetorUON2[i].nm2 := strAux1;
              log_DEBUG('Gravei VetorUON2.nm2: "'+strAux1+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON2[i].id_local := strAux1;
              log_DEBUG('Gravei VetorUON2.id_local: "'+strAux1+'"');
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
      frmMapaCacic.Mensagem('ATENÇÃO! Verifique se esta subrede foi cadastrada no CACIC.',true,intPausaPadrao * 2);
      Finalizar(true);
    End;

  For i := 0 to Length(VetorUON1) - 1 Do
    Begin
      Log_DEBUG('VetorUON1['+IntToStr(i)+'].id1='+VetorUON1[i].id1);
      Log_DEBUG('VetorUON1['+IntToStr(i)+'].nm1='+VetorUON1[i].nm1);
    End;

  For i := 0 to Length(VetorUON1a) - 1 Do
    Begin
      Log_DEBUG('VetorUON1a['+IntToStr(i)+'].id1='+VetorUON1a[i].id1);
      Log_DEBUG('VetorUON1a['+IntToStr(i)+'].id1a='+VetorUON1a[i].id1a);
      Log_DEBUG('VetorUON1a['+IntToStr(i)+'].nm1a='+VetorUON1a[i].nm1a);
      Log_DEBUG('VetorUON1a['+IntToStr(i)+'].id_local='+VetorUON1a[i].id_local);
    End;

  For i := 0 to Length(VetorUON2) - 1 Do
    Begin
      Log_DEBUG('VetorUON2['+IntToStr(i)+'].id1a='+VetorUON2[i].id1a);
      Log_DEBUG('VetorUON2['+IntToStr(i)+'].id2='+VetorUON2[i].id2);
      Log_DEBUG('VetorUON2['+IntToStr(i)+'].nm2='+VetorUON2[i].nm2);
      Log_DEBUG('VetorUON2['+IntToStr(i)+'].id_local='+VetorUON2[i].id_local);
    End;
end;


procedure TfrmMapaCacic.cb_id_unid_organizacional_nivel1Change(Sender: TObject);
var i, j: Word;
    strIdUON1 : String;
begin
      log_DEBUG('Nível 1 CHANGE');
      // Filtro os itens do combo2, de acordo com o item selecionado no combo1
      strIdUON1 := VetorUON1[cb_id_unid_organizacional_nivel1.ItemIndex].id1;
      cb_id_unid_organizacional_nivel1a.Items.Clear;
      cb_id_unid_organizacional_nivel2.Items.Clear;
      cb_id_unid_organizacional_nivel1a.Enabled := false;
      cb_id_unid_organizacional_nivel2.Enabled  := false;
      SetLength(VetorUON1aFiltrado, 0);

      log_DEBUG('Tamanho de VetorUON1..: '+IntToStr(Length(VetorUON1)));
      log_DEBUG('ItemIndex de cb_nivel1: '+IntToStr(cb_id_unid_organizacional_nivel1.ItemIndex));
      log_DEBUG('Tamanho de VetorUON1a.: '+IntToStr(Length(VetorUON1a)));
      For i := 0 to Length(VetorUON1a) - 1 Do
      Begin
          Try
            if VetorUON1a[i].id1 = strIdUON1 then
              Begin
                log_DEBUG('Add em cb_nivel1a: '+VetorUON1a[i].nm1a);
                cb_id_unid_organizacional_nivel1a.Items.Add(VetorUON1a[i].nm1a);
                j := Length(VetorUON1aFiltrado);
                SetLength(VetorUON1aFiltrado, j + 1);
                VetorUON1aFiltrado[j] := VetorUON1a[i].id1a + '#' +VetorUON1a[i].id_local;
                log_DEBUG('VetorUON1aFiltrado['+IntToStr(j)+']= '+VetorUON1aFiltrado[j]);
              end;
          Except
          End;
      end;
      if (cb_id_unid_organizacional_nivel1a.Items.Count > 0) then
        Begin
          cb_id_unid_organizacional_nivel1a.Enabled   := true;
          cb_id_unid_organizacional_nivel1a.ItemIndex := 0;
          log_DEBUG('Provocando CHANGE em nivel1a');
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
      log_DEBUG('Nível 1a CHANGE');
      // Filtro os itens do combo2, de acordo com o item selecionado no combo1
      //intAux := IfThen(cb_id_unid_organizacional_nivel1a.Items.Count > 1,cb_id_unid_organizacional_nivel1a.ItemIndex+1,0);
      intAux := cb_id_unid_organizacional_nivel1a.ItemIndex;
      Log_debug('cb_id_unid_organizacional_nivel1a.ItemIndex = '+intToStr(cb_id_unid_organizacional_nivel1a.ItemIndex));

      Log_debug('VetorUON1aFiltrado['+intToStr(cb_id_unid_organizacional_nivel1a.ItemIndex)+'] => '+VetorUON1aFiltrado[cb_id_unid_organizacional_nivel1a.ItemIndex]);
      tstrAux := TStrings.Create;
      tstrAux := g_oCacic.explode(VetorUON1aFiltrado[cb_id_unid_organizacional_nivel1a.ItemIndex],'#');

      strIdUON1a := tstrAux[0];
      strIdLocal := tstrAux[1];

      Log_debug('strIdLocal = '+strIdLocal);
      cb_id_unid_organizacional_nivel2.Items.Clear;
      cb_id_unid_organizacional_nivel2.Enabled  := false;
      SetLength(VetorUON2Filtrado, 0);

      log_DEBUG('Tamanho de VetorUON1a..: '+IntToStr(Length(VetorUON1a)));
      log_DEBUG('ItemIndex de cb_nivel1a: '+IntToStr(cb_id_unid_organizacional_nivel1a.ItemIndex));
      log_DEBUG('Tamanho de VetorUON2...: '+IntToStr(Length(VetorUON2)));

      For i := 0 to Length(VetorUON2) - 1 Do
      Begin
          Try
            if (VetorUON2[i].id1a     = strIdUON1a) and
               (VetorUON2[i].id_local = strIdLocal) then
              Begin
                log_DEBUG('Add em cb_nivel2: '+VetorUON2[i].nm2);
                cb_id_unid_organizacional_nivel2.Items.Add(VetorUON2[i].nm2);
                j := Length(VetorUON2Filtrado);
                SetLength(VetorUON2Filtrado, j + 1);
                VetorUON2Filtrado[j] := VetorUON2[i].id2 + '#' + VetorUON2[i].id_local;
                log_DEBUG('VetorUON2Filtrado['+IntToStr(j)+']= '+VetorUON2Filtrado[j]);
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
  Matar(g_oCacic.getCacicPath,'aguarde_CACIC.txt');

  if FileExists(g_oCacic.getCacicPath + 'aguarde_CACIC.txt') then
    MessageDLG(#13#10+'ATENÇÃO!'+#13#10#13#10+
                'Para o envio das informações, é necessário finalizar o Agente Principal do CACIC.',mtError,[mbOK],0)
  else
    Begin
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
        tstrListAux.Values['te_node_address']               := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS'                    , frmMapaCacic.tStringsCipherOpened));
        tstrListAux.Values['id_so']                         := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('Configs.ID_SO'                            , frmMapaCacic.tStringsCipherOpened));
        tstrListAux.Values['te_so']                         := g_oCacic.enCrypt(g_oCacic.getWindowsStrId());
        tstrListAux.Values['id_ip_rede']                    := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.ID_IP_REDE'                         , frmMapaCacic.tStringsCipherOpened));
        tstrListAux.Values['te_ip']                         := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_IP'                              , frmMapaCacic.tStringsCipherOpened));
        tstrListAux.Values['te_nome_computador']            := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR'                 , frmMapaCacic.tStringsCipherOpened));
        tstrListAux.Values['te_workgroup']                  := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_WORKGROUP'                       , frmMapaCacic.tStringsCipherOpened));
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

        log_DEBUG('Informações para contato com mapa_set_patrimonio:');
        log_DEBUG('te_node_address: '+tstrListAux.Values['te_node_address']);
        log_DEBUG('id_so: '+tstrListAux.Values['id_so']);
        log_DEBUG('te_so: '+tstrListAux.Values['te_so']);
        log_DEBUG('id_ip_rede: '+tstrListAux.Values['id_ip_rede']);
        log_DEBUG('te_ip: '+tstrListAux.Values['te_ip']);
        log_DEBUG('te_nome_computador: '+tstrListAux.Values['te_nome_computador']);
        log_DEBUG('te_workgroup: '+tstrListAux.Values['te_workgroup']);

        strRetorno := frmMapaCacic.ComunicaServidor('mapa_set_patrimonio.php', tstrListAux, '');
        tstrListAux.Free;

        if not (frmMapaCacic.XML_RetornaValor('STATUS', strRetorno)='OK') then
            Mensagem('ATENÇÃO: PROBLEMAS NO ENVIO DAS INFORMAÇÕES COLETADAS AO BANCO DE DADOS...',true,intPausaPadrao)
        else
          Begin
            Mensagem('Salvando Informações Coletadas em Base Local...',false,intPausaPadrao div 3);
            SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1', strIdUON1, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1a', strIdUON1a, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2' , strIdUON2, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.id_local'                      , strIdLocal, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.te_localizacao_complementar'  , ed_te_localizacao_complementar.Text, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.te_info_patrimonio1'          , ed_te_info_patrimonio1.Text, tStringsCipherOpened);
            SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1', ed_te_info_patrimonio1.Text);
            SetValorDatMemoria('Patrimonio.te_info_patrimonio2'          , ed_te_info_patrimonio2.Text, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.te_info_patrimonio3'          , ed_te_info_patrimonio3.Text, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.te_info_patrimonio4'          , ed_te_info_patrimonio4.Text, tStringsCipherOpened);
            SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4', ed_te_info_patrimonio4.Text);
            SetValorDatMemoria('Patrimonio.te_info_patrimonio5'          , ed_te_info_patrimonio5.Text, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.te_info_patrimonio6'          , ed_te_info_patrimonio6.Text, tStringsCipherOpened);
            SetValorDatMemoria('Patrimonio.ultima_rede_obtida'           , GetValorDatMemoria('TcpIp.ID_IP_REDE',frmMapaCacic.tStringsCipherOpened),tStringsCipherOpened);
          End;
        Finalizar(true);
    End;
end;

procedure TfrmMapaCacic.MontaInterface(p_strConfigs : String);
Begin
   Mensagem('Montando Interface para Coleta de Informações...',false,intPausaPadrao div 3);

   lbEtiqueta1.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta1', p_strConfigs));
   lbEtiqueta1.Visible := true;
   cb_id_unid_organizacional_nivel1.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta1', p_strConfigs));
   cb_id_unid_organizacional_nivel1.Visible := true;

   lbEtiqueta1a.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta1a', p_strConfigs));
   lbEtiqueta1a.Visible := true;
   cb_id_unid_organizacional_nivel1a.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta1a', p_strConfigs));
   cb_id_unid_organizacional_nivel1a.Visible := true;

   lbEtiqueta2.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta2', p_strConfigs));
   lbEtiqueta2.Visible := true;
   cb_id_unid_organizacional_nivel2.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta2', p_strConfigs));
   cb_id_unid_organizacional_nivel2.Visible := true;

   lbEtiqueta3.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta3', p_strConfigs));
   lbEtiqueta3.Visible := true;
   ed_te_localizacao_complementar.Text := strTe_localizacao_complementar;
   ed_te_localizacao_complementar.Visible := true;

   log_DEBUG('in_exibir_etiqueta4 -> "'+g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta4', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta4', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta4.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta4', p_strConfigs));
      lbEtiqueta4.Visible := true;
      ed_te_info_patrimonio1.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta4', p_strConfigs));
      ed_te_info_patrimonio1.Text          := strTe_info_patrimonio1;
      ed_te_info_patrimonio1.visible := True;
   end;

   log_DEBUG('in_exibir_etiqueta5 -> "'+g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta5', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta5', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta5.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta5', p_strConfigs));
      lbEtiqueta5.Visible := true;
      ed_te_info_patrimonio2.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta5', p_strConfigs));
      ed_te_info_patrimonio2.Text          := strTe_info_patrimonio2;
      ed_te_info_patrimonio2.visible := True;
   end;

   log_DEBUG('in_exibir_etiqueta6 -> "'+g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta6', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta6', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta6.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta6', p_strConfigs));
      lbEtiqueta6.Visible := true;
      ed_te_info_patrimonio3.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta6', p_strConfigs));
      ed_te_info_patrimonio3.Text          := strTe_info_patrimonio3;
      ed_te_info_patrimonio3.visible := True;
   end;

   log_DEBUG('in_exibir_etiqueta7 -> "'+g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta7', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta7', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta7.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta7', p_strConfigs));
      lbEtiqueta7.Visible := true;
      ed_te_info_patrimonio4.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta7', p_strConfigs));
      ed_te_info_patrimonio4.Text          := strTe_info_patrimonio4;
      ed_te_info_patrimonio4.visible := True;
   end;

   log_DEBUG('in_exibir_etiqueta8 -> "'+g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta8', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta8', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta8.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta8', p_strConfigs));
      lbEtiqueta8.Visible := true;
      ed_te_info_patrimonio5.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta8', p_strConfigs));
      ed_te_info_patrimonio5.Text          := strTe_info_patrimonio5;
      ed_te_info_patrimonio5.visible := True;
   end;

   log_DEBUG('in_exibir_etiqueta9 -> "'+g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta9', p_strConfigs))+'"');
   if (trim(g_oCacic.deCrypt(XML.XML_RetornaValor('in_exibir_etiqueta9', p_strConfigs))) = 'S') then
   begin
      lbEtiqueta9.Caption := g_oCacic.deCrypt(XML.XML_RetornaValor('te_etiqueta9', p_strConfigs));
      lbEtiqueta9.Visible := true;
      ed_te_info_patrimonio6.Hint := g_oCacic.deCrypt(XML.XML_RetornaValor('te_help_etiqueta9', p_strConfigs));
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
// Função adaptada de http://www.latiumsoftware.com/en/delphi/00004.php
//Para buscar do RegEdit...
function TfrmMapaCacic.GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := g_oCacic.explode(Chave, '\');

    strRootKey := ListaAuxGet[0];
    For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';
    strValue := ListaAuxGet[ListaAuxGet.Count - 1];
    if (strValue = '(Padrão)') then strValue := ''; //Para os casos de se querer buscar o valor default (Padrão)
    RegEditGet := TRegistry.Create;

        RegEditGet.Access := KEY_READ;
        RegEditGet.Rootkey := GetRootKey(strRootKey);
        if RegEditGet.OpenKeyReadOnly(strKey) then //teste
        Begin
             RegDataType := RegEditGet.GetDataType(strValue);
             if (RegDataType = rdString) or (RegDataType = rdExpandString) then Result := RegEditGet.ReadString(strValue)
             else if RegDataType = rdInteger then Result := RegEditGet.ReadInteger(strValue)
             else if (RegDataType = rdBinary) or (RegDataType = rdUnknown)
             then
             begin
               DataSize := RegEditGet.GetDataSize(strValue);
               if DataSize = -1 then exit;
               SetLength(s, DataSize);
               Len := RegEditGet.ReadBinaryData(strValue, PChar(s)^, DataSize);
               if Len <> DataSize then exit;
               Result := trim(RemoveCaracteresEspeciais(s,' ',32,126));
             end
        end;
    finally
    RegEditGet.CloseKey;
    RegEditGet.Free;
    ListaAuxGet.Free;

    end;
end;

Function TfrmMapaCacic.RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
var I : Integer;
    strAux : String;
Begin
//     if ord(Texto[I]) in [32..126] Then
//   else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := 0 To Length(Texto) Do
       if ord(Texto[I]) in [p_start..p_end] Then
         strAux := strAux + Texto[I]
       else
         strAux := strAux + p_Fill;
   Result := strAux;
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
begin
  Try
    strConfigs                           := GetValorDatMemoria('Patrimonio.Configs', frmMapaCacic.tStringsCipherOpened);
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
    v_strCacicPath    : String;
    Request_mapa      : TStringList;
begin
  g_oCacic := TCACIC.Create();

  g_oCacic.setBoolCipher(true);
  frmMapaCacic.lbVersao.Caption          := 'Versão: ' + frmMapaCacic.GetVersionInfo(ParamStr(0));
  log_DEBUG('Versão do MapaCacic: '+frmMapaCacic.lbVersao.Caption);

  if (g_oCacic.isWindowsNTPlataform()) and (not g_oCacic.isWindowsAdmin()) then
    Begin
      MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);
      Sair;
    End
  else
    Begin
      frmMapaCacic.tStringsCipherOpened := TStrings.Create;

      // Buscarei o caminho do Sistema em \WinDIR\chkSIS.DAT
      frmMapaCacic.tStringsCipherOpened := CipherOpen(g_oCacic.getWinDir + 'chksis.dat');
      v_strCacicPath := GetValorDatMemoria('cacic2.cacic_dir',frmMapaCacic.tStringsCipherOpened);

      if not (v_strCacicPath = '') then
        Begin
          g_oCacic.setCacicPath(v_strCacicPath);
          frmMapaCacic.tStringsCipherOpened := frmMapaCacic.CipherOpen(frmMapaCacic.g_oCacic.getCacicPath + frmMapaCacic.g_oCacic.getDatFileName);
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
            End
          else
            Begin
              Matar(g_oCacic.getCacicPath,'aguarde_CACIC.txt');

              if FileExists(g_oCacic.getCacicPath + 'aguarde_CACIC.txt') then
                Begin
                  MessageDLG(#13#10+'ATENÇÃO! É necessário finalizar o Agente Principal do CACIC.',mtError,[mbOK],0);
                  Sair;
                End;

              boolDebugs := false;
              if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
                Begin
                  if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                    Begin
                      boolDebugs := true;
                      log_DEBUG('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                    End;
                End;

              // Acessar...
              CriaFormSenha(nil);
              frmAcesso.ShowModal;

              if not (boolAcessoOK) then
                Finalizar(true)
              else
                Begin
                  pnMensagens.Visible := true;
                  Mensagem('Efetuando Comunicação com o Módulo Gerente WEB em "'+GetValorDatMemoria('Configs.EnderecoServidor', tStringsCipherOpened)+'"...',false,intPausaPadrao div 3);
                  frmAcesso.Free;

                  // Povoamento com dados de configurações da interface patrimonial
                  // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
                  Request_mapa  :=  TStringList.Create;
                  Request_mapa.Values['te_node_address']   := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS'   , frmMapaCacic.tStringsCipherOpened));
                  Request_mapa.Values['id_so']             := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('Configs.ID_SO'           , frmMapaCacic.tStringsCipherOpened));
                  Request_mapa.Values['te_so']             := g_oCacic.enCrypt(g_oCacic.getWindowsStrId());
                  Request_mapa.Values['id_ip_rede']        := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.ID_IP_REDE'        , frmMapaCacic.tStringsCipherOpened));
                  Request_mapa.Values['te_ip']             := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_IP'             , frmMapaCacic.tStringsCipherOpened));
                  Request_mapa.Values['te_nome_computador']:= g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR', frmMapaCacic.tStringsCipherOpened));
                  Request_mapa.Values['te_workgroup']      := g_oCacic.enCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_WORKGROUP'      , frmMapaCacic.tStringsCipherOpened));
                  Request_mapa.Values['id_usuario']        := g_oCacic.enCrypt(frmMapaCacic.strId_usuario);

                  strRetorno := frmMapaCacic.ComunicaServidor('mapa_get_patrimonio.php', Request_mapa, '.');

                  log_DEBUG('Retorno: "'+strRetorno+'"');

                  if (frmMapaCacic.XML_RetornaValor('STATUS', strRetorno)='OK') then
                    Begin
                      Mensagem('Comunicação Efetuada com Sucesso! Salvando Configurações Obtidas...',false,intPausaPadrao div 3);
                      frmMapaCacic.SetValorDatMemoria('Patrimonio.Configs', strRetorno, frmMapaCacic.tStringsCipherOpened)
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

end;


end.
