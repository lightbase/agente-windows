(*
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

NOTA: O componente MiTeC System Information Component (MSIC) é baseado na classe TComponent e contém alguns subcomponentes baseados na classe TPersistent
      Este componente é apenas freeware e não open-source, e foi baixado de http://www.mitec.cz/Downloads/MSIC.zip
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

program ger_cols;
{$R *.res}

uses
  ShellApi,
  Windows,
  SysUtils,
  Classes,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  IdFTP,
  idFTPCommon,
  IdBaseComponent,
  IdComponent,
  PJVersionInfo,
  MSI_Machine,
  MSI_NETWORK,
  MSI_XML_Reports,
  StrUtils,
  Math,
  WinSock,
  NB30,
  IniFiles,
  Registry,
  LibXmlParser in 'LibXmlParser.pas',
  DCPcrypt2,
  DCPrijndael,
  DCPbase64,
  ZLibEx,
  CACIC_Library in '..\CACIC_Library.pas';

{$APPTYPE CONSOLE}
var p_path_cacic,
    v_scripter,
    p_Shell_Command,
    v_acao_gercols,
    v_Tamanho_Arquivo,
    v_Endereco_Servidor,
    v_Aux,
    strAux,
    endereco_servidor_cacic,
    v_ModulosOpcoes,
    v_CipherKey,
    v_IV,
    v_DatFileName,
    v_ResultCompress,
    v_ResultUnCompress,
    v_te_so        : string;

var v_Aguarde                 : TextFile;

var CountUPD,
    intAux,
    intMontaBatch,
    intLoop : integer;

var tstrTripa1,
    v_tstrCipherOpened,
    v_tstrCipherOpened1,
    tstringsAux               : TStrings;

var v_Debugs,
    l_cs_cipher,
    l_cs_compress,
    v_CS_AUTO_UPDATE          : boolean;

var BatchFile,
    Request_Ger_Cols          : TStringList;

var
  g_oCacic: TCACIC;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

// Pad a string with zeros so that it is a multiple of size
function PadWithZeros(const str : string; size : integer) : string;
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

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (p_path_cacic + 'cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,p_path_cacic + 'cacic2.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Gerente de Coletas] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
       if (trim(v_acao_gercols)='') then v_acao_gercols := strMsg;
   except
   end;
end;

// Gerador de Palavras-Chave
function GeraPalavraChave: String;
var intLimite,
    intContaLetras : integer;
    strPalavra,
    strCaracter    : String;
    charCaracter   : Char;
begin
  Randomize;
  strPalavra  := '';
  intLimite  := RandomRange(10,30); // Gerarei uma palavra com tamanho mínimo 10 e máximo 30
  for intContaLetras := 1 to intLimite do
    Begin
      strCaracter := '.';
      while not (strCaracter[1] in ['0'..'9','A'..'Z','a'..'z']) do
        Begin
          if (strCaracter = '.') then strCaracter := '';
          Randomize;
          strCaracter := chr(RandomRange(1,250));
        End;

      strPalavra := strPalavra + strCaracter;
    End;
  Result := strPalavra;
end;

function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

function Compress(p_strToCompress : string) : String;
var   v_tstrToCompress, v_tstrCompressed : TStringStream;
      Zip : TZCompressionStream;
begin
  v_tstrToCompress := TStringStream.Create('');
  v_tstrCompressed := TStringStream.Create(p_strToCompress);
  Zip := TZCompressionStream.Create(v_tstrCompressed,zcLevel9);
  Zip.CopyFrom(v_tstrToCompress,v_tstrToCompress.Size);
  Zip.Free;

  Result := ZlibEx.ZCompressStrWeb(v_tstrCompressed.DataString);
end; {Compress}

function DeCompress(p_ToDeCompress : String) : String;
var v_tstrToDeCompress, v_tstrDeCompressed : TStringStream;
    DeZip: TZDecompressionStream;
    i: Integer;
    Buf: array[0..1023]of Byte;
begin
  v_tstrDeCompressed := TstringStream.Create('');
  v_tstrToDeCompress   := TstringStream.Create(p_ToDeCompress);
  DeZip:=TZDecompressionStream.Create(v_tstrDeCompressed);
try
  repeat
  i:=DeZip.Read(Buf, SizeOf(Buf));
  if i <> 0 then v_tstrDeCompressed.Write(buf,i);
  until i <= 0;
except
end;

DeZip.Free;
  Result := ZlibEx.ZDecompressStrEx(v_tstrDeCompressed.DataString);
end; {DeCompress}

Function RemoveCaracteresEspeciais(Texto, p_Fill : String; p_start, p_end:integer) : String;
var I : Integer;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := 0 To Length(Texto) Do
       if ord(Texto[I]) in [p_start..p_end] Then
         strAux := strAux + Texto[I]
       else
         strAux := strAux + p_Fill;
   Result := trim(strAux);
end;

Function RemoveZerosFimString(Texto : String) : String;
var I : Integer;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         strAux := Texto[I] + strAux;
   Result := trim(strAux);
end;

Function XML_RetornaValor(Tag : String; Fonte : String): String;
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


Function Explode(Texto, Separador : String) : TStrings;
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

function StringtoHex(Data: string): string;
var 
  i, i2: Integer;
  s: string;
begin
  i2 := 1;
  for i := 1 to Length(Data) do
  begin
    Inc(i2);
    if i2 = 2 then
    begin
      s  := s + ' ';
      i2 := 1;
    end;
    s := s + IntToHex(Ord(Data[i]), 2);
  end;
  Result := s;
end;

Function Implode(p_Array : TStrings ; p_Separador : String) : String;
var intAux : integer;
Begin
    strAux := '';
    For intAux := 0 To p_Array.Count -1 do
      Begin
        if (strAux<>'') then strAux := strAux + p_Separador;
        strAux := strAux + p_Array[intAux];
      End;
    Implode := strAux;
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
var v_Aux     : string;
begin
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    v_Aux := RemoveZerosFimString(p_Valor);
    log_DEBUG('Gravando Chave: "'+p_Chave+'" => "'+v_Aux+'"');
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1] := v_Aux
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(v_Aux);
      End;
end;
Function GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
begin
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        Result := trim(p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1])
    else
        Result := '';

    log_DEBUG('Resgatando Chave: "'+p_Chave+'" => "'+Result+'"');
end;

// Encrypt a string and return the Base64 encoded result
function EnCrypt(p_Data : String; p_Compress : Boolean) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data,
  l_Key,
  l_IV,
  strAux : String;
begin
  Try
    if l_cs_cipher then
      Begin
        // Pad Key, IV and Data with zeros as appropriate
        l_Key   := PadWithZeros(v_CipherKey,KeySize);
        l_IV    := PadWithZeros(v_IV,BlockSize);
        l_Data  := PadWithZeros(trim(p_Data),BlockSize);

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);
        if Length(v_CipherKey) <= 16 then
          l_Cipher.Init(l_Key[1],128,@l_IV[1])
        else if Length(v_CipherKey) <= 24 then
          l_Cipher.Init(l_Key[1],192,@l_IV[1])
        else
          l_Cipher.Init(l_Key[1],256,@l_IV[1]);

        // Encrypt the data
        l_Cipher.EncryptCBC(l_Data[1],l_Data[1],Length(l_Data));

        // Free the cipher and clear sensitive information
        l_Cipher.Free;
        FillChar(l_Key[1],Length(l_Key),0);
        log_DEBUG('Criptografia(ATIVADA) de "'+p_Data+'" => "'+l_Data+'"');
        // Return the Base64 encoded result

        Result := trim(Base64EncodeStr(l_Data));
      End
    else
      Begin
        log_DEBUG('Criptografia(DESATIVADA) de "'+p_Data+'"');
        Result := trim(p_Data);
      End;
  Except
    log_diario('Erro no Processo de Criptografia');
  End;
  if (p_Compress) and (l_cs_compress) then
       Result := Compress(Result);
end;

function DeCrypt(p_Data : String ; p_DeCompress : Boolean) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV, v_Data : string;
begin
  Try
    v_Data := p_Data;
    if (p_DeCompress) and (l_cs_compress) then
         v_Data := DeCompress(p_Data);

    if l_cs_cipher then
      Begin
        // Pad Key and IV with zeros as appropriate
        l_Key := PadWithZeros(v_CipherKey,KeySize);
        l_IV := PadWithZeros(v_IV,BlockSize);

        // Decode the Base64 encoded string
        l_Data := Base64DecodeStr(trim(v_Data));

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);
        if Length(v_CipherKey) <= 16 then
          l_Cipher.Init(l_Key[1],128,@l_IV[1])
        else if Length(v_CipherKey) <= 24 then
          l_Cipher.Init(l_Key[1],192,@l_IV[1])
        else
          l_Cipher.Init(l_Key[1],256,@l_IV[1]);

        // Decrypt the data
        l_Cipher.DecryptCBC(l_Data[1],l_Data[1],Length(l_Data));

        // Free the cipher and clear sensitive information
        l_Cipher.Free;
        FillChar(l_Key[1],Length(l_Key),0);
        log_DEBUG('DeCriptografia(ATIVADA) de "'+v_Data+'" => "'+l_Data+'"');
        // Return the result
        Result := trim(RemoveZerosFimString(l_Data));
      End
    else
      Begin
        log_DEBUG('DeCriptografia(DESATIVADA) de "'+v_Data+'"');
        Result := trim(v_Data);
      End;
  Except
    log_diario('Erro no Processo de DeCriptografia. Dado = '+v_Data);
  End;
end;

procedure Matar(v_dir,v_files: string);
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

Function CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
var v_strCipherOpenImploded,
    v_strCipherClosed,
    strAux                  : string;
    v_DatFile,
    v_DatFileDebug          : TextFile;
    v_cs_cipher             : boolean;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       // Criação do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       if v_Debugs then
         Begin
           strAux := StringReplace(p_DatFileName,'.dat','_Debug.dat',[rfReplaceAll]);
           AssignFile(v_DatFileDebug,strAux); {Associa o arquivo a uma variável do tipo TextFile}

           // Criação do arquivo .DAT para Debug
           {$IOChecks off}
           Rewrite (v_DatFileDebug);
           {$IOChecks on}
           Append(v_DatFileDebug);
         End;

       v_strCipherOpenImploded := Implode(p_tstrCipherOpened,'=CacicIsFree=');

       v_cs_cipher := l_cs_cipher;
       l_cs_cipher := true;
       log_DEBUG('Rotina de Fechamento do cacic2.dat ATIVANDO criptografia.');
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded, false);

       l_cs_cipher := v_cs_cipher;
       log_DEBUG('Rotina de Fechamento do cacic2.dat RESTAURANDO estado da criptografia.');
       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}
       if v_Debugs then
          Begin
            Writeln(v_DatFileDebug,StringReplace(v_strCipherOpenImploded,'=CacicIsFree=',#13#10,[rfReplaceAll]));
            CloseFile(v_DatFileDebug);
          End;
       CloseFile(v_DatFile);
   except
     log_diario('ERRO NA GRAVAÇÃO DO ARQUIVO DE CONFIGURAÇÕES.');
   end;

   // Pausa (5 seg.) para conclusão da operação de ESCRITA do arquivo .DAT
   sleep(5000);
end;

Function CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
    //intLoop           : integer;
    v_cs_cipher       : boolean;
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
      v_cs_cipher := l_cs_cipher;
      l_cs_cipher := true;
      log_DEBUG('Rotina de Abertura do cacic2.dat ATIVANDO criptografia.');
      v_strCipherOpened:= DeCrypt(v_strCipherClosed,false);
      l_cs_cipher := v_cs_cipher;
      log_DEBUG('Rotina de Abertura do cacic2.dat RESTAURANDO estado da criptografia.');
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := explode(v_strCipherOpened,'=CacicIsFree=')
    else
      Result := explode('Configs.ID_SO=CacicIsFree='+g_oCacic.getWindowsStrId()+'=CacicIsFree=Configs.Endereco_WS=CacicIsFree=/cacic2/ws/','=CacicIsFree=');

    if Result.Count mod 2 = 0 then
        Result.Add('');

end;

procedure Apaga_Temps;
begin
  Matar(p_path_cacic + 'temp\','*.vbs');
  Matar(p_path_cacic + 'temp\','*.txt');
end;

procedure Finalizar(p_pausa:boolean);
Begin
  CipherClose(v_DatFileName, v_tstrCipherOpened);
  Apaga_Temps;
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclusão de operações de arquivos.
End;

procedure Sair;
Begin
  log_DEBUG('Liberando Memória - FreeMemory(0)');
  FreeMemory(0);
  log_DEBUG('Suspendendo - Halt(0)');
  Halt(0);
End;

procedure Seta_l_cs_cipher(p_strRetorno : String);
var v_Aux : string;
Begin
  l_cs_cipher := false;

  v_Aux := XML_RetornaValor('cs_cipher',p_strRetorno);
  if (p_strRetorno = '') or (v_Aux = '') then v_Aux := '3';

  if (v_Aux='1') then
    Begin
      log_DEBUG('ATIVANDO Criptografia!');
      l_cs_cipher := true;
    End
  else if (v_Aux='2') then
    Begin
      log_diario('Setando criptografia para nível 2 e finalizando para rechamada.');
      SetValorDatMemoria('Configs.CS_CIPHER', v_Aux,v_tstrCipherOpened);
      Finalizar(true);
      Sair;
    End;
  SetValorDatMemoria('Configs.CS_CIPHER', v_Aux,v_tstrCipherOpened);
End;

procedure Seta_l_cs_compress(p_strRetorno : String);
var v_Aux : string;
Begin
  l_cs_compress := false;

  v_Aux := XML_RetornaValor('cs_compress',p_strRetorno);
  if v_Aux = '' then v_Aux := '3';

  if (v_Aux='1') then
    Begin
      log_DEBUG('ATIVANDO Compressão!');
      l_cs_compress := true;
    End
  else log_DEBUG('DESATIVANDO Compressão!');

  SetValorDatMemoria('Configs.CS_COMPRESS', v_Aux,v_tstrCipherOpened);
End;

//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
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


function GetFolderDate(Folder: string): TDateTime;
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

function GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

// Função adaptada de http://www.latiumsoftware.com/en/delphi/00004.php
// Para buscar do RegEdit...
function GetValorChaveRegEdit(Chave: String): Variant;
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
      if (strValue = '(Padrão)') then strValue := ''; // Para os casos de se querer buscar o valor default (Padrão)
      RegEditGet := TRegistry.Create;

      RegEditGet.Access   := KEY_READ;
      RegEditGet.Rootkey  := GetRootKey(strRootKey);
      if RegEditGet.OpenKeyReadOnly(strKey) then // Somente para leitura no Registry
        Begin
         RegDataType := RegEditGet.GetDataType(strValue);
         if (RegDataType = rdString) or (RegDataType = rdExpandString) then Result := RegEditGet.ReadString(strValue)
         else if RegDataType = rdInteger then Result := RegEditGet.ReadInteger(strValue)
         else if (RegDataType = rdBinary) or (RegDataType = rdUnknown) then
          begin
           DataSize := RegEditGet.GetDataSize(strValue);
           if DataSize = -1 then exit;
           SetLength(s, DataSize);
           Len := RegEditGet.ReadBinaryData(strValue, PChar(s)^, DataSize);
           if Len <> DataSize then exit;
           Result := RemoveCaracteresEspeciais(s,' ',32,126);
          end
        end;
    finally
      RegEditGet.CloseKey;
      RegEditGet.Free;
      ListaAuxGet.Free;
    end;
end;

function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
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

Procedure DelValorReg(Chave: String);
var RegDelValorReg: TRegistry;
    strRootKey, strKey, strValue : String;
    ListaAuxDel : TStrings;
    I : Integer;
begin
    ListaAuxDel := Explode(Chave, '\');
    strRootKey := ListaAuxDel[0];
    For I := 1 To ListaAuxDel.Count - 2 Do strKey := strKey + ListaAuxDel[I] + '\';
    strValue := ListaAuxDel[ListaAuxDel.Count - 1];
    RegDelValorReg := TRegistry.Create;

    try
        RegDelValorReg.Access := KEY_WRITE;
        RegDelValorReg.Rootkey := GetRootKey(strRootKey);

        if RegDelValorReg.OpenKey(strKey, True) then
        RegDelValorReg.DeleteValue(strValue);
    finally
      RegDelValorReg.CloseKey;
    end;
    RegDelValorReg.Free;
    ListaAuxDel.Free;
end;

function Get_File_Size(sFileToExamine: string; bInKBytes: Boolean): string;
var
  SearchRec: TSearchRec;
  sgPath: string;
  inRetval, I1: Integer;
begin
  sgPath := ExpandFileName(sFileToExamine);
  try
    inRetval := FindFirst(ExpandFileName(sFileToExamine), faAnyFile, SearchRec);
    if inRetval = 0 then
      I1 := SearchRec.Size
    else
      I1 := -1;
  finally
    SysUtils.FindClose(SearchRec);
  end;
  Result := IntToStr(I1);
end;

function LastPos(SubStr, S: string): Integer;
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

function GetMACAddress: string;
var
  NCB: PNCB;
  Adapter: PAdapterStatus;

  URetCode: PChar;
  RetCode: char;
  I: integer;
  Lenum: PlanaEnum;
  _SystemID: string;
  TMPSTR: string;
begin
  Result    := '';
  _SystemID := '';
  Getmem(NCB, SizeOf(TNCB));
  Fillchar(NCB^, SizeOf(TNCB), 0);

  Getmem(Lenum, SizeOf(TLanaEnum));
  Fillchar(Lenum^, SizeOf(TLanaEnum), 0);

  Getmem(Adapter, SizeOf(TAdapterStatus));
  Fillchar(Adapter^, SizeOf(TAdapterStatus), 0);

  Lenum.Length    := chr(0);
  NCB.ncb_command := chr(NCBENUM);
  NCB.ncb_buffer  := Pointer(Lenum);
  NCB.ncb_length  := SizeOf(Lenum);
  RetCode         := Netbios(NCB);

  i := 0;
  repeat
    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBRESET);
    Ncb.ncb_lana_num := lenum.lana[I];
    RetCode          := Netbios(Ncb);

    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBASTAT);
    Ncb.ncb_lana_num := lenum.lana[I];
    // Must be 16
    Ncb.ncb_callname := '*               ';

    Ncb.ncb_buffer := Pointer(Adapter);

    Ncb.ncb_length := SizeOf(TAdapterStatus);
    RetCode        := Netbios(Ncb);
    //---- calc _systemId from mac-address[2-5] XOR mac-address[1]...
    if (RetCode = chr(0)) or (RetCode = chr(6)) then
    begin
      _SystemId := IntToHex(Ord(Adapter.adapter_address[0]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[1]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[2]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[3]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[4]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[5]), 2);
    end;
    Inc(i);
  until (I >= Ord(Lenum.Length)) or (_SystemID <> '00-00-00-00-00-00');
  FreeMem(NCB);
  FreeMem(Adapter);
  FreeMem(Lenum);
  GetMacAddress := _SystemID;
end;

Function GetWorkgroup : String;
var listaAux_GWG : TStrings;
begin
   If Win32Platform = VER_PLATFORM_WIN32_WINDOWS Then { Windows 9x/ME }
       Result := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VxD\VNETSUP\Workgroup')
   Else If Win32Platform = VER_PLATFORM_WIN32_NT Then
     Begin
       Try
          strAux := GetValorChaveRegEdit('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Last Domain');
          listaAux_GWG := Explode(strAux, ',');
          Result := Trim(listaAux_GWG[2]);
          listaAux_GWG.Free;
       Except
          Result := '';
       end;
     end;

   Try
     // XP
     if Result='' then Result := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultDomainName');
   Except
   End;
end;

function GetIPRede(IP_Computador : String ; MascaraRede : String) : String;
var L1_GIR, L2_GIR : TStrings;
    aux1, aux2, aux3, aux4, aux5 : string;
    j, i : short;

    function IntToBin(Value: LongInt;  Digits: Integer): String;
    var i: Integer;
    begin
       Result:='';
       for i:=Digits downto 0 do
          if Value and (1 shl i)<>0 then  Result:=Result + '1'
          else  Result:=Result + '0';
    end;

    function BinToInt(Value: String): LongInt;
    var i,Size: Integer;
        aux : Extended;
    begin
        aux := 0;
        Size := Length(Value);
        For i := Size - 1 downto 0 do
        Begin
           if Copy(Value, i+1, 1) = '1' Then aux := aux + IntPower(2, (Size - 1) - i);
        end;
       Result := Round(aux);
    end;
begin
  Try
   L1_GIR := Explode(IP_Computador, '.');
   L2_GIR := Explode(MascaraRede, '.');

   //Percorre cada um dos 4 octetos dos endereços
   for i := 0 to 3  do
   Begin
       aux1 := IntToBin(StrToInt(L1_GIR[i]), 7);
       aux2 := IntToBin(StrToInt(L2_GIR[i]), 7);
       aux4 := '';
       for j := 1 to Length(aux1) do
       Begin
           If ((aux1[j] = '0') or (aux2[j] = '0')) then aux3 := '0' else aux3 := '1';
           aux4 := aux4 + aux3;
       end;
       aux5 := aux5 + inttostr(BinToInt(aux4)) + '.';
   end;
   L1_GIR.Free;
   L2_GIR.Free;
   aux5 := Copy(aux5, 0, Length(aux5)-1);

     // Para os casos em que a rotina GetIPRede não funcionar!  (Ex.: Win95x em NoteBook)
     if (aux5 = '') or (aux5 = IP_Computador) or (aux5 = '0.0.0.0')then
        begin
        aux5 := '';
        i := 0;
        for j := 1 to Length(IP_Computador) do
          Begin
           If (IP_Computador[j] = '.') then i := i + 1;
           if (i < 3) then
              begin
                aux5 := aux5 + IP_Computador[j];
              end
           else
              begin
                if (i = 3) then //Consideraremos provisoriamente que a máscara seja 255.255.255.0
                    begin
                      aux5 := aux5 + '.0';
                      i := 30; // Para não entrar mais nessa condição!
                    end;
              end;
          end;
     end;
   Result := aux5;
  Except
   Result := '';
  End;
end;

// Função criada devido a divergências entre os valores retornados pelos métodos dos componentes MSI e seus Reports.
function Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
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
        Begin
          log_diario('ERRO! Problema na rotina parse');
        End;
    end;
end;

procedure Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := p_path_cacic + '\Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt';
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

//Para gravar no Arquivo INI...
function SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    if (FileGetAttr(p_Path) and faReadOnly) > 0 then
    FileSetAttr(p_Path, FileGetAttr(p_Path) xor faReadOnly);

    Reg_Ini := TIniFile.Create(p_Path);
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

function GetIP: string;
var ipwsa:TWSAData; p:PHostEnt; s:array[0..128] of char; c:pchar;
begin
  wsastartup(257,ipwsa);
  GetHostName(@s, 128);
  p := GetHostByName(@s);
  c := iNet_ntoa(PInAddr(p^.h_addr_list^)^);
  Result := String(c);
end;

Function ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
var Response_CS     : TStringStream;
    strEndereco,
    v_Endereco_WS,
    strAux          : String;
    idHTTP1         : TIdHTTP;
    intAux          : integer;
    v_AuxRequest    : TStringList;
Begin
    v_AuxRequest := TStringList.Create;
    v_AuxRequest := Request;

    // A partir da versão 2.0.2.5+ envio um Classificador indicativo de dados criptografados...
    v_AuxRequest.Values['cs_cipher']   := GetValorDatMemoria('Configs.CS_CIPHER',v_tstrCipherOpened);

    // A partir da versão 2.0.2.18+ envio um Classificador indicativo de dados compactados...
    v_AuxRequest.Values['cs_compress']   := GetValorDatMemoria('Configs.CS_COMPRESS',v_tstrCipherOpened);

    strAux := GetValorDatMemoria('TcpIp.TE_IP', v_tstrCipherOpened);
    if (strAux = '') then
        strAux := 'A.B.C.D'; // Apenas para forçar que o Gerente extraia via _SERVER[REMOTE_ADDR]

    v_AuxRequest.Values['te_node_address']   := StringReplace(EnCrypt(GetValorDatMemoria('TcpIp.TE_NODE_ADDRESS'   , v_tstrCipherOpened),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_so']             := StringReplace(EnCrypt(g_oCacic.getWindowsStrId()                   , l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    // Tratamentos de valores para tráfego POST:
    // v_te_so => transformar ' ' em <ESPACE> Razão: o mmcrypt se perde quando encontra ' ' (espaço)
    //v_te_so := StringReplace(v_te_so,' ','<ESPACE>',[rfReplaceAll]);
    v_AuxRequest.Values['te_so']             := StringReplace(EnCrypt(StringReplace(v_te_so,' ','<ESPACE>',[rfReplaceAll])              ,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_ip']             := StringReplace(EnCrypt(strAux                                                            ,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_ip_rede']        := StringReplace(EnCrypt(GetValorDatMemoria('TcpIp.ID_IP_REDE'        , v_tstrCipherOpened),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_workgroup']      := StringReplace(EnCrypt(GetValorDatMemoria('TcpIp.TE_WORKGROUP'      , v_tstrCipherOpened),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_nome_computador']:= StringReplace(EnCrypt(GetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR', v_tstrCipherOpened),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_ip_estacao']     := StringReplace(EnCrypt(GetIP,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_versao_cacic']   := StringReplace(EnCrypt(getVersionInfo(p_path_cacic + 'cacic2.exe'),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_versao_gercols'] := StringReplace(EnCrypt(getVersionInfo(ParamStr(0)),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

    v_Endereco_WS       := GetValorDatMemoria('Configs.Endereco_WS', v_tstrCipherOpened);
    v_Endereco_Servidor := GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened);

    if (trim(v_Endereco_WS)='') then
      Begin
        v_Endereco_WS := '/cacic2/ws/';
        SetValorDatMemoria('Configs.Endereco_WS', v_Endereco_WS, v_tstrCipherOpened);
      End;

    if (trim(v_Endereco_Servidor)='') then
        v_Endereco_Servidor := Trim(GetValorChaveRegIni('Configs','EnderecoServidor',p_path_cacic + 'cacic2.ini'));

    strEndereco := 'http://' + v_Endereco_Servidor + v_Endereco_WS + URL;

    if (trim(MsgAcao)='') then
        MsgAcao := '>> Enviando informações iniciais ao Gerente WEB.';

    if (trim(MsgAcao)<>'.') then
        log_diario(MsgAcao);

    Response_CS := TStringStream.Create('');

    log_DEBUG('Iniciando comunicação com http://' + v_Endereco_Servidor + v_Endereco_WS + URL);

    Try
       idHTTP1 := TIdHTTP.Create(nil);
       idHTTP1.AllowCookies                     := true;
       idHTTP1.ASCIIFilter                      := false; // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.AuthRetries                      := 1;     // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.BoundPort                        := 0;
       idHTTP1.HandleRedirects                  := false;
       idHTTP1.ProxyParams.BasicAuthentication  := false;
       idHTTP1.ProxyParams.ProxyPort            := 0;
       idHTTP1.ReadTimeout                      := 0;
       idHTTP1.RedirectMaximum                  := 15;
       idHTTP1.Request.UserAgent                := StringReplace(EnCrypt('AGENTE_CACIC',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Username                 := StringReplace(EnCrypt('USER_CACIC',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Password                 := StringReplace(EnCrypt('PW_CACIC',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Accept                   := 'text/html, */*';
       idHTTP1.Request.BasicAuthentication      := true;
       idHTTP1.Request.ContentLength            := -1;
       idHTTP1.Request.ContentRangeStart        := 0;
       idHTTP1.Request.ContentRangeEnd          := 0;
       idHTTP1.Request.ContentType              := 'text/html';
       idHTTP1.RecvBufferSize                   := 32768; // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.SendBufferSize                   := 32768; // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.Tag                              := 0;

       // ATENÇÃO: Substituo os sinais de "+" acima por <MAIS> devido a problemas encontrados no envio POST

       if v_Debugs then
          Begin
            Log_Debug('te_so => '+v_te_so);
            Log_Debug('Valores de REQUEST para envio ao Gerente WEB:');
            for intAux := 0 to v_AuxRequest.count -1 do
                Log_Debug('#'+inttostr(intAux)+': '+v_AuxRequest[intAux]);
          End;

       IdHTTP1.Post(strEndereco, v_AuxRequest, Response_CS);
       idHTTP1.Disconnect;
       idHTTP1.Free;

       log_DEBUG('Retorno: "'+Response_CS.DataString+'"');
    Except
       log_diario('ERRO! Comunicação impossível com o endereço ' + strEndereco + Response_CS.DataString);
       result := '0';
       Exit;
    end;

    Try
      if (UpperCase(XML_RetornaValor('Status', Response_CS.DataString)) <> 'OK') Then
        Begin
           log_diario('PROBLEMAS DURANTE A COMUNICAÇÃO:');
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
        log_diario('PROBLEMAS DURANTE A COMUNICAÇÃO:');
        log_diario('Endereço: ' + strEndereco);
        log_diario('Mensagem: ' + Response_CS.DataString);
        result := '0';
      End;
    End;
end;

procedure GetInfoPatrimonio;
var strDt_ultima_renovacao_patrim,
    strUltimaRedeObtida,
    strRetorno,
    strIntervaloRenovacaoPatrimonio   : string;
    intHoje                           : Integer;
    Request_Ger_Cols                  : TStringList;
Begin
    // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
    Request_Ger_Cols:=TStringList.Create;

    strRetorno := ComunicaServidor('get_patrimonio.php', Request_Ger_Cols, '.');
    SetValorDatMemoria('Patrimonio.Configs', strRetorno, v_tstrCipherOpened);
    SetValorDatMemoria('Patrimonio.cs_abre_janela_patr', DeCrypt(XML_RetornaValor('cs_abre_janela_patr', strRetorno),true), v_tstrCipherOpened);

    Request_Ger_Cols.Free;

    strUltimaRedeObtida := GetValorDatMemoria('Patrimonio.ultima_rede_obtida', v_tstrCipherOpened);
    strDt_ultima_renovacao_patrim := GetValorDatMemoria('Patrimonio.dt_ultima_renovacao_patrim', v_tstrCipherOpened);

    // Inicializa como "N' os valores de Remanejamento e Renovação que serão lidos pelo módulo de Coleta de Informações Patrimoniais.
    SetValorDatMemoria('Patrimonio.in_alteracao_fisica', 'N', v_tstrCipherOpened);
    SetValorDatMemoria('Patrimonio.in_renovacao_informacoes', 'N', v_tstrCipherOpened);

    if (strUltimaRedeObtida <> '') and
       (GetValorDatMemoria('TcpIp.ID_IP_REDE', v_tstrCipherOpened) <> strUltimaRedeObtida) and
       (GetValorDatMemoria('Patrimonio.cs_abre_janela_patr', v_tstrCipherOpened)='S') then
      Begin
        // Neste caso seto como "S" o valor de Remanejamento para ser lido pelo módulo de Coleta de Informações Patrimoniais.
        SetValorDatMemoria('Patrimonio.in_alteracao_fisica', 'S', v_tstrCipherOpened);
      end
    Else
      Begin
        intHoje := StrToInt(FormatDateTime('yyyymmdd', Date));
        strIntervaloRenovacaoPatrimonio := GetValorDatMemoria('Configs.NU_INTERVALO_RENOVACAO_PATRIMONIO', v_tstrCipherOpened);
        if ((strUltimaRedeObtida <> '') and (strIntervaloRenovacaoPatrimonio <> '') and ((intHoje - StrToInt64(strDt_ultima_renovacao_patrim)) >= strtoint(strIntervaloRenovacaoPatrimonio))) or
           (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_PATR', v_tstrCipherOpened) = 'S') Then
          Begin
            // E neste caso seto como "S" o valor de Renovação de Informações para ser lido pelo módulo de Coleta de Informações Patrimoniais.
            SetValorDatMemoria('Patrimonio.in_renovacao_informacoes', 'S', v_tstrCipherOpened);
          end;
      end;
end;

// Baixada de http://www.geocities.com/SiliconValley/Bay/1058/fdelphi.html
Function Rat(OQue: String; Onde: String) : Integer;
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

Function PegaDadosIPConfig(p_array_campos: TStringList; p_array_valores: TStringList; p_tripa:String; p_excecao:String): String;
var tstrOR, tstrAND, tstrEXCECOES : TStrings;
var intAux1, intAux2, intAux3, intAux4, v_conta, v_conta_EXCECOES : integer;

Begin
   Result   := '';
   tstrOR   := Explode(p_tripa,';'); // OR

    for intAux1 := 0 to tstrOR.Count-1 Do
      Begin
        tstrAND  := Explode(tstrOR[intAux1],','); // AND
        for intAux2 := 0 to p_array_campos.Count-1 Do
          Begin
            v_conta := 0;
            for intAux3 := 0 to tstrAND.Count-1 Do
              Begin
                if (LastPos(tstrAND[intAux3],StrLower(PChar(p_array_campos[intAux2]))) > 0) then
                  Begin
                    v_conta := v_conta + 1;
                  End;
              End;
            if (v_conta = tstrAND.Count) then
              Begin
                v_conta_EXCECOES := 0;
                if (p_excecao <> '') then
                  Begin
                    tstrEXCECOES  := Explode(p_excecao,','); // Excecoes a serem tratadas
                    for intAux4 := 0 to tstrEXCECOES.Count-1 Do
                      Begin
                        if (rat(tstrEXCECOES[intAux4],p_array_valores[intAux2]) > 0) then
                          Begin
                            v_conta_EXCECOES := 1;
                            break;
                          End;
                      End;
                  End;
              if (v_conta_EXCECOES = 0) then
                Begin
                  Result := p_array_valores[intAux2];
                  break;
                End;
              End;
          End;
        if (v_conta = tstrAND.Count) then
          Begin
            break;
          End
        else
          Begin
            Result := '';
          End;
      End;
End;

Function FTP_Get(strHost, strUser, strPass, strArq, strDirOrigem, strDirDestino, strTipo : String; intPort : integer) : Boolean;
var IdFTP1 : TIdFTP;
begin
    log_DEBUG('Instanciando FTP...');
    IdFTP1                := TIdFTP.Create(IdFTP1);
    log_DEBUG('FTP Instanciado!');
    IdFTP1.Host           := strHost;
    IdFTP1.Username       := strUser;
    IdFTP1.Password       := strPass;
    IdFTP1.Port           := intPort;
    IdFTP1.Passive        := true;
    if (strTipo = 'ASC') then
      IdFTP1.TransferType := ftASCII
    else
      IdFTP1.TransferType := ftBinary;

    log_DEBUG('Iniciando FTP de '+strArq +' para '+StringReplace(strDirDestino + '\' + strArq,'\\','\',[rfReplaceAll]));
    log_DEBUG('Host........ ='+IdFTP1.Host);
    log_DEBUG('UserName.... ='+IdFTP1.Username);
    log_DEBUG('Port........ ='+inttostr(IdFTP1.Port));
    log_DEBUG('Pasta Origem ='+strDirOrigem);

    Try
      if IdFTP1.Connected = true then
        begin
          IdFTP1.Disconnect;
        end;
      //IdFTP1.Connect(True);
      IdFTP1.Connect;
      IdFTP1.ChangeDir(strDirOrigem);
      Try
        // Substituo \\ por \ devido a algumas vezes em que o DirDestino assume o valor de DirTemp...
        log_DEBUG('FTP - Size de "'+strArq+'" Antes => '+IntToSTR(IdFTP1.Size(strArq)));
        IdFTP1.Get(strArq, StringReplace(strDirDestino + '\' + strArq,'\\','\',[rfReplaceAll]), True);
        log_DEBUG('FTP - Size de "'+strDirDestino + '\' + strArq +'" Após => '+Get_File_Size(strDirDestino + '\' + strArq,true));
      Finally
        result := true;
        log_DEBUG('FTP - Size de "'+strDirDestino + '\' + strArq +'" Após em Finally => '+Get_File_Size(strDirDestino + '\' + strArq,true));
        idFTP1.Disconnect;
        IdFTP1.Free;
      End;
    Except
        log_DEBUG('FTP - Erro - Size de "'+strDirDestino + '\' + strArq +'" Após em Except => '+Get_File_Size(strDirDestino + '\' + strArq,true));
        result := false;
    end;
end;

procedure CriaTXT(p_Dir, p_File : string);
var v_TXT : TextFile;
begin
  AssignFile(v_TXT,p_Dir + '\' + p_File + '.txt'); {Associa o arquivo a uma variável do tipo TextFile}
  Rewrite (v_TXT);
  Closefile(v_TXT);
end;

function Ver_UPD(p_File, p_Nome_Modulo, p_Dir_Inst, p_Dir_Temp : string; p_Medir_FTP:boolean) : integer;
var Baixar      : boolean;
    strAux, strAux1, v_versao_disponivel,
    v_Dir_Temp, v_versao_atual : String;
Begin
   log_DEBUG('Verificando necessidade de FTP para "'+p_Nome_Modulo +'" ('+p_File+')');
   Result := 0;
   Try

       if (trim(p_Dir_Temp)='') then
          Begin
            v_Dir_Temp := p_Dir_Inst;
          End
       else
          Begin
            v_Dir_Temp := p_path_cacic + p_Dir_Temp;
          End;

       v_versao_disponivel := '';
       v_versao_atual      := '';
       if not (p_Medir_FTP) then
          Begin
            v_versao_disponivel := StringReplace(GetValorDatMemoria('Configs.'+UpperCase('DT_VERSAO_'+ p_File + '_DISPONIVEL'), v_tstrCipherOpened),'.EXE','',[rfReplaceAll]);
            log_DEBUG('Versão Disponível para "'+p_Nome_Modulo+'": '+v_versao_disponivel);
            if (trim(v_versao_disponivel)='') then v_versao_disponivel := '*';

            v_versao_atual := trim(StringReplace(GetVersionInfo(p_Dir_Inst + p_File + '.exe'),'.','',[rfReplaceAll]));

            if (v_versao_atual = '0.0.0.0') then
              Begin
                Matar(p_Dir_Inst,p_File + '.exe');
                v_versao_atual := '';
              End;

            // Atenção: Foi acrescentada a string "0103", símbolo do dia/mês de primeira release, para simular versão maior no GER_COLS até 02/2005.
            // Solução provisória até total convergência das versões para 2.0.1.x
            if (v_versao_atual <> '') then v_versao_atual := v_versao_atual + '0103';
          End;

       v_Tamanho_Arquivo := Get_File_Size(p_Dir_Inst + p_File + '.exe',true);
       Baixar := false;

       if not (FileExists(p_Dir_Inst + p_File + '.exe')) then
          Begin
            if (p_Medir_FTP) then Result := 1
            else
              Begin
                log_diario(p_Nome_Modulo + ' inexistente');
                log_diario('<< Efetuando FTP do ' + p_Nome_Modulo);
                Baixar := true;
              End
          End
       else
          Begin
           if (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') or (trim(GetVersionInfo(p_Dir_Inst + p_File + '.exe'))='0.0.0.0') then
              Begin
                if (p_Medir_FTP) then
                  Result := 1
                else
                  Begin
                    log_diario(p_Nome_Modulo + ' corrompido');
                    log_diario('<< Efetuando FTP do ' + p_Nome_Modulo);
                    Baixar := true;
                  End;
              End;
          End;

       if (Baixar) or ((v_versao_atual <> v_versao_disponivel) and (v_versao_disponivel <> '*')) Then
        Begin
           if (v_versao_atual <> v_versao_disponivel) and not Baixar then
                log_diario('<< Recebendo módulo ' + p_Nome_Modulo);

           Try
             log_DEBUG('Baixando: '+ p_File + '.exe para '+v_Dir_Temp);
             if (FTP_Get(GetValorDatMemoria('Configs.TE_SERV_UPDATES', v_tstrCipherOpened),
                         GetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES', v_tstrCipherOpened),
                         GetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES', v_tstrCipherOpened),
                         p_File + '.exe',
                         GetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES', v_tstrCipherOpened),
                         v_Dir_Temp,
                         'BIN',
                         strtoint(GetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES', v_tstrCipherOpened))) = False) Then
               Begin
                log_diario('ERRO!');
                strAux  := 'Não foi possível baixar o módulo "'+ p_Nome_Modulo + '".';
                strAux1 := 'Verifique se foi disponibilizado no Servidor de Updates pelo administrador do Gerente WEB.';
                log_diario(strAux);
                log_diario(strAux1);
                if (GetValorDatMemoria('Configs.IN_EXIBE_ERROS_CRITICOS', v_tstrCipherOpened) = 'S') Then
                  Begin
                    SetValorDatMemoria('Mensagens.cs_tipo', 'mtError', v_tstrCipherOpened);
                    SetValorDatMemoria('Mensagens.te_mensagem', strAux + '. ' + strAux1, v_tstrCipherOpened);
                  End;
               end
             else log_diario('Versão Atual-> '+v_versao_atual+' / Versão Recebida-> '+v_versao_disponivel);
           Except
              log_diario('Não foi possível baixar o módulo '+ p_Nome_Modulo + '.');
           End;
        end;
   Except
        Begin
          CriaTXT(p_path_cacic,'ger_erro');
          SetValorDatMemoria('Erro_Fatal','PROBLEMAS COM ROTINA DE EXECUÇÃO DE UPDATES DE VERSÕES. Não foi possível baixar o módulo '+ p_Nome_Modulo + '.', v_tstrCipherOpened);
          log_diario('PROBLEMAS COM ROTINA DE EXECUÇÃO DE UPDATES DE VERSÕES.');
        End;
   End;
End;


function PegaWinDir(Sender: TObject) : string;
var WinPath: array[0..MAX_PATH + 1] of char;
begin
      GetWindowsDirectory(WinPath,MAX_PATH);
      Result := WinPath
end;


function GetNetworkUserName : String;
  //  Gets the name of the user currently logged into the network on
  //  the local PC
var
  temp: PChar;
  Ptr: DWord;
const
  buff = 255;
begin
  ptr := buff;
  temp := StrAlloc(buff);
  GetUserName(temp, ptr);
  Result := string(temp);
  StrDispose(temp);
end;

// Dica baixada de http://www.swissdelphicenter.ch/torry/showcode.php?id=1142
function GetDomainName: AnsiString;
type
 WKSTA_INFO_100 = record
   wki100_platform_id: Integer;
   wki100_computername: PWideChar;
   wki100_langroup: PWideChar;
   wki100_ver_major: Integer;
   wki100_ver_minor: Integer;
 end;

 WKSTA_USER_INFO_1 = record
   wkui1_username: PChar;
   wkui1_logon_domain: PChar;
   wkui1_logon_server: PChar;
   wkui1_oth_domains: PChar;
 end;
type
 //Win9X ANSI prototypes from RADMIN32.DLL and RLOCAL32.DLL

 TWin95_NetUserGetInfo = function(ServerName, UserName: PChar; Level: DWORD; var
   BfrPtr: Pointer): Integer;
 stdcall;
 TWin95_NetApiBufferFree = function(BufPtr: Pointer): Integer;
 stdcall;
 TWin95_NetWkstaUserGetInfo = function(Reserved: PChar; Level: Integer; var
   BufPtr: Pointer): Integer;
 stdcall;

 //WinNT UNICODE equivalents from NETAPI32.DLL

 TWinNT_NetWkstaGetInfo = function(ServerName: PWideChar; level: Integer; var
   BufPtr: Pointer): Integer;
 stdcall;
 TWinNT_NetApiBufferFree = function(BufPtr: Pointer): Integer;
 stdcall;

 function IsWinNT: Boolean;
 var
   VersionInfo: TOSVersionInfo;
 begin
   VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
   Result := GetVersionEx(VersionInfo);
   if Result then
     Result := VersionInfo.dwPlatformID = VER_PLATFORM_WIN32_NT;
 end;
var

 Win95_NetUserGetInfo: TWin95_NetUserGetInfo;
 Win95_NetWkstaUserGetInfo: TWin95_NetWkstaUserGetInfo;
 Win95_NetApiBufferFree: TWin95_NetApiBufferFree;

 WinNT_NetWkstaGetInfo: TWinNT_NetWkstaGetInfo;
 WinNT_NetApiBufferFree: TWinNT_NetApiBufferFree;

 WSNT: ^WKSTA_INFO_100;
 WS95: ^WKSTA_USER_INFO_1;

 EC: DWORD;
 hNETAPI: THandle;
begin
 try

   Result := '';

   if IsWinNT then
   begin
     hNETAPI := LoadLibrary('NETAPI32.DLL');
     if hNETAPI <> 0 then
     begin @WinNT_NetWkstaGetInfo := GetProcAddress(hNETAPI, 'NetWkstaGetInfo');
         @WinNT_NetApiBufferFree  := GetProcAddress(hNETAPI, 'NetApiBufferFree');

       EC := WinNT_NetWkstaGetInfo(nil, 100, Pointer(WSNT));
       if EC = 0 then
       begin
         Result := WideCharToString(WSNT^.wki100_langroup);
         WinNT_NetApiBufferFree(Pointer(WSNT));
       end;
     end;
   end
   else
   begin
     hNETAPI := LoadLibrary('RADMIN32.DLL');
     if hNETAPI <> 0 then
     begin @Win95_NetApiBufferFree := GetProcAddress(hNETAPI, 'NetApiBufferFree');
         @Win95_NetUserGetInfo := GetProcAddress(hNETAPI, 'NetUserGetInfoA');

       EC := Win95_NetWkstaUserGetInfo(nil, 1, Pointer(WS95));
       if EC = 0 then
       begin
         Result := WS95^.wkui1_logon_domain;
         Win95_NetApiBufferFree(Pointer(WS95));
       end;
     end;
   end;

 finally
   if hNETAPI <> 0 then
     FreeLibrary(hNETAPI);
 end;
end;

function ChecaAgente(agentFolder, agentName : String) : boolean;
var strFraseVersao : String;
Begin
  Result := true;

  log_DEBUG('Verificando existência e tamanho de "'+agentFolder+'\'+agentName+'"');
  v_Tamanho_Arquivo := Get_File_Size(agentFolder+'\'+agentName,true);

  log_DEBUG('Resultado: #'+v_Tamanho_Arquivo);

  if (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') then
    Begin
      Result := false;

      Matar(agentFolder+'\',agentName);

      Ver_UPD(StringReplace(LowerCase(agentName),'.exe','',[rfReplaceAll]),agentName,agentFolder+'\','Temp',false);

      sleep(15000); // 15 segundos de espera para download do agente
      v_Tamanho_Arquivo := Get_File_Size(agentFolder+'\'+agentName,true);
      if not(v_Tamanho_Arquivo = '0') and not(v_Tamanho_Arquivo = '-1') then
        Begin
          log_diario('Agente "'+agentFolder+'\'+agentName+'" RECUPERADO COM SUCESSO!');
          Result := True;
        End
      else
          log_diario('Agente "'+agentFolder+'\'+agentName+'" NÃO RECUPERADO!');
    End;
End;

procedure Patrimnio1Click(Sender: TObject);
begin
  SetValorDatMemoria('Patrimonio.dt_ultima_renovacao_patrim','', v_tstrCipherOpened);
  if ChecaAgente(p_path_cacic + 'modulos', 'ini_cols.exe') then
    g_oCacic.createSampleProcess( p_path_cacic + 'modulos\ini_cols.exe /p_CipherKey=' + v_CipherKey +
                                           ' /p_ModulosOpcoes=col_patr,wait,user#', CACIC_PROCESS_WAIT );
end;

procedure ChecaCipher;
begin
    // Os valores possíveis serão 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Será transformado em "1") 3-Ainda se comunicará com o Gerente WEB
    l_cs_cipher  := false;
    v_Aux := GetValorDatMemoria('Configs.CS_CIPHER', v_tstrCipherOpened);
    if (v_Aux='1') or (v_Aux='2') then
        Begin
          l_cs_cipher  := true;
          SetValorDatMemoria('Configs.CS_CIPHER','1', v_tstrCipherOpened);
        End
    else
        SetValorDatMemoria('Configs.CS_CIPHER','3', v_tstrCipherOpened);

end;

procedure ChecaCompress;
begin
    // Os valores possíveis serão 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Será transformado em "1") 3-Ainda se comunicará com o Gerente WEB
    l_cs_compress  := false;
    v_Aux := GetValorDatMemoria('Configs.CS_COMPRESS', v_tstrCipherOpened);
    if (v_Aux='1') or (v_Aux='2') then
        Begin
          l_cs_compress  := true;
          SetValorDatMemoria('Configs.CS_COMPRESS','1', v_tstrCipherOpened);
        End
    else
        SetValorDatMemoria('Configs.CS_COMPRESS','3', v_tstrCipherOpened);
end;

procedure BuscaConfigs(p_mensagem_log : boolean);
var Request_SVG, v_array_campos, v_array_valores, v_Report : TStringList;
    intAux1, intAux2, intAux3, intAux4, v_conta_EXCECOES, v_index_ethernet : integer;
    strRetorno, strTripa, strAux3, ValorChaveRegistro, ValorRetornado, v_mensagem_log,
    v_mascara,te_ip,te_mascara, te_gateway, te_serv_dhcp, te_dns_primario, te_dns_secundario, te_wins_primario, te_wins_secundario, te_nome_host, te_dominio_dns, te_dominio_windows,
    v_mac_address,v_metodo_obtencao,v_nome_arquivo,IpConfigLINHA, v_enderecos_mac_invalidos, v_win_dir, v_dir_command, v_dir_ipcfg, v_win_dir_command, v_win_dir_ipcfg, v_te_serv_cacic : string;
    tstrTripa1, tstrTripa2, tstrTripa3, tstrTripa4, tstrTripa5, tstrEXCECOES : TStrings;
    IpConfigTXT, chksis_ini : textfile;

    v_oMachine : TMiTec_Machine;
    v_TCPIP     : TMiTeC_TCPIP;
    v_NETWORK : TMiTeC_Network;
Begin
  Try
    ChecaCipher;
    ChecaCompress;

    v_acao_gercols := 'Instanciando TMiTeC_Machine...';
    v_oMachine := TMiTec_Machine.Create(nil);
    v_oMachine.RefreshData();

    v_acao_gercols := 'Instanciando TMiTeC_TcpIp...';
    v_TCPIP := TMiTeC_tcpip.Create(nil);
    v_tcpip.RefreshData;

    // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
    // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI MiTeC.
    if (v_Debugs) then
      Begin
        log_DEBUG('Montando ambiente para busca de configurações...');
        v_Report := TStringList.Create;
        MSI_XML_Reports.TCPIP_XML_Report(v_TCPIP,true,v_Report);
        for intAux1:=0 to v_Report.count-1 do
            Grava_Debugs(v_report[intAux1]);

        v_Report.Free;
      End;
    v_tcpip.RefreshData;

    v_index_ethernet := -1;

    for intAux1:=0 to v_tcpip.AdapterCount -1 do
        if (v_index_ethernet=-1) and (v_tcpip.Adapter[intAux1].Typ=atEthernet) and (v_tcpip.Adapter[intAux1].IPAddress[0]<>'0.0.0.0') then v_index_ethernet := intAux1;

    if (v_index_ethernet=-1) then
        v_index_ethernet := 0;

    Try v_mac_address      := v_tcpip.Adapter[v_index_ethernet].Address                    except v_mac_address       := ''; end;
    Try te_mascara         := v_tcpip.Adapter[v_index_ethernet].IPAddressMask[0]           except te_mascara          := ''; end;
    Try te_ip              := v_tcpip.Adapter[v_index_ethernet].IPAddress[0]               except te_ip               := ''; end;
    Try te_nome_host       := v_oMachine.MachineName                                       except te_nome_host        := ''; end;

    if (v_mac_address='') or (te_ip='') then
      Begin
        v_acao_gercols := 'Instanciando TMiTeC_Network...';
        v_NETWORK := TMiTeC_Network.Create(nil);
        v_NETWORK.RefreshData;

        // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
        // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI MiTeC.
        v_acao_gercols := 'Instanciando Report para TMiTeC_Network...';
        v_Report := TStringList.Create;
        if (v_Debugs) then
          Begin
            v_acao_gercols := 'Gerando Report para TMiTeC_Network...';
            MSI_XML_Reports.Network_XML_Report(v_NETWORK,true,v_Report);

            for intAux1:=0 to v_Report.count-1 do
              Begin
                v_acao_gercols := 'Gravando Report para TMiTeC_Network...';
                Grava_Debugs(v_report[intAux1]);
              End;
          End;
        v_NETWORK.RefreshData;

        v_mac_address  := parse('TNetwork','MACAdresses','MACAddress[0]',v_Report);
        te_ip          := parse('TNetwork','IPAddresses','IPAddress[0]',v_Report);

        v_Report.Free;
      End;

    // Verifico comunicação com o Módulo Gerente WEB.
    Request_SVG := TStringList.Create;
    Request_SVG.Values['in_teste']          := StringReplace(EnCrypt('OK',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

    v_acao_gercols := 'Preparando teste de comunicação com Módulo Gerente WEB.';

    log_DEBUG('Teste de Comunicação.');

    Try
      v_te_serv_cacic := GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened);

      intAux2 := (v_tcpip.Adapter[v_index_ethernet].IPAddress.Count)-1;
      if intAux2 < 0 then intAux2 := 0;

      // Testando a comunicação com o Módulo Gerente WEB.
      for intAux1 := 0 to intAux2 do
        Begin
          v_acao_gercols := 'Setando Request.te_ip com ' + v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1];
          SetValorDatMemoria('TcpIp.TE_IP',v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1], v_tstrCipherOpened);
          Try
            strRetorno := ComunicaServidor('get_config.php', Request_SVG, 'Testando comunicação com o Módulo Gerente WEB.');
            Seta_l_cs_cipher(strRetorno);
            Seta_l_cs_compress(strRetorno);

            v_Aux := DeCrypt(XML_RetornaValor('te_serv_cacic', strRetorno),l_cs_compress);
            if (v_te_serv_cacic <> v_Aux) and (v_Aux <> '') then
               SetValorDatMemoria('Configs.EnderecoServidor',v_Aux, v_tstrCipherOpened);

            if (strRetorno <> '0') and (DeCrypt(XML_RetornaValor('te_rede_ok', strRetorno),l_cs_compress)<>'N') Then
              Begin
                v_acao_gercols := 'IP/Máscara usados: ' + v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1]+'/'+v_tcpip.Adapter[v_index_ethernet].IPAddressMask[intAux1]+' validados pelo Módulo Gerente WEB.';
                te_ip      := v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1];
                te_mascara := v_tcpip.Adapter[v_index_ethernet].IPAddressMask[intAux1];
                log_diario(v_acao_gercols);
                break;
              End;
          except log_diario('Insucesso na comunicação com o Módulo Gerente WEB.');
          end
        End;
    Except
      Begin
        v_acao_gercols := 'Teste de comunicação com o Módulo Gerente WEB.';

        // Nova tentativa, preciso reinicializar o objeto devido aos restos da operação anterior... (Eu acho!)  :)
        Request_SVG.Free;
        Request_SVG := TStringList.Create;
        Request_SVG.Values['in_teste']          := StringReplace(EnCrypt('OK',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
        Try
          strRetorno := ComunicaServidor('get_config.php', Request_SVG, 'Teste de comunicação com o Módulo Gerente WEB.');
          Seta_l_cs_cipher(strRetorno);
          Seta_l_cs_compress(strRetorno);

          v_Aux := DeCrypt(XML_RetornaValor('te_serv_cacic', strRetorno),l_cs_compress);
          if (v_te_serv_cacic <> v_Aux) and (v_Aux <> '') then
             SetValorDatMemoria('Configs.EnderecoServidor',v_Aux, v_tstrCipherOpened);

          if (strRetorno <> '0') and (DeCrypt(XML_RetornaValor('te_rede_ok', strRetorno),l_cs_compress)<>'N') Then
            Begin
              v_acao_gercols := 'IP validado pelo Módulo Gerente WEB.';
              log_diario(v_acao_gercols);
            End
          else log_diario('Insucesso na comunicação com o Módulo Gerente WEB.');
        except
          log_diario('Problemas no teste de comunicação com o Módulo Gerente WEB.');
        end;
      End;
    End;
    Request_SVG.Free;

    Try te_gateway         := v_tcpip.Adapter[v_index_ethernet].Gateway_IPAddress[0]       except te_gateway          := ''; end;
    Try te_serv_dhcp       := v_tcpip.Adapter[v_index_ethernet].DHCP_IPAddress[0]          except te_serv_dhcp        := ''; end;
    Try te_dns_primario    := v_tcpip.DNSServers[0]                                        except te_dns_primario     := ''; end;
    Try te_dns_secundario  := v_tcpip.DNSServers[1]                                        except te_dns_secundario   := ''; end;
    Try te_wins_primario   := v_tcpip.Adapter[v_index_ethernet].PrimaryWINS_IPAddress[0]   except te_wins_primario    := ''; end;
    Try te_wins_secundario := v_tcpip.Adapter[v_index_ethernet].SecondaryWINS_IPAddress[0] except te_wins_secundario  := ''; end;
    Try te_dominio_dns     := v_tcpip.DomainName                                           except te_dominio_dns      := ''; end;

    v_acao_gercols := 'Setando endereço WS para /cacic2/ws/';
    // Setando /cacic2/ws/ como caminho de pseudo-WebServices
    SetValorDatMemoria('Configs.Endereco_WS','/cacic2/ws/', v_tstrCipherOpened);

    v_acao_gercols := 'Setando TE_FILA_FTP=0';
    // Setando controle de FTP para 0 (0=tempo de espera para FTP   de algum componente do sistema)
    SetValorDatMemoria('Configs.TE_FILA_FTP','0', v_tstrCipherOpened);
    CountUPD := 0;

    // Verifico e contabilizo as necessidades de FTP dos agentes (instalação ou atualização)
    // Para possível requisição de acesso ao grupo FTP... (Essa medida visa balancear o acesso aos servidores de atualização de versões, principalmente quando é um único S.A.V.)
    v_acao_gercols := 'Contabilizando necessidade de Updates...';

    // O valor "true" para o 5º parâmetro da função Ver_UPD informa para apenas verificar a necessidade de FTP do referido objeto.
    CountUPD := CountUPD + Ver_UPD('ini_cols'                                        ,'Inicializador de Coletas'      ,p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD(StringReplace(v_scripter,'.exe','',[rfReplaceAll]),'Interpretador VBS'             ,p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('chksis'                                          ,'Verificador de Integridade do Sistema',PegaWinDir(nil)+'\','',true);
    CountUPD := CountUPD + Ver_UPD('cacic2'  ,'Agente Principal',p_path_cacic,'Temp',true);
    CountUPD := CountUPD + Ver_UPD('ger_cols','Gerente de Coletas',p_path_cacic + 'modulos\','Temp',true);
    CountUPD := CountUPD + Ver_UPD('col_anvi','Coletor de Informações de Anti-Vírus OfficeScan',p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_comp','Coletor de Informações de Compartilhamentos',p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_hard','Coletor de Informações de Hardware',p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_patr','Coletor de Informações de Patrimônio/Loc.Fís.',p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_moni','Coletor de Informações de Sistemas Monitorados',p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_soft','Coletor de Informações de Softwares Básicos',p_path_cacic + 'modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_undi','Coletor de Informações de Unidades de Disco',p_path_cacic + 'modulos\','',true);


    // Verifica existência dos dados de configurações principais e estado de CountUPD. Caso verdadeiro, simula uma instalação pelo chkCACIC...
    if  ((GetValorDatMemoria('Configs.TE_SERV_UPDATES'              , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES', v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES'  , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES'         , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES'        , v_tstrCipherOpened) = '') or
         (GetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'     , v_tstrCipherOpened) = '') or
         (CountUPD > 0)) and
         (GetValorDatMemoria('Configs.ID_FTP', v_tstrCipherOpened) = '') then
        Begin
          log_DEBUG('Preparando contato com módulo Gerente WEB para Downloads.');
          v_acao_gercols := 'Contactando o módulo Gerente WEB: get_config.php...';
          Request_SVG := TStringList.Create;
          Request_SVG.Values['in_chkcacic']   := StringReplace(EnCrypt('chkcacic',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
          Request_SVG.Values['te_fila_ftp']   := StringReplace(EnCrypt('1',l_cs_compress),'+','<MAIS>',[rfReplaceAll]); // Indicará que o agente quer entrar no grupo para FTP
          //Request_SVG.Values['id_ip_estacao'] := EnCrypt(GetIP,l_cs_compress); // Informará o IP para registro na tabela redes_grupos_FTP

          log_DEBUG(v_acao_gercols + ' Parâmetros: in_chkcacic="'+Request_SVG.Values['in_chkcacic']+'", te_fila_ftp="'+Request_SVG.Values['te_fila_ftp']+'" e id_ip_estacao="'+Request_SVG.Values['id_ip_estacao']+'"');
          strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);
          Seta_l_cs_cipher(strRetorno);
          Seta_l_cs_compress(strRetorno);

          Request_SVG.Free;
          if (strRetorno <> '0') Then
            Begin
              SetValorDatMemoria('Configs.TE_SERV_UPDATES'              ,DeCrypt(XML_RetornaValor('te_serv_updates'                   , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES',DeCrypt(XML_RetornaValor('nm_usuario_login_serv_updates'     , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES'  ,DeCrypt(XML_RetornaValor('te_senha_login_serv_updates'       , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES'         ,DeCrypt(XML_RetornaValor('te_path_serv_updates'              , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES'        ,DeCrypt(XML_RetornaValor('nu_porta_serv_updates'             , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.TE_FILA_FTP'                  ,DeCrypt(XML_RetornaValor('te_fila_ftp'                       , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('Configs.ID_FTP'                       ,DeCrypt(XML_RetornaValor('id_ftp'                            , strRetorno),true), v_tstrCipherOpened);
              SetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'     ,DeCrypt(XML_RetornaValor('te_enderecos_mac_invalidos'        , strRetorno),true), v_tstrCipherOpened);
            End;
        End;

    v_Aux := GetValorDatMemoria('Configs.TE_FILA_FTP', v_tstrCipherOpened);
    // Caso seja necessário fazer algum FTP e o Módulo Gerente Web tenha devolvido um tempo para espera eu finalizo e espero o tempo para uma nova tentativa
    if (CountUPD > 0) and (v_Aux <> '') and (v_Aux <> '0') then
      Begin
        log_DEBUG('Finalizando para nova tentativa de FTP em '+v_Aux+' minuto(s)');
        Finalizar(true);
        Sair;
      End;

    v_acao_gercols := 'Verificando versões do scripter e chksis';
    log_DEBUG(''+v_acao_gercols);
    Ver_UPD(StringReplace(v_scripter,'.exe','',[rfReplaceAll]),'Interpretador VBS'                    ,p_path_cacic + 'modulos\','',false);
    Ver_UPD('chksis'                                          ,'Verificador de Integridade do Sistema',PegaWinDir(nil)+'\'      ,'',false);

    // Verifico existência do chksis.ini
    if not (FileExists(PegaWinDir(nil) + 'chksis.ini')) then
      Begin
         Try
           v_acao_gercols := 'chksis.ini inexistente, recriando...';
           tstrTripa1  := Explode(p_path_cacic,'\');
           AssignFile(chksis_ini,PegaWinDir(nil) + '\chksis.ini'); {Associa o arquivo a uma variável do tipo TextFile}
           Rewrite(chksis_ini); // Recria o arquivo...
           Append(chksis_ini);
           Writeln(chksis_ini,'[Cacic2]');
           Writeln(chksis_ini,'ip_serv_cacic='+GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened));
           Writeln(chksis_ini,'cacic_dir='+StringReplace(tstrTripa1[1],'\','',[rfReplaceAll]));
           Writeln(chksis_ini,'rem_cacic_v0x=S');
           CloseFile(chksis_ini); {Fecha o arquivo texto}
         Except
           log_diario('Erro na recuperação de chksis.');
         End;
      End;

    v_mensagem_log  := '<< Obtendo configurações a partir do Gerente WEB.';

    if (not p_mensagem_log) then v_mensagem_log := '';

  // Caso a obtenção dos dados de TCP via MSI_NETWORK/TCP tenha falhado...
  // (considerado falha somente se v_mac_address, te_ip ou v_te_so forem nulos
  //  por serem chaves - demais valores devem ser avaliados pelo administrador)

  if (v_mac_address='') or (te_ip='') then begin
      v_nome_arquivo    := p_path_cacic + 'Temp\ipconfig.txt';
      v_metodo_obtencao := 'WMI Object';
      v_acao_gercols    := 'Criando batch para obtenção de IPCONFIG via WMI...';
      Try
         Batchfile := TStringList.Create;
         Batchfile.Add('Dim FileSys,FileSysOk,IPConfigFile,IPConfigFileOK,strComputer,objWMIService,colItems,colUser,v_ok');
         Batchfile.Add('Set FileSys  = WScript.CreateObject("Scripting.FileSystemObject")');
         Batchfile.Add('Set IPConfigFile= FileSys.CreateTextFile("'+ v_nome_arquivo + '", True)');
         Batchfile.Add('On Error Resume Next');
         Batchfile.Add('strComputer = "."');
         Batchfile.Add('v_ok        = ""');
         Batchfile.Add('Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")');
         Batchfile.Add('Set colItems      = objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE")');
         Batchfile.Add('For Each objItem in colItems');
         Batchfile.Add('  ipconfigfile.WriteLine "Endereço físico.........: " & objItem.MACAddress');
         Batchfile.Add('  ipconfigfile.WriteLine "Endereço ip.............: " & objItem.IPAddress(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Máscara de Sub-rede.....: " & objItem.IPSubnet(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Gateway padrão..........: " & objItem.DefaultIPGateway(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Nome do host............: " & objItem.DNSHostName');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor DHCP...........: " & objItem.DHCPServer');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidores DNS..........: " & objItem.DNSDomain');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor WINS Primario..: " & objItem.WINSPrimaryServer');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor WINS Secundario: " & objItem.WINSSecondaryServer');
         Batchfile.Add('  v_ok = "OK"');
         Batchfile.Add('Next');
         Batchfile.Add('Set GetUser = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")');
         Batchfile.Add('Set colUser       = GetUser.ExecQuery("Select * from Win32_ComputerSystem")');
         Batchfile.Add('For Each objUser in colUser');
         Batchfile.Add('	ipconfigfile.WriteLine "Domínio/Usuário Logado..: " & objUser.UserName');
         Batchfile.Add('Next');
         Batchfile.Add('IPConfigFile.Close');
         Batchfile.Add('if v_ok = "OK" then');
         Batchfile.Add('  Set FileSysOK      = WScript.CreateObject("Scripting.FileSystemObject")');
         Batchfile.Add('  Set IPConfigFileOK = FileSysOK.CreateTextFile("'+p_path_cacic + 'Temp\ipconfi1.txt", True)');
         Batchfile.Add('  IPConfigFileOK.Close');
         Batchfile.Add('end if');
         Batchfile.Add('WScript.Quit');
         Batchfile.SaveToFile(p_path_cacic + 'Temp\ipconfig.vbs');
         BatchFile.Free;
         v_acao_gercols := 'Invocando execução de VBS para obtenção de IPCONFIG...';
         log_DEBUG('Executando "'+p_path_cacic + 'modulos\' + v_scripter + ' //b ' + p_path_cacic + 'temp\ipconfig.vbs"');

         if ChecaAgente(p_path_cacic + 'modulos', v_scripter) then
           WinExec(PChar(p_path_cacic + 'modulos\' + v_scripter + ' //b ' + p_path_cacic + 'temp\ipconfig.vbs'), SW_HIDE);

      Except
        Begin
          log_diario('Erro na geração do ipconfig.txt pelo ' + v_metodo_obtencao+'.');
        End;
      End;

      // Para aguardar o processamento acima, caso aconteça
      sleep(5000);

      v_Tamanho_Arquivo := Get_File_Size(p_path_cacic + 'Temp\ipconfig.txt',true);
      // O arquivo ipconfig.txt foi gerado vazio, tentarei IPConfig ou WinIPcfg!
      if not (FileExists(p_path_cacic + 'Temp\ipconfi1.txt')) or (v_Tamanho_Arquivo='0')  then
        Begin
          Try
             v_win_dir          := PegaWinDir(nil);
             v_win_dir_command  := PegaWinDir(nil);
             v_win_dir_ipcfg    := PegaWinDir(nil);
             v_dir_command      := '';
             v_dir_ipcfg        := '';

             // Definição do comando para obtenção de informações de TCP (Ipconfig ou WinIpCFG)
             if (strtoint(GetValorDatMemoria('Configs.ID_SO', v_tstrCipherOpened)) > 5) then
                Begin
                  v_metodo_obtencao := 'Execução de IPConfig';
                  if      (fileexists(v_win_dir_command + '\system32\cmd.exe'))          then v_dir_command := '\system32'
                  else if (fileexists(v_win_dir_command + '\system32\dllcache\cmd.exe')) then v_dir_command := '\system32\dllcache'
                  else if (fileexists(v_win_dir_command + '\system\cmd.exe'))            then v_dir_command := '\system'
                  else if (fileexists(LeftStr(v_win_dir_command,2) + '\cmd.exe')) then
                    Begin
                      v_win_dir_command := LeftStr(v_win_dir_command,2);
                      v_dir_command     := '\';
                    End;

                  if      (fileexists(v_win_dir + '\system32\ipconfig.exe'))     then v_dir_ipcfg := '\system32'
                  else if (fileexists(v_win_dir + '\ipconfig.exe'))              then v_dir_ipcfg := '\'
                  else if (fileexists(v_win_dir + '\system\ipconfig.exe'))       then v_dir_ipcfg := '\system'
                  else if (fileexists(LeftStr(v_win_dir,2) + '\ipconfig.exe')) then
                    Begin
                      v_win_dir_ipcfg := LeftStr(v_win_dir_command,2);
                      v_dir_ipcfg     := '\';
                    End;

                  WinExec(PChar(v_win_dir + v_dir_command + '\cmd.exe /c ' + v_win_dir + v_dir_ipcfg + '\ipconfig.exe /all > ' + v_nome_arquivo), SW_MINIMIZE);
                End
             else
                Begin
                  v_metodo_obtencao := 'Execução de WinIPCfg';
                  if      (fileexists(v_win_dir_command + '\system32\command.com'))          then v_dir_command := '\system32'
                  else if (fileexists(v_win_dir_command + '\system32\dllcache\command.com')) then v_dir_command := '\system32\dllcache'
                  else if (fileexists(v_win_dir_command + '\system\command.com'))            then v_dir_command := '\system'
                  else if (fileexists(LeftStr(v_win_dir_command,2) + '\command.com')) then
                    Begin
                      v_win_dir_command := LeftStr(v_win_dir_command,2);
                      v_dir_command     := '\';
                    End;

                  if      (fileexists(v_win_dir + '\system32\winipcfg.exe'))     then v_dir_ipcfg := '\system32'
                  else if (fileexists(v_win_dir + '\winipcfg.exe'))              then v_dir_ipcfg := '\'
                  else if (fileexists(v_win_dir + '\system\winipcfg.exe'))       then v_dir_ipcfg := '\system'
                  else if (fileexists(LeftStr(v_win_dir,2) + '\winipcfg.exe')) then
                    Begin
                      v_win_dir_ipcfg := LeftStr(v_win_dir_command,2);
                      v_dir_ipcfg     := '\';
                    End;
                  WinExec(PChar(v_win_dir + v_dir_command + '\command.com /c ' + v_win_dir + v_dir_ipcfg + '\winipcfg.exe /all /batch ' + v_nome_arquivo), SW_MINIMIZE);
                End;
          Except log_diario('Erro na geração do ipconfig.txt pelo ' + v_metodo_obtencao+'.');
          End;
        End;

      sleep(3000); // 3 Segundos para finalização do ipconfig...

      // Seto a forma de obtenção das informações de TCP...
      SetValorDatMemoria('TcpIp.TE_ORIGEM_MAC',v_metodo_obtencao, v_tstrCipherOpened);
      v_mac_address := '';
      v_acao_gercols := 'Criando StringLists para campos e valores de temp/ipconfig.txt...';
      v_array_campos  := TStringList.Create;
      v_array_valores := TStringList.Create;
      Try
        v_acao_gercols := 'Acessando o arquivo ' + v_nome_arquivo;
        AssignFile(IpConfigTXT, v_nome_arquivo);
        v_acao_gercols := 'Abrindo o arquivo ' + v_nome_arquivo;
        Reset(IpConfigTXT);
        while not Eof(IpConfigTXT) do
         begin
           v_acao_gercols := 'Lendo linha ' + IpConfigLINHA + ' de ' + v_nome_arquivo;
           ReadLn(IpConfigTXT, IpConfigLINHA);
           IpConfigLINHA := trim (IpConfigLINHA);
           intAux1 := LastPos(': ',PChar(IpConfigLINHA));
           if (intAux1 > 0) then
             Begin
               v_acao_gercols := 'Adicionando ' + copy(IpConfigLINHA,1,intAux1) + ' à matriz campos';
               v_array_campos.Add(copy(IpConfigLINHA,1,intAux1));
               v_acao_gercols := 'Adicionando ' + copy(IpConfigLINHA,intAux1 + 2, length(IpConfigLINHA)) + ' à matriz valores';
               v_array_valores.Add(copy(IpConfigLINHA,intAux1 + 2, length(IpConfigLINHA)));
             End;
         end;
      Except log_diario('Erro na extração de informações do ipconfig.txt.');
      End; // fim do Try

      v_acao_gercols := 'Fechando ' + v_nome_arquivo;

      // Pausa para total unlock do arquivo
      sleep(2000);

      // Fecho o arquivo
      CloseFile(IpConfigTXT);
      v_acao_gercols := 'Arquivo ' + v_nome_arquivo + ' fechado com sucesso!';
      sleep(1000);

      if (v_array_campos.Count > 0) then
        Begin
           v_acao_gercols := 'Definindo pseudo MAC´s...';
           // Vamos desviar dos famosos pseudo-MAC´s...
           v_enderecos_mac_invalidos := GetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS', v_tstrCipherOpened);
           if (v_enderecos_mac_invalidos <> '') then v_enderecos_mac_invalidos := v_enderecos_mac_invalidos + ',';
           v_enderecos_mac_invalidos := v_enderecos_mac_invalidos + '00:00:00:00:00:00';

           v_acao_gercols := 'Extraindo informações TCP via PegaDadosIPConfig...';
           // Os parâmetros para a chamada à função PegaDadosIPConfig devem estar estar em minúsculo.
           if (v_mac_address='')      then Try v_mac_address      := PegaDadosIPConfig(v_array_campos,v_array_valores,'endere,sico;physical,address;direcci,adaptador',v_enderecos_mac_invalidos) Except v_mac_address      := ''; end;
           if (te_mascara='')         then Try te_mascara         := PegaDadosIPConfig(v_array_campos,v_array_valores,'scara,sub,rede;sub,net,mask;scara,subred','255.255.255.255;')         Except te_mascara         := ''; end;
           if (te_ip='')              then Try te_ip              := PegaDadosIPConfig(v_array_campos,v_array_valores,'endere,ip;ip,address;direcci,ip','0.0.0.0')                         Except te_ip              := ''; end;
           if (te_gateway='')         then Try te_gateway         := PegaDadosIPConfig(v_array_campos,v_array_valores,'gateway,padr;gateway,definido;default,gateway;puerta,enlace,predeterminada','')       Except te_gateway         := ''; end;
           if (te_nome_host='')       then Try te_nome_host       := PegaDadosIPConfig(v_array_campos,v_array_valores,'nome,host;host,name;nombre,del,host','')                                 Except te_nome_host       := ''; end;
           if (te_serv_dhcp='')       then Try te_serv_dhcp       := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,dhcp;dhcp,server','')                           Except te_serv_dhcp       := ''; end;
           if (te_dns_primario='')    then Try te_dns_primario    := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidores,dns;dns,servers','')                          Except te_dns_primario    := ''; end;
           if (te_wins_primario='')   then Try te_wins_primario   := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,wins,prim;wins,server,primary','')              Except te_wins_primario   := ''; end;
           if (te_wins_secundario='') then Try te_wins_secundario := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,wins,secund;wins,server,secondary','')          Except te_wins_secundario := ''; end;

           if (g_oCacic.isWindowsNT()) then //Se NT/2K/XP
             Try
                te_dominio_windows := PegaDadosIPConfig(v_array_campos,v_array_valores,'usu,rio,logado;usu,rio,logado','')
             Except
                te_dominio_windows := 'Não Identificado';
             end
           else
             Try
                te_dominio_windows := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\MSNP32\NetworkProvider\AuthenticatingAgent') + '@' + GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Network\Logon\username')
             Except te_dominio_windows := 'Não Identificado';
             end;

        End // fim do Begin
      Else
        Begin
          Try
             if (v_mac_address = '') then
                Begin
                  v_mac_address := GetMACAddress;
                  SetValorDatMemoria('TcpIp.TE_ORIGEM_MAC','utils_GetMACaddress', v_tstrCipherOpened);
                End;
             if (v_mac_address = '') then
                Begin
                  v_mac_address := Trim(v_tcpip.Adapter[v_index_ethernet].Address);
                  SetValorDatMemoria('TcpIp.TE_ORIGEM_MAC','MSI_TCP.Adapter['+IntToStr(v_index_ethernet)+'].Address', v_tstrCipherOpened);
                End;

             if (v_mac_address <> '') then
                Begin
                  v_enderecos_mac_invalidos := GetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS', v_tstrCipherOpened);
                  v_conta_EXCECOES := 0;
                  if (v_enderecos_mac_invalidos <> '') then
                    Begin
                      tstrEXCECOES  := Explode(v_enderecos_mac_invalidos,','); // Excecoes a serem tratadas
                      for intAux4 := 0 to tstrEXCECOES.Count-1 Do
                        Begin
                          if (rat(tstrEXCECOES[intAux4],v_mac_address) > 0) then
                            Begin
                              v_conta_EXCECOES := 1;
                              break;
                            End;
                        End;

                      if (v_conta_EXCECOES > 0) then
                        Begin
                          v_mac_address := '';
                        End;
                    End;
                End;
              Except log_diario('Erro na obtenção de informações de rede! (GetMACAddress).');
              End;
        End;

      // Deleto os arquivos usados na obtenção via VBScript e CMD/Command
      v_acao_gercols := 'Excluindo arquivo '+v_nome_arquivo+', usado na obtenção de IPCONFIG...';
      log_DEBUG('Excluindo: "'+v_nome_arquivo+'"');
      DeleteFile(v_nome_arquivo);

      v_acao_gercols := 'Excluindo arquivo '+p_path_cacic + 'Temp\ipconfi1.txt, usado na obtenção de IPCONFIG...';
      Matar(p_path_cacic+'Temp\','ipconfi1.txt');

      v_acao_gercols := 'Excluindo arquivo '+p_path_cacic + 'Temp\ipconfig.vbs, usado na obtenção de IPCONFIG...';
      Matar(p_path_cacic+'Temp\','ipconfig.vbs');
    End;

    v_mascara := te_mascara;
    // Em 12/08/2005, extinção da obrigatoriedade de obtenção de Máscara de Rede na estação.
    // O cálculo para obtenção deste parâmetro poderá ser feito pelo módulo Gerente Web através do script get_config.php
    // if (trim(v_mascara)='') then v_mascara := '255.255.255.0';

    if(te_ip<>'') then
      try
        SetValorDatMemoria('TcpIp.TE_IP',te_ip, v_tstrCipherOpened);
      except
         log_diario('Erro setando TE_IP.');
      end;

    try
      if (trim(GetIPRede(te_ip, te_mascara))<>'') then
      SetValorDatMemoria('TcpIp.ID_IP_REDE',GetIPRede(te_ip, te_mascara), v_tstrCipherOpened);
    except
       log_diario('Erro setando IP_REDE.');
    end;

    if( (v_te_so<>'') and (v_mac_address<>'') and (te_ip<>'') ) // Verifica dados chave para controles
       then log_diario('Dados de rede usados: SO=' + v_te_so + ' MAC=' + v_mac_address + ' IP=' + te_ip)
       else log_diario('Erro na obtenção de dados de rede: SO=' + v_te_so + ' MAC=' + v_mac_address + ' IP=' + te_ip);

    try
      SetValorDatMemoria('TcpIp.TE_NODE_ADDRESS',StringReplace(v_mac_address,':','-',[rfReplaceAll]), v_tstrCipherOpened);
    except
       log_diario('Erro setando NODE_ADDRESS.');
    end;

    Try
      SetValorDatMemoria('TcpIp.TE_NOME_HOST',TE_NOME_HOST, v_tstrCipherOpened);
    Except
      log_diario('Erro setando NOME_HOST.');
    End;

    try
       SetValorDatMemoria('TcpIp.TE_NOME_COMPUTADOR' ,TE_NOME_HOST, v_tstrCipherOpened);
    except
       log_diario('Erro setando NOME_COMPUTADOR.');
    end;

    Try
      SetValorDatMemoria('TcpIp.TE_WORKGROUP',GetWorkgroup, v_tstrCipherOpened);
    except
      log_diario('Erro setando TE_WORKGROUP.');
    end;

    if (GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened)<>'') then
        begin
            // Passei a enviar sempre a versão do CACIC...
            // Solicito do servidor a configuração que foi definida pelo administrador do CACIC.
            Request_SVG := TStringList.Create;

            //Tratamento de Sistemas Monitorados
            intAux4 := 1;
            strAux3 := '';
            ValorChaveRegistro := '*';
            while ValorChaveRegistro <> '' do
              begin
                strAux3 := 'SIS' + trim(inttostr(intAux4));
                ValorChaveRegistro  := GetValorDatMemoria('Coletas.'+strAux3, v_tstrCipherOpened);

                if (ValorChaveRegistro <> '') then
                  Begin
                     tstrTripa1  := Explode(ValorChaveRegistro,'#');
                     for intAux1 := 0 to tstrTripa1.Count-1 Do
                       Begin
                         tstrTripa2  := Explode(tstrTripa1[intAux1],',');
                         //Apenas os dois primeiros itens, id_aplicativo e dt_atualizacao
                         strTripa := strTripa + tstrTripa2[0] + ',' + tstrTripa2[1]+'#';
                       end;
                  End; //If
                intAux4 := intAux4 + 1;
              end; //While

             // Proposital, para forçar a chegada dos perfis, solução temporária...
             Request_SVG.Values['te_tripa_perfis']       := StringReplace(EnCrypt('',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

             // Gero e armazeno uma palavra-chave e a envio ao Gerente WEB para atualização no BD.
             // Essa palavra-chave será usada para o acesso ao Agente Principal
             strAux := GeraPalavraChave;

             SetValorDatMemoria('Configs.te_palavra_chave',strAux, v_tstrCipherOpened);
             Request_SVG.Values['te_palavra_chave']       := EnCrypt(strAux,l_cs_compress);
             v_te_serv_cacic := GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened);

             strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);

             // A versão com criptografia do Módulo Gerente WEB retornará o valor cs_cipher=1(Quando receber "1") ou cs_cipher=2(Quando receber "3")
             Seta_l_cs_cipher(strRetorno);

             // A versão com compressão do Módulo Gerente WEB retornará o valor cs_compress=1(Quando receber "1") ou cs_compress=2(Quando receber "3")
             Seta_l_cs_compress(strRetorno);

             v_te_serv_cacic := DeCrypt(XML_RetornaValor('te_serv_cacic',strRetorno),true);

             if (strRetorno <> '0') and
                (v_te_serv_cacic<>'') and
                (v_te_serv_cacic<>GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened)) then
                Begin
                  v_mensagem_log := 'Novo endereço para Gerente WEB: '+v_te_serv_cacic;
                  SetValorDatMemoria('Configs.EnderecoServidor',v_te_serv_cacic, v_tstrCipherOpened);
                  log_DEBUG('Setando Criptografia para 3. (Primeiro contato)');
                  Seta_l_cs_cipher('');
                  log_DEBUG('Refazendo comunicação');

                  // Passei a enviar sempre a versão do CACIC...
                  // Solicito do servidor a configuração que foi definida pelo administrador do CACIC.
                  Request_SVG.Free;
                  Request_SVG := TStringList.Create;
                  Request_SVG.Values['te_tripa_perfis']    := StringReplace(EnCrypt('',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                  strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);
                  Seta_l_cs_cipher(strRetorno);
                  Seta_l_cs_compress(strRetorno);
                End;

             Request_SVG.Free;

             if (strRetorno <> '0') Then
              Begin
                ValorRetornado := DeCrypt(XML_RetornaValor('SISTEMAS_MONITORADOS_PERFIS', strRetorno),true);
                log_DEBUG('Valor Retornado para Sistemas Monitorados: "'+ValorRetornado+'"');
                IF (ValorRetornado <> '') then
                Begin
                     intAux4 := 1;
                     strAux3 := '*';
                     while strAux3 <> '' do
                      begin
                        strAux3 := GetValorDatMemoria('Coletas.SIS' + trim(inttostr(intAux4)), v_tstrCipherOpened);
                        if (trim(strAux3)<>'') then
                          Begin
                            strAux3 := 'SIS' + trim(inttostr(intAux4));
                            SetValorDatMemoria('Coletas.'+strAux3,'', v_tstrCipherOpened);
                          End;
                        intAux4 := intAux4 + 1;
                      end;

                   intAux4 := 0;
                   tstrTripa3  := Explode(ValorRetornado,'#');
                   for intAux3 := 0 to tstrTripa3.Count-1 Do
                   Begin
                     strAux3 := 'SIS' + trim(inttostr(intAux4));
                     tstrTripa4  := Explode(tstrTripa3[intAux3],',');
                     while strAux3 <> '' do
                      begin
                        intAux4 := intAux4 + 1;
                        strAux3 := GetValorDatMemoria('Coletas.SIS' + trim(inttostr(intAux4)), v_tstrCipherOpened);
                        if (trim(strAux3)<>'') then
                          Begin
                            tstrTripa5 := Explode(strAux3,',');
                            if (tstrTripa5[0] = tstrTripa4[0]) then strAux3 := '';
                          End;
                      end;
                     strAux3 := 'SIS' + trim(inttostr(intAux4));
                     SetValorDatMemoria('Coletas.'+strAux3,tstrTripa3[intAux3], v_tstrCipherOpened);
                   end;
                end;

                log_DEBUG('Armazenando valores obtidos no DAT Memória.');
                v_acao_gercols := 'Armazenando valores obtidos no DAT Memória.';

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //Gravação no CACIC2.DAT dos valores de REDE, COMPUTADOR e EXECUÇÃO obtidos, para consulta pelos outros módulos...
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                SetValorDatMemoria('Configs.CS_AUTO_UPDATE'               ,UpperCase(DeCrypt(XML_RetornaValor('cs_auto_update'          , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_HARDWARE'           ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_hardware'      , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_SOFTWARE'           ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_software'      , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_MONITORADO'         ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_monitorado'    , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_OFFICESCAN'         ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_officescan'    , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_COMPARTILHAMENTOS'  ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_compart'       , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_UNID_DISC'          ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_unid_disc'     , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.CS_COLETA_PATRIMONIO'         ,UpperCase(DeCrypt(XML_RetornaValor('cs_coleta_patrimonio'    , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_CACIC2_DISPONIVEL'  ,DeCrypt(XML_RetornaValor('dt_versao_cacic2_disponivel'       , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_GER_COLS_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_ger_cols_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_CHKSIS_DISPONIVEL'  ,DeCrypt(XML_RetornaValor('dt_versao_chksis_disponivel'       , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_ANVI_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_anvi_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_COMP_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_comp_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_HARD_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_hard_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_MONI_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_moni_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_PATR_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_patr_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_SOFT_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_soft_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_COL_UNDI_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_col_undi_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_INI_COLS_DISPONIVEL',DeCrypt(XML_RetornaValor('dt_versao_ini_cols_disponivel'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_VERSAO_'+
                 StringReplace(v_scripter,'.exe','',[rfReplaceAll])+
                 '_DISPONIVEL'                                            ,DeCrypt(XML_RetornaValor('dt_versao_'+
                                                                           StringReplace(v_scripter,'.exe','',[rfReplaceAll])+
                                                                           '_disponivel'                                                , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_SERV_UPDATES'              ,DeCrypt(XML_RetornaValor('te_serv_updates'                   , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_PORTA_SERV_UPDATES'        ,DeCrypt(XML_RetornaValor('nu_porta_serv_updates'             , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_PATH_SERV_UPDATES'         ,DeCrypt(XML_RetornaValor('te_path_serv_updates'              , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NM_USUARIO_LOGIN_SERV_UPDATES',DeCrypt(XML_RetornaValor('nm_usuario_login_serv_updates'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_SENHA_LOGIN_SERV_UPDATES'  ,DeCrypt(XML_RetornaValor('te_senha_login_serv_updates'       , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.IN_EXIBE_ERROS_CRITICOS'      ,UpperCase(DeCrypt(XML_RetornaValor('in_exibe_erros_criticos' , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_SENHA_ADM_AGENTE'          ,DeCrypt(XML_RetornaValor('te_senha_adm_agente'               , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_INTERVALO_RENOVACAO_PATRIM',DeCrypt(XML_RetornaValor('nu_intervalo_renovacao_patrim'     , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_INTERVALO_EXEC'            ,DeCrypt(XML_RetornaValor('nu_intervalo_exec'                 , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.NU_EXEC_APOS'                 ,DeCrypt(XML_RetornaValor('nu_exec_apos'                      , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.IN_EXIBE_BANDEJA'             ,UpperCase(DeCrypt(XML_RetornaValor('in_exibe_bandeja'        , strRetorno),true)), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.TE_JANELAS_EXCECAO'           ,DeCrypt(XML_RetornaValor('te_janelas_excecao'                , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.TE_ENDERECOS_MAC_INVALIDOS'     ,DeCrypt(XML_RetornaValor('te_enderecos_mac_invalidos'        , strRetorno),true) , v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA'         ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada'     , strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_ANVI'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_anvi', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_COMP'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_comp', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_HARD'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_hard', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_MONI'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_moni', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_PATR'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_patr', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_SOFT'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_soft', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                SetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_UNDI'    ,stringreplace(stringreplace(stringreplace(DeCrypt(XML_RetornaValor('dt_hr_coleta_forcada_undi', strRetorno),true),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]), v_tstrCipherOpened);
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
              end;


            // Envio de Dados de TCP_IP
            if (te_dominio_windows = '') then
              Begin
                Try
                  if (g_oCacic.isWindowsNT()) then //Se NT/2K/XP
                     te_dominio_windows := GetNetworkUserName + '@' + GetDomainName
                  else
                     te_dominio_windows := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Network\Logon\username')+ '@' + GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\MSNP32\NetworkProvider\AuthenticatingAgent');
                Except te_dominio_windows := 'Não Identificado';
                End;
              End;

            Request_SVG := TStringList.Create;
            Request_SVG.Values['te_mascara']         := StringReplace(EnCrypt(te_mascara,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_gateway']         := StringReplace(EnCrypt(te_gateway,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_serv_dhcp']       := StringReplace(EnCrypt(te_serv_dhcp,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dns_primario']    := StringReplace(EnCrypt(te_dns_primario,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dns_secundario']  := StringReplace(EnCrypt(te_dns_secundario,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_wins_primario']   := StringReplace(EnCrypt(te_wins_primario,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_wins_secundario'] := StringReplace(EnCrypt(te_wins_secundario,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_nome_host']       := StringReplace(EnCrypt(te_nome_host,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dominio_dns']     := StringReplace(EnCrypt(te_dominio_dns,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_origem_mac']      := StringReplace(EnCrypt(GetValorDatMemoria('TcpIp.TE_ORIGEM_MAC', v_tstrCipherOpened),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dominio_windows'] := StringReplace(EnCrypt(te_dominio_windows,l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

            v_acao_gercols := 'Contactando módulo Gerente WEB: set_tcp_ip.php';

            strRetorno := ComunicaServidor('set_tcp_ip.php', Request_SVG, '>> Enviando configurações de TCP/IP ao Gerente WEB.');
            if (strRetorno <> '0') Then
              Begin
                SetValorDatMemoria('TcpIp.te_mascara'        , te_mascara        , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_gateway'        , te_gateway        , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_serv_dhcp'      , te_serv_dhcp      , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_dns_primario'   , te_dns_primario   , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_dns_secundario' , te_dns_secundario , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_wins_primario'  , te_wins_primario  , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_wins_secundario', te_wins_secundario, v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_nome_host'      , te_nome_host      , v_tstrCipherOpened);
                SetValorDatMemoria('TcpIp.te_dominio_dns'    , te_dominio_dns    , v_tstrCipherOpened);
              End;

            Request_SVG.Free;


        end;
  v_tcpip.Free;
  except log_diario('PROBLEMAS EM BUSCACONFIGS - ' + v_acao_gercols+'.');
  End;
end;

procedure Executa_Ger_Cols;
var strDtHrColetaForcada,
    strDtHrUltimaColeta : String;
Begin
  Try
          // Parâmetros possíveis (aceitos)
          //   /ip_serv_cacic =>  Endereço IP do Módulo Gerente. Ex.: 10.71.0.212
          //   /cacic_dir     =>  Diretório para instalação do Cacic na estação. Ex.: Cacic
          //   /coletas       =>  Chamada para ativação das coletas
          //   /patrimonio    =>  Chamada para ativação do Formulário de Patrimônio
          // UpdatePrincipal  =>  Atualização do Agente Principal
          // Chamada com parâmetros pelo chkcacic.exe ou linha de comando
          // Chamada efetuada pelo Cacic2.exe quando da existência de temp\cacic2.exe para AutoUpdate
          If FindCmdLineSwitch('UpdatePrincipal', True) Then
            Begin
               log_DEBUG('Opção /UpdatePrincipal recebida...');
               // 15 segundos de tempo total até a execução do novo cacic2.exe
               sleep(7000);
               v_acao_gercols := 'Atualização do Agente Principal - Excluindo '+p_path_cacic + 'cacic2.exe';
               Matar(p_path_cacic,'cacic2.exe');
               sleep(2000);

               v_acao_gercols := 'Atualização do Agente Principal - Copiando '+p_path_cacic + 'temp\cacic2.exe para '+p_path_cacic + 'cacic2.exe';
               log_DEBUG('Copiando '+p_path_cacic + 'temp\cacic2.exe para '+p_path_cacic + 'cacic2.exe');
               CopyFile(pChar(p_path_cacic + 'temp\cacic2.exe'),pChar(p_path_cacic + 'cacic2.exe'),FALSE {Fail if Exists});
               sleep(2000);

               v_acao_gercols := 'Atualização do Agente Principal - Excluindo '+p_path_cacic + 'temp\cacic2.exe';
               Matar(p_path_cacic+'temp\','cacic2.exe');
               sleep(2000);

               SetValorDatMemoria('Configs.NU_EXEC_APOS','12345', v_tstrCipherOpened); // Para que o Agente Principal comande a coleta logo após 1 minuto...
               sleep(2000);

               log_DEBUG('Invocando atualização do Agente Principal...');

               v_acao_gercols := 'Atualização do Agente Principal - Invocando '+p_path_cacic + 'cacic2.exe /atualizacao';
               Finalizar(false);

               if ChecaAgente(p_path_cacic, 'cacic2.exe') then
                  WinExec(PChar(p_path_cacic + 'cacic2.exe /atualizacao'), SW_MINIMIZE);
               Sair;
              end;

          For intAux := 1 to ParamCount do
            Begin
              if LowerCase(Copy(ParamStr(intAux),1,15)) = '/ip_serv_cacic=' then
                begin
                  v_acao_gercols := 'Configurando ip_serv_cacic.';
                  strAux := Trim(Copy(ParamStr(intAux),16,Length((ParamStr(intAux)))));
                  endereco_servidor_cacic := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
                  log_DEBUG('Parâmetro /ip_serv_cacic recebido com valor="'+endereco_servidor_cacic+'"');
                  If endereco_servidor_cacic = '' Then endereco_servidor_cacic := strAux;
                  SetValorDatMemoria('Configs.EnderecoServidor', endereco_servidor_cacic, v_tstrCipherOpened);
                end;
            end;

          // Chamada com parâmetros pelo chkcacic.exe ou linha de comando
          For intAux := 1 to ParamCount do
            Begin
              If LowerCase(Copy(ParamStr(intAux),1,11)) = '/cacic_dir=' then
                Begin
                  v_acao_gercols := 'Configurando diretório para o CACIC. (Registry para w95/95OSR2/98/98SE/ME)';
                  // Identifico a versão do Windows
                  If (g_oCacic.isWindows9xME()) then
                    begin
                    //Se for 95/95OSR2/98/98SE/ME faço aqui...  (Em NT Like isto é feito no LoginScript)
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux))))) + '\cacic2.exe');
                    log_DEBUG('Setando Chave de AutoExecução...');
                    end;
                  log_DEBUG('Parâmetro /cacic_dir recebido com valor="'+Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux)))))+'"');
                end;
            End;

          // Chamada efetuada pelo Cacic2.exe quando o usuário clica no menu "Informações Patrimoniais"
          // Caso existam informações patrimoniais preenchidas, será pedida a senha configurada no módulo gerente WEB
          If FindCmdLineSwitch('patrimonio', True) Then
            Begin
              log_DEBUG('Opção /patrimonio recebida...');
              v_acao_gercols := 'Invocando Col_Patr.';
              log_DEBUG('Chamando Coletor de Patrimônio...');
              Patrimnio1Click(Nil);
              Finalizar(false);
              CriaTXT(p_path_cacic+'temp','coletas');
              Sair;
            End;

          If FindCmdLineSwitch('BuscaConfigsPrimeira', True) Then
            begin
              log_DEBUG('Opção /BuscaConfigsPrimeira recebida...');
              BuscaConfigs(false);
              Batchfile := TStringList.Create;
              Batchfile.Add('*** Simulação de cookie para cacic2.exe recarregar os valores de configurações ***');
              // A existência deste arquivo forçará o Cacic2.exe a recarregar valores das configurações obtidas e gravadas no Cacic2.DAT
              Batchfile.SaveToFile(p_path_cacic + 'Temp\reset.txt');
              BatchFile.Free;
              log_DEBUG('Configurações apanhadas no módulo Gerente WEB. Retornando ao Agente Principal...');
              Finalizar(false);
              Sair;
            end;

          // Chamada temporizada efetuada pelo Cacic2.exe
        If FindCmdLineSwitch('coletas', True) Then
            begin
              log_DEBUG('Parâmetro(opção) /coletas recebido...');
              v_acao_gercols := 'Ger_Cols invocado para coletas...';

              // Verificando o registro de coletas do dia e eliminando datas diferentes...
              strAux := GetValorDatMemoria('Coletas.HOJE', v_tstrCipherOpened);
              if (strAux = '') or
                 (copy(strAux,0,8) <> FormatDateTime('yyyymmdd', Date)) then
                 SetValorDatMemoria('Coletas.HOJE', FormatDateTime('yyyymmdd', Date),v_tstrCipherOpened);

              BuscaConfigs(true);

              // Abaixo eu testo se existe um endereço configurado para não disparar os procedimentos de coleta em vão.
              if (GetValorDatMemoria('Configs.EnderecoServidor', v_tstrCipherOpened)<>'') then
                  begin
                      v_CS_AUTO_UPDATE := (GetValorDatMemoria('Configs.CS_AUTO_UPDATE', v_tstrCipherOpened) = 'S');
                      if (v_CS_AUTO_UPDATE) then
                          Begin
                            log_DEBUG('Indicador CS_AUTO_UPDATE=S encontrado.');
                            log_diario('Verificando nova versão para módulo Agente Principal.');
                            // Caso encontre nova versão de cacic2.exe esta será gravada em temp e ocorrerá o autoupdate em sua próxima tentativa de chamada ao Ger_Cols.
                            v_acao_gercols := 'Verificando versão do Agente Principal';
                            Ver_UPD('cacic2','Agente Principal',p_path_cacic,'Temp',false);
                            log_diario('Verificando nova versão para módulo Gerente de Coletas.');
                            // Caso encontre nova versão de Ger_Cols esta será gravada em temp e ocorrerá o autoupdate.
                            Ver_UPD('ger_cols','Gerente de Coletas',p_path_cacic + 'modulos\','Temp',false);
                            if (FileExists(p_path_cacic + 'Temp\ger_cols.exe')) or
                               (FileExists(p_path_cacic + 'Temp\cacic2.exe'))  then
                                Begin
                                  log_diario('Finalizando... (Update em ± 1 minuto).');
                                  Finalizar(false);
                                  Sair;
                                End;
                          End;

                      if ((GetValorDatMemoria('Configs.CS_COLETA_HARDWARE'         , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_SOFTWARE'         , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_MONITORADO'       , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_OFFICESCAN'       , v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_COMPARTILHAMENTOS', v_tstrCipherOpened) = 'S') or
                          (GetValorDatMemoria('Configs.CS_COLETA_UNID_DISC'        , v_tstrCipherOpened) = 'S')) and
                          not FileExists(p_path_cacic + 'Temp\ger_cols.exe')  then
                          begin
                             v_acao_gercols := 'Montando script de coletas';
                             // Monto o batch de coletas de acordo com as configurações
                             log_diario('Verificando novas versões para Coletores de Informações.');
                             intMontaBatch := 0;
                             v_ModulosOpcoes := '';
                             strDtHrUltimaColeta := '0';
                             Try
                               strDtHrUltimaColeta := GetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA', v_tstrCipherOpened);
                             Except
                             End;
                             if (strDtHrUltimaColeta = '') then
                                strDtHrUltimaColeta := '0';

                             if (GetValorDatMemoria('Configs.CS_COLETA_PATRIMONIO', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_PATR', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada PATR: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_PATR','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_PATR','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_patr','Coletor de Informações de Patrimônio/Loc.Fís.',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_patr.exe'))  then
                                      Begin
                                         GetInfoPatrimonio;
                                         // Só chamo o Coletor de Patrimônio caso haja alteração de localização(e esteja configurado no módulo gerente WEB a abertura automática da janela)
                                         // ou o prazo de renovação esteja vencido ou seja o momento da instalação
                                         if (GetValorDatMemoria('Patrimonio.in_alteracao_fisica'     , v_tstrCipherOpened) = 'S') or
                                            (GetValorDatMemoria('Patrimonio.in_renovacao_informacoes', v_tstrCipherOpened) = 'S') or
                                            (GetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA'        , v_tstrCipherOpened)         = '' ) then
                                              Begin
                                                 intMontaBatch := 1;
                                                 if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                                 v_ModulosOpcoes := v_ModulosOpcoes + 'col_patr,wait,system';
                                              End;
                                      End
                                   Else
                                      log_diario('Executável Col_Patr Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_OFFICESCAN'       , v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_ANVI', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada ANVI: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_ANVI','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_ANVI','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_anvi','Coletor de Informações de Anti-Vírus OfficeScan',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_anvi.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_anvi,nowait,system';
                                      End
                                   Else log_diario('Executável Col_Anvi Inexistente!');

                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_COMPARTILHAMENTOS', v_tstrCipherOpened) = 'S') then
                                begin

                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_COMP', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada COMP: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);
                                  if not(strDtHrColetaForcada = '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_COMP','S', v_tstrCipherOpened)
                                  else
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_COMP','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_comp','Coletor de Informações de Compartilhamentos',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_comp.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_comp,nowait,system';
                                      End
                                   Else
                                      log_diario('Executável Col_Comp Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_HARDWARE', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_HARD', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada HARD: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_HARD','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_HARD','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_hard','Coletor de Informações de Hardware',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_hard.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_hard,nowait,system';
                                      End
                                   Else
                                      log_diario('Executável Col_Hard Inexistente!');
                                end;


                             if (GetValorDatMemoria('Configs.CS_COLETA_MONITORADO', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_MONI', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada MONI: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_MONI','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_MONI','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_moni','Coletor de Informações de Sistemas Monitorados',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_moni.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_moni,wait,system';
                                      End
                                   Else
                                      log_diario('Executável Col_Moni Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_SOFTWARE', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_SOFT', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada SOFT: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_SOFT','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_SOFT','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_soft','Coletor de Informações de Softwares Básicos',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_soft.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_soft,nowait,system';
                                      End
                                   Else
                                      log_diario('Executável Col_Soft Inexistente!');
                                end;

                             if (GetValorDatMemoria('Configs.CS_COLETA_UNID_DISC', v_tstrCipherOpened) = 'S') then
                                begin
                                  strDtHrColetaForcada := GetValorDatMemoria('Configs.DT_HR_COLETA_FORCADA_UNDI', v_tstrCipherOpened);
                                  log_DEBUG('Data/Hora Coleta Forçada UNDI: '+strDtHrColetaForcada);
                                  log_DEBUG('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     SetValorDatMemoria('Configs.IN_COLETA_FORCADA_UNDI','S', v_tstrCipherOpened)
                                  else
                                      SetValorDatMemoria('Configs.IN_COLETA_FORCADA_UNDI','N', v_tstrCipherOpened);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_undi','Coletor de Informações de Unidades de Disco',p_path_cacic + 'modulos\','',false);
                                   if (FileExists(p_path_cacic + 'Modulos\col_undi.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_undi,nowait,system';
                                      End
                                   Else
                                      log_diario('Executável Col_Undi Inexistente!');
                                end;
                             if (countUPD > 0) or
                                (GetValorDatMemoria('Configs.ID_FTP',v_tstrCipherOpened)<>'') then
                                Begin
                                  Request_Ger_Cols := TStringList.Create;
                                  Request_Ger_Cols.Values['in_chkcacic']   := StringReplace(EnCrypt('chkcacic',l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                                  Request_Ger_Cols.Values['te_fila_ftp']   := StringReplace(EnCrypt('2',l_cs_compress),'+','<MAIS>',[rfReplaceAll]); // Indicará sucesso na operação de FTP e liberará lugar para o próximo
                                  Request_Ger_Cols.Values['id_ftp']        := StringReplace(EnCrypt(GetValorDatMemoria('Configs.ID_FTP',v_tstrCipherOpened),l_cs_compress),'+','<MAIS>',[rfReplaceAll]); // Indicará sucesso na operação de FTP e liberará lugar para o próximo
                                  ComunicaServidor('get_config.php', Request_Ger_Cols, '>> Liberando Grupo FTP!...');
                                  Request_Ger_Cols.Free;
                                  SetValorDatMemoria('Configs.ID_FTP','', v_tstrCipherOpened)
                                End;
                             if (intMontaBatch > 0) then
                                Begin
                                     Ver_UPD('ini_cols','Inicializador de Coletas',p_path_cacic + 'modulos\','',false);
                                     log_diario('Iniciando coletas.');
                                     Finalizar(false);
                                     Matar(p_path_cacic + 'temp\','*.dat');
                                     CriaTXT(p_path_cacic+'temp','coletas');
                                     g_oCacic.createSampleProcess( p_path_cacic + 'modulos\ini_cols.exe /p_CipherKey=' + v_CipherKey +
                                                                     ' /p_ModulosOpcoes=' + v_ModulosOpcoes, CACIC_PROCESS_WAIT );
                                End;

                          end
                       else
                          begin
                             if not FileExists(p_path_cacic + 'Temp\ger_cols.exe') and
                                not FileExists(p_path_cacic + 'modulos\ger_cols.exe')  then
                                  log_diario('Módulo Gerente de Coletas inexistente.')
                             else log_diario('Nenhuma coleta configurada para essa subrede / estação / S.O.');
                          end;
                  End;
            end;

        // Caso não existam os arquivos abaixo, será finalizado.
        if (FileExists(p_path_cacic + 'Temp\coletas.txt')) or (FileExists(p_path_cacic + 'Temp\coletas.bat')) then
            begin
              log_DEBUG('Encontrado indicador de Coletas - Realizando leituras...');
              v_tstrCipherOpened1 := TStrings.Create;

              // Envio das informações coletadas com exclusão dos arquivos batchs e inis utilizados...
              Request_Ger_Cols:=TStringList.Create;
              intAux := 0;

              if (FileExists(p_path_cacic + 'Temp\col_anvi.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_anvi.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Anti-Vírus.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_anvi.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações sobre Anti-Vírus OfficeScan', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Anvi.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Anvi.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Anvi.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['nu_versao_engine' ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Anvi.nu_versao_engine' ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['nu_versao_pattern'] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Anvi.nu_versao_pattern',v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['dt_hr_instalacao' ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Anvi.dt_hr_instalacao' ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_servidor'      ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Anvi.te_servidor'      ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['in_ativo'         ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Anvi.in_ativo'         ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Anvi: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_officescan.php', Request_Ger_Cols, '>> Enviando informações de Antivírus OfficeScan para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            strAux := GetValorDatMemoria('Col_Anvi.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.OfficeScan',strAux, v_tstrCipherOpened) ;
                            intAux := 1;
                          End
                        else
                            // Armazeno o Status Negativo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);

                      End
                    Else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_anvi.dat');
                  End;

              if (FileExists(p_path_cacic + 'Temp\col_comp.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_comp.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Compartilhamentos.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_comp.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações sobre Compartilhamentos', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Comp.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Comp.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Comp.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['CompartilhamentosLocais'] := StringReplace(EnCrypt(StringReplace(GetValorDatMemoria('Col_Comp.UVC',v_tstrCipherOpened1),'\','<BarrInv>',[rfReplaceAll]),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        if v_Debugs then
                          Begin
                            log_DEBUG('Col_Comp.UVC => '+GetValorDatMemoria('Col_Comp.UVC',v_tstrCipherOpened1));
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Comp: '+Request_Ger_Cols.ValueFromIndex[intLoop]);
                          End;

                        if (ComunicaServidor('set_compart.php', Request_Ger_Cols, '>> Enviando informações de Compartilhamentos para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            strAux := GetValorDatMemoria('Col_Comp.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Compartilhamentos', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        Else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_comp.dat');
                  End;

              if (FileExists(p_path_cacic + 'Temp\col_hard.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_hard.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Hardware.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_hard.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações sobre Hardware', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Hard.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Hard.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Hard.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['te_Tripa_TCPIP'          ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_Tripa_TCPIP'          ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_Tripa_CPU'            ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_Tripa_CPU'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_Tripa_CDROM'          ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_Tripa_CDROM'          ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_mae_fabricante' ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_placa_mae_fabricante' ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_mae_desc'       ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_placa_mae_desc'       ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_mem_ram'              ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.qt_mem_ram'              ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_mem_ram_desc'         ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_mem_ram_desc'         ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_desc'            ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_bios_desc'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_data'            ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_bios_data'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_fabricante'      ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_bios_fabricante'      ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_placa_video_cores'    ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.qt_placa_video_cores'    ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_video_desc'     ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_placa_video_desc'     ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_placa_video_mem'      ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.qt_placa_video_mem'      ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_video_resolucao'] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_placa_video_resolucao',v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_som_desc'       ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_placa_som_desc'       ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_teclado_desc'         ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_teclado_desc'         ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_mouse_desc'           ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_mouse_desc'           ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_modem_desc'           ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Hard.te_modem_desc'           ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Hard: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_hardware.php', Request_Ger_Cols, '>> Enviando informações de Hardware para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            strAux :=GetValorDatMemoria('Col_Hard.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Hardware', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_hard.dat');
                  End;

              if (FileExists(p_path_cacic + 'Temp\col_patr.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_patr.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Patrimônio.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_patr.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações Patrimoniais', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Patr.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Patr.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Patr.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['id_unid_organizacional_nivel1']  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1'  ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['id_unid_organizacional_nivel1a'] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a' ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['id_unid_organizacional_nivel2']  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2'  ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_localizacao_complementar'  ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_localizacao_complementar'    ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio1'          ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio1'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio2'          ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio2'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio3'          ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio3'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio4'          ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio4'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio5'          ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio5'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_info_patrimonio6'          ]  := StringReplace(EnCrypt(GetValorDatMemoria('Col_Patr.te_info_patrimonio6'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Patr: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_patrimonio.php', Request_Ger_Cols, '>> Enviando informações de Patrimônio para o Gerente WEB.') <> '0') Then
                            Begin
                              // Armazeno o Status Positivo de Envio
                              SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                              // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                              //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1' , GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1',v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel1a', GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel1a',v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.id_unid_organizacional_nivel2' , GetValorDatMemoria('Col_Patr.id_unid_organizacional_nivel2',v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_localizacao_complementar'   , GetValorDatMemoria('Col_Patr.te_localizacao_complementar'  ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio1'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio1'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio2'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio2'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio3'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio3'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio4'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio4'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio5'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio5'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.te_info_patrimonio6'           , GetValorDatMemoria('Col_Patr.te_info_patrimonio6'          ,v_tstrCipherOpened1), v_tstrCipherOpened);
                              SetValorDatMemoria('Patrimonio.ultima_rede_obtida'            , GetValorDatMemoria('TcpIp.ID_IP_REDE'                      ,v_tstrCipherOpened) , v_tstrCipherOpened);
                              intAux := 1;
                            End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_patr.dat');
                  End;

              if (FileExists(p_path_cacic + 'Temp\col_moni.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_moni.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Sistemas Monitorados.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_moni.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações sobre Sistemas Monitorados', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Moni.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Moni.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Moni.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['te_tripa_monitorados'] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Moni.UVC',v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Moni: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_monitorado.php', Request_Ger_Cols, '>> Enviando informações de Sistemas Monitorados para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            strAux := GetValorDatMemoria('Col_Moni.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Sistemas_Monitorados', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_moni.dat');
                  End;

              if (FileExists(p_path_cacic + 'Temp\col_soft.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_soft.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Softwares.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_soft.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações sobre Softwares', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Soft.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Soft.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Soft.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['te_versao_bde'           ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_bde'           ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_dao'           ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_dao'           ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_ado'           ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_ado'           ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_odbc'          ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_odbc'          ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_directx'       ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_directx'       ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_acrobat_reader'] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_acrobat_reader',v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_ie'            ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_ie'            ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_mozilla'       ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_mozilla'       ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_jre'           ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_versao_jre'           ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_inventario_softwares' ] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Soft.te_inventario_softwares' ,v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_variaveis_ambiente'   ] := StringReplace(EnCrypt(StringReplace(GetValorDatMemoria('Col_Soft.te_variaveis_ambiente',v_tstrCipherOpened1),'\','<BarrInv>',[rfReplaceAll]),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Soft: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_software.php', Request_Ger_Cols, '>> Enviando informações de Softwares Básicos para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            // Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            strAux := GetValorDatMemoria('Col_Soft.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.Software', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_soft.dat');
                  End;

              if (FileExists(p_path_cacic + 'Temp\col_undi.dat')) then
                  Begin
                    log_DEBUG('Indicador '+p_path_cacic + 'Temp\col_undi.dat encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Unidades de Disco.';
                    v_tstrCipherOpened1  := CipherOpen(p_path_cacic + 'Temp\col_undi.dat');

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+'#Informações sobre Unidades de Disco', v_tstrCipherOpened);

                    // Armazeno as horas de início e fim das coletas
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Undi.Inicio',v_tstrCipherOpened1), v_tstrCipherOpened);
                    SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+','+GetValorDatMemoria('Col_Undi.Fim',v_tstrCipherOpened1), v_tstrCipherOpened);

                    if (GetValorDatMemoria('Col_Undi.nada',v_tstrCipherOpened1)='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['UnidadesDiscos'] := StringReplace(EnCrypt(GetValorDatMemoria('Col_Undi.UVC',v_tstrCipherOpened1),l_cs_compress),'+','<MAIS>',[rfReplaceAll]);

                        if v_Debugs then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                log_DEBUG('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Undi: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_unid_discos.php', Request_Ger_Cols, '>> Enviando informações de Unidades de Disco para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',1', v_tstrCipherOpened);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            strAux := GetValorDatMemoria('Col_Undi.UVC',v_tstrCipherOpened1);
                            SetValorDatMemoria('Coletas.UnidadesDisco', strAux, v_tstrCipherOpened);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',-1', v_tstrCipherOpened);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      SetValorDatMemoria('Coletas.HOJE',GetValorDatMemoria('Coletas.HOJE',v_tstrCipherOpened)+',0', v_tstrCipherOpened);

                    Request_Ger_Cols.Clear;
                    Matar(p_path_cacic+'Temp\','col_undi.dat');
                  End;
              Request_Ger_Cols.Free;

              // Reinicializo o indicador de Fila de Espera para FTP
              SetValorDatMemoria('Configs.TE_FILA_FTP','0', v_tstrCipherOpened);

              if (intAux = 0) then
                  log_diario('Sem informações para envio ao Gerente WEB.')
              else begin
                  // Atualiza a data de última coleta
                  SetValorDatMemoria('Configs.DT_HR_ULTIMA_COLETA',FormatDateTime('YYYYmmddHHnnss', Now), v_tstrCipherOpened);
                  log_diario('Todos os dados coletados foram enviados ao Gerente WEB.');
              end;
            end;
  Except
    Begin
     log_diario('PROBLEMAS EM EXECUTA_GER_COLS! Ação: ' + v_acao_gercols+'.');
     CriaTXT(p_path_cacic,'ger_erro');
     Finalizar(false);
     SetValorDatMemoria('Erro_Fatal_Descricao', v_acao_gercols, v_tstrCipherOpened);
    End;
  End;

End;

const
   CACIC_APP_NAME = 'ger_cols';

begin
   g_oCacic := TCACIC.Create();

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then begin
     Try
       // Pegarei o nível anterior do diretório, que deve ser, por exemplo \Cacic, para leitura do cacic2.DAT
       tstrTripa1   := explode(ExtractFilePath(ParamStr(0)),'\');
       p_path_cacic := '';
       For intAux := 0 to tstrTripa1.Count -2 do
           p_path_cacic := p_path_cacic + tstrTripa1[intAux] + '\';

       g_oCacic.setCacicPath(p_path_cacic);

       // Obtem a string de identificação do SO (v_te_so), para uso nas comunicações com o Gerente WEB.
       v_te_so := g_oCacic.getWindowsStrId();

       v_Debugs := false;
       if DirectoryExists(p_path_cacic + 'Temp\Debugs') then
           if (FormatDateTime('ddmmyyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
          Begin
            v_Debugs := true;
            log_DEBUG('Pasta "' + p_path_cacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
          End;

        For intAux := 1 to ParamCount do
          if LowerCase(Copy(ParamStr(intAux),1,13)) = '/p_cipherkey=' then
            Begin
              v_CipherKey := Trim(Copy(ParamStr(intAux),14,Length((ParamStr(intAux)))));
              log_DEBUG('Parâmetro para cifragem recebido.');
            End;

        // Caso tenha sido invocado por um CACIC2.EXE versão antiga, assumo o valor abaixo...
        // Solução provisória até a convergência das versões do Agente Principal e do Gerente de Coletas
        if (trim(v_CipherKey)='') then
           v_CipherKey := 'CacicBrasil';

        if (trim(v_CipherKey)<>'') then
          Begin
            v_IV := 'abcdefghijklmnop';

           // De acordo com a versão do OS, determina-se o ShellCommand para chamadas externas.
           p_Shell_Command := 'cmd.exe /c '; //NT/2K/XP
           if(g_oCacic.isWindows9xME()) then
              p_Shell_Command := 'command.com /c ';

           if not DirectoryExists(p_path_cacic + 'Temp') then
             ForceDirectories(p_path_cacic + 'Temp');

           // A chave AES foi obtida no parâmetro p_CipherKey. Recomenda-se que cada empresa altere a sua chave.
           v_DatFileName      := p_path_cacic + 'cacic2.dat';
           v_tstrCipherOpened := TStrings.Create;
           v_tstrCipherOpened := CipherOpen(v_DatFileName);

           // Não tirar desta posição
           SetValorDatMemoria('Configs.ID_SO',g_oCacic.getWindowsStrId(), v_tstrCipherOpened);

           v_scripter := 'wscript.exe';
           // A existência e bloqueio do arquivo abaixo evitará que Cacic2.exe chame o Ger_Cols quando este estiver em funcionamento
           AssignFile(v_Aguarde,p_path_cacic + 'temp\aguarde_GER.txt'); {Associa o arquivo a uma variável do tipo TextFile}
           {$IOChecks off}
           Reset(v_Aguarde); {Abre o arquivo texto}
           {$IOChecks on}
           if (IOResult <> 0) then // Arquivo não existe, será recriado.
             Rewrite (v_Aguarde);

           Append(v_Aguarde);
           Writeln(v_Aguarde,'Apenas um pseudo-cookie para o Cacic2 esperar o término de Ger_Cols');
           Append(v_Aguarde);

           ChecaCipher;
           ChecaCompress;

           Executa_Ger_Cols;
           Finalizar(true);
          End;
       Except
         Begin
           log_diario('PROBLEMAS EM EXECUTA_GER_COLS! Ação: ' + v_acao_gercols+'.');
           CriaTXT(p_path_cacic,'ger_erro');
           Finalizar(false);
           SetValorDatMemoria('Erro_Fatal_Descricao', v_acao_gercols, v_tstrCipherOpened);
         End;
     End;
   End;

   g_oCacic.Free();
end.
