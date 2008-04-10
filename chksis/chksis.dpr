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

program chksis;
{$R *.res}

uses  Windows,
      forms,
      SysUtils,
      Classes,
      Registry,
      Inifiles,
      XML,
      LibXmlParser,
      strUtils,
      IdHTTP,
      IdFTP,
      idFTPCommon,
      IdBaseComponent,
      IdComponent,
      IdTCPConnection,
      IdTCPClient,
      PJVersionInfo,
      Winsock,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64,
      Tlhelp32;

var PJVersionInfo1: TPJVersionInfo;
    Dir,
    v_CipherKey,
    v_IV,
    v_SeparatorKey,
    v_strCipherClosed,
    v_DatFileName,
    v_versao_local,
    v_versao_remota,
    v_retorno,
    v_te_so             : String;
    intWinVer    : integer;
    v_Debugs                  : Boolean;
var v_tstrCipherOpened        : TStrings;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

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


function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

{ TMainForm }
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

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal,
    strDataAtual,
    p_path : string;
begin
   try
       p_path := Dir + '\chksis.log';
       FileSetAttr (p_path,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,p_path); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path)));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Verif.Integr.Sistema] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
     log_diario('Erro na gravação do log!');
   end;
end;
function GetVersionInfo(p_File: string):string;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(PJVersionInfo1);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
end;

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

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

Function CipherClose(p_DatFileName : string) : String;
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try

       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       {$IOChecks off}
       ReWrite(v_DatFile); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then
        Begin
         // Recriação do arquivo .DAT
         Rewrite (v_DatFile);
         Append(v_DatFile);
        End;

       //v_Cipher  := TDCP_rijndael.Create(nil);
       //v_Cipher.InitStr(v_CipherKey,TDCP_md5);
       v_strCipherOpenImploded := Implode(v_tstrCipherOpened,v_SeparatorKey);
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);
       //log_diario('Finalizando o Arquivo de Configurações com criptografia de: '+v_strCipherOpenImploded,ExtractFilePath(ParamStr(0)));
       //v_strCipherClosed := v_Cipher.EncryptString(v_strCipherOpenImploded);
       //v_Cipher.Burn;
       //v_Cipher.Free;

       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(v_DatFile);
   except
        log_diario('Problema na gravação do arquivo de configurações.');
   end;
end;

function abstraiCSD(p_te_so : String) : integer;
  var tstrTe_so : tstrings;
  Begin
    tstrTe_so := Explode(p_te_so, '.');
    Result := StrToInt(tstrTe_so[0] + tstrTe_so[1] + tstrTe_so[2]);
  End;

function GetWinVer: Integer;
const
  { operating system (OS)constants }
  cOsUnknown    = 0;
  cOsWin95      = 1;
  cOsWin95OSR2  = 2;  // Não implementado.
  cOsWin98      = 3;
  cOsWin98SE    = 4;
  cOsWinME      = 5;
  cOsWinNT      = 6;
  cOsWin2000    = 7;
  cOsXP         = 8;
  cOsServer2003 = 13;
var
  osVerInfo: TOSVersionInfo;
  platformID,
  majorVer,
  minorVer: Integer;
  CSDVersion : String;
begin
  Result := cOsUnknown;
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
    platformId        :=      osVerInfo.dwPlatformId;
    majorVer          :=      osVerInfo.dwMajorVersion;
    minorVer          :=      osVerInfo.dwMinorVersion;
    CSDVersion        := trim(osVerInfo.szCSDVersion);

    case osVerInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT: { Windows NT/2000 }
        begin
          if majorVer <= 4 then
            Result := cOsWinNT
          else if (majorVer = 5) and (minorVer = 0) then
            Result := cOsWin2000
          else if (majorVer = 5) and (minorVer = 1) then
            Result := cOsXP
          else if (majorVer = 5) and (minorVer = 2) then
            Result := cOsServer2003
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

  // A partir da versão 2.2.0.24, defino o valor da ID Interna e atribuo-a sem o CSDVersion à versão externa
  v_te_so := IntToStr(platformId) + '.' +
             IntToStr(majorVer)   + '.' +
             IntToStr(minorVer)   +
             IfThen(CSDVersion='','','.'+CSDVersion);
  if (Result = 0) then
    Result := abstraiCSD(v_te_so);

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
      Result := explode(v_strCipherOpened,v_SeparatorKey)
    else
      Result := explode('Configs.ID_SO' + v_SeparatorKey + inttostr(intWinVer)+v_SeparatorKey+'Configs.Endereco_WS'+v_SeparatorKey+'/cacic2/ws/',v_SeparatorKey);

    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String);
begin
    //log_diario('Setando chave: '+p_Chave+' com valor: '+p_Valor,ExtractFilePath(ParamStr(0)));
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        v_tstrCipherOpened.Add(p_Chave);
        v_tstrCipherOpened.Add(p_Valor);
      End;
end;


function GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
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

//Para buscar do RegEdit...
function GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    ListaAuxGet := Explode(Chave, '\');

    strRootKey := ListaAuxGet[0];
    For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';
    strValue := ListaAuxGet[ListaAuxGet.Count - 1];
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


function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
//function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
    v_SectionName := '[' + p_Secao + ']';
    v_Size_Section := strLen(PChar(v_SectionName));
    v_KeyName := p_Chave + '=';
    v_Size_Key     := strLen(PChar(v_KeyName));
    FileText := TStringList.Create;
    if (FileExists(p_File)) then
      Begin
        try
          FileText.LoadFromFile(p_File);
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
      end
    else FileText.Free;
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



Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
var IdFTP : TIdFTP;
begin
  Try
    IdFTP               := TIdFTP.Create(IdFTP);
    IdFTP.Host          := p_Host;
    IdFTP.Username      := p_Username;
    IdFTP.Password      := p_Password;
    IdFTP.Port          := strtoint(p_Port);
    IdFTP.TransferType  := ftBinary;
    IdFTP.Passive       := true;
    Try
      if IdFTP.Connected = true then
        begin
          IdFTP.Disconnect;
        end;
      IdFTP.Connect(true);
      IdFTP.ChangeDir(p_PathServer);
      Try
        log_DEBUG('Size de "'+p_File+'" Antes do FTP => '+IntToSTR(IdFTP.Size(p_File)));
        IdFTP.Get(p_File, p_Dest + '\' + p_File, True);
        log_DEBUG('Size de "'+p_Dest + '\' + p_File +'" Após o FTP   => '+Get_File_Size(p_Dest + '\' + p_File,true));
      Finally
        log_DEBUG('Size de "'+p_Dest + '\' + p_File +'" Após o FTP em Finally   => '+Get_File_Size(p_Dest + '\' + p_File,true));
        idFTP.Disconnect;
        idFTP.Free;
        result := true;
      End;
    Except
        result := false;
    end;
  Except
    result := false;
  End;
end;


function HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
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
function FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  ConHandle : Thandle;
  NextTitle: array[0..260] of char;
begin
  // Get the first window

  NextHandle := GetWindow(ConHandle, GW_HWNDFIRST);
  while NextHandle > 0 do
  begin
    // retrieve its text
    GetWindowText(NextHandle, NextTitle, 255);

    if (trim(StrPas(NextTitle))<> '') and (Pos(strlower(pchar(WindowTitle)), strlower(PChar(StrPas(NextTitle)))) <> 0) then
    begin
      Result := NextHandle;
      Exit;
    end
    else
      // Get the next window
      NextHandle := GetWindow(NextHandle, GW_HWNDNEXT);
  end;
  Result := 0;
end;

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{For Windows 9x/ME/2000/XP }
function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{ For Windows NT/2000/XP }
procedure KillProcess(hWindowHandle: HWND);
var
  hprocessID: INTEGER;
  processHandle: THandle;
  DWResult: DWORD;
begin
  SendMessageTimeout(hWindowHandle, WM_DDE_TERMINATE, 0, 0,
    SMTO_ABORTIFHUNG or SMTO_NORMAL, 5000, DWResult);

  if isWindow(hWindowHandle) then
  begin
    // PostMessage(hWindowHandle, WM_QUIT, 0, 0);

    { Get the process identifier for the window}
    GetWindowThreadProcessID(hWindowHandle, @hprocessID);
    if hprocessID <> 0 then
    begin
      { Get the process handle }
      processHandle := OpenProcess(PROCESS_TERMINATE or PROCESS_QUERY_INFORMATION,
        False, hprocessID);
      if processHandle <> 0 then
      begin
        { Terminate the process }
        TerminateProcess(processHandle, 0);
        CloseHandle(ProcessHandle);
      end;
    end;
  end;
end;


// Dica baixada de http://procedure.blig.ig.com.br/
// Adaptada por Anderson Peterle - v:2.2.0.16 - 03/2007
procedure Matar(v_dir,v_files: string);
var SearchRec: TSearchRec;
    Result: Integer;
    strFileName : String;
begin
  strFileName := StringReplace(v_dir + '\' + v_files,'\\','\',[rfReplaceAll]);
  Result:=FindFirst(strFileName, faAnyFile, SearchRec);

  while result=0 do
    begin
      strFileName := StringReplace(v_dir + '\' + SearchRec.Name,'\\','\',[rfReplaceAll]);

      if not DeleteFile(strFileName) then
        Begin
          if ((intWinVer <> 0) and (intWinVer <= 5))  or
             (abstraiCSD(v_te_so) < 250) then // Menor que NT Like
            KillTask(SearchRec.Name)
          else
            KillProcess(FindWindow(PChar(SearchRec.Name),nil));

            DeleteFile(strFileName);
        End;

      Result:=FindNext(SearchRec);
    end;
end;

function Posso_Rodar_CACIC : boolean;
Begin
  result := false;

  // Se o aguarde_CACIC.txt existir é porque refere-se a uma versão mais atual: 2.2.0.20 ou maior
  if  (FileExists(Dir + '\aguarde_CACIC.txt')) then
    Begin
      // Se eu conseguir matar o arquivo abaixo é porque não há outra sessão deste agente aberta... (POG? Nããão!  :) )
      Matar(Dir,'aguarde_CACIC.txt');
      if  (not (FileExists(Dir + '\aguarde_CACIC.txt'))) then
        result := true;
    End;
End;

Function ChecaVersoesAgentes(p_strNomeAgente : String) : integer;
var v_versao_REM,
    v_versao_LOC,
    strNomeAgente : String;
    v_array_NomeAgente : TStrings;
    intAux : integer;
Begin
  v_array_NomeAgente := explode(p_strNomeAgente,'\');

  v_versao_REM := XML_RetornaValor(StringReplace(StrUpper(PChar(v_array_NomeAgente[v_array_NomeAgente.count-1])),'.EXE','',[rfReplaceAll]), v_retorno);
  v_versao_LOC := GetVersionInfo(p_strNomeAgente);

  log_diario('Checando versão de "'+p_strNomeAgente+'"');

  intAux := v_array_NomeAgente.Count;

  // V: 2.2.0.16
  // Verifico existência do arquivo "versoes_agentes.ini" para comparação das versões dos agentes principais
  if (v_versao_REM = '') AND FileExists(ExtractFilePath(Application.Exename)+'versoes_agentes.ini') then
    Begin
      if (GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
        Begin
          log_diario('Encontrado arquivo "'+(ExtractFilePath(Application.Exename)+'versoes_agentes.ini')+'"');
          v_versao_REM := GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
        End;
    End;

  log_diario('Versão Remota: "'+v_versao_REM+'" - Versão Local: "'+v_versao_LOC+'"');

  if (v_versao_REM + v_versao_LOC <> '') and
     (v_versao_LOC <> '0000') then
    Begin
      if (v_versao_REM = v_versao_LOC) then
        Result := 1
      else
        Result := 2;
    End
  else
    Result := 0;
End;

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

procedure executa_chksis;
var
  bool_download_CACIC2,
  bool_ExistsAutoRun : boolean;
  v_home_drive, v_ip_serv_cacic, v_cacic_dir, v_rem_cacic_v0x,
  v_te_serv_updates, v_nu_porta_serv_updates, v_nm_usuario_login_serv_updates,
  v_te_senha_login_serv_updates, v_te_path_serv_updates : String;
  Request_Config : TStringList;
  Response_Config : TStringStream;
  IdHTTP1: TIdHTTP;
  intAux : integer;
begin

  bool_download_CACIC2  := false;
  v_home_drive       := MidStr(HomeDrive,1,3); //x:\
  v_ip_serv_cacic    := GetValorChaveRegIni('Cacic2', 'ip_serv_cacic', ExtractFilePath(ParamStr(0)) + 'chksis.ini');
  v_cacic_dir        := GetValorChaveRegIni('Cacic2', 'cacic_dir', ExtractFilePath(ParamStr(0)) + 'chksis.ini');
  v_rem_cacic_v0x    := GetValorChaveRegIni('Cacic2', 'rem_cacic_v0x', ExtractFilePath(ParamStr(0)) + 'chksis.ini');
  Dir                := v_home_drive + v_cacic_dir;

  v_Debugs := false;
  if DirectoryExists(v_cacic_dir + '\Temp\Debugs') then
      Begin
       if (FormatDateTime('ddmmyyyy', GetFolderDate(v_cacic_dir + '\Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
         Begin
           v_Debugs := true;
           log_DEBUG('Pasta "' + v_cacic_dir + '\Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(v_cacic_dir + '\Temp\Debugs'))+' encontrada. DEBUG ativado.');
         End;
      End;

  intWinVer := GetWinVer;

  // Caso o parâmetro rem_cacic_v0x seja "S/s" removo a chave/valor de execução do Cacic antigo
  if (LowerCase(v_rem_cacic_v0x)='s') then
      begin
        //log_diario('Excluindo chave de execução do CACIC',ExtractFilePath(ParamStr(0)));
        DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic');
      end;

  // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(Dir) then
      begin
        //log_diario('Criando diretório ' + Dir,ExtractFilePath(ParamStr(0)));
        ForceDirectories(Dir);
      end;

  // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
  if not DirectoryExists(Dir+'\modulos') then
      begin
        log_diario('Excluindo '+ Dir + '\cacic2.exe');
        Matar(Dir,'\cacic2.exe');
        log_diario('Criando diretório ' + Dir + '\modulos');
        ForceDirectories(Dir + '\modulos');
      end;

  // Crio o SubDiretório TEMP, caso não exista
  if not DirectoryExists(Dir+'\temp') then
      begin
        log_diario('Criando diretório ' + Dir + '\temp');
        ForceDirectories(Dir + '\temp');
      end;


  // Igualo as chaves ip_serv_cacic e cacic dos arquivos chksis.ini e cacic2.ini!
//  log_diario('Setando chave Configs/EnderecoServidor=' + v_ip_serv_cacic + ' em '+Dir + '\cacic2.dat',ExtractFilePath(ParamStr(0)));
//  SetValorChaveRegIni('Configs', 'EnderecoServidor', v_ip_serv_cacic, Dir + '\cacic2.ini');

  //chave AES. Recomenda-se que cada empresa altere a sua chave.
  v_CipherKey    := 'CacicBrasil';
  v_IV           := 'abcdefghijklmnop';
  v_SeparatorKey := '=CacicIsFree=';
  v_DatFileName  := Dir + '\cacic2.dat';
  //v_tstrCipherOpened := CipherOpen(v_DatFileName);

  //SetValorDatMemoria('Configs.EnderecoServidor', v_ip_serv_cacic);

//  log_diario('Setando chave Configs/cacic_dir=' + v_cacic_dir + ' em '+Dir + '\cacic2.ini',ExtractFilePath(ParamStr(0)));
//  SetValorChaveRegIni('Configs', 'cacic_dir', v_cacic_dir, Dir + '\cacic2.ini');
  //SetValorDatMemoria('Configs.cacic_dir', v_cacic_dir);

  //CipherClose(v_DatFileName);
  // Verifico existência dos dois principais objetos
  If (not FileExists(Dir + '\cacic2.exe')) or (not FileExists(Dir + '\modulos\ger_cols.exe')) Then
      Begin
        // Busco as configurações para acesso ao ambiente FTP - Updates
        Request_Config                        := TStringList.Create;
        Request_Config.Values['in_chkcacic']  := 'chkcacic';
        Request_Config.Values['te_fila_ftp']  := '1'; // Indicará que o agente quer entrar no grupo para FTP
        Request_Config.Values['id_ip_estacao']:= GetIP; // Informará o IP para registro na tabela redes_grupos_FTP
        Response_Config                       := TStringStream.Create('');

        Try
          log_diario('Tentando contato com ' + 'http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php');
          IdHTTP1 := TIdHTTP.Create(nil);
          IdHTTP1.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php', Request_Config, Response_Config);
          IdHTTP1.Disconnect;
          IdHTTP1.Free;
          v_retorno := Response_Config.DataString;
          v_te_serv_updates               := XML_RetornaValor('te_serv_updates'              , Response_Config.DataString);
          v_nu_porta_serv_updates         := XML_RetornaValor('nu_porta_serv_updates'        , Response_Config.DataString);
          v_nm_usuario_login_serv_updates := XML_RetornaValor('nm_usuario_login_serv_updates', Response_Config.DataString);
          v_te_senha_login_serv_updates   := XML_RetornaValor('te_senha_login_serv_updates'  , Response_Config.DataString);
          v_te_path_serv_updates          := XML_RetornaValor('te_path_serv_updates'         , Response_Config.DataString);

          log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          log_diario(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
          log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          log_diario('Servidor de updates......................: '+v_te_serv_updates);
          log_diario('Porta do servidor de updates.............: '+v_nu_porta_serv_updates);
          log_diario('Usuário para login no servidor de updates: '+v_nm_usuario_login_serv_updates);
          log_diario('Pasta no servidor de updates.............: '+v_te_path_serv_updates);
          log_diario(' ');
          log_diario('Versões dos Agentes Principais:');
          log_diario('------------------------------');
          log_diario('Cacic2   - Agente do Systray.........: '+XML_RetornaValor('CACIC2', v_retorno));
          log_diario('Ger_Cols - Gerente de Coletas........: '+XML_RetornaValor('GER_COLS', v_retorno));
          log_diario('ChkSis   - Verificador de Integridade: '+XML_RetornaValor('CHKSIS', v_retorno));
          log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

        Except log_diario('Falha no contato com ' + 'http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php');
        End;

        Request_Config.Free;
        Response_Config.Free;

  // Verificação de versão do cacic2.exe e exclusão em caso de versão antiga
  If (FileExists(Dir + '\cacic2.exe')) Then
      Begin
        intAux := ChecaVersoesAgentes(Dir + '\cacic2.exe');
        // 0 => Arquivo de versões ou informação inexistente
        // 1 => Versões iguais
        // 2 => Versões diferentes
        if (intAux = 0) then
          Begin
            v_versao_local  := StringReplace(trim(GetVersionInfo(Dir + '\cacic2.exe')),'.','',[rfReplaceAll]);
            v_versao_remota := StringReplace(XML_RetornaValor('CACIC2' , v_retorno),'0103','',[rfReplaceAll]);
          End;

        if (intAux = 2) or // Caso haja diferença na comparação de versões com "versoes_agentes.ini"...
           (v_versao_local ='0000') or // Provavelmente versão muito antiga ou corrompida
           (v_versao_local ='2208') then
           Matar(Dir, '\cacic2.exe');
      End;

    // Verificação de versão do ger_cols.exe e exclusão em caso de versão antiga
    If (FileExists(Dir + '\modulos\ger_cols.exe')) Then
        Begin
          intAux := ChecaVersoesAgentes(Dir + '\modulos\ger_cols.exe');
          // 0 => Arquivo de versões ou informação inexistente
          // 1 => Versões iguais
          // 2 => Versões diferentes
          if (intAux = 0) then
            Begin
              v_versao_local  := StringReplace(trim(GetVersionInfo(Dir + '\modulos\ger_cols.exe')),'.','',[rfReplaceAll]);
              v_versao_remota := StringReplace(XML_RetornaValor('GER_COLS' , v_retorno),'0103','',[rfReplaceAll]);
            End;

          if (intAux = 2) or // Caso haja diferença na comparação de versões com "versoes_agentes.ini"...
             (v_versao_local ='0000') then // Provavelmente versão muito antiga ou corrompida
             Matar(Dir + '\modulos\', 'ger_cols.exe');

        End;

        // Tento detectar o Agente Principal e faço FTP caso não exista
        If not FileExists(Dir + '\cacic2.exe') Then
            begin
              log_diario('Fazendo FTP de cacic2.exe a partir de ' + v_te_serv_updates + '/' +
                                                                    v_nu_porta_serv_updates+'/'+
                                                                    v_nm_usuario_login_serv_updates + '/' +
                                                                    v_te_path_serv_updates + ' para a pasta ' + Dir);
              FTP(v_te_serv_updates,
                  v_nu_porta_serv_updates,
                  v_nm_usuario_login_serv_updates,
                  v_te_senha_login_serv_updates,
                  v_te_path_serv_updates,
                  'cacic2.exe',
                  Dir);
              bool_download_CACIC2 := true;
            end;

        // Tento detectar o Gerente de Coletas e faço FTP caso não exista
        If (not FileExists(Dir + '\modulos\ger_cols.exe')) Then
            begin
              log_diario('Fazendo FTP de ger_cols.exe a partir de ' + v_te_serv_updates + '/' +
                                                                      v_nu_porta_serv_updates+'/'+
                                                                      v_nm_usuario_login_serv_updates + '/' +
                                                                      v_te_path_serv_updates + ' para a pasta ' + Dir + '\modulos');

              FTP(v_te_serv_updates,
                  v_nu_porta_serv_updates,
                  v_nm_usuario_login_serv_updates,
                  v_te_senha_login_serv_updates,
                  v_te_path_serv_updates,
                  'ger_cols.exe',
                  Dir + '\modulos');
            end;
      End;

  // 5 segundos para espera de possível FTP...
  Sleep(5000);

  Try
    // Crio a chave/valor chksis para autoexecução do Cacic, caso não exista esta chave/valor
    log_diario('Setando chave HLM../Run com ' + HomeDrive + '\chksis.exe');
    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', HomeDrive + '\chksis.exe');
  Except
  End;

  bool_ExistsAutoRun := false;
  if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=Dir + '\cacic2.exe') then
    bool_ExistsAutoRun := true
  else
    Begin
      Try
        // Crio a chave/valor cacic2 para autoexecução do Cacic, caso não exista esta chave/valor
        log_diario('Setando chave HLM../Run com ' + Dir + '\cacic2.exe');
        SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', Dir + '\cacic2.exe');
      Except
      End;
    End;

  // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
  //if (bool_download_CACIC2) then
      //Begin
         //if not bool_ExistsAutoRun then
         // Begin
      if Posso_Rodar_CACIC or not bool_ExistsAutoRun then
        Begin
          log_diario('Executando '+Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic);

          // Caso tenha havido download de agentes principais, executar coletas imediatamente...
          if (bool_download_CACIC2) then
            WinExec(PChar(Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic+ ' /execute'), SW_HIDE)
          else
            WinExec(PChar(Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic             ), SW_HIDE);
        End;
        //  End
        // else
      log_diario('Não Executei. Chave de AutoExecução já existente...');
      //End
      Application.Terminate;
end;

begin
//  Application.ShowMainForm:=false;
  if (FindWindowByTitle('chkcacic') = 0) and (FindWindowByTitle('cacic2') = 0) then
      if (FileExists(ExtractFilePath(ParamStr(0)) + 'chksis.ini')) then executa_chksis
  else log_diario('Não executei devido execução em paralelo de "chkcacic" ou "cacic2"!');

  Halt;
  //Application.Terminate;

end.

