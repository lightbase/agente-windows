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

program col_moni;
{$R *.res}

uses  Windows,
      sysutils,
      inifiles,
      Registry,
      Classes,
      PJVersionInfo,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64;

var  p_path_cacic, v_Res_Search, v_Drive, v_File : string;
     PJVersionInfo1: TPJVersionInfo;
     v_CipherKey,
     v_IV,
     v_strCipherClosed,
     v_DatFileName             : String;

var v_Debugs                   : boolean;

var v_tstrCipherOpened,
    v_tstrCipherOpened1        : TStrings;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

procedure GetSubDirs(Folder:string; sList:TStringList);
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

function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
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
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor MONI] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
     log_diario('Erro na gravação do log!');
   end;
end;

function GetVersionInfo(p_File: string):string;
var v_versao : string;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := p_File;
  v_versao := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
  Result := v_versao;
end;

// Baixada de http://www.infoeng.hpg.ig.com.br/borland_delphi_dicas_2.htm
function LetrasDrives: string;
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
function SearchFile(p_Drive,p_File:string) : boolean;
var sr:TSearchRec;
    sDirList:TStringList;
    i:integer;
begin
   Result := false;
   v_Res_Search := '';
   if FindFirst(p_Drive+p_File,faAnyFile,sr) = 0 then
    Begin
      v_Res_Search := p_Drive+p_File;
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


function HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
end;

Function Implode(p_Array : TStrings ; p_Separador : String) : String;
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


// Encrypt a string and return the Base64 encoded result
function EnCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    // Pad Key, IV and Data with zeros as appropriate
    l_Key   := PadWithZeros(v_CipherKey,KeySize);
    l_IV    := PadWithZeros(v_IV,BlockSize);
    l_Data  := PadWithZeros(p_Data,BlockSize);

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

    // Return the Base64 encoded result
    Result := Base64EncodeStr(l_Data);
  Except
    log_diario('Erro no Processo de Criptografia');
  End;
end;

function DeCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    // Pad Key and IV with zeros as appropriate
    l_Key := PadWithZeros(v_CipherKey,KeySize);
    l_IV := PadWithZeros(v_IV,BlockSize);

    // Decode the Base64 encoded string
    l_Data := Base64DecodeStr(p_Data);

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

    // Return the result
    Result := l_Data;
  Except
    log_diario('Erro no Processo de Decriptografia');
  End;
end;

Function CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       // Criação do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       //v_Cipher  := TDCP_rijndael.Create(nil);
       //v_Cipher.InitStr(v_CipherKey,TDCP_md5);
       v_strCipherOpenImploded := Implode(p_tstrCipherOpened,'=CacicIsFree=');
       //v_strCipherClosed := v_Cipher.EncryptString(v_strCipherOpenImploded);
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);
       //v_Cipher.Burn;
       //v_Cipher.Free;

       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(v_DatFile);
   except
   end;
end;
function GetWinVer: Integer;
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


Function CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
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
      v_strCipherOpened:= DeCrypt(v_strCipherClosed);
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := explode(v_strCipherOpened,'=CacicIsFree=')
    else
      Result := explode('Configs.ID_SO=CacicIsFree='+inttostr(GetWinVer)+'=CacicIsFree=Configs.Endereco_WS=CacicIsFree=/cacic2/ws/','=CacicIsFree=');

    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
begin
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(p_Valor);
      End;
end;
procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

Function GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
begin
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
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

Function RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;

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
               Result := RemoveCaracteresEspeciais(s);
             end
        end;
    finally
    RegEditGet.CloseKey;
    RegEditGet.Free;
    ListaAuxGet.Free;

    end;
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


procedure Executa_Col_moni;
var tstrTripa2, tstrTripa3, v_array1, v_array2, v_array3, v_array4 : TStrings;
    strAux, strAux1, strAux3, strAux4, strTripa, ValorChavePerfis, UVC, v_LetrasDrives, v_Data : String;
    intAux4, v1, v3, v_achei : Integer;

begin
  Try
   SetValorDatMemoria('Col_Moni.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
   // Verifica se deverá ser realizada a coleta de informações de sistemas monitorados neste
   // computador, perguntando ao agente gerente.
   log_diario('Coletando informações de Sistemas Monitorados.');
   ShortDateFormat := 'dd/mm/yyyy';
   intAux4          := 1;
   strAux3          := '';
   ValorChavePerfis := '*';
   v_LetrasDrives   := LetrasDrives;

   while ValorChavePerfis <> '' do
      begin
         strAux3 := 'SIS' + trim(inttostr(intAux4));
         strTripa := ''; // Conterá as informações a serem enviadas ao Gerente.
         // Obtenho do registro o valor que foi previamente armazenado
         ValorChavePerfis := Trim(GetValorDatMemoria('Coletas.'+strAux3,v_tstrCipherOpened));

         if (ValorChavePerfis <> '') then
           Begin
               //Atenção, OS ELEMENTOS DEVEM ESTAR DE ACORDO COM A ORDEM QUE SÃO TRATADOS NO MÓDULO GERENTE.
               tstrTripa2  := Explode(ValorChavePerfis,',');
               if (strAux <> '') then strAux := strAux + '#';
               strAux := strAux + trim(tstrTripa2[0]) + ',';


               ///////////////////////////////////////////
               ///// Coleta de Informação de Licença /////
               ///////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[2])='0') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Caminho\Chave\Valor em Registry
               if (trim(tstrTripa2[2])='1') then
                 Begin
                    strAux4 := '';
                    log_debug('Buscando informação de LICENÇA em '+tstrTripa2[3]);
                    Try
                      strAux4 := Trim(GetValorChaveRegEdit(trim(tstrTripa2[3])));
                    Except
                    End;
                    if (strAux4 = '') then strAux4 := '?';
                    strAux  := strAux + strAux4 + ',';
                 End;

               //Nome/Seção/Chave de Arquivo INI
               if (trim(tstrTripa2[2])='2') then
                 Begin
                    log_debug('Buscando informação de LICENÇA em '+tstrTripa2[3]);
                    Try
                      if (LastPos('/',trim(tstrTripa2[3]))>0) then
                        Begin
                          tstrTripa3  := Explode(trim(tstrTripa2[3]),'/');
                          //
                          for v1:=1 to length(v_LetrasDrives) do
                            Begin
                              v_File := trim(tstrTripa3[0]);
                              if (LastPos(':\',v_File)>0) then
                                Begin
                                  v_Drive := Copy(v_File,1,3);
                                  v_File  := Copy(v_File,4,Length(v_File));
                                End
                              else
                                Begin
                                  v_Drive := v_LetrasDrives[v1] + ':';
                                  if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                                  v_File  := Copy(v_File,1,Length(v_File));
                                End;

                              strAux1 := ExtractShortPathName(v_Drive + v_File);
                              if (strAux1 = '') then
                                begin
                                  if (SearchFile(v_Drive,v_File)) then
                                    Begin
                                      strAux1 := v_Res_Search;
                                      break;
                                    End;
                                end
                              else break;
                            End;

                          strAux4 := Trim(GetValorChaveRegIni(tstrTripa3[1],tstrTripa3[2],strAux1));
                          if (strAux4 = '') then strAux4 := '?';
                          strAux := strAux + strAux4 + ',';
                        End;

                      if (LastPos('/',trim(tstrTripa2[3]))=0) then
                        Begin
                          strAux := strAux + 'Parâm.Lic.Incorreto,';
                        End
                    Except
                        strAux := strAux + 'Parâm.Lic.Incorreto,';
                    End;
                 End;



               //////////////////////////////////////////////
               ///// Coleta de Informação de Instalação /////
               //////////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[5])='0') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Nome de Executável OU Nome de Arquivo de Configuração (CADPF!!!)
               if (trim(tstrTripa2[5])='1') or (trim(tstrTripa2[5]) = '2') then
                 Begin
                  strAux1 := '';
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                    v_File := trim(tstrTripa2[6]);
                    log_debug('Buscando informação de INSTALAÇÃO em '+tstrTripa2[6]);
                    if (LastPos(':\',v_File)>0) then
                      Begin
                        v_Drive := Copy(v_File,1,3);
                        v_File  := Copy(v_File,4,Length(v_File));
                      End
                    else
                      Begin
                        v_Drive := v_LetrasDrives[v1] + ':';
                        if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                        v_File  := Copy(v_File,1,Length(v_File));
                      End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;

                    End;

                  if (strAux1 <> '') then strAux := strAux + 'S,';
                  if (strAux1 = '')  then strAux := strAux + 'N,';
                  strAux1 := '';
                 End;

               //Caminho\Chave\Valor em Registry
               if (trim(tstrTripa2[5])='3') then
                 Begin
                  strAux1 := '';
                  Try
                    log_debug('Buscando informação de INSTALAÇÃO em '+tstrTripa2[6]);
                    strAux1 := Trim(GetValorChaveRegEdit(trim(tstrTripa2[6])));
                  Except
                  End;
                  if (strAux1 <> '') then strAux  := strAux + 'S,';
                  if (strAux1 = '') then strAux := strAux + 'N,';
                  strAux1 := '';
                 End;



               //////////////////////////////////////////
               ///// Coleta de Informação de Versão /////
               //////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[7])='0') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Data de Arquivo
               if (trim(tstrTripa2[7])='1') then
                 Begin
                  strAux1 := '';
                  log_debug('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                    v_File := trim(tstrTripa2[8]);
                    if (LastPos(':\',v_File)>0) then
                      Begin
                        v_Drive := Copy(v_File,1,3);
                        v_File  := Copy(v_File,4,Length(v_File));
                      End
                    else
                      Begin
                        v_Drive := v_LetrasDrives[v1] + ':';
                        if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                        v_File  := Copy(v_File,1,Length(v_File));
                      End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;
                    End;

                  if (strAux1 <> '') then
                    Begin
                      v_Data := StringReplace(DateToStr(FileDateToDateTime(FileAge(strAux1))),'.','/',[rfReplaceAll]);
                      v_Data := StringReplace(v_Data,'-','/',[rfReplaceAll]);
                      strAux := strAux + v_Data + ',';
                      v_Data := '';
                    End;

                  if (strAux1 = '') then strAux := strAux + '?,';
                  strAux1 := '';
                 End;

               //Caminho\Chave\Valor em Registry
               if (trim(tstrTripa2[7])='2') then
                 Begin
                  strAux1 := '';
                  log_debug('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                  Try
                    strAux1 := Trim(GetValorChaveRegEdit(trim(tstrTripa2[8])));
                  Except
                  End;
                  if (strAux1 <> '') then strAux := strAux + strAux1 + ',';
                  if (strAux1 = '') then strAux := strAux + '?,';
                  strAux1 := '';
                 End;


               //Nome/Seção/Chave de Arquivo INI
               if (trim(tstrTripa2[7])='3') then
                 Begin
                    Try
                      log_debug('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                      if (LastPos('/',trim(tstrTripa2[8]))>0) then
                        Begin
                          tstrTripa3  := Explode(trim(tstrTripa2[8]),'/');
                          //
                          for v1:=1 to length(v_LetrasDrives) do
                            Begin
                              v_File := trim(tstrTripa3[0]);
                              if (LastPos(':\',v_File)>0) then
                                Begin
                                  v_Drive := Copy(v_File,1,3);
                                  v_File  := Copy(v_File,4,Length(v_File));
                                End
                              else
                                Begin
                                  v_Drive := v_LetrasDrives[v1] + ':';
                                  if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                                  v_File  := Copy(v_File,1,Length(v_File));
                                End;

                              strAux1 := ExtractShortPathName(v_Drive + v_File);
                              if (strAux1 = '') then
                                begin
                                  if (SearchFile(v_Drive,v_File)) then
                                    Begin
                                      strAux1 := v_Res_Search;
                                      break;
                                    End;
                                end
                              else break;
                            End;

                          //
                          strAux4 := Trim(GetValorChaveRegIni(tstrTripa3[1],tstrTripa3[2],strAux1));
                          if (strAux4 = '') then strAux4 := '?';
                          strAux := strAux + strAux4 + ',';
                        End
                      else
                        Begin
                          strAux := strAux + 'Parâm.Versao Incorreto,';
                        End;
                    Except
                    End;
                 End;


             //Versão de Executável
             if (trim(tstrTripa2[7])='4') then
               Begin
                 log_debug('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                 Try
                  v_achei := 0;
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                      if v_achei = 0 then
                        Begin
                          v_File := trim(tstrTripa2[8]);
                          if (LastPos(':\',v_File)>0) then
                            Begin
                              v_Drive := Copy(v_File,1,3);
                              v_File  := Copy(v_File,4,Length(v_File));
                            End
                          else
                            Begin
                              v_Drive := v_LetrasDrives[v1] + ':';
                              if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                              v_File  := Copy(v_File,1,Length(v_File));
                            End;

                          strAux1 := ExtractShortPathName(v_Drive + v_File);
                          if (strAux1 = '') then
                            begin
                            if (SearchFile(v_Drive,v_File)) then
                              Begin
                                strAux1 := v_Res_Search;
                                v_achei := 1;
                              End;
                            end
                          else v_achei := 1;
                        End;
                    End;
                 Except
                 End;

                 if (strAux1 <> '') then
                    Begin
                      strAux := strAux + getVersionInfo(strAux1);
                    End
                else strAux := strAux + '?';

                strAux := strAux + ',';

               End;


               //////////////////////////////////////////
               ///// Coleta de Informação de Engine /////
               //////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[9])='.') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Arquivo para Versão de Engine
               //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
               if (trim(tstrTripa2[9])<>'.') then
                 Begin
                  log_debug('Buscando informação de ENGINE em '+tstrTripa2[9]);
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                      v_File := trim(tstrTripa2[9]);
                      if (LastPos(':\',v_File)>0) then
                        Begin
                          v_Drive := Copy(v_File,1,3);
                          v_File  := Copy(v_File,4,Length(v_File));
                        End
                      else
                        Begin
                          v_Drive := v_LetrasDrives[v1] + ':';
                          if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                          v_File  := Copy(v_File,1,Length(v_File));
                        End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;
                    End;
                  if (strAux1 <> '') then
                    Begin
                      tstrTripa3 := Explode(getVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                      strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                    End;
                 End;


               ///////////////////////////////////////////
               ///// Coleta de Informação de Pattern /////
               ///////////////////////////////////////////

               //Arquivo para Versão de Pattern
               //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
               strAux1 := '';
               if (trim(tstrTripa2[10])<>'.') then
                 Begin
                  log_debug('Buscando informação de PATTERN em '+tstrTripa2[9]);
                    for v1:=1 to length(v_LetrasDrives) do
                      Begin
                      v_File := trim(tstrTripa2[10]);
                      if (LastPos(':\',v_File)>0) then
                        Begin
                          v_Drive := Copy(v_File,1,3);
                          v_File  := Copy(v_File,4,Length(v_File));
                        End
                      else
                        Begin
                          v_Drive := v_LetrasDrives[v1] + ':';
                          if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                          v_File  := Copy(v_File,1,Length(v_File));
                        End;

                        strAux1 := ExtractShortPathName(v_Drive + v_File);
                        if (strAux1 = '') then
                          begin
                          if (SearchFile(v_Drive, v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;

                      End;
                 End;
                 if (strAux1 <> '') then
                    Begin
                      tstrTripa3 := Explode(getVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                      strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                    End;
                 if (strAux1 = '') then strAux := strAux + ',';
                 strAux1 := '';
           End;
           intAux4 := intAux4 + 1;
      End;

      UVC := Trim(GetValorDatMemoria('Coletas.Sistemas_Monitorados',v_tstrCipherOpened));

      SetValorDatMemoria('Col_Moni.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

      If (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_MONI',v_tstrCipherOpened)='S') or (trim(strAux) <> trim(UVC)) Then
        Begin
          if (trim(UVC) <> '') then
            begin
              v_array1  :=  Explode(strAux, '#');
              strAux    :=  '';
              v_array3  :=  Explode(UVC, '#');
              for v1 := 0 to (v_array1.count)-1 do
                Begin
                  v_array2  :=  Explode(v_array1[v1], ',');
                  v_achei   :=  0;
                  for v3 := 0 to (v_array3.count)-1 do
                    Begin
                      v_array4  :=  Explode(v_array3[v3], ',');
                      if (v_array4=v_array2) then v_achei := 1;
                    End;
                  if (v_achei = 0) then
                    Begin
                      if (strAUX <> '') then strAUX :=  strAUX + '#';
                      strAUX  :=  strAUX + v_array1[v1];
                    End;
                End;
              end;
          log_debug('Coleta anterior: '+UVC);
          log_debug('Coleta atual...: '+strAux);
          SetValorDatMemoria('Col_Moni.UVC', strAux, v_tstrCipherOpened1);
          CipherClose(p_path_cacic + 'temp\col_moni.dat', v_tstrCipherOpened1);
        end
      else
        Begin
          log_debug('Nenhuma Coleta Efetuada');
          SetValorDatMemoria('Col_Moni.nada', 'nada', v_tstrCipherOpened1);
          CipherClose(p_path_cacic + 'temp\col_moni.dat', v_tstrCipherOpened1);
        End;

  Except
    Begin
      SetValorDatMemoria('Col_Moni.nada', 'nada', v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Moni.Fim', '99999999', v_tstrCipherOpened1);
      CipherClose(p_path_cacic + 'temp\col_moni.dat', v_tstrCipherOpened1);
    End;
  End;
END;

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


var tstrTripa1 : TStrings;
    intAux     : integer;
begin
  if (ParamCount>0) then
    Begin
      For intAux := 1 to ParamCount do
        Begin
          if LowerCase(Copy(ParamStr(intAux),1,13)) = '/p_cipherkey=' then
            v_CipherKey := Trim(Copy(ParamStr(intAux),14,Length((ParamStr(intAux)))));
        End;

       if (trim(v_CipherKey)<>'') then
          Begin

             //Pegarei o nível anterior do diretório, que deve ser, por exemplo \Cacic, para leitura do cacic2.ini
             tstrTripa1 := explode(ExtractFilePath(ParamStr(0)),'\');
             p_path_cacic := '';
             For intAux := 0 to tstrTripa1.Count -2 do
               begin
                 p_path_cacic := p_path_cacic + tstrTripa1[intAux] + '\';
               end;

             v_Debugs := false;
             if DirectoryExists(p_path_cacic + 'Temp\Debugs') then
               Begin
                if (FormatDateTime('ddmmyyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                  Begin
                    v_Debugs := true;
                    log_diario('Pasta "' + p_path_cacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                  End;
              End;

             // A chave AES foi obtida no parâmetro p_CipherKey. Recomenda-se que cada empresa altere a sua chave.
             v_IV                := 'abcdefghijklmnop';
             v_DatFileName       := p_path_cacic + 'cacic2.dat';
             v_tstrCipherOpened  := TStrings.Create;
             v_tstrCipherOpened  := CipherOpen(v_DatFileName);

             v_tstrCipherOpened1 := TStrings.Create;
             v_tstrCipherOpened1 := CipherOpen(p_path_cacic + 'temp\col_moni.dat');

             Try
               Executa_Col_moni;
             Except
               SetValorDatMemoria('Col_Moni.nada', 'nada', v_tstrCipherOpened1);
               CipherClose(p_path_cacic + 'temp\col_moni.dat', v_tstrCipherOpened1);
             End;
             Halt(0);
          End;
    End;
end.
