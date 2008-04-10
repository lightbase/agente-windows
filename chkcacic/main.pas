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
=====================================================================================================
ChkCacic.exe : Verificador/Instalador dos agentes principais Cacic2.exe e Ger_Cols.exe
=====================================================================================================

v 2.2.0.38
+ Acrescentado a obtenção de versão interna do S.O.
+ Acrescentado a inserção dos agentes principais nas exceções do FireWall interno do MS-Windows VISTA...
.
Diversas rebuilds...
.
v 2.2.0.17
+ Acrescentado o tratamento da passagem de opções em linha de comando
  * chkcacic /serv=<ip_server> /dir=<local_path>c:\%windir%\cacic
  Exemplo de uso: chkcacic /serv=UXbra001 /dir=Cacic

v 2.2.0.16
* Corrigido o fechamento do arquivo de configurações de ChkSis

v 2.2.0.15
* Substituída a mensagem "File System diferente de "NTFS" por 'File System: "<NomeFileSystem>" - Ok!'

v 2.2.0.14
+ Críticas/mensagens:
  "ATENÇÃO! Não foi possível estabelecer comunicação com o módulo Gerente WEB em <servidor>." e
  "ATENÇÃO: Não foi possível efetuar FTP para <agente>. Verifique o Servidor de Updates."
+ Opção checkbox "Exibe informações sobre o processo de instalação" ao formulário de configuração;
+ Botão "Sair" ao formulário de configuração;
+ Execução automática do Agente Principal ao fim da instalação quando a unidade origem do ChkCacic não
  for mapeamento de rede ou unidade inválida.

- Retirados os campos "Frase para Sucesso na Instalação" e "Frase para Insucesso na Instalação"
  do formulário de configuração, passando essas frases a serem fixas na aplicação.
- Retirada a opção radiobutton "Remove Versão Anterior?";

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
      NTFileSecurity,
      IdFTP,
      Tlhelp32,
      dialogs,
      ExtCtrls;

var   v_ip_serv_cacic,
      v_cacic_dir,
//      v_rem_cacic_v0x,
      v_te_instala_frase_sucesso,
      v_te_instala_frase_insucesso,
      v_te_instala_informacoes_extras,
      v_exibe_informacoes,
      v_versao_local,
      v_versao_remota,
      v_CipherKey,
      v_SeparatorKey,
      v_IV,
      v_strCipherClosed,
      v_strCipherOpened,
      v_DatFileName,
      v_retorno,
      v_versao_REM,
      v_versao_LOC,
      v_te_so        : String;

      intWinVer    : integer;
      v_Debugs     : boolean;

var   v_tstrCipherOpened        : TStrings;

// Constantes a serem usadas pela função IsAdmin...
const constSECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
      constSECURITY_BUILTIN_DOMAIN_RID = $00000020;
      constDOMAIN_ALIAS_RID_ADMINS = $00000220;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

Procedure chkcacic;
procedure ComunicaInsucesso(strIndicador : String); //2.2.0.32
Procedure CriaFormConfigura;
Procedure DelValorReg(Chave: String);
Procedure GravaConfiguracoes;
procedure GravaIni(strFullPath : STring);
procedure KillProcess(hWindowHandle: HWND); // 2.2.0.15
procedure LogDebug(p_msg:string);
procedure LogDiario(strMsg : String);
procedure Matar(v_dir,v_files: string); // 2.2.0.16
Procedure MostraFormConfigura;

function abstraiCSD(p_te_so : String) : integer;
Function ChecaVersoesAgentes(p_strNomeAgente : String) : integer; // 2.2.0.16
Function Explode(Texto, Separador : String) : TStrings;
Function FindWindowByTitle(WindowTitle: string): Hwnd;
Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
function Get_File_Size(sFileToExamine: string): integer; // 2.2.0.31
function GetFolderDate(Folder: string): TDateTime;
function GetNetworkUserName : String; // 2.2.0.32
Function GetRootKey(strRootKey: String): HKEY;
Function GetValorChaveRegEdit(Chave: String): Variant;
Function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
Function GetVersionInfo(p_File: string):string;
Function GetWinVer: Integer;
Function HomeDrive : string;
Function KillTask(ExeFileName: string): Integer;
Function ListFileDir(Path: string):string;
function Posso_Rodar_CACIC : boolean;
Function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
Function SetValorChaveRegIni(p_Secao, p_Chave, p_Valor, p_File : String): String;
Function RemoveCaracteresEspeciais(Texto : String) : String;
Function VerFmt(const MS, LS: DWORD): string;

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

  LogDebug('GetWinVer => ID_interna: '+ v_te_so + ' ID_Externa: ' + IntToStr(Result));
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

procedure ComunicaInsucesso(strIndicador : String);
var IdHTTP2: TIdHTTP;
    Request_Config  : TStringList;
    Response_Config : TStringStream;
begin
  GetWinVer(); // Para obtenção de "te_so"
  // Envio notificação de insucesso para o Módulo Gerente Centralizado
  Request_Config                                 := TStringList.Create;
  Request_Config.Values['cs_indicador']          := strIndicador;
  Request_Config.Values['id_usuario']            := GetNetworkUserName();
  Request_Config.Values['te_so']                 := v_te_so;
  Response_Config                                := TStringStream.Create('');
  Try
    Try
      IdHTTP2 := TIdHTTP.Create(nil);
      IdHTTP2.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/instalacacic.php', Request_Config, Response_Config);
      IdHTTP2.Free;
      Request_Config.Free;
      Response_Config.Free;
    Except
    End;
  finally
    Begin
      IdHTTP2.Free;
      Request_Config.Free;
      Response_Config.Free;
    End;
  End;
end;

procedure LogDiario(strMsg : String);
var
    HistoricoLog : TextFile;
begin
   try
       FileSetAttr (v_home_drive + 'chkcacic.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,v_home_drive + 'chkcacic.log'); {Associa o arquivo a uma variável do tipo TextFile}

       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Instalador] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
       //Erro na gravação do log!
       //Application.Terminate;
   end;
end;

procedure LogDebug(p_msg:string);
Begin
  if v_Debugs then
    Begin

      //if FileExists(Dir + '\Temp\Debugs\show.txt') then
      //    ShowMessage('DEBUG - '+p_msg);

      LogDiario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
    End;
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
    LogDiario('Erro no Processo de Criptografia');
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
    LogDiario('Erro no Processo de Decriptografia');
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
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       // Recriação do arquivo .DAT
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
      Result := explode('Configs.ID_SO'+v_SeparatorKey+inttostr(intWinVer)+v_SeparatorKey+'Configs.Endereco_WS'+v_SeparatorKey+'/cacic2/ws/',v_SeparatorKey);


    if Result.Count mod 2 <> 0 then
        Result.Add('');

end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String);
begin
    LogDebug('Setando Chave "'+p_Chave+'" com "'+p_Valor+'"');
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



function abstraiCSD(p_te_so : String) : integer;
  var tstrTe_so : tstrings;
  Begin
    tstrTe_so := Explode(p_te_so, '.');
    Result := StrToInt(tstrTe_so[0] + tstrTe_so[1] + tstrTe_so[2]);
    LogDebug('abstraiCSD=> '+ tstrTe_so[0] + tstrTe_so[1] + tstrTe_so[2]);
  End;

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
    LogDebug('Setando valor "'+Dado+'" para chave "'+Chave+'"');
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
  FormConfig.Configs.lbVersao.Caption := 'v: ' + getVersionInfo(ParamStr(0));
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
    LogDebug('FTP: Criando instance');

    IdFTP               := TIdFTP.Create(nil);

    LogDebug('FTP: Host       => "'+p_Host+'"');
    IdFTP.Host          := p_Host;

    LogDebug('FTP: UserName   => "'+p_Username+'"');
    IdFTP.Username      := p_Username;

    LogDebug('FTP: PassWord   => "'+p_Password+'"');
    IdFTP.Password      := p_Password;

    LogDebug('FTP: PathServer => "'+p_PathServer+'"');
    IdFTP.Port          := strtoint(p_Port);

    LogDebug('FTP: Setando TransferType para "ftBinary"');
    IdFTP.TransferType  := ftBinary;

    LogDebug('FTP: Setando Passive para "true"');
    IdFTP.Passive := true;

    LogDebug('FTP: Change to "'+p_PathServer+'"');
    Try
      if IdFTP.Connected = true then
        begin
          LogDebug('FTP: Connected => Desconectando...');
          IdFTP.Disconnect;
        end;
      LogDebug('FTP: Efetuando Conexão...');
      IdFTP.Connect(true);
      LogDebug('FTP: Change to "'+p_PathServer+'"');
      IdFTP.ChangeDir(p_PathServer);
      Try
        LogDebug('Iniciando FTP de "'+p_Dest + '\' + p_File+'"');
        LogDebug('Size de "'+p_File+'" Antes do FTP => '+IntToSTR(IdFTP.Size(p_File)));
        IdFTP.Get(p_File, p_Dest + '\' + p_File, True, True);
        LogDebug('Size de "'+p_Dest + '\' + p_File +'" Após o FTP   => '+IntToSTR(Get_File_Size(p_Dest + '\' + p_File)));
      Finally
          LogDebug('Size de "'+p_Dest + '\' + p_File +'" Após o FTP em Finally   => '+IntToStr(Get_File_Size(p_Dest + '\' + p_File)));
          IdFTP.Disconnect;
          IdFTP.Free;
          result := true;
      End;
    Except
      Begin
        LogDebug('Oops! Problemas Sem Início de Operação...');
        result := false;
      End;
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
       FileSetAttr (ExtractFilePath(Application.Exename) + '\chkcacic.ini',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(chkcacic_ini,ExtractFilePath(Application.Exename) + '\chkcacic.ini'); {Associa o arquivo a uma variável do tipo TextFile}
       Rewrite (chkcacic_ini); // Recria o arquivo...
       Append(chkcacic_ini);
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# A edição deste arquivo também pode ser feita com o comando "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OBRIGATÓRIOS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# ip_serv_cacic');
       Writeln(chkcacic_ini,'#          Endereço IP ou Nome(DNS) do servidor onde o Módulo Gerente do CACIC foi instalado');
       Writeln(chkcacic_ini,'#          Ex1.: ip_serv_cacic=10.xxx.yyy.zzz');
       Writeln(chkcacic_ini,'#          Ex2.: ip_serv_cacic=uxesa001');
       Writeln(chkcacic_ini,'# cacic_dir');
       Writeln(chkcacic_ini,'#          Pasta a ser criada na estação para instalação do CACIC agente');
       Writeln(chkcacic_ini,'#          Ex.: cacic_dir=Cacic');
       Writeln(chkcacic_ini,'# exibe_informacoes');
       Writeln(chkcacic_ini,'#          Indicador de exibicao de informações sobre o processo de instalação');
       Writeln(chkcacic_ini,'#          Ex.: exibe_informacoes=N');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OPCIONAIS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# (ATENÇÃO: NÃO PREENCHER EM CASO DE CHKCACIC.INI PARA O NETLOGON!)');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# te_instala_informacoes_extras');
       Writeln(chkcacic_ini,'#          Informações a serem mostradas na janela de Instalação/Recuperação');
       Writeln(chkcacic_ini,'#          Ex.: Empresa-UF / Suporte Técnico');
       Writeln(chkcacic_ini,'#                  Emails: email_do_suporte@xxxxxx.yyy.zz, outro_email@outro_dominio.xxx.yy');
       Writeln(chkcacic_ini,'#                  Telefones: (xx) yyyy-zzzz  /  (xx) yyyy-zzzz');
       Writeln(chkcacic_ini,'#                  Endereço: Rua Nome_da_Rua, Nº 99999');
       Writeln(chkcacic_ini,'#                            Cidade/UF');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# Recomendação Importante:');
       Writeln(chkcacic_ini,'# =======================');
       Writeln(chkcacic_ini,'# Para benefício da rede local, criar uma pasta "modulos" no mesmo nível do chkcacic.exe, onde deverão');
       Writeln(chkcacic_ini,'# ser colocados todos os arquivos executáveis para uso do CACIC, pois, quando da necessidade de download');
       Writeln(chkcacic_ini,'# de módulo, o arquivo será apenas copiado e não será necessário o FTP:');
       Writeln(chkcacic_ini,'# cacic2.exe ............=> Agente Principal');
       Writeln(chkcacic_ini,'# ger_cols.exe ..........=> Gerente de Coletas');
       Writeln(chkcacic_ini,'# chksis.exe ............=> Check System Routine (chkcacic residente)');
       Writeln(chkcacic_ini,'# ini_cols.exe ..........=> Inicializador de Coletas');
       Writeln(chkcacic_ini,'# wscript.exe ...........=> Motor de Execução de Scripts VBS');
       Writeln(chkcacic_ini,'# col_anvi.exe ..........=> Agente Coletor de Informações de Anti-Vírus');
       Writeln(chkcacic_ini,'# col_comp.exe ..........=> Agente Coletor de Informações de Compartilhamentos');
       Writeln(chkcacic_ini,'# col_hard.exe ..........=> Agente Coletor de Informações de Hardware');
       Writeln(chkcacic_ini,'# col_moni.exe ..........=> Agente Coletor de Informações de Sistemas Monitorados');
       Writeln(chkcacic_ini,'# col_patr.exe ..........=> Agente Coletor de Informações de Patrimônio e Localização Física');
       Writeln(chkcacic_ini,'# col_soft.exe ..........=> Agente Coletor de Informações de Software');
       Writeln(chkcacic_ini,'# col_undi.exe ..........=> Agente Coletor de Informações de Unidades de Disco');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Exemplo de estrutura para KIT (CD) de instalação');
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
       Writeln(chkcacic_ini,'# Obs.: Antes da gravação do CD ou imagem, é necessário executar "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'[Cacic2]');

       // Atribuição dos valores do form FormConfig às variáveis...
       v_ip_serv_cacic                 := Configs.Edit_ip_serv_cacic.text;
       v_cacic_dir                     := Configs.Edit_cacic_dir.text;
       if Configs.ckboxExibeInformacoes.Checked then
         v_exibe_informacoes             := 'S'
       else
         v_exibe_informacoes             := 'N';

       v_te_instala_informacoes_extras := Configs.Memo_te_instala_informacoes_extras.Text;

       // Escrita dos parâmetros obrigatórios
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

procedure GravaIni(strFullPath : STring);
var iniFile : TextFile;
begin
   try
       FileSetAttr (strFullPath,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(iniFile,strFullPath); {Associa o arquivo a uma variável do tipo TextFile}
       Rewrite (iniFile); // Recria o arquivo...
       Append(iniFile);
       Writeln(iniFile,'');
       Writeln(iniFile,'[Cacic2]');
       Writeln(iniFile,'ip_serv_cacic='+v_ip_serv_cacic);
       Writeln(iniFile,'cacic_dir='+v_cacic_dir);
       CloseFile(iniFile); {Fecha o arquivo texto}
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
  LogDebug('Rotina para Liberação de FireWall...');
  Try
    if (abstraiCSD(v_te_so) >= 260) then // Se VISTA...
      Begin
        if (trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll])))='') then
          Begin
            SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll]),p_objeto+'.exe:*:Enabled:'+p_objeto);
          End
        else
          LogDebug('Exceção para "'+p_objeto+'" já existente.');
      End
    else
      if (trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll])))='') then
        Begin
          SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll]),p_objeto+'.exe:*:Enabled:'+p_objeto);
        End
      else
        LogDebug('Exceção para "'+p_objeto+'" já existente.');
  Except
    LogDebug('Problema adicionando "'+p_objeto+'" à lista de exceções do FireWall!');
  End;
end;

{
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
}

Function ChecaVersoesAgentes(p_strNomeAgente : String) : integer; // 2.2.0.16
var strNomeAgente : String;
    v_array_NomeAgente : TStrings;
    intAux : integer;
Begin
  v_array_NomeAgente := explode(p_strNomeAgente,'\');

  v_versao_REM := XML_RetornaValor(StringReplace(StrUpper(PChar(v_array_NomeAgente[v_array_NomeAgente.count-1])),'.EXE','',[rfReplaceAll]), v_retorno);
  v_versao_LOC := GetVersionInfo(p_strNomeAgente);

  LogDebug('Checando versão de "'+p_strNomeAgente+'"');

  intAux := v_array_NomeAgente.Count;

  // V: 2.2.0.16
  // Verifico existência do arquivo "versoes_agentes.ini" para comparação das versões dos agentes principais
  if (v_versao_REM = '') AND FileExists(ExtractFilePath(Application.Exename)+'versoes_agentes.ini') then
    Begin
      if (GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
        Begin
          LogDebug('Encontrado arquivo "'+(ExtractFilePath(Application.Exename)+'versoes_agentes.ini')+'"');
          v_versao_REM := GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
        End;
    End;

  LogDebug('Versão Remota: "'+v_versao_REM+'" - Versão Local: "'+v_versao_LOC+'"');

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
      LogDebug('Tentando Excluir: '+strFileName);
      if DeleteFile(strFileName) then
        LogDebug('Exclusão de ' + strFileName + ' efetuada com sucesso!')
      else
        Begin
          LogDebug('Exclusão não efetuada! Provavelmente já esteja sendo executado...');
          LogDebug('Tentarei finalizar Tarefa/Processo...');
          if ((intWinVer <> 0) and (intWinVer <= 5))  or
             (abstraiCSD(v_te_so) < 250) then // Menor que NT Like
            KillTask(SearchRec.Name)
          else
            KillProcess(FindWindow(PChar(SearchRec.Name),nil));

            if DeleteFile(strFileName) then
              LogDebug('Exclusão Impossibilitada de ' + strFileName + '!');
        End;

      Result:=FindNext(SearchRec);
    end;
end;

function Posso_Rodar_CACIC : boolean;
Begin
  result := false;

  // Se o aguarde_CACIC.txt existir é porque refere-se a uma versão mais atual: 2.2.0.20 ou maior
  if  (FileExists(v_cacic_dir + 'aguarde_CACIC.txt')) then
    Begin
      // Se eu conseguir matar o arquivo abaixo é porque não há outra sessão deste agente aberta... (POG? Nããão!  :) )
      Matar(v_cacic_dir,'aguarde_CACIC.txt');
      if  (not (FileExists(v_cacic_dir + 'aguarde_CACIC.txt'))) then
        result := true;
    End;
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

function Get_File_Size(sFileToExamine: string): integer;
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
  Result := I1;
end;

procedure verifyAndGet(strModuleName,
                       strDestinationFolderName,
                       strServUpdates,
                       strPortaServUpdates,
                       strNomeUsuarioLoginServUpdates,
                       strSenhaLoginServUpdates,
                       strPathServUpdates,
                       strExibeInformacoes : String);
  var intFileSize : integer;
  Begin

    // Verifico validade do Módulo e mato-o em caso negativo.
    intFileSize := Get_File_Size(strDestinationFolderName + '\'+strModuleName);

    LogDebug('verifyAndGet - intFileSize de "'+strDestinationFolderName + '\'+strModuleName+'": ' + IntToStr(intFileSize));

    If (intFileSize <= 0) then
      Matar(strDestinationFolderName, strModuleName);

    If not FileExists(strDestinationFolderName + '\'+strModuleName) Then
      Begin
        if (FileExists(ExtractFilePath(Application.Exename) + '\modulos\'+strModuleName)) then
          Begin
            LogDiario('Copiando '+strModuleName+' de '+ExtractFilePath(Application.Exename)+'modulos\');
            CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\'+strModuleName), PChar(strDestinationFolderName + '\'+strModuleName),false);
            FileSetAttr (PChar(strDestinationFolderName + '\' + strModuleName),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED
          End
        else
          begin
            Try
              if not FTP(strServUpdates,
                         strPortaServUpdates,
                         strNomeUsuarioLoginServUpdates,
                         strSenhaLoginServUpdates,
                         strPathServUpdates,
                         strModuleName,
                         strDestinationFolderName) and (strExibeInformacoes = 'S') then
                  MessageDLG(#13#10+'ATENÇÃO! Não foi possível efetuar FTP para "'+strDestinationFolderName + '\'+strModuleName+'".'+#13#10+'Verifique o Servidor de Updates.',mtError,[mbOK],0);
            Except
              LogDebug('FTP de "'+ strDestinationFolderName + '\' + strModuleName+'" Interrompido.');
            End;

            if not FileExists(strDestinationFolderName + '\' + strModuleName) Then
              Begin
                LogDebug('Problemas Efetuando Download de '+ strDestinationFolderName + '\' + strModuleName+' (FTP)');
                LogDebug('Conexão:');
                LogDebug(strServUpdates+', '+strPortaServUpdates+', '+strNomeUsuarioLoginServUpdates+', '+strSenhaLoginServUpdates+', '+strPathServUpdates);
              End
            else
                LogDiario('Download Concluído de "'+strModuleName+'" (FTP)');
          end;
      End;
  End;

procedure chkcacic;
var bool_configura,
    bool_ExistsAutoRun,
    bool_CommandLine : boolean;

    v_te_serv_updates,
    v_nu_porta_serv_updates,
    v_nm_usuario_login_serv_updates,
    v_te_senha_login_serv_updates,
    v_te_path_serv_updates,
    v_te_texto_janela_instalacao,
    v_modulos,
    strAux,
    strDataHoraCACIC2_INI,
    strDataHoraGERCOLS_INI,
    strDataHoraCACIC2_FIM,
    strDataHoraGERCOLS_FIM : String;

    Request_Config  : TStringList;
    v_array_modulos : TStrings;
    Response_Config : TStringStream;
    IdHTTP1: TIdHTTP;
    intDownload_CACIC2,
    intDownload_GER_COLS,
    intAux : integer;
begin
  strDataHoraCACIC2_INI           := '';
  strDataHoraCACIC2_FIM           := '';
  strDataHoraGERCOLS_INI          := '';
  strDataHoraGERCOLS_FIM          := '';
  v_te_instala_frase_sucesso      := 'INSTALAÇÃO/ATUALIZAÇÃO EFETUADA COM SUCESSO!';
  v_te_instala_frase_insucesso    := '*****  INSTALAÇÃO/ATUALIZAÇÃO NÃO EFETUADA COM SUCESSO  *****';
  bool_CommandLine                := false;

  Try
  v_home_drive                    := MidStr(HomeDrive,1,3); //x:\

  // 2.2.0.17 - Tratamento de opções passadas em linha de comando
  // Grande dica do grande Cláudio Filho (OpenOffice.org)
  if (ParamCount > 0) then
    Begin
      For intAux := 1 to ParamCount do
        Begin
          if LowerCase(Copy(ParamStr(intAux),1,6)) = '/serv=' then
            begin
              strAux := Trim(Copy(ParamStr(intAux),7,Length((ParamStr(intAux)))));
              v_ip_serv_cacic := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
              If v_ip_serv_cacic = '' Then v_ip_serv_cacic := strAux;
            end;
          if LowerCase(Copy(ParamStr(intAux),1,5)) = '/dir=' then
            begin
              strAux := Trim(Copy(ParamStr(intAux),6,Length((ParamStr(intAux)))));
              v_cacic_dir := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
              If v_cacic_dir = '' Then v_cacic_dir := strAux;
            end;

        end;
        if not(v_ip_serv_cacic='') and
           not(v_cacic_dir='')then
           bool_CommandLine := true;
    End;


  // ATENÇÃO: Trecho para uso exclusivo no âmbito da DATAPREV a nível Brasil, para internalização maciça.
  //          Para envio à Comunidade, retirar as chaves mais abaixo, para que o código padrão seja descomentado.
  //          Anderson Peterle - FEV2008
  //v_ip_serv_cacic                 := 'UXRJO115';
  //v_cacic_dir                     := 'Cacic';
  //v_exibe_informacoes             := 'N'; // Manter o "N", pois, esse mesmo ChkCacic será colocado em NetLogons!



  if not bool_CommandLine then
    Begin
      If not (FileExists(ExtractFilePath(Application.Exename) + '\chkcacic.ini')) then
          Begin
              LogDiario('Abrindo formulário de configurações');
              CriaFormConfigura;
              MostraFormConfigura;
          End;
      v_ip_serv_cacic                 := GetValorChaveRegIni('Cacic2', 'ip_serv_cacic'    , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_cacic_dir                     := GetValorChaveRegIni('Cacic2', 'cacic_dir'        , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_exibe_informacoes             := GetValorChaveRegIni('Cacic2', 'exibe_informacoes', ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_te_instala_informacoes_extras := StringReplace(GetValorChaveRegIni('Cacic2', 'te_instala_informacoes_extras', ExtractFilePath(Application.Exename) + '\chkcacic.ini'),'*13*10',#13#10,[rfReplaceAll]);
    End;

  Dir                             := v_home_drive + v_cacic_dir; // Ex.: c:\cacic\

  if DirectoryExists(Dir + '\Temp\Debugs') then
    Begin
     if (FormatDateTime('ddmmyyyy', GetFolderDate(Dir + '\Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
       Begin
         v_Debugs := true;
         LogDebug('Pasta "' + Dir + '\Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(Dir + '\Temp\Debugs'))+' encontrada. DEBUG ativado.');
       End;
    End;

  intWinVer := GetWinVer;

  // Verifico se o S.O. é NT Like e se o Usuário está com privilégio administrativo...
  if (((intWinVer <> 0) and (intWinVer >= 6)) or
      (abstraiCSD(v_te_so) >= 250)) and
     not IsAdmin then // Se NT/2000/XP/...
    Begin
      if (v_exibe_informacoes = 'S') then
        MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);
      ComunicaInsucesso('0'); // O indicador "0" (zero) sinalizará falta de privilégio na estação
    End
  else
    Begin
      LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      LogDebug(':::::::::::::: OBTENDO VALORES DO "chkcacic.ini" ::::::::::::::');
      LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      LogDebug('Drive de instalação......................: '+v_home_drive);
      LogDebug('Pasta para instalação....................: '+Dir);
      LogDebug('IP do servidor...........................: '+v_ip_serv_cacic);
      LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      bool_configura := false;

      //chave AES. Recomenda-se que cada empresa/órgão altere a sua chave.
      v_CipherKey    := 'CacicBrasil';
      v_IV           := 'abcdefghijklmnop';
      v_SeparatorKey := '=CacicIsFree='; // Usada apenas para o cacic2.dat
      v_DatFileName  := Dir + '\cacic2.dat';
      v_tstrCipherOpened := CipherOpen(v_DatFileName);

      if ((intWinVer <> 0) and (intWinVer >= 8)) or
         (abstraiCSD(v_te_so) >= 250) then // Se >= Maior ou Igual ao WinXP...
        Begin
          Try
            // Libero as policies do FireWall Interno
            if (abstraiCSD(v_te_so) >= 260) then // Maior ou Igual ao VISTA...
              Begin
                Try
                  Begin
                    // Liberando as conexões de Saída para o FTP
                    SetValorChaveRegEdit('HKEY_LOCAL//_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App=C:\\windows\\system32\\ftp.exe|Name=Programa de transferência de arquivos|Desc=Programa de transferência de arquivos|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App=C:\\windows\\system32\\ftp.exe|Name=Programa de transferência de arquivos|Desc=Programa de transferência de arquivos|Edge=FALSE|');

                    // Liberando as conexões de Saída para o Ger_Cols
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+Dir+'\modulos\\ger_cols.exe|Name=Módulo Gerente de Coletas do Sistema CACIC|Desc=Módulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+Dir+'\modulos\\ger_cols.exe|Name=Módulo Gerente de Coletas do Sistema CACIC|Desc=Módulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');

                    // Liberando as conexões de Saída para o ChkCacic
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkcacic.exe|Desc=chkcacic.exe|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkcacic.exe|Desc=chkcacic.exe|Edge=FALSE|');

                    // Liberando as conexões de Saída para o ChkSis
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+HomeDrive + '\chksis.exe|Name=Módulo Verificador de Integridade do Sistema CACIC|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+HomeDrive + '\chksis.exe|Name=Módulo Verificador de Integridade do Sistema CACIC|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                  End
                Except
                  LogDebug('Problema Liberando Policies de FireWall!');
                End;
              End
            else
              Begin
                // Acrescento o ChkCacic às exceções do FireWall nativo...
                {chkcacic}
                LogDebug('Inserindo "'+ExtractFilePath(Application.Exename) + 'chkcacic" nas exceções do FireWall!');
                LiberaFireWall(ExtractFilePath(Application.Exename) + 'chkcacic');
              End;
          Except
          End;
        End;


      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then bool_configura := true;

      while (v_ip_serv_cacic = '') or (v_cacic_dir = '') or bool_configura do
          Begin
              LogDiario('Abrindo formulário de configurações');
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

      // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
      if not DirectoryExists(Dir) then
          begin
            LogDiario('Criando pasta '+Dir);
            ForceDirectories(Dir);
          end;

      // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
      if not DirectoryExists(Dir+'\modulos') then
          begin
            Matar(Dir, '\cacic2.exe');
            ForceDirectories(Dir + '\modulos');
            LogDiario('Criando pasta '+Dir+'\modulos');
          end;

      // Crio o SubDiretório TEMP, caso não exista
      if not DirectoryExists(Dir+'\temp') then
          begin
            ForceDirectories(Dir + '\temp');
            LogDiario('Criando pasta '+Dir+'\temp');
          end;


      // Tento o contato com o módulo gerente WEB para obtenção de
      // dados para conexão FTP e relativos às versões atuais dos principais agentes
      // Busco as configurações para acesso ao ambiente FTP - Updates
      Request_Config                       := TStringList.Create;
      Request_Config.Values['in_chkcacic'] := 'chkcacic';
      Response_Config                      := TStringStream.Create('');

      Try
        LogDiario('Iniciando comunicação com '+'http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php');
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
        
        IdHTTP1.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php', Request_Config, Response_Config);
        idHTTP1.Disconnect;
        idHTTP1.Free;

        v_retorno := Response_Config.DataString;
        v_te_serv_updates               := XML_RetornaValor('te_serv_updates'              , v_retorno);
        v_nu_porta_serv_updates         := XML_RetornaValor('nu_porta_serv_updates'        , v_retorno);
        v_nm_usuario_login_serv_updates := XML_RetornaValor('nm_usuario_login_serv_updates', v_retorno);
        v_te_senha_login_serv_updates   := XML_RetornaValor('te_senha_login_serv_updates'  , v_retorno);
        v_te_path_serv_updates          := XML_RetornaValor('te_path_serv_updates'         , v_retorno);

        LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        LogDebug(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
        LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        LogDebug('Servidor de updates......................: '+v_te_serv_updates);
        LogDebug('Porta do servidor de updates.............: '+v_nu_porta_serv_updates);
        LogDebug('Usuário para login no servidor de updates: '+v_nm_usuario_login_serv_updates);
        LogDebug('Pasta no servidor de updates.............: '+v_te_path_serv_updates);
        LogDebug(' ');
        LogDebug('Versões dos Agentes Principais:');
        LogDebug('------------------------------');
        LogDebug('Cacic2   - Agente do Systray.........: '+XML_RetornaValor('CACIC2', v_retorno));
        LogDebug('Ger_Cols - Gerente de Coletas........: '+XML_RetornaValor('GER_COLS', v_retorno));
        LogDebug('ChkSis   - Verificador de Integridade: '+XML_RetornaValor('CHKSIS', v_retorno));
        LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      Except
        Begin
          if v_exibe_informacoes = 'S' then
            MessageDLG(#13#10+'ATENÇÃO! Não foi possível estabelecer comunicação com o módulo Gerente WEB em "'+v_ip_serv_cacic+'".',mtError,[mbOK],0);
          LogDiario('**********************************************************');
          LogDiario('Oops! Não Foi Possível Comunicar com o Módulo Gerente WEB!');
          LogDiario('**********************************************************');
        End
      End;
      Request_Config.Free;
      Response_Config.Free;

      // Se NTFS em NT/2K/XP...
      // If NTFS on NT Like...
      if ((intWinVer <> 0) and (intWinVer > 5)) or
          (abstraiCSD(v_te_so) >= 250) then
        Begin
          LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          LogDebug('::::::: VERIFICANDO FILE SYSTEM E ATRIBUINDO PERMISSÕES :::::::');
          LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

          // Atribuição de acesso ao módulo principal e pastas
          Form1.FS_SetSecurity(Dir);
          Form1.FS_SetSecurity(Dir + '\cacic2.exe');
          Form1.FS_SetSecurity(Dir + '\cacic2.dat');
          Form1.FS_SetSecurity(Dir + '\cacic2.log');
          Form1.FS_SetSecurity(Dir + '\modulos');
          Form1.FS_SetSecurity(Dir + '\temp');

          // Atribuição de acesso aos módulos de gerenciamento de coletas e coletas para permissão de atualizações de versões
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

          // Atribuição de acesso para atualização do módulo verificador de integridade do sistema e seus arquivos
          Form1.FS_SetSecurity(HomeDrive + '\chksis.exe');
          Form1.FS_SetSecurity(HomeDrive + '\chksis.log');
          Form1.FS_SetSecurity(HomeDrive + '\chksis.dat');

          // Atribuição de acesso para atualização/exclusão de log do instalador
          Form1.FS_SetSecurity(v_home_drive + 'chkcacic.log');
          LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        End;

      // Verificação de versão do cacic2.exe e exclusão em caso de versão antiga/diferente da atual
      If (FileExists(Dir + '\cacic2.exe')) Then
          Begin
            // Pego as informações de dia/mês/ano/horas/minutos/segundos/milésimos que identificam o agente Cacic2
            strDataHoraCACIC2_INI := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(Dir + '\cacic2.exe'));

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

      // Verificação de versão do ger_cols.exe e exclusão em caso de versão antiga/diferente da atual
      If (FileExists(Dir + '\modulos\ger_cols.exe')) Then
        Begin
          // Pego as informações de dia/mês/ano/horas/minutos/segundos/milésimos que identificam o agente Ger_Cols
          strDataHoraGERCOLS_INI := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(Dir + '\modulos\ger_cols.exe'));

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


      // Verificação de versão do chksis.exe e exclusão em caso de versão antiga/diferente da atual
      If (FileExists(HomeDrive + '\chksis.exe')) Then
        Begin
          intAux := ChecaVersoesAgentes(HomeDrive + '\chksis.exe');
          // 0 => Arquivo de versões ou informação inexistente
          // 1 => Versões iguais
          // 2 => Versões diferentes
          if (intAux = 0) then
            Begin
              v_versao_local  := StringReplace(trim(GetVersionInfo(HomeDrive + '\chksis.exe')),'.','',[rfReplaceAll]);
              v_versao_remota := StringReplace(XML_RetornaValor('CHKSIS' , v_retorno),'0103','',[rfReplaceAll]);
            End;

          if (intAux = 2) or // Caso haja diferença na comparação de versões com "versoes_agentes.ini"...
             (v_versao_local ='0000') then // Provavelmente versão muito antiga ou corrompida
            Matar(HomeDrive,'chksis.exe');
        End;

      // Tento detectar o ChkSis.EXE e copio ou faço FTP caso não exista
      verifyAndGet('chksis.exe',
                    HomeDrive,
                    v_te_serv_updates,
                    v_nu_porta_serv_updates,
                    v_nm_usuario_login_serv_updates,
                    v_te_senha_login_serv_updates,
                    v_te_path_serv_updates,
                    v_exibe_informacoes);

      // Tento detectar o ChkSis.INI e crio-o caso necessário
      If not FileExists(HomeDrive + '\chksis.ini') Then
          begin
            LogDebug('Criando '+HomeDrive + '\chksis.ini');
            GravaIni(HomeDrive + '\chksis.ini');
            FileSetAttr ( PChar(HomeDrive + '\chksis.ini'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
          end;

      // Tento detectar o cacic2.INI e crio-o caso necessário
      If not FileExists(Dir + '\cacic2.ini') Then
          begin
            LogDebug('Criando/Recriando '+Dir + '\cacic2.ini');
            GravaIni(Dir + '\cacic2.ini');
          end;

      // Verifico se existe a pasta "modulos"
      v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'\modulos\*.exe');
      if (v_modulos <> '') then LogDiario('Pasta "Modulos" encontrada..');

      // Tento detectar o Agente Principal e copio ou faço FTP caso não exista
      verifyAndGet('cacic2.exe',
                   Dir,
                   v_te_serv_updates,
                   v_nu_porta_serv_updates,
                   v_nm_usuario_login_serv_updates,
                   v_te_senha_login_serv_updates,
                   v_te_path_serv_updates,
                   v_exibe_informacoes);

      verifyAndGet('ger_cols.exe',
                   Dir + '\modulos',
                   v_te_serv_updates,
                   v_nu_porta_serv_updates,
                   v_nm_usuario_login_serv_updates,
                   v_te_senha_login_serv_updates,
                   v_te_path_serv_updates,
                   v_exibe_informacoes);

        // Caso exista a pasta "modulos", copio todos os executáveis para a pasta Cacic\modulos, exceto cacic2.exe, ger_cols.exe e chksis.exe
        if (v_modulos <> '') then
          Begin
            v_array_modulos := explode(v_modulos,'#');
            For intAux := 0 To v_array_modulos.count -1 Do
              Begin
                if (v_array_modulos[intAux]<>'cacic2.exe') and
                   (v_array_modulos[intAux]<>'ger_cols.exe') and
                   (v_array_modulos[intAux]<>'chksis.exe') then
                  Begin
                    LogDiario('Copiando '+v_array_modulos[intAux]+' de '+ExtractFilePath(Application.Exename)+'modulos\');
                    CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\'+v_array_modulos[intAux]), PChar(Dir + '\modulos\'+v_array_modulos[intAux]),false);
                    FileSetAttr (PChar(Dir + '\modulos\'+v_array_modulos[intAux]),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
                  End;
              End;
          End;

      // ATENÇÃO:
      // Após testes no Vista, percebí que o firewall nativo interrompia o FTP e truncava o agente com tamanho zero...
      // A nova tentativa abaixo ajudará a sobrepor o agente truncado e corrompido

      // Tento detectar (de novo) o ChkSis.EXE e copio ou faço FTP caso não exista
      verifyAndGet('chksis.exe',
                    HomeDrive,
                    v_te_serv_updates,
                    v_nu_porta_serv_updates,
                    v_nm_usuario_login_serv_updates,
                    v_te_senha_login_serv_updates,
                    v_te_path_serv_updates,
                    v_exibe_informacoes);

      // Tento detectar (de novo) o Agente Principal e copio ou faço FTP caso não exista
      verifyAndGet('cacic2.exe',
                   Dir,
                   v_te_serv_updates,
                   v_nu_porta_serv_updates,
                   v_nm_usuario_login_serv_updates,
                   v_te_senha_login_serv_updates,
                   v_te_path_serv_updates,
                   v_exibe_informacoes);

      verifyAndGet('ger_cols.exe',
                   Dir + '\modulos',
                   v_te_serv_updates,
                   v_nu_porta_serv_updates,
                   v_nm_usuario_login_serv_updates,
                   v_te_senha_login_serv_updates,
                   v_te_path_serv_updates,
                   v_exibe_informacoes);

      if ((intWinVer <> 0) and (intWinVer >= 8)) or
         (abstraiCSD(v_te_so) >= 250) then // Se >= WinXP...
        Begin
          Try
            // Acrescento o ChkSis e o Ger_Cols às exceções do FireWall nativo...

            {chksis}
            LogDebug('Inserindo "'+HomeDrive + '\chksis" nas exceções do FireWall!');
            LiberaFireWall(HomeDrive + '\chksis');

            {ger_cols}
            LogDebug('Inserindo "'+Dir + '\modulos\ger_cols" nas exceções do FireWall!');
            LiberaFireWall(Dir + '\modulos\ger_cols');
          Except
          End;
        End;

      LogDebug('Gravando registros para auto-execução');

      // Crio a chave/valor cacic2 para autoexecução do Cacic, caso não exista esta chave/valor
      // Crio a chave/valor chksis para autoexecução do ChkSIS, caso não exista esta chave/valor
      SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', HomeDrive + '\chksis.exe');

      bool_ExistsAutoRun := false;
      if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=Dir + '\cacic2.exe') then
        bool_ExistsAutoRun := true
      else
        SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', Dir + '\cacic2.exe');

      // Igualo as chaves ip_serv_cacic dos arquivos chksis.ini e cacic2.ini!
      SetValorDatMemoria('Configs.EnderecoServidor', v_ip_serv_cacic);
      LogDebug('Fechando Arquivo de Configurações do Cacic');
      CipherClose(v_DatFileName);

      LogDebug('Abrindo Arquivo de Configurações do ChkSis');
      CipherOpen(HomeDrive + '\chksis.dat');
      SetValorDatMemoria('Cacic2.ip_serv_cacic', v_ip_serv_cacic);
      CipherClose(HomeDrive + '\chksis.dat');

      // Volto a gravar o chksis.ini para o difícil caso de leitura por versões antigas
      SetValorChaveRegIni('Cacic2', 'ip_serv_cacic', v_ip_serv_cacic, HomeDrive + '\chksis.ini');
      LogDebug('Fechando Arquivo de Configurações do ChkSis');

      LogDebug('Resgatando informações para identificação de alteração do agente CACIC2');
      // Pego as informações de dia/mês/ano/horas/minutos/segundos/milésimos que identificam os agentes
      strDataHoraCACIC2_FIM  := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(Dir + '\cacic2.exe'));
      LogDebug('Inicial => "' + strDataHoraCACIC2_INI  + '" Final => "' + strDataHoraCACIC2_FIM  + '"');

      LogDebug('Resgatando informações para identificação de alteração do agente GER_COLS');
      strDataHoraGERCOLS_FIM := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(Dir + '\modulos\ger_cols.exe'));
      LogDebug('Inicial => "' + strDataHoraGERCOLS_INI + '" Final => "' + strDataHoraGERCOLS_FIM + '"');

      // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
      if ((strDataHoraCACIC2_INI <> strDataHoraCACIC2_FIM) OR
          (strDataHoraGERCOLS_INI <> strDataHoraGERCOLS_FIM)) then
          Begin
            v_te_texto_janela_instalacao := v_te_instala_informacoes_extras;
            if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=Dir + '\cacic2.exe') then
              Begin
                if (v_exibe_informacoes = 'S') then
                  MessageDlg(#13#10+#13#10+'Sistema CACIC'+#13#10+#13#10+v_te_instala_frase_sucesso+#13#10+#13#10+#13#10 + '======================================================' + #13#10 + v_te_texto_janela_instalacao+ #13#10 +'======================================================',mtInformation,[mbok],0);
              End
            else
              Begin
                if (v_exibe_informacoes = 'S') then
                  MessageDlg(#13#10+#13#10+'Sistema CACIC'+#13#10+#13#10+v_te_instala_frase_insucesso+#13#10+#13#10+#13#10 + '======================================================' + #13#10 +  v_te_texto_janela_instalacao+ #13#10 +'======================================================',mtInformation,[mbok],0);
                ComunicaInsucesso('1'); // O indicador "1" sinalizará que não foi devido a privilégio na estação
              End;
          End
      else
        LogDiario('ATENÇÃO: Instalação NÃO REALIZADA ou ATUALIZAÇÃO DESNECESSÁRIA!');

      if Posso_Rodar_CACIC or
         not bool_ExistsAutoRun or
         (strDataHoraCACIC2_INI <> strDataHoraCACIC2_FIM) then
        Begin
          LogDebug('Executando '+Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic);

          // Caso tenha havido download de agentes principais, executar coletas imediatamente...
          if (strDataHoraCACIC2_INI <> strDataHoraCACIC2_FIM) then
            WinExec(PChar(Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic+ ' /execute'), SW_HIDE)
          else
            WinExec(PChar(Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic             ), SW_HIDE);
        End
      else
        LogDebug('Chave de Auto-Execução já existente ou Execução já iniciada...');
    End;
  Except
    LogDiario('Falha na Instalação/Atualização');
  End;
  Application.Terminate;
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
  v_Debugs := false;

//  if (FindWindowByTitle('chksis') = 0) then
      chkcacic;
//  else
//      LogDiario('Não executei devido execução em paralelo de "chksis"');

  Application.Terminate;
end;

procedure TForm1.FS_SetSecurity(p_Target : String);
var intAux : integer;
    v_FS_Security : TNTFileSecurity;
    boolFound : boolean;
begin
  v_FS_Security := TNTFileSecurity.Create(nil);
  v_FS_Security.FileName := '';
  v_FS_Security.FileName := p_Target;
  v_FS_Security.RefreshSecurity;

  if (v_FS_Security.FileSystemName='NTFS')then
    Begin
      for intAux := 0 to Pred(v_FS_Security.EntryCount) do
        begin
          case v_FS_Security.EntryType[intAux] of seAlias, seDomain, seGroup :
            Begin   // If local group, alias or user...
              v_FS_Security.FileRights[intAux]       := [faAll];
              v_FS_Security.DirectoryRights[intAux]  := [faAll];
              LogDebug(p_Target + ' [Full Access] >> '+v_FS_Security.EntryName[intAux]);
              //Setting total access on p_Target to local groups.
            End;
          End;
        end;

      // Atribui permissão total aos grupos locais
      // Set total permissions to local groups
      v_FS_Security.SetSecurity;
    end
  else LogDiario('File System: "' + v_FS_Security.FileSystemName+'" - Ok!');

  v_FS_Security.Free;
end;
end.
