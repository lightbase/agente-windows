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

uses  IniFiles,
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
      DIALOGS,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64,
      ExtCtrls,
      Graphics;

var  strCipherClosed,
     strCipherOpened,
     strPathCacic                 : string;

var  boolDebugs                 : boolean;


// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const constKeySize = 32; // 32 bytes = 256 bits
      constBlockSize = 16; // 16 bytes = 128 bits

// Constantes a serem usadas pela função IsAdmin...
const constSECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
      constSECURITY_BUILTIN_DOMAIN_RID = $00000020;
      constDOMAIN_ALIAS_RID_ADMINS = $00000220;

const constCipherKey    = 'CacicES2005';
      constIV           = 'abcdefghijklmnop';
      constSeparatorKey = '=CacicIsFree='; // Usada apenas para o cacic2.dat


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
    pnVersao: TPanel;
    lbVersao: TLabel;
    pnMensagens: TPanel;
    lbMensagens: TLabel;

    procedure mapa;
    procedure Grava_Debugs(strMsg : String);
    function  SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
    function  GetValorChaveRegEdit(Chave: String): Variant;
    function  GetRootKey(strRootKey: String): HKEY;
    Function  RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
    function  HomeDrive : string;
    Function  Implode(p_Array : TStrings ; p_Separador : String) : String;
    Function  CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
    function  GetWinVer: Integer;
    Function  Explode(Texto, Separador : String) : TStrings;
    Function  CipherOpen(p_DatFileName : string) : TStrings;
    Function  GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
    function  PadWithZeros(const str : string; size : integer) : string;
    function  EnCrypt(p_Data : String) : String;
    function  DeCrypt(p_Data : String) : String;
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
    function  IsAdmin: Boolean;
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
    Function  RetornaValorVetorUON1(id1Procurado1 : string) : String;
    Function  RetornaValorVetorUON2(id1Procurado : string; id2Procurado : string) : String;
    function  LetrasDrives: string;
    function  SearchFile(p_Drive,p_File:string) : boolean;
    procedure GetSubDirs(Folder:string; sList:TStringList);
    procedure Mensagem(p_strMsg : String; p_boolAlerta : boolean);
    procedure FormActivate(Sender: TObject);
  private
    var_id_unid_organizacional_nivel1,
    var_id_unid_organizacional_nivel2,
    var_te_localizacao_complementar,
    var_te_info_patrimonio1,
    var_te_info_patrimonio2,
    var_te_info_patrimonio3,
    var_te_info_patrimonio4,
    var_te_info_patrimonio5,
    var_te_info_patrimonio6           : String;
  public
    boolAcessoOK               : boolean;
    strId_usuario,
    strDatFileName             : String;
    tStringsDadosPatrimonio,
    tStringsCipherOpened,
    tStringsTripa1             : TStrings;
  end;

var
  frmMapaCacic: TfrmMapaCacic;

implementation

uses acesso;

{$R *.dfm}


// Estruturas de dados para armazenar os itens da uon1 e uon2
type
  TRegistroUON1 = record
    id1 : String;
    nm1 : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON2 = record
    id1 : String;
    id2 : String;
    nm2 : String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1 : TVetorUON1;
    VetorUON2 : TVetorUON2;

    // Esse array é usado apenas para saber a uon2, após a filtragem pelo uon1
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

procedure TfrmMapaCacic.Mensagem(p_strMsg : String; p_boolAlerta : boolean);
Begin
  if p_boolAlerta then
    lbMensagens.Font.Color := clRed
  else
    lbMensagens.Font.Color := clBlack;

  lbMensagens.Caption := p_strMsg;
  log_diario(lbMensagens.Caption);
  Application.ProcessMessages;
End;

procedure TfrmMapaCacic.log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (strPathCacic + 'MapaCacic.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,strPathCacic + 'MapaCacic.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(strPathCacic + 'MapaCacic.log')));
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
       v_file_debugs := strPathCacic + '\debug_mapa.txt';
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


//
Function TfrmMapaCacic.Explode(Texto, Separador : String) : TStrings;
var
    strItem       : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres,
    TamanhoSeparador,
    I : Integer;
Begin
    ListaAuxUTILS    := TStringList.Create;
    strItem          := '';
    NumCaracteres    := Length(Texto);
    TamanhoSeparador := Length(Separador);
    I                := 1;
    While I <= NumCaracteres Do
      Begin
        If (Copy(Texto,I,TamanhoSeparador) = Separador) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + Texto[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
            strItem := strItem + Texto[I];

        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
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
        v_array_SectionName := explode(p_SectionName,'/');
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
          frmMapaCacic.Mensagem('ERRO! Problema na rotina parse',true);
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
  application.Terminate;
//  FreeMemory(0);
//  Halt(0);
End;

procedure TfrmMapaCacic.Finalizar(p_pausa:boolean);
Begin
  Mensagem('Finalizando MapaCacic...',false);

  CipherClose(strDatFileName, tStringsCipherOpened);
  Apaga_Temps;
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclusão de operações de arquivos.
  Sair;
End;
procedure TfrmMapaCacic.Apaga_Temps;
begin
  Matar(strPathCacic + 'temp\','*.vbs');
  Matar(strPathCacic + 'temp\','*.txt');
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
        strEnderecoServidor := Trim(GetValorChaveRegIni('Cacic2','ip_serv_cacic',strPathCacic + 'MapaCacic.ini'));

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
       idHTTP1.Request.UserAgent                := EnCrypt('AGENTE_CACIC');
       idHTTP1.Request.Username                 := EnCrypt('USER_CACIC');
       idHTTP1.Request.Password                 := EnCrypt('PW_CACIC');
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
       Mensagem('ERRO! Comunicação impossível com o endereço ' + strEndereco + Response_CS.DataString,true);
       result := '0';
       Exit;
    end;

    Application.ProcessMessages;
    Try
      if (UpperCase(XML_RetornaValor('Status', Response_CS.DataString)) <> 'OK') Then
        Begin
           Mensagem('PROBLEMAS DURANTE A COMUNICAÇÃO',true);
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
        Mensagem('PROBLEMAS DURANTE A COMUNICAÇÃO',true);
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


// Pad a string with zeros so that it is a multiple of size
function TfrmMapaCacic.PadWithZeros(const str : string; size : integer) : string;
var
  origsize, i : integer;
begin
  Result := str;
  origsize := Length(Result);
  if ((origsize mod size) <> 0) or (origsize = 0) then
  begin
    SetLength(Result,((origsize div size)+1)*size);
    for i := origsize+1 to Length(Result) do
      Result[i] := #0;
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

// Encrypt a string and return the Base64 encoded result
function TfrmMapaCacic.EnCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
        // Pad Key, IV and Data with zeros as appropriate
        l_Key   := PadWithZeros(constCipherKey,constKeySize);
        l_IV    := PadWithZeros(constIV,constBlockSize);
        l_Data  := PadWithZeros(p_Data,constBlockSize);

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);
        if Length(constCipherKey) <= 16 then
          l_Cipher.Init(l_Key[1],128,@l_IV[1])
        else if Length(constCipherKey) <= 24 then
          l_Cipher.Init(l_Key[1],192,@l_IV[1])
        else
          l_Cipher.Init(l_Key[1],256,@l_IV[1]);

        // Encrypt the data
        l_Cipher.EncryptCBC(l_Data[1],l_Data[1],Length(l_Data));

        // Free the cipher and clear sensitive information
        l_Cipher.Free;
        FillChar(l_Key[1],Length(l_Key),0);

        // Return the Base64 encoded result
        Result := Base64EncodeStr(l_Data);
  Except
    log_diario('Erro no Processo de Criptografia');
  End;
end;

function TfrmMapaCacic.DeCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
        // Pad Key and IV with zeros as appropriate
        l_Key := PadWithZeros(constCipherKey,constKeySize);
        l_IV := PadWithZeros(constIV,constBlockSize);

        // Decode the Base64 encoded string
        l_Data := Base64DecodeStr(p_Data);

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);
        if Length(constCipherKey) <= 16 then
          l_Cipher.Init(l_Key[1],128,@l_IV[1])
        else if Length(constCipherKey) <= 24 then
          l_Cipher.Init(l_Key[1],192,@l_IV[1])
        else
          l_Cipher.Init(l_Key[1],256,@l_IV[1]);

        // Decrypt the data
        l_Cipher.DecryptCBC(l_Data[1],l_Data[1],Length(l_Data));

        // Free the cipher and clear sensitive information
        l_Cipher.Free;
        FillChar(l_Key[1],Length(l_Key),0);
        log_DEBUG('DeCriptografia(ATIVADA) de "'+p_Data+'" => "'+l_Data+'"');
        // Return the result
        Result := trim(l_Data);
  Except
    log_diario('Erro no Processo de Decriptografia');
  End;
end;

function TfrmMapaCacic.HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
end;

Function TfrmMapaCacic.Implode(p_Array : TStrings ; p_Separador : String) : String;
var intAux : integer;
    strAux : string;
Begin
    strAux := '';
    For intAux := 0 To p_Array.Count -1 do
      Begin
        if (strAux<>'') then strAux := strAux + p_Separador;
        strAux := strAux + p_Array[intAux];
      End;
    Implode := strAux;
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

       strCipherOpenImploded := Implode(p_tstrCipherOpened,'=CacicIsFree=');
       log_DEBUG('Rotina de Fechamento do cacic2.dat ATIVANDO criptografia.');
       strCipherClosed := EnCrypt(strCipherOpenImploded);
       log_DEBUG('Rotina de Fechamento do cacic2.dat RESTAURANDO estado da criptografia.');

       Writeln(txtFileDatFile,strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(txtFileDatFile);
   except
   end;
end;
function TfrmMapaCacic.GetWinVer: Integer;
const
  { operating system (OS)constants }
  cOsUnknown = 0;
  cOsWin95 = 1;
  cOsWin95OSR2 = 2;  // Não implementado.
  cOsWin98 = 3;
  cOsWin98SE = 4;
  cOsWinME = 5;
  cOsWinNT = 6;
  cOsWin2000 = 7;
  cOsXP = 8;
var
  osVerInfo: TOSVersionInfo;
  majorVer, minorVer: Integer;
begin
  Result := cOsUnknown;
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
    majorVer := osVerInfo.dwMajorVersion;
    minorVer := osVerInfo.dwMinorVersion;
    case osVerInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT: { Windows NT/2000 }
        begin
          if majorVer <= 4 then
            Result := cOsWinNT
          else if (majorVer = 5) and (minorVer = 0) then
            Result := cOsWin2000
          else if (majorVer = 5) and (minorVer = 1) then
            Result := cOsXP
          else
            Result := cOsUnknown;
        end;
      VER_PLATFORM_WIN32_WINDOWS:  { Windows 9x/ME }
        begin
          if (majorVer = 4) and (minorVer = 0) then
            Result := cOsWin95
          else if (majorVer = 4) and (minorVer = 10) then
          begin
            if osVerInfo.szCSDVersion[1] = 'A' then
              Result := cOsWin98SE
            else
              Result := cOsWin98;
          end
          else if (majorVer = 4) and (minorVer = 90) then
            Result := cOsWinME
          else
            Result := cOsUnknown;
        end;
      else
        Result := cOsUnknown;
    end;
  end
  else
    Result := cOsUnknown;
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
      strCipherOpened:= DeCrypt(v_strCipherClosed);
    end;
    if (trim(strCipherOpened)<>'') then
      Result := explode(strCipherOpened,'=CacicIsFree=')
    else
      Result := explode('Configs.ID_SO=CacicIsFree='+inttostr(GetWinVer)+'=CacicIsFree=Configs.Endereco_WS=CacicIsFree=/cacic2/ws/','=CacicIsFree=');

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

    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := trim(p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1])
    else
      Result := '';
    log_DEBUG('Resgatando Chave: "'+p_Chave+ '" => "'+Result+'"');
end;

function TfrmMapaCacic.SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
var RegEditSet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue : String;
    ListaAuxSet : TStrings;
    I : Integer;
begin
    ListaAuxSet := Explode(Chave, '\');
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

Function TfrmMapaCacic.RetornaValorVetorUON1(id1Procurado1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].id1 = id1Procurado1) Then Result := VetorUON1[I].nm1;
end;


Function TfrmMapaCacic.RetornaValorVetorUON2(id1Procurado : string; id2Procurado : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].id1 = id1Procurado) and (VetorUON2[I].id2 = id2Procurado) Then Result := VetorUON2[I].nm2;
end;

procedure TfrmMapaCacic.RecuperaValoresAnteriores(p_strConfigs : String);
begin
    Mensagem('Recuperando Valores Anteriores...',false);

    var_id_unid_organizacional_nivel1 := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1',tStringsCipherOpened);
    if (var_id_unid_organizacional_nivel1='') then var_id_unid_organizacional_nivel1 := DeCrypt(XML.XML_RetornaValor('ID_UON1', p_strConfigs));

    var_id_unid_organizacional_nivel2 := GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2',tStringsCipherOpened);
    if (var_id_unid_organizacional_nivel2='') then var_id_unid_organizacional_nivel2 := DeCrypt(XML.XML_RetornaValor('ID_UON2', p_strConfigs));

    Try
      cb_id_unid_organizacional_nivel1.ItemIndex := cb_id_unid_organizacional_nivel1.Items.IndexOf(RetornaValorVetorUON1(var_id_unid_organizacional_nivel1));
      cb_id_unid_organizacional_nivel1Change(Nil); // Para filtrar os valores do combo2 de acordo com o valor selecionado no combo1
      cb_id_unid_organizacional_nivel2.ItemIndex := cb_id_unid_organizacional_nivel2.Items.IndexOf(RetornaValorVetorUON2(var_id_unid_organizacional_nivel1, var_id_unid_organizacional_nivel2));
    Except
    end;

    lbEtiqueta1.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta1', p_strConfigs));


    var_te_localizacao_complementar   := GetValorDatMemoria('Patrimonio.te_localizacao_complementar',tStringsCipherOpened);
    if (var_te_localizacao_complementar='') then var_te_localizacao_complementar := DeCrypt(XML.XML_RetornaValor('TE_LOC_COMPL', p_strConfigs));

    // Tentarei buscar informação gravada no Registry
    var_te_info_patrimonio1           := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1');
    if (var_te_info_patrimonio1='') then
      Begin
        var_te_info_patrimonio1           := GetValorDatMemoria('Patrimonio.te_info_patrimonio1',tStringsCipherOpened);
      End;
    if (var_te_info_patrimonio1='') then var_te_info_patrimonio1 := DeCrypt(XML.XML_RetornaValor('TE_INFO1', p_strConfigs));

    var_te_info_patrimonio2           := GetValorDatMemoria('Patrimonio.te_info_patrimonio2',tStringsCipherOpened);
    if (var_te_info_patrimonio2='') then var_te_info_patrimonio2 := DeCrypt(XML.XML_RetornaValor('TE_INFO2', p_strConfigs));

    var_te_info_patrimonio3           := GetValorDatMemoria('Patrimonio.te_info_patrimonio3',tStringsCipherOpened);
    if (var_te_info_patrimonio3='') then var_te_info_patrimonio3 := DeCrypt(XML.XML_RetornaValor('TE_INFO3', p_strConfigs));

    // Tentarei buscar informação gravada no Registry
    var_te_info_patrimonio4           := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4');
    if (var_te_info_patrimonio4='') then
      Begin
        var_te_info_patrimonio4           := GetValorDatMemoria('Patrimonio.te_info_patrimonio4',tStringsCipherOpened);
      End;
    if (var_te_info_patrimonio4='') then var_te_info_patrimonio4 := DeCrypt(XML.XML_RetornaValor('TE_INFO4', p_strConfigs));

    var_te_info_patrimonio5           := GetValorDatMemoria('Patrimonio.te_info_patrimonio5',tStringsCipherOpened);
    if (var_te_info_patrimonio5='') then var_te_info_patrimonio5 := DeCrypt(XML.XML_RetornaValor('TE_INFO5', p_strConfigs));

    var_te_info_patrimonio6           := GetValorDatMemoria('Patrimonio.te_info_patrimonio6',tStringsCipherOpened);
    if (var_te_info_patrimonio6='') then var_te_info_patrimonio6 := DeCrypt(XML.XML_RetornaValor('TE_INFO6', p_strConfigs));
end;

procedure TfrmMapaCacic.MontaCombos(p_strConfigs : String);
var Parser   : TXmlParser;
    i        : integer;
    v_Tag    : boolean;
begin
  Mensagem('Montando Listas para Seleção de U.O. Nível 1 e U.O. Nível 2...',false);

  Parser := TXmlParser.Create;
  Parser.Normalize := True;
  Parser.LoadFromBuffer(PAnsiChar(p_strConfigs));
  Parser.StartScan;
  i := -1;
  v_Tag := false;
  While Parser.Scan and (UpperCase(Parser.CurName) <> 'IT2') DO
  Begin
     if ((Parser.CurPartType = ptStartTag) and (UpperCase(Parser.CurName) = 'IT1')) Then
        Begin
          v_Tag := true;
          i := i + 1;
          SetLength(VetorUON1, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
        end
     else if (Parser.CurPartType in [ptContent, ptCData]) and v_Tag Then
          if      (UpperCase(Parser.CurName) = 'ID1') then VetorUON1[i].id1 := DeCrypt(Parser.CurContent)
          else if (UpperCase(Parser.CurName) = 'NM1') then VetorUON1[i].nm1 := DeCrypt(Parser.CurContent);
  end;

  // Código para montar o combo 2
  Parser.StartScan;

  v_Tag := false;
  i := -1;
  While Parser.Scan DO
  Begin
     if ((Parser.CurPartType = ptStartTag) and (UpperCase(Parser.CurName) = 'IT2')) Then
       Begin
         v_Tag := TRUE;
         i := i + 1;
         SetLength(VetorUON2, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
       end
     else if (Parser.CurPartType in [ptContent, ptCData]) and v_Tag Then
        if      (UpperCase(Parser.CurName) = 'ID1') then VetorUON2[i].id1 := DeCrypt(Parser.CurContent)
        else if (UpperCase(Parser.CurName) = 'ID2') then VetorUON2[i].id2 := DeCrypt(Parser.CurContent)
        else if (UpperCase(Parser.CurName) = 'NM2') then VetorUON2[i].nm2 := DeCrypt(Parser.CurContent);
  end;
  Parser.Free;
  // Como os itens do combo1 nunca mudam durante a execução do programa (ao contrario do combo2), posso colocar o seu preenchimento aqui mesmo.
  cb_id_unid_organizacional_nivel1.Items.Clear;
  For i := 0 to Length(VetorUON1) - 1 Do
     cb_id_unid_organizacional_nivel1.Items.Add(VetorUON1[i].nm1);
end;


procedure TfrmMapaCacic.cb_id_unid_organizacional_nivel1Change(Sender: TObject);
var i, j: Word;
    strAux : String;
begin
  // Filtro os itens do combo2, de acordo com o item selecionado no combo1
  strAux := VetorUON1[cb_id_unid_organizacional_nivel1.ItemIndex].id1;

  cb_id_unid_organizacional_nivel2.Items.Clear;
  SetLength(VetorUON2Filtrado, 0);
  For i := 0 to Length(VetorUON2) - 1 Do
  Begin
     if VetorUON2[i].id1 = strAux then
     Begin
        cb_id_unid_organizacional_nivel2.Items.Add(VetorUON2[i].nm2);
        j := Length(VetorUON2Filtrado);
        SetLength(VetorUON2Filtrado, j + 1);
        VetorUON2Filtrado[j] := VetorUON2[i].id2;
     end;
  end;
end;


procedure TfrmMapaCacic.AtualizaPatrimonio(Sender: TObject);
var strAux1,
    strAux2,
    strRetorno   : String;
    Request_mapa : TStringList;
begin
     Try
        strAux1 := VetorUON1[cb_id_unid_organizacional_nivel1.ItemIndex].id1;
        strAux2 := VetorUON2Filtrado[cb_id_unid_organizacional_nivel2.ItemIndex];
     Except
     end;
// Assim, o envio será incondicional!  -  01/12/2006 - Anderson Peterle
//     if (strAux1 <> var_id_unid_organizacional_nivel1) or
//        (strAux2 <> var_id_unid_organizacional_nivel2) or
//         (ed_te_localizacao_complementar.Text <> var_te_localizacao_complementar) or
//         (ed_te_info_patrimonio1.Text <> var_te_info_patrimonio1) or
//         (ed_te_info_patrimonio2.Text <> var_te_info_patrimonio2) or
//         (ed_te_info_patrimonio3.Text <> var_te_info_patrimonio3) or
//         (ed_te_info_patrimonio4.Text <> var_te_info_patrimonio4) or
//         (ed_te_info_patrimonio5.Text <> var_te_info_patrimonio5) or
//         (ed_te_info_patrimonio6.Text <> var_te_info_patrimonio6) then
//      begin

          Mensagem('Enviando Informações Coletadas ao Banco de Dados...',false);

          // Envio dos Dados Coletados ao Banco de Dados
          Request_mapa  :=  TStringList.Create;
          Request_mapa.Values['te_node_address']               := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS'                    , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['id_so']                         := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Configs.ID_SO'                            , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['id_ip_rede']                    := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.ID_IP_REDE'                         , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_ip']                         := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_IP'                              , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_nome_computador']            := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR'                 , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_workgroup']                  := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_WORKGROUP'                       , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['id_usuario']                    := frmMapaCacic.EnCrypt(frmMapaCacic.strId_usuario);

          Request_mapa.Values['id_unid_organizacional_nivel1'] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1' , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['id_unid_organizacional_nivel2'] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2' , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_localizacao_complementar'  ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_localizacao_complementar'   , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_info_patrimonio1'          ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_info_patrimonio1'           , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_info_patrimonio2'          ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_info_patrimonio2'           , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_info_patrimonio3'          ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_info_patrimonio3'           , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_info_patrimonio4'          ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_info_patrimonio4'           , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_info_patrimonio5'          ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_info_patrimonio5'           , frmMapaCacic.tStringsCipherOpened));
          Request_mapa.Values['te_info_patrimonio6'          ] := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Patrimonio.te_info_patrimonio6'           , frmMapaCacic.tStringsCipherOpened));

          strRetorno := frmMapaCacic.ComunicaServidor('mapa_set_patrimonio.php', Request_mapa, '');
          Request_mapa.Free;

          if not (frmMapaCacic.XML_RetornaValor('STATUS', strRetorno)='OK') then
              Mensagem('ATENÇÃO: PROBLEMAS NO ENVIO DAS INFORMAÇÕES COLETADAS AO BANCO DE DADOS...',true);
//          else
//            Begin
              Mensagem('Salvando Informações Coletadas em Base Local...',false);
              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1', strAux1, tStringsCipherOpened);
              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2', strAux2, tStringsCipherOpened);
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
//            End;
//      end
//    else
//      Mensagem('NÃO HÁ COLETA ATENÇÃO: PROBLEMAS NO ENVIO DAS INFORMAÇÕES COLETADAS AO BANCO DE DADOS...',true);
    Finalizar(true);
end;

procedure TfrmMapaCacic.MontaInterface(p_strConfigs : String);
Begin
   Mensagem('Montando Interface para Coleta de Informações...',false);

   lbEtiqueta1.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta1', p_strConfigs));
   lbEtiqueta1.Visible := true;
   cb_id_unid_organizacional_nivel1.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta1', p_strConfigs));
   cb_id_unid_organizacional_nivel1.Visible := true;

   lbEtiqueta2.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta2', p_strConfigs));
   lbEtiqueta2.Visible := true;
   cb_id_unid_organizacional_nivel2.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta2', p_strConfigs));
   cb_id_unid_organizacional_nivel2.Visible := true;

   lbEtiqueta3.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta3', p_strConfigs));
   lbEtiqueta3.Visible := true;
   ed_te_localizacao_complementar.Text := var_te_localizacao_complementar;
   ed_te_localizacao_complementar.Visible := true;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta4', p_strConfigs)) = 'S') then
   begin
      lbEtiqueta4.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta4', p_strConfigs));
      lbEtiqueta4.Visible := true;
      ed_te_info_patrimonio1.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta4', p_strConfigs));
      ed_te_info_patrimonio1.Text          := var_te_info_patrimonio1;
      ed_te_info_patrimonio1.visible := True;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta5', p_strConfigs)) = 'S') then
   begin
      lbEtiqueta5.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta5', p_strConfigs));
      lbEtiqueta5.Visible := true;
      ed_te_info_patrimonio2.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta5', p_strConfigs));
      ed_te_info_patrimonio2.Text          := var_te_info_patrimonio2;
      ed_te_info_patrimonio2.visible := True;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta6', p_strConfigs)) = 'S') then
   begin
      lbEtiqueta6.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta6', p_strConfigs));
      lbEtiqueta6.Visible := true;
      ed_te_info_patrimonio3.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta6', p_strConfigs));
      ed_te_info_patrimonio3.Text          := var_te_info_patrimonio3;
      ed_te_info_patrimonio3.visible := True;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta7', p_strConfigs)) = 'S') then
   begin
      lbEtiqueta7.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta7', p_strConfigs));
      lbEtiqueta7.Visible := true;
      ed_te_info_patrimonio4.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta7', p_strConfigs));
      ed_te_info_patrimonio4.Text          := var_te_info_patrimonio4;
      ed_te_info_patrimonio4.visible := True;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta8', p_strConfigs)) = 'S') then
   begin
      lbEtiqueta8.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta8', p_strConfigs));
      lbEtiqueta8.Visible := true;
      ed_te_info_patrimonio5.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta8', p_strConfigs));
      ed_te_info_patrimonio5.Text          := var_te_info_patrimonio5;
      ed_te_info_patrimonio5.visible := True;
   end;

   if (DeCrypt(XML.XML_RetornaValor('in_exibir_etiqueta9', p_strConfigs)) = 'S') then
  begin
     lbEtiqueta9.Caption := DeCrypt(XML.XML_RetornaValor('te_etiqueta9', p_strConfigs));
     lbEtiqueta9.Visible := true;
     ed_te_info_patrimonio6.Hint := DeCrypt(XML.XML_RetornaValor('te_help_etiqueta9', p_strConfigs));
     ed_te_info_patrimonio6.Text          := var_te_info_patrimonio6;
     ed_te_info_patrimonio6.visible := True;
  end;
  Mensagem('',false);
  btGravarInformacoes.Visible := true;
end;

procedure TfrmMapaCacic.FormClose(Sender: TObject; var Action: TCloseAction);
begin
Sair;
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
    ListaAuxGet := Explode(Chave, '\');

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

function TfrmMapaCacic.IsAdmin: Boolean;
var hAccessToken: THandle;
    ptgGroups: PTokenGroups;
    dwInfoBufferSize: DWORD;
    psidAdministrators: PSID;
    x: Integer;
    bSuccess: BOOL;
begin
  Result   := False;
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
  end;
  if bSuccess then
  begin
    GetMem(ptgGroups, 1024);
    bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize);
    CloseHandle(hAccessToken);
    if bSuccess then
    begin
      AllocateAndInitializeSid(constSECURITY_NT_AUTHORITY, 2,
                               constSECURITY_BUILTIN_DOMAIN_RID,
                               constDOMAIN_ALIAS_RID_ADMINS,
                               0, 0, 0, 0, 0, 0, psidAdministrators);
      {$R-}
      for x := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then
        begin
          Result := True;
          Break;
        end;
      {$R+}
      FreeSid(psidAdministrators);
    end;
    FreeMem(ptgGroups);
  end;
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
    strRetorno        : String;
    Request_mapa      : TStringList;
begin
  frmMapaCacic.lbVersao.Caption := 'v: ' + frmMapaCacic.GetVersionInfo(ParamStr(0));
  if (GetWinVer > 5) and not IsAdmin then
    Begin
      MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);
      Sair;
    End
  else
    Begin
      // Varrer unidades C:\, D:\ e E:\ ... em busca da estrutura Cacic\cacic2.dat
      strLetrasDrives := LetrasDrives;
      strPathCacic    := '';
      for intAux := 1 to length(strLetrasDrives) do
        Begin
          lbMensagens.Caption := 'Procurando Estrutura CACIC em "'+strLetrasDrives[intAux] + ':\"';

          Log_Debug('Testando "'+strLetrasDrives[intAux] + ':\Cacic\cacic2.dat'+'"');
          if (strPathCacic='') and (SearchFile(strLetrasDrives[intAux] + ':','\Cacic\cacic2.dat')) then
            Begin
              strPathCacic := strLetrasDrives[intAux] + ':\Cacic\';
              lbMensagens.Caption := 'Estrutura Encontrada!';
              Log_Debug('Validado "'+strLetrasDrives[intAux] + ':\Cacic\cacic2.dat'+'"');
            End
          else
            Log_Debug('Não Validado em "'+strLetrasDrives[intAux] + ':\Cacic\cacic2.dat'+'"');
          application.ProcessMessages;
        End;

      if not (strPathCacic = '') then
        Begin
          strDatFileName := strPathCacic + 'cacic2.dat'; // Algo como X:\Cacic\cacic2.dat

          boolDebugs := false;
          if DirectoryExists(strPathCacic + 'Temp\Debugs') then
            Begin
              if (FormatDateTime('ddmmyyyy', GetFolderDate(strPathCacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                Begin
                  boolDebugs := true;
                  log_DEBUG('Pasta "' + strPathCacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(strPathCacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
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
              Mensagem('Efetuando Comunicação com o Módulo Gerente WEB...',false);
              frmAcesso.Free;

              // Povoamento com dados de configurações da interface patrimonial
              // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
              Request_mapa  :=  TStringList.Create;
              Request_mapa.Values['te_node_address']   := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS'   , frmMapaCacic.tStringsCipherOpened));
              Request_mapa.Values['id_so']             := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('Configs.ID_SO'           , frmMapaCacic.tStringsCipherOpened));
              Request_mapa.Values['id_ip_rede']        := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.ID_IP_REDE'        , frmMapaCacic.tStringsCipherOpened));
              Request_mapa.Values['te_ip']             := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_IP'             , frmMapaCacic.tStringsCipherOpened));
              Request_mapa.Values['te_nome_computador']:= frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR', frmMapaCacic.tStringsCipherOpened));
              Request_mapa.Values['te_workgroup']      := frmMapaCacic.EnCrypt(frmMapaCacic.GetValorDatMemoria('TcpIp.TE_WORKGROUP'      , frmMapaCacic.tStringsCipherOpened));

              strRetorno := frmMapaCacic.ComunicaServidor('mapa_get_patrimonio.php', Request_mapa, '.');
              if (frmMapaCacic.XML_RetornaValor('STATUS', strRetorno)='OK') then
                Begin
                  Mensagem('Comunicação Efetuada com Sucesso! Salvando Configurações Obtidas...',true);
                  frmMapaCacic.SetValorDatMemoria('Patrimonio.Configs', strRetorno, frmMapaCacic.tStringsCipherOpened)
                End
              else
                Begin
                  Mensagem('PROBLEMAS NA COMUNICAÇÃO COM O MÓDULO GERENTE WEB...',true);
                  sleep(3);
                  Finalizar(true);
                End;

              Request_mapa.Free;

              mapa;
            End;
        End
      else
        Begin
          lbMensagens.Caption := 'Estrutura CACIC não Encontrada!';
          application.ProcessMessages;        
          MessageDLG(#13#10+'Não Encontrei a Estrutura do Sistema CACIC!'+#13#10+
                     'Operação Abortada!',mtError,[mbOK],0);
          Sair;
        End;
    End;

end;

end.
