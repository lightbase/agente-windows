(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

---------------------------------------------------------------------------------------------------------------------------------------------------------------
=====================================================================================================
ChkCacic.exe : Verificador/Instalador dos agentes principais Cacic2.exe e Ger_Cols.exe
=====================================================================================================
v 2.2.0.14
+ Cr�ticas/mensagens:
  "ATEN��O! N�o foi poss�vel estabelecer comunica��o com o m�dulo Gerente WEB em <servidor>." e
  "ATEN��O: N�o foi poss�vel efetuar FTP para <agente>. Verifique o Servidor de Updates."
+ Op��o checkbox "Exibe informa��es sobre o processo de instala��o" ao formul�rio de configura��o;
+ Bot�o "Sair" ao formul�rio de configura��o;
+ Execu��o autom�tica do Agente Principal ao fim da instala��o quando a unidade origem do ChkCacic n�o
  for mapeamento de rede ou unidade inv�lida.

- Retirados os campos "Frase para Sucesso na Instala��o" e "Frase para Insucesso na Instala��o"
  do formul�rio de configura��o, passando essas frases a serem fixas na aplica��o.
- Retirada a op��o radiobutton "Remove Vers�o Anterior?";

=====================================================================================================
*)


unit main;

interface

uses  Windows,
      strUtils,
      SysUtils,
      Classes,
      Forms,
      Registry,
      Inifiles,
      idFTPCommon,
      XML,
      LibXmlParser,
      IdHTTP,
      dialogs,
      PJVersionInfo,
      Controls,
      StdCtrls,
      IdBaseComponent,
      IdComponent,
      IdTCPConnection,
      IdTCPClient,
      variants,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64,
      NTFileSecurity, IdFTP,
      Tlhelp32;

var   v_ip_serv_cacic,
      v_cacic_dir,
//      v_rem_cacic_v0x,
      v_te_instala_frase_sucesso,
      v_te_instala_frase_insucesso,
      v_te_instala_informacoes_extras,
      v_exibe_informacoes,
      v_versao_local,
      v_versao_remota_inteira,
      v_versao_remota_capada,
      v_CipherKey,
      v_SeparatorKey,
      v_IV,
      v_strCipherClosed,
      v_strCipherOpened,
      v_DatFileName     : String;

var   v_tstrCipherOpened        : TStrings;

// Constantes a serem usadas pela fun��o IsAdmin...
const constSECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
      constSECURITY_BUILTIN_DOMAIN_RID = $00000020;
      constDOMAIN_ALIAS_RID_ADMINS = $00000220;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

Procedure chkcacic;
Procedure CriaFormConfigura;
Procedure MostraFormConfigura;
Procedure GravaConfiguracoes;
Procedure DelValorReg(Chave: String);
procedure log_diario(strMsg : String);
Function ListFileDir(Path: string):string;
Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
Function Explode(Texto, Separador : String) : TStrings;
Function GetRootKey(strRootKey: String): HKEY;
Function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
Function GetValorChaveRegEdit(Chave: String): Variant;
function SetValorChaveRegIni(p_Secao, p_Chave, p_Valor, p_File : String): String;
function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
function HomeDrive : string;
Function RemoveCaracteresEspeciais(Texto : String) : String;
function FindWindowByTitle(WindowTitle: string): Hwnd;
function GetVersionInfo(p_File: string):string;
function VerFmt(const MS, LS: DWORD): string;
function GetWinVer: Integer;
function KillTask(ExeFileName: string): Integer;
procedure KillProcess(hWindowHandle: HWND);

type
  TForm1 = class(TForm)
    PJVersionInfo1: TPJVersionInfo;
    IdFTP1: TIdFTP;
    FS: TNTFileSecurity;
    procedure FormCreate(Sender: TObject);
    procedure FS_SetSecurity(p_Target : String);
  end;

var
  Form1: TForm1;
  Dir, ENDERECO_SERV_CACIC,
  v_home_drive : string;
implementation

uses FormConfig;

{$R *.dfm}
function IsAdmin: Boolean;
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

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
begin
   try
       FileSetAttr (v_home_drive + 'chkcacic.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(HistoricoLog,v_home_drive + 'chkcacic.log'); {Associa o arquivo a uma vari�vel do tipo TextFile}

       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Instalador] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
       //Erro na grava��o do log!
       //Application.Terminate;
   end;
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

Function CipherClose(p_DatFileName : string) : String;
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma vari�vel do tipo TextFile}

       // Recria��o do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       v_strCipherOpenImploded := Implode(v_tstrCipherOpened,v_SeparatorKey);
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);

       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(v_DatFile);
   except
   end;
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
      if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
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
      Result := explode('Configs.ID_SO'+v_SeparatorKey+inttostr(GetWinVer)+v_SeparatorKey+'Configs.Endereco_WS'+v_SeparatorKey+'/cacic2/ws/',v_SeparatorKey);


    if Result.Count mod 2 <> 0 then
        Result.Add('');

end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String);
begin
    log_diario('Setando Chave "'+p_Chave+'" com "'+p_Valor+'"');
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        v_tstrCipherOpened.Add(p_Chave);
        v_tstrCipherOpened.Add(p_Valor);
      End;
end;

Function GetValorDatMemoria(p_Chave : String) : String;
begin
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
end;


function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function GetWinVer: Integer;
const
  { operating system (OS)constants }
  cOsUnknown    = 0;
  cOsWin95      = 1;
  cOsWin95OSR2  = 2;  // N�o implementado.
  cOsWin98      = 3;
  cOsWin98SE    = 4;
  cOsWinME      = 5;
  cOsWinNT      = 6;
  cOsWin2000    = 7;
  cOsXP         = 8;
  cOsServer2003 = 13;
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
end;



function GetVersionInfo(p_File: string):string;
begin
  Form1.PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(Form1.PJVersionInfo1.FixedFileInfo.dwFileVersionMS, Form1.PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
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
     else strAux := strAux + ' ';  // Coloca um espa�o onde houver caracteres especiais
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

//Para gravar no Arquivo INI...
function SetValorChaveRegIni(p_Secao, p_Chave, p_Valor, p_File : String): String;
var Reg_Ini     : TIniFile;
begin
//    FileSetAttr (p_File,0);
    {
    To remove write protection on a file:
    Den Schreibschutz einer Datei aufheben:
    }
    if (FileGetAttr(p_File) and faReadOnly) > 0 then
      FileSetAttr(p_File, FileGetAttr(p_File) xor faReadOnly);

    Reg_Ini := TIniFile.Create(p_File);
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
//Para buscar do Arquivo INI...
// Marreta devido a limita��es do KERNEL w9x no tratamento de arquivos texto e suas se��es
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

Procedure CriaFormConfigura;
begin
  Application.CreateForm(TConfigs, FormConfig.Configs);
  FormConfig.Configs.Label2.Caption := 'v: ' + getVersionInfo(ParamStr(0));
end;

Procedure MostraFormConfigura;
begin
  FormConfig.Configs.ShowModal;
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
        If ((Copy(Texto,I,TamanhoSeparador) = Separador) and (Texto[I-1]<>'?')) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + Texto[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
          if (Texto[I]<>'?') then strItem := strItem + Texto[I];
        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
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
    Try
      if IdFTP.Connected = true then
        begin
          IdFTP.Disconnect;
        end;
      IdFTP.Connect(true);
      IdFTP.ChangeDir(p_PathServer);
      Try
        IdFTP.Get(p_File, p_Dest + '\' + p_File, True);
        result := true;
      Except
        result := false;
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

procedure GravaConfiguracoes;
var chkcacic_ini : TextFile;
begin
   try
       FileSetAttr (ExtractFilePath(Application.Exename) + '\chkcacic.ini',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
       AssignFile(chkcacic_ini,ExtractFilePath(Application.Exename) + '\chkcacic.ini'); {Associa o arquivo a uma vari�vel do tipo TextFile}
       Rewrite (chkcacic_ini); // Recria o arquivo...
       Append(chkcacic_ini);
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# A edi��o deste arquivo tamb�m pode ser feita com o comando "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OBRIGAT�RIOS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# ip_serv_cacic');
       Writeln(chkcacic_ini,'#          Endere�o IP ou Nome(DNS) do servidor onde o M�dulo Gerente do CACIC foi instalado');
       Writeln(chkcacic_ini,'#          Ex1.: ip_serv_cacic=10.xxx.yyy.zzz');
       Writeln(chkcacic_ini,'#          Ex2.: ip_serv_cacic=uxesa001');
       Writeln(chkcacic_ini,'# cacic_dir');
       Writeln(chkcacic_ini,'#          Pasta a ser criada na esta��o para instala��o do CACIC agente');
       Writeln(chkcacic_ini,'#          Ex.: cacic_dir=Cacic');
       Writeln(chkcacic_ini,'# exibe_informacoes');
       Writeln(chkcacic_ini,'#          Indicador de exibicao de informa��es sobre o processo de instala��o');
       Writeln(chkcacic_ini,'#          Ex.: exibe_informacoes=N');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OPCIONAIS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# (ATEN��O: N�O PREENCHER EM CASO DE CHKCACIC.INI PARA O NETLOGON!)');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# te_instala_informacoes_extras');
       Writeln(chkcacic_ini,'#          Informa��es a serem mostradas na janela de Instala��o/Recupera��o');
       Writeln(chkcacic_ini,'#          Ex.: Empresa-UF / Suporte T�cnico');
       Writeln(chkcacic_ini,'#                  Emails: email_do_suporte@xxxxxx.yyy.zz, outro_email@outro_dominio.xxx.yy');
       Writeln(chkcacic_ini,'#                  Telefones: (xx) yyyy-zzzz  /  (xx) yyyy-zzzz');
       Writeln(chkcacic_ini,'#                  Endere�o: Rua Nome_da_Rua, N� 99999');
       Writeln(chkcacic_ini,'#                            Cidade/UF');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# Recomenda��o Importante:');
       Writeln(chkcacic_ini,'# =======================');
       Writeln(chkcacic_ini,'# Para benef�cio da rede local, criar uma pasta "modulos" no mesmo n�vel do chkcacic.exe, onde dever�o');
       Writeln(chkcacic_ini,'# ser colocados todos os arquivos execut�veis para uso do CACIC, pois, quando da necessidade de download');
       Writeln(chkcacic_ini,'# de m�dulo, o arquivo ser� apenas copiado e n�o ser� necess�rio o FTP:');
       Writeln(chkcacic_ini,'# cacic2.exe ............=> Agente Principal');
       Writeln(chkcacic_ini,'# ger_cols.exe ..........=> Gerente de Coletas');
       Writeln(chkcacic_ini,'# chksis.exe ............=> Check System Routine (chkcacic residente)');
       Writeln(chkcacic_ini,'# ini_cols.exe ..........=> Inicializador de Coletas');
       Writeln(chkcacic_ini,'# wscript.exe ...........=> Motor de Execu��o de Scripts VBS');
       Writeln(chkcacic_ini,'# col_anvi.exe ..........=> Agente Coletor de Informa��es de Anti-V�rus');
       Writeln(chkcacic_ini,'# col_comp.exe ..........=> Agente Coletor de Informa��es de Compartilhamentos');
       Writeln(chkcacic_ini,'# col_hard.exe ..........=> Agente Coletor de Informa��es de Hardware');
       Writeln(chkcacic_ini,'# col_moni.exe ..........=> Agente Coletor de Informa��es de Sistemas Monitorados');
       Writeln(chkcacic_ini,'# col_patr.exe ..........=> Agente Coletor de Informa��es de Patrim�nio e Localiza��o F�sica');
       Writeln(chkcacic_ini,'# col_soft.exe ..........=> Agente Coletor de Informa��es de Software');
       Writeln(chkcacic_ini,'# col_undi.exe ..........=> Agente Coletor de Informa��es de Unidades de Disco');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Exemplo de estrutura para KIT (CD) de instala��o');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# d:\chkcacic.exe');
       Writeln(chkcacic_ini,'# d:\chkcacic.ini');
       Writeln(chkcacic_ini,'#        \modulos');
       Writeln(chkcacic_ini,'#             cacic2.exe');
       Writeln(chkcacic_ini,'#             chksis.exe');
       Writeln(chkcacic_ini,'#             col_anvi.exe');
       Writeln(chkcacic_ini,'#             col_comp.exe');
       Writeln(chkcacic_ini,'#             col_hard.exe');
       Writeln(chkcacic_ini,'#             col_moni.exe');
       Writeln(chkcacic_ini,'#             col_patr.exe');
       Writeln(chkcacic_ini,'#             col_soft.exe');
       Writeln(chkcacic_ini,'#             col_undi.exe');
       Writeln(chkcacic_ini,'#             ger_cols.exe');
       Writeln(chkcacic_ini,'#             ini_cols.exe');
       Writeln(chkcacic_ini,'#             wscript.exe');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Obs.: Antes da grava��o do CD ou imagem, � necess�rio executar "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'[Cacic2]');

       // Atribui��o dos valores do form FormConfig �s vari�veis...
       v_ip_serv_cacic                 := Configs.Edit_ip_serv_cacic.text;
       v_cacic_dir                     := Configs.Edit_cacic_dir.text;
       if Configs.ckboxExibeInformacoes.Checked then
         v_exibe_informacoes             := 'S'
       else
         v_exibe_informacoes             := 'N';

       v_te_instala_informacoes_extras := Configs.Memo_te_instala_informacoes_extras.Text;

       // Escrita dos par�metros obrigat�rios
       Writeln(chkcacic_ini,'ip_serv_cacic='+v_ip_serv_cacic);
       Writeln(chkcacic_ini,'cacic_dir='+v_cacic_dir);
       Writeln(chkcacic_ini,'exibe_informacoes='+v_exibe_informacoes);

       // Escrita dos valores opcionais quando existirem
       if (v_te_instala_informacoes_extras <>'') then
          Writeln(chkcacic_ini,'te_instala_informacoes_extras='+ StringReplace(v_te_instala_informacoes_extras,#13#10,'*13*10',[rfReplaceAll]));
       CloseFile(chkcacic_ini); {Fecha o arquivo texto}
   except
   end;
end;

Function ListFileDir(Path: string):string;
var
  SR: TSearchRec;
  FileList : string;
begin
  if FindFirst(Path, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) then
      begin
        if (FileList<>'') then FileList := FileList + '#';
        FileList := FileList + SR.Name;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
    Result := FileList;
  end;
end;
procedure LiberaFireWall(p_objeto:string);
begin
  Try
    if (trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll])))='') then
      Begin
        SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll]),p_objeto+'.exe:*:Enabled:'+p_objeto);
        log_diario('Libera��o de FireWall para "'+p_objeto+'" efetivada!');
      End
    else log_diario('Libera��o de FireWall para "'+p_objeto+'" j� existente.');
  Except
    log_diario('Problema Liberando FireWall para "'+p_objeto+'"!');
  End;

end;

// Dica obtida em http://www.webmundi.com/delphi/dfuncaof.asp?SubTipo=Sistema
Function DriveType(Unidade: String):String;
Var StrDrive,
    StrDriveType : String;
    intDriveType : Integer;
begin
  StrDrive := Unidade;
  If StrDrive[Length(StrDrive)] <> '\' Then
     StrDrive := StrDrive + ':\';

  intDriveType := GetDriveType(PChar(StrDrive));
  Case intDriveType Of
     0                : StrDriveType := 'ERRO';
     1                : StrDriveType := 'ERRO';
     DRIVE_REMOVABLE  : StrDriveType := 'FLOPPY';
     DRIVE_FIXED      : StrDriveType := 'HD';
     DRIVE_REMOTE     : StrDriveType := 'REDE';
     DRIVE_CDROM      : StrDriveType := 'CDROM';
     DRIVE_RAMDISK    : StrDriveType := 'RAM';
  end;
  Result := StrDriveType;
End;

procedure chkcacic;
var bool_download_CACIC2,
    bool_download_GER_COLS,
    bool_configura,
    bool_ExistsAutoRun : boolean;

    v_te_serv_updates,
    v_nu_porta_serv_updates,
    v_nm_usuario_login_serv_updates,
    v_te_senha_login_serv_updates,
    v_te_path_serv_updates,
    v_te_texto_janela_instalacao,
    v_modulos,
    v_retorno,
    strAux : String;

    Request_Config  : TStringList;
    v_array_modulos : TStrings;
    Response_Config : TStringStream;
    IdHTTP1: TIdHTTP;
    intAux : integer;
begin
  v_te_instala_frase_sucesso      := 'INSTALA��O/ATUALIZA��O EFETUADA COM SUCESSO!';
  v_te_instala_frase_insucesso    := '*****  INSTALA��O/ATUALIZA��O N�O EFETUADA COM SUCESSO  *****';

  Try
  v_home_drive                    := MidStr(HomeDrive,1,3); //x:\
  If not (FileExists(ExtractFilePath(Application.Exename) + '\chkcacic.ini')) then
      Begin
          log_diario('Abrindo formul�rio de configura��es');
          CriaFormConfigura;
          MostraFormConfigura;
      End;

  bool_download_CACIC2            := false;
  bool_download_GER_COLS          := false;
  v_ip_serv_cacic                 := GetValorChaveRegIni('Cacic2', 'ip_serv_cacic'    , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
  v_cacic_dir                     := GetValorChaveRegIni('Cacic2', 'cacic_dir'        , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
  v_exibe_informacoes             := GetValorChaveRegIni('Cacic2', 'exibe_informacoes', ExtractFilePath(Application.Exename) + '\chkcacic.ini');
  v_te_instala_informacoes_extras := StringReplace(GetValorChaveRegIni('Cacic2', 'te_instala_informacoes_extras', ExtractFilePath(Application.Exename) + '\chkcacic.ini'),'*13*10',#13#10,[rfReplaceAll]);
  Dir                             := v_home_drive + v_cacic_dir; // Ex.: c:\cacic\

  // Verifico se o S.O. � NT Like e se o Usu�rio est� com privil�gio administrativo...
  if (GetWinVer >= 6) and
     (v_exibe_informacoes = 'S') and
     not IsAdmin then // Se NT/2000/XP/...
    Begin
      MessageDLG(#13#10+'ATEN��O! Essa aplica��o requer execu��o com n�vel administrativo.',mtError,[mbOK],0);
    End
  else
    Begin
      log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      log_diario(':::::::::::::: OBTENDO VALORES DO "chkcacic.ini" ::::::::::::::');
      log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      log_diario('Drive de instala��o......................: '+v_home_drive);
      log_diario('Pasta para instala��o....................: '+Dir);
      log_diario('IP do servidor...........................: '+v_ip_serv_cacic);
      log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      bool_configura := false;

      //chave AES. Recomenda-se que cada empresa/�rg�o altere a sua chave.
      v_CipherKey    := 'CacicBrasil';
      v_IV           := 'abcdefghijklmnop';
      v_SeparatorKey := '=CacicIsFree='; // Usada apenas para o cacic2.dat
      v_DatFileName  := Dir + '\cacic2.dat';
      v_tstrCipherOpened := CipherOpen(v_DatFileName);


      if (GetWinVer >= 8) then // Se >= WinXP...
        Begin
          Try
            // Acrescento os valores para uso do FireWall nativo...

            {chkcacic}
            LiberaFireWall(ExtractFilePath(Application.Exename) + 'chkcacic');

            {chksis}
            LiberaFireWall(HomeDrive + '\chksis');

            {ger_cols}
            LiberaFireWall(Dir + '\modulos\ger_cols');

          Except
          End;
        End;


      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then bool_configura := true;

      while (v_ip_serv_cacic = '') or (v_cacic_dir = '') or bool_configura do
          Begin
              log_diario('Abrindo formul�rio de configura��es');
              bool_configura := false;
              CriaFormConfigura;
              Configs.Edit_ip_serv_cacic.text                 := v_ip_serv_cacic;
              Configs.Edit_cacic_dir.text                     := v_cacic_dir;
              if v_exibe_informacoes = 'S' then
                Configs.ckboxExibeInformacoes.Checked   := true
              else
                Configs.ckboxExibeInformacoes.Checked   := false;
              Configs.Memo_te_instala_informacoes_extras.text := v_te_instala_informacoes_extras;
              MostraFormConfigura;
          End;

      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then application.Terminate;

      // Caso o par�metro rem_cacic_v0x seja "S/s" removo a chave/valor de execu��o do Cacic antigo
      //if (LowerCase(v_rem_cacic_v0x)='s') then
      //      DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic');

      // Verifico a exist�ncia do diret�rio configurado para o Cacic, normalmente CACIC
      if not DirectoryExists(Dir) then
          begin
            log_diario('Criando pasta '+Dir);
            ForceDirectories(Dir);
          end;

      // Para eliminar vers�o 20014 e anteriores que provavelmente n�o fazem corretamente o AutoUpdate
      if not DirectoryExists(Dir+'\modulos') then
          begin
            if DeleteFile(Dir + '\cacic2.exe') then
              log_diario('Exclus�o de '+Dir + '\cacic2.exe' + ' efetuada com sucesso!')
            else
              Begin
                log_diario('Exclus�o n�o efetuada! Provavelmente j� esteja sendo executado...');
                log_diario('Tentarei finalizar Tarefa/Processo...');
                if (GetWinVer <= 5) then // At�
                  KillTask('cacic2.exe')
                else
                  KillProcess(FindWindow('cacic2.exe',nil));
                if DeleteFile(Dir + '\cacic2.exe') then
                  log_diario('Exclus�o Impossibilitada de '+Dir + '\cacic2.exe' + '!');
              End;

            ForceDirectories(Dir + '\modulos');
            log_diario('Criando pasta '+Dir+'\modulos');
          end;

      // Crio o SubDiret�rio TEMP, caso n�o exista
      if not DirectoryExists(Dir+'\temp') then
          begin
            ForceDirectories(Dir + '\temp');
            log_diario('Criando pasta '+Dir+'\temp');
          end;


      // Tento o contato com o m�dulo gerente WEB para obten��o de
      // dados para conex�o FTP e relativos �s vers�es atuais dos principais agentes
      // Busco as configura��es para acesso ao ambiente FTP - Updates
      Request_Config                       := TStringList.Create;
      Request_Config.Values['in_chkcacic'] := 'chkcacic';
      Response_Config                      := TStringStream.Create('');

      Try
        IdHTTP1 := TIdHTTP.Create(IdHTTP1);
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
        idHTTP1.Request.Accept                   := 'text/html, */*';
        idHTTP1.Request.BasicAuthentication      := true;
        idHTTP1.Request.ContentLength            := -1;
        idHTTP1.Request.ContentRangeStart        := 0;
        idHTTP1.Request.ContentRangeEnd          := 0;
        idHTTP1.Request.ContentType              := 'text/html';
        idHTTP1.SendBufferSize                   := 32768;
        idHTTP1.Tag                              := 0;
        log_diario('Iniciando comunica��o com '+'http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php');
        IdHTTP1.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php', Request_Config, Response_Config);
        idHTTP1.Free;
        v_retorno := Response_Config.DataString;
        v_te_serv_updates               := XML_RetornaValor('te_serv_updates'              , v_retorno);
        v_nu_porta_serv_updates         := XML_RetornaValor('nu_porta_serv_updates'        , v_retorno);
        v_nm_usuario_login_serv_updates := XML_RetornaValor('nm_usuario_login_serv_updates', v_retorno);
        v_te_senha_login_serv_updates   := XML_RetornaValor('te_senha_login_serv_updates'  , v_retorno);
        v_te_path_serv_updates          := XML_RetornaValor('te_path_serv_updates'         , v_retorno);

        //log_diario('Retorno da comunica��o: '+v_retorno);

        log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        log_diario(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
        log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        log_diario('Servidor de updates......................: '+v_te_serv_updates);
        log_diario('Porta do servidor de updates.............: '+v_nu_porta_serv_updates);
        log_diario('Usu�rio para login no servidor de updates: '+v_nm_usuario_login_serv_updates);
        log_diario('Pasta no servidor de updates.............: '+v_te_path_serv_updates);
        log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      Except
        Begin
          if v_exibe_informacoes = 'S' then
            MessageDLG(#13#10+'ATEN��O! N�o foi poss�vel estabelecer comunica��o com o m�dulo Gerente WEB em "'+v_ip_serv_cacic+'".',mtError,[mbOK],0);
          log_diario('**********************************************************');
          log_diario('Oops! N�o Foi Poss�vel Comunicar com o M�dulo Gerente WEB!');
          log_diario('**********************************************************');
        End
      End;
      Request_Config.Free;
      Response_Config.Free;

      // Verifica��o de vers�o do cacic2.exe e exclus�o em caso de vers�o antiga
      If (FileExists(Dir + '\cacic2.exe')) Then
          Begin
           v_versao_local   := trim(GetVersionInfo(Dir + '\cacic2.exe'));
           v_versao_local   := StringReplace(v_versao_local,'.','',[rfReplaceAll]);

           v_versao_remota_inteira  := XML_RetornaValor('CACIC2' , v_retorno);
           v_versao_remota_capada  := Copy(v_versao_remota_inteira,1,StrLen(PAnsiChar(v_versao_remota_inteira))-4);

            if not (v_versao_remota_inteira = '') then
              log_diario('Vers�o remota de "cacic2.exe": '+v_versao_remota_capada + '('+v_versao_remota_inteira+')');

           if (v_versao_local ='0000') or // Provavelmente vers�o muito antiga ou corrompida
              (v_versao_local ='2208') then
//              (v_versao_local <> v_versao_remota_capada) then
              Begin
                log_diario('Excluindo vers�o "'+v_versao_local+'" de Cacic2.exe');
                if DeleteFile(Dir + '\cacic2.exe') then
                  log_diario('Exclus�o de '+Dir + '\cacic2.exe'+' efetuada com sucesso!')
                else
                  Begin
                    log_diario('Exclus�o n�o efetuada! Provavelmente j� esteja sendo executado...');
                    log_diario('Tentarei finalizar Tarefa/Processo...');
                    if (GetWinVer <= 5) then // At�
                      KillTask('cacic2.exe')
                    else
                      KillProcess(FindWindow('cacic2.exe',nil));
                    if DeleteFile(Dir + '\cacic2.exe') then
                      log_diario('Exclus�o Impossibilitada de '+Dir + '\cacic2.exe' + '!');
                  End;
              End;
          End;

      // Verifica��o de vers�o do ger_cols.exe e exclus�o em caso de vers�o antiga
      If (FileExists(Dir + '\modulos\ger_cols.exe')) Then
          Begin
          v_versao_local := trim(GetVersionInfo(Dir + '\modulos\ger_cols.exe'));
          v_versao_local   := StringReplace(v_versao_local,'.','',[rfReplaceAll]);

          v_versao_remota_inteira  := XML_RetornaValor('GER_COLS' , v_retorno);
          v_versao_remota_capada  := Copy(v_versao_remota_inteira,1,StrLen(PAnsiChar(v_versao_remota_inteira))-4);

          if not (v_versao_remota_inteira = '') then
            log_diario('Vers�o remota de "ger_cols.exe": '+v_versao_remota_capada+ '('+v_versao_remota_inteira+')');

          if (v_versao_local ='0000') then //or // Provavelmente vers�o muito antiga ou corrompida
//             (v_versao_local <> v_versao_remota_capada) then
              Begin
                log_diario('Excluindo vers�o "'+v_versao_local+'" de Ger_Cols.exe');
                if DeleteFile(Dir + '\modulos\ger_cols.exe') then
                  log_diario('Exclus�o de '+Dir + '\modulos\ger_cols.exe'+' efetuada com sucesso!')
                else
                  Begin
                    log_diario('Exclus�o n�o efetuada! Provavelmente j� esteja sendo executado...');
                    log_diario('Tentarei finalizar Tarefa/Processo...');
                    if (GetWinVer <= 5) then // At�
                      KillTask('ger_cols.exe')
                    else
                      KillProcess(FindWindow('ger_cols.exe',nil));
                    if DeleteFile(Dir + '\modulos\ger_cols.exe') then
                      log_diario('Exclus�o Impossibilitada de '+Dir + '\modulos\ger_cols.exe' + '!');
                  End;
              End;
          End;


      // Verifica��o de vers�o do chksis.exe e exclus�o em caso de vers�o antiga
      If (FileExists(HomeDrive + '\chksis.exe')) Then
          Begin
          v_versao_local := trim(GetVersionInfo(HomeDrive + '\chksis.exe'));
          v_versao_local   := StringReplace(v_versao_local,'.','',[rfReplaceAll]);

          v_versao_remota_inteira  := XML_RetornaValor('CHKSIS' , v_retorno);
          v_versao_remota_capada  := Copy(v_versao_remota_inteira,1,StrLen(PAnsiChar(v_versao_remota_inteira))-4);

          if not (v_versao_remota_inteira = '') then
            log_diario('Vers�o remota de "chksis.exe": '+v_versao_remota_capada+ '('+v_versao_remota_inteira+')');

          if (v_versao_local ='0000') then //or // Provavelmente vers�o muito antiga ou corrompida
//             (v_versao_local <> v_versao_remota_capada) then
              Begin
                log_diario('Excluindo vers�o "'+v_versao_local+'" de ChkSis.exe');
                if DeleteFile(HomeDrive + '\chksis.exe') then
                  log_diario('Exclus�o de '+HomeDrive + '\chksis.exe'+' efetuada com sucesso!')
                else
                  Begin
                    log_diario('Exclus�o n�o efetuada! Provavelmente j� esteja sendo executado...');
                    log_diario('Tentarei finalizar Tarefa/Processo...');
                    if (GetWinVer <= 5) then // At�
                      KillTask('chksis.exe')
                    else
                      KillProcess(FindWindow('chksis.exe',nil));
                    if DeleteFile(HomeDrive + '\chksis.exe') then
                      log_diario('Exclus�o Impossibilitada de '+HomeDrive + '\chksis.exe' + '!');
                  End;

                End;
          End;

      // Tento detectar o ChkSis.EXE e copio ou fa�o FTP caso n�o exista
      If not FileExists(HomeDrive + '\chksis.exe') Then
          begin
            if (FileExists(ExtractFilePath(Application.Exename) + 'modulos\chksis.exe')) then
              Begin
                log_diario('Copiando ChkSis.exe de '+ExtractFilePath(Application.Exename)+'modulos\');
                CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\chksis.exe'), PChar(HomeDrive + '\chksis.exe'),false);
                FileSetAttr (PChar(HomeDrive + '\chksis.exe'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
              End
            else
              Begin
                if not FTP(v_te_serv_updates,
                           v_nu_porta_serv_updates,
                           v_nm_usuario_login_serv_updates,
                           v_te_senha_login_serv_updates,
                           v_te_path_serv_updates,
                           'chksis.exe',
                           HomeDrive) and (v_exibe_informacoes = 'S') then
                  MessageDLG(#13#10+'ATEN��O! N�o foi poss�vel efetuar FTP para "'+HomeDrive + '\chksis.exe".'+#13#10+'Verifique o Servidor de Updates.',mtError,[mbOK],0);

                If not FileExists(HomeDrive + '\chksis.exe') Then
                  Begin
                    log_diario('Problemas Efetuando Download de ChkSis.exe(FTP):');
                    log_diario('v_te_serv_updates:'+v_te_serv_updates);
                    log_diario('v_nu_porta_serv_updates:'+v_nu_porta_serv_updates);
                    log_diario('v_nm_usuario_login_serv_updates:'+v_nm_usuario_login_serv_updates);
                    log_diario('v_te_senha_login_serv_updates:'+v_te_senha_login_serv_updates);
                    log_diario('v_te_path_serv_updates:'+v_te_path_serv_updates);
                  End
                else log_diario('Download Conclu�do de ChkSis.exe (FTP)');

              End;
          end;

      // Tento detectar o ChkSis.INI e crio-o apartir do chkcacic.ini
      If not FileExists(HomeDrive + '\chksis.ini') Then
          begin
            log_diario('Criando ChkSis.ini');
            CopyFile(PChar(ExtractFilePath(Application.Exename) + 'chkcacic.ini'), PChar(HomeDrive + '\chksis.ini'),false);
            FileSetAttr ( PChar(HomeDrive + '\chksis.ini'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
          end;

      // Tento detectar o cacic2.INI e crio-o apartir do chkcacic.ini
      If not FileExists(Dir + '\cacic2.ini') Then
          begin
            CopyFile(PChar(ExtractFilePath(Application.Exename) + 'chkcacic.ini'), PChar(Dir + '\cacic2.ini'),false)
          end;

      // Verifico se existe a pasta "modulos"
      v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'\modulos\*.exe');
      if (v_modulos <> '') then log_diario('Pasta "Modulos" encontrada..');

      // Tento detectar o Agente Principal e copio ou fa�o FTP caso n�o exista
      If not FileExists(Dir + '\cacic2.exe') Then
        Begin
          if (FileExists(ExtractFilePath(Application.Exename) + '\modulos\cacic2.exe')) then
            Begin
              log_diario('Copiando Cacic2.exe de '+ExtractFilePath(Application.Exename)+'modulos\');
              CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\cacic2.exe'), PChar(Dir + '\cacic2.exe'),false);
              FileSetAttr (PChar(Dir + '\cacic2.exe'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
              bool_download_CACIC2 := true;
            End
          else
            begin
              if not FTP(v_te_serv_updates,
                         v_nu_porta_serv_updates,
                         v_nm_usuario_login_serv_updates,
                         v_te_senha_login_serv_updates,
                         v_te_path_serv_updates,
                         'cacic2.exe',
                         Dir) and (v_exibe_informacoes = 'S') then
                  MessageDLG(#13#10+'ATEN��O! N�o foi poss�vel efetuar FTP para "'+Dir + '\cacic2.exe".'+#13#10+'Verifique o Servidor de Updates.',mtError,[mbOK],0);

              bool_download_CACIC2 := true;

              If not FileExists(Dir + '\cacic2.exe') Then
                  Begin
                    log_diario('Problemas Efetuando Download de Cacic2.exe(FTP):');
                    log_diario('v_te_serv_updates:'+v_te_serv_updates);
                    log_diario('v_nu_porta_serv_updates:'+v_nu_porta_serv_updates);
                    log_diario('v_nm_usuario_login_serv_updates:'+v_nm_usuario_login_serv_updates);
                    log_diario('v_te_senha_login_serv_updates:'+v_te_senha_login_serv_updates);
                    log_diario('v_te_path_serv_updates:'+v_te_path_serv_updates);
                    bool_download_CACIC2 := false;
                  End
              else log_diario('Download Conclu�do de Cacic2.exe (FTP)');

            end;
        End;
      // Tento detectar o Gerente de Coletas e copio ou fa�o FTP caso n�o exista
      If (not FileExists(Dir + '\modulos\ger_cols.exe')) Then
        Begin
          if (FileExists(ExtractFilePath(Application.Exename) + '\modulos\ger_cols.exe')) then
            Begin
              log_diario('Copiando Ger_Cols.exe de '+ExtractFilePath(Application.Exename)+'modulos\');
              CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\ger_cols.exe'), PChar(Dir + '\modulos\ger_cols.exe'),false);
              FileSetAttr (PChar(Dir + '\modulos\ger_cols.exe'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
              bool_download_GER_COLS := true;
            End
          else
            begin
              if not FTP(v_te_serv_updates,
                         v_nu_porta_serv_updates,
                         v_nm_usuario_login_serv_updates,
                         v_te_senha_login_serv_updates,
                         v_te_path_serv_updates,
                         'ger_cols.exe',
                         Dir + '\modulos') and (v_exibe_informacoes = 'S') then
                  MessageDLG(#13#10+'ATEN��O! N�o foi poss�vel efetuar FTP para "'+Dir + '\modulos\ger_cols.exe".'+#13#10+'Verifique o Servidor de Updates.',mtError,[mbOK],0);

              bool_download_GER_COLS := true;
              If (not FileExists(Dir + '\modulos\ger_cols.exe')) Then
                  Begin
                    log_diario('Problemas Efetuando Download de Ger_Cols.exe(FTP):');
                    log_diario('v_te_serv_updates:'+v_te_serv_updates);
                    log_diario('v_nu_porta_serv_updates:'+v_nu_porta_serv_updates);
                    log_diario('v_nm_usuario_login_serv_updates:'+v_nm_usuario_login_serv_updates);
                    log_diario('v_te_senha_login_serv_updates:'+v_te_senha_login_serv_updates);
                    log_diario('v_te_path_serv_updates:'+v_te_path_serv_updates);
                    bool_download_GER_COLS := false;
                  End
              else log_diario('Download Conclu�do de Ger_Cols.exe (FTP)');

            end;
        End;

        // Caso exista a pasta "modulos", copio todos os execut�veis para a pasta Cacic\modulos, exceto cacic2.exe, ger_cols.exe e chksis.exe
        if (v_modulos <> '') then
          Begin
            v_array_modulos := explode(v_modulos,'#');
            For intAux := 0 To v_array_modulos.count -1 Do
              Begin
                if (v_array_modulos[intAux]<>'cacic2.exe') and
                   (v_array_modulos[intAux]<>'ger_cols.exe') and
                   (v_array_modulos[intAux]<>'chksis.exe') then
                  Begin
                    log_diario('Copiando '+v_array_modulos[intAux]+' de '+ExtractFilePath(Application.Exename)+'modulos\');
                    CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\'+v_array_modulos[intAux]), PChar(Dir + '\modulos\'+v_array_modulos[intAux]),false);
                    FileSetAttr (PChar(Dir + '\modulos\'+v_array_modulos[intAux]),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em m�quinas 2000
                  End;
              End;
          End;

      log_diario('Gravando registros para auto-execu��o');

      // Crio a chave/valor cacic2 para autoexecu��o do Cacic, caso n�o exista esta chave/valor
      // Crio a chave/valor chksis para autoexecu��o do ChkSIS, caso n�o exista esta chave/valor
      SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', HomeDrive + '\chksis.exe');

      bool_ExistsAutoRun := false;
      if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=Dir + '\cacic2.exe') then
        bool_ExistsAutoRun := true
      else
        SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', Dir + '\cacic2.exe');

      // Igualo as chaves ip_serv_cacic dos arquivos chksis.ini e cacic2.ini!
      SetValorDatMemoria('Configs.EnderecoServidor', v_ip_serv_cacic);
      log_diario('Fechando Arquivo de Configura��es do CACIC');
      CipherClose(v_DatFileName);
      log_diario('Abrindo Arquivo de Configura��es do CHKSIS');
      CipherOpen(HomeDrive + '\chksis.dat');
      SetValorDatMemoria('Cacic2.ip_serv_cacic', v_ip_serv_cacic);
      //  SetValorChaveRegIni('Cacic2', 'ip_serv_cacic', v_ip_serv_cacic, HomeDrive + '\chksis.ini');


      // Se NT/2K/XP...
      // If NT Like...
      if (GetWinVer > 5) then
        Begin
          log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          log_diario('::::::: VERIFICANDO FILE SYSTEM E ATRIBUINDO PERMISS�ES :::::::');
          log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          Form1.FS_SetSecurity(Dir);
          Form1.FS_SetSecurity(Dir + '\cacic2.exe');
          Form1.FS_SetSecurity(Dir + '\modulos');
          Form1.FS_SetSecurity(Dir + '\temp');
          Form1.FS_SetSecurity(v_DatFileName) ; // cacic2.dat

          // Atribui��o de acesso a todos os m�dulos para permiss�o de atualiza��es de vers�o
          Form1.FS_SetSecurity(Dir + '\modulos\ger_cols.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_anvi.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_comp.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_hard.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_moni.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_patr.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_soft.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\col_undi.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\ini_cols.exe');
          Form1.FS_SetSecurity(Dir + '\modulos\wscript.exe');
          log_diario(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        End;

      // Caso o Cacic tenha sido baixado executo-o com par�metro de configura��o de servidor
      if (bool_download_CACIC2) or (bool_download_GER_COLS) then
          Begin
            v_te_texto_janela_instalacao := v_te_instala_informacoes_extras;
            if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=Dir + '\cacic2.exe') then
              Begin
                if (v_exibe_informacoes = 'S') then
                  MessageDlg(#13#10+#13#10+v_te_instala_frase_sucesso+#13#10+#13#10+#13#10 + '======================================================' + #13#10 + v_te_texto_janela_instalacao+ '======================================================',mtInformation,[mbok],0);
              End
            else if (v_exibe_informacoes = 'S') then
                  MessageDlg(#13#10+#13#10+v_te_instala_frase_insucesso+#13#10+#13#10+#13#10 + '======================================================' + #13#10 +  v_te_texto_janela_instalacao+ '======================================================',mtInformation,[mbok],0);

           // Se eu n�o encontrei a chave de autoexecu��o ou
           // Se a unidade origem de chamada ao ChkCacic refere-se a Floppy, CDROM ou Flash
           // Eu executo o agente principal
           strAux := DriveType(Copy(ExtractFilePath(Application.Exename),1,1));
           if  not bool_ExistsAutoRun or
              (not(strAux = 'ERRO') and
               not(strAux = 'REDE')) then
            Begin
              log_diario('Executando '+Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic);
              WinExec(PChar(Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic+ ' /execute'), SW_HIDE);
            End
           else
            log_diario('N�o Executei. Chave de AutoExecu��o j� existente...');

          End
      else
        log_diario('ATEN��O: A Instala��o N�O Foi Realizada com Sucesso ou Atualiza��o Desnecess�ria!');
    End;
  Except
    log_diario('Falha na instala��o');
  End;

end;

function FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..260] of char;
begin
  // Get the first window
  NextHandle := GetWindow(Application.Handle, GW_HWNDFIRST);
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.ShowMainForm:=false;
  if (FindWindowByTitle('chksis') = 0) then
      chkcacic
  else
      log_diario('N�o executei devido execu��o em paralelo de "chksis"');

  Application.Terminate;
end;

procedure TForm1.FS_SetSecurity(p_Target : String);
var intAux : integer;
    v_FS_Security : TNTFileSecurity;
begin
  v_FS_Security := TNTFileSecurity.Create(nil);
  v_FS_Security.FileName := '';
  v_FS_Security.FileName := p_Target;
  v_FS_Security.RefreshSecurity;

  if (v_FS_Security.FileSystemName='NTFS')then
    Begin
      for intAux := 0 to Pred(v_FS_Security.EntryCount) do
        begin
          case v_FS_Security.EntryType[intAux] of
            seAlias : Try
                        // Atribuo total privil�gio aos grupos locais sobre a pasta "CACIC"
                        // Set all privilegies to local groups on p_Target
                        case v_FS_Security.EntryType[intAux] of
                          seAlias : // Se for grupo local...
                            Begin   // If local group...
                              v_FS_Security.FileRights[intAux]       := [faAll];
                              v_FS_Security.DirectoryRights[intAux]  := [faAll];
                              log_diario(p_Target + ' [Full Access] >> '+v_FS_Security.EntryName[intAux]);
                              //Setting total access on p_Target to local groups.
                            End;
                        end;
                      Except
                      End;
          End;
        end;

      // Atribui permiss�o total aos grupos locais
      // Set total permissions to local groups
      v_FS_Security.SetSecurity;
    end
  else Log_diario('File System diferente de "NTFS"');

  v_FS_Security.Free;
end;
end.
