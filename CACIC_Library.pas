{*------------------------------------------------------------------------------
   Package of both methods/properties to be used by CACIC Clients

   @version CACIC_Library 2009-01-07 23:00 harpiain
   @package CACIC_Agente
   @subpackage CACIC_Library
   @author Adriano dos Santos Vieira <harpiain at gmail.com>
   @copyright Copyright (C) Adriano dos Santos Vieira. All rights reserved.
   @license GNU/GPL, see LICENSE.php
   CACIC_Library is free software and parts of it may contain or be derived from
   the GNU General Public License or other free or open source software license.
   See COPYRIGHT.php for copyright notices and details.

   CACIC_Library - Coding style
   for Constants
      - characters always in uppercase
      - use underscore for long name
      e.g.
        const CACIC_VERSION = '2.4.0';

   for Variables
      - characters always in lowercase
      - start with "g" character for global
      - start with "v" character for local
      - start with "p" character for methods parameters
      - start with "P" character for pointers
      - use underscore for better read
      e.g.
        var g_global : string;
        var v_local  : string;

   for Objects
      - start with "o" character
      e.g.
        oCacicObject : TCACIC_Common;

   for Methods
      - start with lowercase word
      - next words start with capital letter
      e.g.
        function getLocalFolder() : string;
        procedure setLocalFolder( pPath: string );
-------------------------------------------------------------------------------}

unit CACIC_Library;

interface

uses
	Windows,
    Classes,
    SysUtils,
    StrUtils,
    MD5,
    DCPcrypt2,
    DCPrijndael,
    DCPbase64,
    ActiveX,
    PJVersionInfo,
    LibXmlParser,
    Registry,
    IniFiles,
    Tlhelp32,
    ComObj;
type

{ ------------------------------------------------------------------------------
  Tipo de dados para obter informacoes extendidas dos Sistema Operacional
  ver MSDN: http://msdn.microsoft.com/en-us/library/ms724833(VS.85).aspx
-------------------------------------------------------------------------------}
  TOSVersionInfoEx = packed record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of AnsiChar;
    wServicePackMajor: WORD;
    wServicePackMinor: WORD;
    wSuiteMask: WORD;
    wProductType: Byte;
    wReserved: Byte;
  end;

{*------------------------------------------------------------------------------
 Classe para obter informações do sistema windows
-------------------------------------------------------------------------------}
   TCACIC_Windows = class
       private
         g_debug: boolean;
       protected
         g_strAcao    :string;
         g_local_folder: string;
         /// Mantem a identificação do sistema operacional
         g_osVersionInfo: TOSVersionInfo;
         /// Mantem a identificação extendida do sistema operacional
         g_osVersionInfoEx: TOSVersionInfoEx;
         /// TRUE se houver informação extendida do SO, FALSE caso contrário
         g_osVersionInfoExtended: boolean;

       public
         function  createOneProcess(p_cmd: string; p_wait: boolean; p_showWindow : word = SW_HIDE): boolean;
         function  getBitPlatform()                                     : String;
         function  getLocalFolder()                                     : String;
         function  GetVersionInfo(p_File: string)                       :string;
         function  getWindowsStrId()                                    : string;
         function  getWinDir()                                          : string;
         function  getHomeDrive()                                       : string;
         function  inDebugMode()                                        : boolean;
         function  isWindowsVista()                                     : boolean;
         function  isWindowsGEVista()                                   : boolean;
         function  isWindowsXP()                                        : boolean;
         function  isWindowsGEXP()                                      : boolean;
         function  isWindowsNTPlataform()                               : boolean;
         function  isWindows2000()                                      : boolean;
         function  isWindowsNT()                                        : boolean;
         function  isWindows9xME()                                      : boolean;
         function  isWindowsAdmin()                                     : boolean;
         function  verFmt(const MS, LS: DWORD): string;
         procedure debugOn();
         procedure debugOff();
         procedure writeDailyLog(strMsg : String);
         procedure writeDebugLog(p_msg:string);
         procedure showTrayIcon(p_visible:boolean);
         procedure addApplicationToFirewall(p_EntryName:string;p_ApplicationPathAndExe:string; p_Enabled : boolean);
   end;

{*------------------------------------------------------------------------------
 Classe geral da biblioteca
-------------------------------------------------------------------------------}
   TCACIC = class(TCACIC_Windows)
       constructor Create();
       destructor Destroy; override;
       private

       protected
         /// Mantem o caminho físico de instalação do agente cacic
         g_web_manager_address: string;
         g_main_program_name: string;
         g_main_program_hash: string;
         g_boolDebug,
         g_boolCipher : boolean;

       public
         Windows : TCACIC_Windows; /// objeto de informacoes de windows
         procedure checkDebugMode;
         procedure killFiles(p_Path, p_FilesNames : string);
         procedure killProcess(p_HWindowHandle: HWND);
         procedure killTask(p_ExeFileName: string);
         procedure setBoolCipher(p_boolCipher : boolean);
         procedure setLocalFolder(p_local_folder: string);
         procedure setMainProgramName(p_main_program_name: string);
         procedure setMainProgramHash(p_main_program_hash: string);
         procedure setValueToFile(p_SectionName, p_KeyName, p_Value, p_FileName : String);
         procedure setWebManagerAddress(p_web_manager_address: string);

         function  deCrypt(p_Data : String)                                               : String;
         function  enCrypt(p_Data : String)                                               : String;
         function  explode(p_String, p_Separador : String)                                : TStrings;
         function  getBlockSize()                                                         : integer;
         function  getBoolCipher()                                                        : boolean;
         function  getCipherKey()                                                         : String;
         function  getInfFileName()                                                       : String;
         function  getIniFileName()                                                       : String;         
         function  getFileHash(p_FileName : String)                                       : String;
         function  getFolderDate(var p_FolderName: string)                                : TDateTime;
         function  getIV()                                                                : String;
         function  getKeySize()                                                           : integer;
         function  getMainProgramHash()                                                   : String;
         function  getMainProgramName()                                                   : String;
         function  GetParam(p_strParamName : string)                                      : String;
         function  getRootKey(strRootKey: String)                                         : HKEY;
         function  getSeparatorKey()                                                      : String;
         function  getValueFromFile(p_SectionName, p_KeyName, p_FileName : String)        : String;
         function  getValueRegistryKey(p_KeyName : String)                                : Variant;
         function  getWebManagerAddress()                                                 : String;
         function  implode(p_Array : TStrings ; p_Separador : String)                     : String;
         function  isAppRunning( p_app_name: PAnsiChar )                                  : boolean;
         function  padWithZeros(const str : string; size : integer)                       : String;
         function  removeSpecialsCharacters(p_Text : String)                              : String;
         function  removeZerosFimString(Texto : String)                                   : String;
         function  setValueRegistryKey(p_KeyName: String; p_Data: Variant)                : Variant;
         function  trimEspacosExcedentes(p_str: string)                                   : String;
         function  xmlGetValue(p_TagName, p_Source : String)                              : String;
   end;

// Declaração de constantes para a biblioteca
const
  CACIC_PROCESS_WAIT   = true; // aguardar fim do processo
  CACIC_PROCESS_NOWAIT = false; // não aguardar o fim do processo

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const
  CACIC_KEYSIZE        = 32; // 32 bytes = 256 bits
  CACIC_BLOCKSIZE      = 16; // 16 bytes = 128 bits

// Chave AES. Recomenda-se que cada empresa altere a sua chave.
// Esta chave é passada como parâmetro para o Gerente de Coletas
const
  CACIC_CIPHERKEY      = 'CacicBrasil';
  CACIC_IV             = 'abcdefghijklmnop';
  CACIC_SEPARATORKEY   = '=CacicIsFree='; // Usada apenas para os arquivos de controle (.INF)

{
 Controle de prioridade de processo
 http://msdn.microsoft.com/en-us/library/ms683211(VS.85).aspx
}
const BELOW_NORMAL_PRIORITY_CLASS = $00004000;
  {$EXTERNALSYM BELOW_NORMAL_PRIORITY_CLASS}

var
  P_OSVersionInfo: POSVersionInfo;

implementation

{*------------------------------------------------------------------------------
  Construtor para a classe

  Objetiva inicializar valores a serem usados pelos objetos da
  classe.
-------------------------------------------------------------------------------}
constructor TCACIC.Create();
begin
  FillChar(Self.g_osVersionInfoEx, SizeOf(Self.g_osVersionInfoEx), 0);
  {$TYPEDADDRESS OFF}
  P_OSVersionInfo := @Self.g_osVersionInfoEx;
  {$TYPEDADDRESS ON}

  Self.g_osVersionInfoEx.dwOSVersionInfoSize:= SizeOf(TOSVersionInfoEx);
  Self.g_osVersionInfoExtended := GetVersionEx(P_OSVersionInfo^);
  if (not Self.g_osVersionInfoExtended) then begin
     Self.g_osVersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
     GetVersionEx(Self.g_osVersionInfo);
  end;
  Self.Windows := TCACIC_Windows.Create();
end;

{*------------------------------------------------------------------------------
  Destrutor para a classe

  Objetiva finalizar valores usados pelos objetos da classe.
-------------------------------------------------------------------------------}
destructor TCACIC.Destroy();
begin
   FreeMemory(P_OSVersionInfo);
   inherited;
end;

function TCACIC.getRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

function TCACIC.GetParam(p_strParamName : string) : String;
var strAuxParamName : String;
    intAuxLoop : integer;
Begin
  Result := '';
  strAuxParamName  := '/' + Trim(p_strParamName) + '=';
  For intAuxLoop := 1 to ParamCount do
    if (LowerCase(Copy(ParamStr(intAuxLoop),1,StrLen(PAnsiChar(strAuxParamName)))) = LowerCase(strAuxParamName)) then
      Result := Copy(ParamStr(intAuxLoop),StrLen(PAnsiChar(strAuxParamName))+1,StrLen(PChar(ParamStr(intAuxLoop))));
End;

function TCACIC.removeSpecialsCharacters(p_Text : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(p_Text) Do
     if ord(p_Text[I]) in [32..126] Then
        strAux := strAux + p_Text[I]
     else
        strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;

function TCACIC.setValueRegistryKey(p_KeyName: String; p_Data: Variant): Variant;
var RegEditSet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue : String;
    ListaAuxSet : TStrings;
    I : Integer;
begin
    ListaAuxSet := explode(p_KeyName, '\');
    strRootKey := ListaAuxSet[0];
    For I := 1 To ListaAuxSet.Count - 2 do
      strKey := strKey + ListaAuxSet[I] + '\';
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
                RegEditSet.WriteString(strValue, p_Data);
              end
            else if RegDataType = rdExpandString then
              begin
                RegEditSet.WriteExpandString(strValue, p_Data);
              end
            else if RegDataType = rdInteger then
              begin
                RegEditSet.WriteInteger(strValue, p_Data);
              end
            else
              begin
                RegEditSet.WriteString(strValue, p_Data);
              end;

        end;
    finally
      RegEditSet.CloseKey;
    end;
    ListaAuxSet.Free;
    RegEditSet.Free;
end;

function TCACIC.getValueRegistryKey(p_KeyName: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
      Result := '';
      ListaAuxGet := explode(p_KeyName, '\');

      strRootKey := ListaAuxGet[0];
      For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';
      strValue := ListaAuxGet[ListaAuxGet.Count - 1];
      if (strValue = '(Padrão)') then
        strValue := ''; //Para os casos de se querer buscar o valor default (Padrão)

      RegEditGet := TRegistry.Create;

      RegEditGet.Access := KEY_READ;
      RegEditGet.Rootkey := GetRootKey(strRootKey);
      if RegEditGet.OpenKeyReadOnly(strKey) then //teste
      Begin
           RegDataType := RegEditGet.GetDataType(strValue);
           if (RegDataType = rdString) or (RegDataType = rdExpandString) then
              Result := RegEditGet.ReadString(strValue)
           else if RegDataType = rdInteger then
              Result := RegEditGet.ReadInteger(strValue)
           else if (RegDataType = rdBinary) or (RegDataType = rdUnknown) then
            Begin
              DataSize := RegEditGet.GetDataSize(strValue);
              if DataSize = -1 then
                exit;
              SetLength(s, DataSize);
              Len := RegEditGet.ReadBinaryData(strValue, PChar(s)^, DataSize);
              if Len <> DataSize then
                exit;
              Result := removeSpecialsCharacters(s);
            End
      end;
    finally
      RegEditGet.CloseKey;
      RegEditGet.Free;
      ListaAuxGet.Free;
    end;
end;

function TCACIC.getFolderDate(var p_FolderName: string): TDateTime;
var
  Rec: TSearchRec;
  Found: Integer;
  Date: TDateTime;
begin
  if (p_FolderName[Length(p_FolderName)] = '\') then
    p_FolderName := Copy(p_FolderName,1,Length(p_FolderName)-1);

  Result := 0;
  Found  := FindFirst(p_FolderName, faDirectory, Rec);
  try
    if Found = 0 then
    begin
      Date   := FileDateToDateTime(Rec.Time);
      Result := Date;
    end;
  finally
    sysutils.FindClose(Rec);
  end;
end;

Function TCACIC.removeZerosFimString(Texto : String) : String;
var I       : Integer;
    strAux  : string;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         strAux := Texto[I] + strAux;
   Result := trim(strAux);
end;

procedure TCACIC.checkDebugMode;
var strAuxCDM : String;
Begin
  debugOff;
  if DirectoryExists(getLocalFolder + 'Temp\Debugs') then
      Begin
       strAuxCDM := getLocalFolder + 'Temp\Debugs';
       if (FormatDateTime('ddmmyyyy', GetFolderDate(strAuxCDM)) = FormatDateTime('ddmmyyyy', date)) then
         debugOn;
      End;
End;

function TCACIC.getValueFromFile(p_SectionName, p_KeyName, p_FileName : String): String;
//Para buscar do Arquivo INF...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
var
  FileText : TStringList;
  i, j, v_SectionSize, v_KeySize : integer;
  v_SectionName, v_KeyName : string;
  begin
    writeDebugLog('TCACIC.getValueFromFile - BEGIN');
    writeDebugLog('TCACIC.getValueFromFile - p_SectionName: "'+p_SectionName+'" p_KeyName: "'+p_KeyName+'" p_FileName: "'+p_FileName+'"');
    Result := '';
    v_SectionName := '[' + p_SectionName + ']';
    v_SectionSize := strLen(PChar(v_SectionName));
    v_KeyName := p_KeyName + '=';
    v_KeySize := strLen(PChar(v_KeyName));
    FileText := TStringList.Create;
    if (FileExists(p_FileName)) then
      Begin
        try
          FileText.LoadFromFile(p_FileName);
          For i := 0 To FileText.Count - 1 Do
            Begin
              if (LowerCase(Trim(PChar(Copy(FileText[i],1,v_SectionSize)))) = LowerCase(Trim(PChar(v_SectionName)))) then
                Begin
                  For j := i to FileText.Count - 1 Do
                    Begin
                      if (LowerCase(Trim(PChar(Copy(FileText[j],1,v_KeySize)))) = LowerCase(Trim(PChar(v_KeyName)))) then
                        Begin
                          Result := PChar(Copy(FileText[j],v_KeySize + 1,strLen(PChar(FileText[j]))-v_KeySize));
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
    else
      FileText.Free;

    writeDebugLog('TCACIC.getValueFromFile - Result: "'+Result+'"');
    writeDebugLog('TCACIC.getValueFromFile - END');
  end;

// Para gravar no Arquivo INF...
procedure TCACIC.setValueToFile(p_SectionName, p_KeyName, p_Value, p_FileName : String);
var Reg_Inf     : TIniFile;
begin
    writeDebugLog('TCACIC.setValueToFile - BEGIN');
    writeDebugLog('TCACIC.setValueToFile - p_SectionName: "'+p_SectionName+'" p_KeyName: "'+p_KeyName+'" p_Value: "'+p_Value+'" p_FileName: "'+p_FileName+'"');

    if (FileGetAttr(p_FileName) and faReadOnly) > 0 then
      FileSetAttr(p_FileName, FileGetAttr(p_FileName) xor faReadOnly);

    Reg_Inf := TIniFile.Create(p_FileName);
    Reg_Inf.WriteString(p_SectionName, p_KeyName, p_Value);
    Reg_Inf.Free;
    writeDebugLog('setValueToFile - END');
end;

function TCACIC.xmlGetValue(p_TagName, p_Source : String): String;
VAR
  Parser : TXmlParser;
begin
  Parser := TXmlParser.Create;
  Parser.Normalize := TRUE;
  Parser.LoadFromBuffer(PAnsiChar(p_Source));
  Parser.StartScan;
  WHILE Parser.Scan DO
  Begin
    if (Parser.CurPartType in [ptContent, ptCData]) Then  // Process Parser.CurContent field here
      begin
         if (UpperCase(Parser.CurName) = UpperCase(p_TagName)) then
            Result := RemoveZerosFimString(Parser.CurContent);
      end;
  end;
  Parser.Free;
end;

function TCACIC_Windows.verFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function TCACIC_Windows.getVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

{*------------------------------------------------------------------------------
  Retorna a pasta de instalação do MS-Windows
-------------------------------------------------------------------------------}
function TCACIC_Windows.getWinDir : string;
var
  WinPath: array[0..MAX_PATH + 1] of char;
begin
  GetWindowsDirectory(WinPath,MAX_PATH);
  Result := StrPas(WinPath)+'\';
end;

{*------------------------------------------------------------------------------
  Retorna a unidade de instalação do MS-Windows
-------------------------------------------------------------------------------}
function TCACIC_Windows.getHomeDrive() : string;
begin
  Result := MidStr(getWinDir,1,3); //x:\
end;

{*------------------------------------------------------------------------------
  Insere exceção na FireWall nativa do MS-Windows

  @param p_EntryName             String  Nome da exceção
  @param p_ApplicationPathAndExe String  Caminho e nome da aplicação
  @param p_Enabled               Boolean Estado da exceção
-------------------------------------------------------------------------------}
procedure TCACIC_Windows.addApplicationToFirewall(p_EntryName:string;p_ApplicationPathAndExe:string; p_Enabled : boolean);
var   fwMgr,app:OleVariant;
      profile:OleVariant;
Const NET_FW_PROFILE_DOMAIN = 0;
      NET_FW_PROFILE_STANDARD = 1;
      NET_FW_IP_VERSION_ANY = 2;
      NET_FW_IP_PROTOCOL_UDP = 17;
      NET_FW_IP_PROTOCOL_TCP = 6;
      NET_FW_SCOPE_ALL = 0;
      NET_FW_SCOPE_LOCAL_SUBNET = 1;
begin
  writeDebugLog('addApplicationToFirewall - BEGIN');
  CoInitialize(nil);

  fwMgr := CreateOLEObject('HNetCfg.FwMgr');
  profile := fwMgr.LocalPolicy.CurrentProfile;
  app := CreateOLEObject('HNetCfg.FwAuthorizedApplication');
  app.ProcessImageFileName := p_ApplicationPathAndExe;
  app.Name := p_EntryName;
  app.Scope := NET_FW_SCOPE_ALL;
  app.IpVersion := NET_FW_IP_VERSION_ANY;
  app.Enabled := p_Enabled;
  profile.AuthorizedApplications.Add(app);

  CoUninitialize;
  writeDebugLog('addApplicationToFirewall - END');
end;

{*------------------------------------------------------------------------------
  Retorna array de elementos com base em separador

  @param p_String    String contendo campos e valores separados por caracter ou string
  @param p_Separador String separadora de campos e valores
-------------------------------------------------------------------------------}
Function TCACIC.explode(p_String, p_Separador : String) : TStrings;
var
    strItem       : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres,
    TamanhoSeparador,
    I : Integer;
Begin
    ListaAuxUTILS    := TStringList.Create;
    strItem          := '';
    NumCaracteres    := Length(p_String);
    TamanhoSeparador := Length(p_Separador);
    I                := 1;
    While I <= NumCaracteres Do
      Begin
        If (Copy(p_String,I,TamanhoSeparador) = p_Separador) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + p_String[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
            strItem := strItem + p_String[I];

        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
end;

{*------------------------------------------------------------------------------
  Retorna string com campos e valores separados por caracter ou string

  @param p_Array     Array contendo campos e valores
  @param p_Separador String separadora de campos e valores
-------------------------------------------------------------------------------}
Function TCACIC.implode(p_Array : TStrings ; p_Separador : String) : String;
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

{*------------------------------------------------------------------------------
  Elimina espacos excedentes na string

  @param p_str String a excluir espacos
-------------------------------------------------------------------------------}
function TCACIC.trimEspacosExcedentes(p_str: String): String;
begin
  if(ansipos('  ', p_str ) <> 0 ) then
    repeat
      p_str := StringReplace( p_str, '  ', ' ', [rfReplaceAll] );
    until ( ansipos( '  ', p_str ) = 0 );

  Result := p_str;
end;

{*------------------------------------------------------------------------------
  Atribui valor booleano à variável indicadora do status da criptografia

  @param p_boolCipher Valor booleano para atribuição à variável para status da
                      criptografia.
-------------------------------------------------------------------------------}
procedure TCACIC.setBoolCipher(p_boolCipher : boolean);
Begin
  Self.g_boolCipher := p_boolCipher;
End;
{*------------------------------------------------------------------------------
  Obtém o status da criptografia (TRUE -> Ligada  /  FALSE -> Desligada)

  @return boolean contendo o status para a criptografia
-------------------------------------------------------------------------------}
function TCACIC.getBoolCipher() : boolean;
Begin
  Result := Self.g_boolCipher;
End;

{*------------------------------------------------------------------------------
  Atribui o nome da pasta do Gerente WEB

  @param p_web_manager_address Nome da Pasta do Gerente WEB
-------------------------------------------------------------------------------}
procedure TCACIC.setWebManagerAddress(p_web_manager_address: string);
begin
  Self.g_web_manager_address := p_web_manager_address;
end;

{*------------------------------------------------------------------------------
  Obtém o nome da pasta do Gerente WEB

  @return String Nome da Pasta do Gerente WEB
-------------------------------------------------------------------------------}
function TCACIC.getWebManagerAddress() : string;
begin
  Result := Self.g_web_manager_address;
end;

{*------------------------------------------------------------------------------
  Atribui o caminho físico de instalação do agente cacic

  @param p_local_folder Caminho físico de instalação do agente cacic
-------------------------------------------------------------------------------}
procedure TCACIC.setLocalFolder(p_local_folder: string);
begin
  Self.g_local_folder := p_local_folder;
end;

{*------------------------------------------------------------------------------
  Atribui o nome do programa principal do CACIC

  @param p_main_program_name Nome do programa principal do CACIC
-------------------------------------------------------------------------------}
procedure TCACIC.setMainProgramName(p_main_program_name: string);
begin
  Self.g_main_program_name := p_main_program_name;
end;

{*------------------------------------------------------------------------------
  Atribui o código hash do programa principal do CACIC

  @param p_main_program_hash Código hash do programa principal do CACIC
-------------------------------------------------------------------------------}
procedure TCACIC.setMainProgramHash(p_main_program_hash: string);
begin
  Self.g_main_program_hash := p_main_program_hash;
end;

{*------------------------------------------------------------------------------
  Obter o caminho fisico de instalacao do agente cacic

  @return String contendo o caminho físico
-------------------------------------------------------------------------------}
function TCACIC_Windows.getLocalFolder(): string;
begin
   Result :=  Self.g_local_folder ;
end;

{*------------------------------------------------------------------------------
  Obter o nome do agente principal do CACIC

  @return String contendo o nome do agente principal do CACIC
-------------------------------------------------------------------------------}
function TCACIC.getMainProgramName(): string;
begin
   Result := Self.g_main_program_name;
end;

{*------------------------------------------------------------------------------
  Obter o código hash do agente principal do CACIC

  @return String contendo o código hash do agente principal do CACIC
-------------------------------------------------------------------------------}
function TCACIC.getMainProgramHash(): string;
begin
   Result := Self.g_main_program_hash;
end;

{*------------------------------------------------------------------------------
  Verifica se a aplicação está em execução

  @param p_app_name Nome da aplicação a ser verificada
  @return TRUE se em execução, FALSE caso contrário
-------------------------------------------------------------------------------}
function TCACIC.isAppRunning( p_app_name: PAnsiChar ): boolean;
var
	MutexHandle: THandle;

begin
   MutexHandle := CreateMutex(nil, TRUE, p_app_name);
   if (MutexHandle = 0) OR (GetLastError = ERROR_ALREADY_EXISTS)
      then Result := true
      else Result := false;
end;

{*------------------------------------------------------------------------------
  Coloca o sistema em modo de debug

-------------------------------------------------------------------------------}
procedure TCACIC_Windows.debugOn();
begin
  Self.g_debug := true;
end;

{*------------------------------------------------------------------------------
  Desliga o modo de debug do sistema

-------------------------------------------------------------------------------}
procedure TCACIC_Windows.debugOff();
begin
  Self.g_debug := false;
end;

{*------------------------------------------------------------------------------
  Coloca o sistema em modo de debug

  @return Boolean contendo status do DEBUG
-------------------------------------------------------------------------------}
function TCACIC_Windows.inDebugMode() : boolean;
begin
   Result := Self.g_debug;
end;

{*------------------------------------------------------------------------------
  Verifica se é Windows Vista ou superior

  @return TRUE se Windows Vista ou superior, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista, isWindowsGEVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsGEVista() : boolean;
begin
   Result := false;
   if(Self.g_osVersionInfoExtended) then begin
      if((g_osVersionInfoEx.dwMajorVersion >= 6) and (g_osVersionInfoEx.dwMinorVersion >= 0)) then
         Result := true;
   end
   else
      if((g_osVersionInfo.dwMajorVersion >= 6) and (g_osVersionInfo.dwMinorVersion >= 0)) then
         Result := true;
end;

{*------------------------------------------------------------------------------
  Verifica se é Windows Vista

  @return TRUE se Windows Vista, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsVista() : boolean;
begin
   Result := false;
   if(Self.g_osVersionInfoExtended) then begin
     if((g_osVersionInfoEx.dwMajorVersion = 6) and (g_osVersionInfoEx.dwMinorVersion = 0)) then
        Result := true;
   end
   else
     if((g_osVersionInfo.dwMajorVersion = 6) and (g_osVersionInfo.dwMinorVersion = 0)) then
        Result := true;
end;

{*------------------------------------------------------------------------------
  Verifica se é Windows XP ou superior

  @return TRUE se Windows XP ou superior, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsGEXP() : boolean;
begin
   Result := false;
   if(Self.g_osVersionInfoExtended) then begin
     if((g_osVersionInfoEx.dwMajorVersion >= 5) and (g_osVersionInfoEx.dwMinorVersion >= 1)) then
        Result := true;
   end
   else
     if((g_osVersionInfo.dwMajorVersion >= 5) and (g_osVersionInfo.dwMinorVersion >= 1)) then
        Result := true;
end;

{*------------------------------------------------------------------------------
  Verifica se é Windows XP

  @return TRUE se Windows XP, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsXP() : boolean;
begin
   Result := false;
   if(Self.g_osVersionInfoExtended) then begin
     if((g_osVersionInfoEx.dwMajorVersion = 5) and (g_osVersionInfoEx.dwMinorVersion = 1)) then
        Result := true;
   end
   else
     if((g_osVersionInfo.dwMajorVersion = 5) and (g_osVersionInfo.dwMinorVersion = 1)) then
        Result := true;
end;

{*------------------------------------------------------------------------------
  Verifica se é Windows 2000

  @return TRUE se Windows 2000, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindows2000() : boolean;
begin
   Result := false;
   if(Self.g_osVersionInfoExtended) then begin
     if((g_osVersionInfoEx.dwMajorVersion = 5) and (g_osVersionInfoEx.dwMinorVersion = 0)) then
        Result := true;
   end
   else
     if((g_osVersionInfo.dwMajorVersion = 5) and (g_osVersionInfo.dwMinorVersion = 0)) then
        Result := true;
end;

{*------------------------------------------------------------------------------
  Verifica se é Windows NT

  @return TRUE se Windows NT, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsNT() : boolean;
begin
   Result := false;
   if(Self.g_osVersionInfoExtended) then begin
      if((g_osVersionInfoEx.dwMajorVersion = 4) and (g_osVersionInfoEx.dwMinorVersion = 0)) then
         Result := true;
   end
   else
      if((g_osVersionInfo.dwMajorVersion = 4) and (g_osVersionInfo.dwMinorVersion = 0)) then
         Result := true;
end;

{*------------------------------------------------------------------------------
  Verifica se a plataforma do sistema é de windows 9x ou ME

  @return TRUE se plataforma de Windows 9x/ME, FALSE caso contrário
  @see isWindowsNTPlataform, isWindows9xME, isWindowsNT, isWindows2000
  @see isWindowsXP, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindows9xME() : boolean;
begin
  if (Self.g_osVersionInfoExtended) then
     Result := (Self.g_osVersionInfoEx.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS)
  else
     Result := (Self.g_osVersionInfo.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS);
end;

{*------------------------------------------------------------------------------
  Obter identificação extensa do sistema operacional

  @return String de identificação do sistema operacional
  @example 1.4.10.A
-------------------------------------------------------------------------------}
function TCACIC_Windows.getWindowsStrId() : string;
begin
  Result := 'S.O.unknown';

  try
	  if (Self.g_osVersionInfoExtended) then
      Begin
  		  if(Self.isWindows9xME) then
          Begin
     			  Result := IntToStr(Self.g_osVersionInfoEx.dwPlatformId)   + '.' +
	     	              IntToStr(Self.g_osVersionInfoEx.dwMajorVersion) + '.' +
		                  IntToStr(Self.g_osVersionInfoEx.dwMinorVersion) + ifThen(trim(Self.g_osVersionInfoEx.szCSDVersion)='','','.' + trim(Self.g_osVersionInfoEx.szCSDVersion))
          End
		    else
          Begin
  			    Result := IntToStr(Self.g_osVersionInfoEx.dwPlatformId)   + '.' +
	  			            IntToStr(Self.g_osVersionInfoEx.dwMajorVersion) + '.' +
		  		            IntToStr(Self.g_osVersionInfoEx.dwMinorVersion) + '.' +
			  	            IntToStr(Self.g_osVersionInfoEx.wProductType)   + '.' +
				              IntToStr(Self.g_osVersionInfoEx.wSuiteMask);
          End
      End
	  else
      Begin
  		  Result := IntToStr(Self.g_osVersionInfo.dwPlatformId)   + '.' +
	  			        IntToStr(Self.g_osVersionInfo.dwMajorVersion) + '.' +
		  		        IntToStr(Self.g_osVersionInfo.dwMinorVersion) + ifThen(trim(Self.g_osVersionInfo.szCSDVersion)='','','.'+trim(Self.g_osVersionInfo.szCSDVersion));
      End;
  except
  end;

  Result := Result + getBitPlatform;
end;

{
Returns String with bit platform information ( .32 / .64)
}

function TCACIC_Windows.getBitPlatform() : String;
  // Type of IsWow64Process API fn
  type
    TIsWow64Process = function(Handle: Windows.THandle; var Res: Windows.BOOL): Windows.BOOL; stdcall;
  var
    IsWow64Result: Windows.BOOL; // Result from IsWow64Process
    IsWow64Process: TIsWow64Process; // IsWow64Process fn reference
    boolIsWow64 : boolean;
begin
  Result := '';
  // Try to load required function from kernel32
  IsWow64Process := Windows.GetProcAddress(Windows.GetModuleHandle('kernel32'), 'IsWow64Process');
  if Assigned(IsWow64Process) then
    Begin
      if IsWow64Process(Windows.GetCurrentProcess, IsWow64Result) then
        Begin
          boolIsWow64 := IsWow64Result;
          if boolIsWow64 then
            Result := '.64'
          else
            Result := '.32';
        End;
//      else
//        Result := 'IsWow64 call failed';
    End
//  else
//    s := 'IsWow64Process not present in kernel32.dll';
end;

// Dica baixada de http://procedure.blig.ig.com.br/
// Adaptada por Anderson Peterle - v:2.2.0.16 - 03/2007
procedure TCACIC.killFiles(p_Path, p_FilesNames : string);
var SearchRec: TSearchRec;
    Result: Integer;
    strFileName : String;
begin
  writeDebugLog('killFiles - BEGIN');
  writeDebugLog('killFiles - Path: "' + p_Path + '" FilesNames: "' + p_FilesNames + '"');
  strFileName := StringReplace(p_Path + '\' + p_FilesNames,'\\','\',[rfReplaceAll]);
  Result:=FindFirst(strFileName, faAnyFile, SearchRec);

  while result=0 do
    begin
      strFileName := StringReplace(p_Path + '\' + SearchRec.Name,'\\','\',[rfReplaceAll]);

      if not DeleteFile(strFileName) then
        Begin
          if (not isWindowsNTPlataform()) then // Menor que NT Like
            KillTask(SearchRec.Name)
          else
            KillProcess(FindWindow(PChar(SearchRec.Name),nil));
            DeleteFile(strFileName);
        End;

      Result := FindNext(SearchRec);
    end;
  writeDebugLog('killFiles - END');
end;

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{For Windows 9x/ME/2000/XP }
procedure TCACIC.killTask(p_ExeFileName: string);
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  intAuxKillTask : integer;
begin
  writeDebugLog('killTask - BEGIN');
  writeDebugLog('killTask - ExeFileName: "' + p_ExeFileName + '"');
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(p_ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(p_ExeFileName))) then
      intAuxKillTask := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
  writeDebugLog('killTask - END');
end;

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{ For Windows NT/2000/XP }
procedure TCACIC.KillProcess(p_HWindowHandle: HWND);
var
  hprocessID: INTEGER;
  processHandle: THandle;
  DWResult: DWORD;
begin
  writeDebugLog('killProcess - BEGIN');

  SendMessageTimeout(p_HWindowHandle, WM_DDE_TERMINATE, 0, 0,
    SMTO_ABORTIFHUNG or SMTO_NORMAL, 5000, DWResult);

  if isWindow(p_HWindowHandle) then
  begin
    // PostMessage(hWindowHandle, WM_QUIT, 0, 0);

    { Get the process identifier for the window}
    GetWindowThreadProcessID(p_HWindowHandle, @hprocessID);
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
  writeDebugLog('killProcess - END');
end;

procedure TCACIC_Windows.writeDebugLog(p_msg:string);
Begin
  if inDebugMode then
      writeDailyLog('[DEBUG] - v.' + getVersionInfo(ParamStr(0)) + ' - '+p_msg);
End;


procedure TCACIC_Windows.writeDailyLog(strMsg : String);
var DailyLogFile : TextFile;
    strAtualDate,
    strLogFileDate,
    strLogFileName : string;
begin
   try
      if not DirectoryExists(getLocalFolder + 'Logs') then
        ForceDirectories(getLocalFolder + 'Logs');

      strLogFileName := getLocalFolder + 'Logs\' + StringReplace(UpperCase(ExtractFileName(ParamStr(0))),'.EXE','.log',[rfReplaceAll]);
      DateTimeToString(strAtualDate  , 'yyyymmdd', Date);

      if FileExists(strLogFileName) then
        DateTimeToString(strLogFileDate, 'yyyymmdd', FileDateToDateTime(Fileage(strLogFileName)))
      else
        strLogFileDate := '0';

      FileSetAttr (strLogFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
      AssignFile(DailyLogFile,strLogFileName); {Associa o arquivo a uma variável do tipo TextFile}

      {$IOChecks off}
      Reset(DailyLogFile); {Abre o arquivo texto}
      {$IOChecks on}

      if (IOResult <> 0) or                    // Arquivo de log diário não existe
         (strAtualDate <> strLogFileDate) then // Arquivo de log diário não tem data atual
        Begin
          Rewrite (DailyLogFile); // Recriação do arquivo de log diário
          Append(DailyLogFile);
          Writeln(DailyLogFile,'====================> Inicio de Log Diário para ' + UpperCase(ExtractFileName(ParamStr(0))) + '  <====================');
        End;

      Append(DailyLogFile);
      Writeln(DailyLogFile,FormatDateTime('dd/mm hh:nn:ss ', Now)+ strMsg); {Grava a string no arquivo de log diário}
      CloseFile(DailyLogFile); {Fecha o arquivo de log diário}
      if (trim(g_strAcao)='') then g_strAcao := strMsg;
   except
      Begin
          AssignFile(DailyLogFile,getLocalFolder + 'Logs\ERROR.txt'); {Associa o arquivo a uma variável do tipo TextFile}
          Rewrite(DailyLogFile); // Recriação do arquivo de log diário
          Append(DailyLogFile);
          Writeln(DailyLogFile,'Ocorreu uma exceção ao gravar o log para ' + UpperCase(ExtractFileName(ParamStr(0))));
      End;
   end;
end;

{*------------------------------------------------------------------------------
  Verifica se a plataforma do sistema é de Windows NT

  @return TRUE se plataforma de Windows NT, FALSE caso contrário
  @see isWindows9xME, isWindowsVista
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsNTPlataform() : boolean;
begin
  if(Self.g_osVersionInfoExtended)
    then Result := (Self.g_osVersionInfoEx.dwPlatformId = VER_PLATFORM_WIN32_NT)
    else Result := (Self.g_osVersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT);
end;

{*------------------------------------------------------------------------------
  Verifica se é administrador do sistema operacional se em plataforma NT

  @return TRUE se administrador do sistema, FALSE caso contrário
-------------------------------------------------------------------------------}
function TCACIC_Windows.isWindowsAdmin(): Boolean;

const
   constSECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
   constSECURITY_BUILTIN_DOMAIN_RID = $00000020;
   constDOMAIN_ALIAS_RID_ADMINS = $00000220;

var
   hAccessToken: THandle;
   ptgGroups: PTokenGroups;
   dwInfoBufferSize: DWORD;
   psidAdministrators: PSID;
   x: Integer;
   bSuccess: BOOL;

begin
  if (not Self.isWindowsNTPlataform()) then // Se nao NT (ex: Win95/98)
       // Se nao eh NT nao tem ''admin''
       Result   := True
  else begin
	  Result   := False;
	  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
	  if not bSuccess then begin
  		 if GetLastError = ERROR_NO_TOKEN then
	        bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
	  end;
	  if bSuccess then begin
		GetMem(ptgGroups, 1024);
		bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize);
		CloseHandle(hAccessToken);
		if bSuccess then begin
		  AllocateAndInitializeSid(constSECURITY_NT_AUTHORITY, 2,
								   constSECURITY_BUILTIN_DOMAIN_RID,
								   constDOMAIN_ALIAS_RID_ADMINS,
								   0, 0, 0, 0, 0, 0, psidAdministrators);
		  {$R-}
		  for x := 0 to ptgGroups.GroupCount - 1 do
          if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then begin
			       Result := True;
			       Break;
			    end;
		  {$R+}
		  FreeSid(psidAdministrators);
		end;
		FreeMemory(ptgGroups);
	  end;
  end;
end;

{*------------------------------------------------------------------------------
  Executa commandos, substitui o WinExec

  @autor: Marcos Dell Antonio
  @param p_cmd        Comando a ser executado
  @param p_wait       TRUE se deve aguardar término da excução, FALSE caso contrário
-------------------------------------------------------------------------------}
{function TCACIC_Windows.createSampleProcess(p_cmd: string; p_wait: boolean ): boolean;
begin
end;
}
{*------------------------------------------------------------------------------
  Executa commandos, substitui o WinExec

  @autor: Marcos Dell Antonio
  @param p_cmd        Comando a ser executado
  @param p_wait       TRUE se deve aguardar término da excução, FALSE caso contrário
  @param p_showWindow Constante que define o tipo de exibição da janela do aplicativo
-------------------------------------------------------------------------------}
function TCACIC_Windows.createOneProcess(p_cmd: string; p_wait: boolean; p_showWindow : word = SW_HIDE): boolean;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
begin
  writeDebugLog('createOneProcess - BEGIN');
  writeDebugLog('createOneProcess - Cmd: "' + p_cmd + '"');

  FillChar(SUInfo, SizeOf(SUInfo), #0);
  SUInfo.cb      := SizeOf(SUInfo);
  SUInfo.dwFlags := STARTF_USESHOWWINDOW;
  SUInfo.wShowWindow := p_showWindow;

  Result := CreateProcess(nil,
                          PChar(p_cmd),
                          nil,
                          nil,
                          false,
                          CREATE_NEW_CONSOLE or
                          BELOW_NORMAL_PRIORITY_CLASS,
                          nil,
                          nil,
                          SUInfo,
                          ProcInfo);

  if (Result) then
  begin
    if(p_wait) then begin
       WaitForSingleObject(ProcInfo.hProcess, INFINITE);
       CloseHandle(ProcInfo.hProcess);
       CloseHandle(ProcInfo.hThread);
    end;
  end;
  writeDebugLog('createOneProcess - END');
end;

{*------------------------------------------------------------------------------
  Para cálculo de HASH de determinado arquivo.

  @autor: Anderson Peterle
  @param p_strFileName - Nome do arquivo para extração do HashCode
-------------------------------------------------------------------------------}
function TCACIC.GetFileHash(p_FileName : String) : String;
Begin
  Result := 'Arquivo "'+p_FileName+'" Inexistente!';
  if (FileExists(p_FileName)) then
    Result := MD5Print(MD5File(p_FileName));
End;

{*------------------------------------------------------------------------------
  Mostra ou oculta o cacic na "systray" do windows

  @autor: Diversos - compilado de vários exemplos obtidos na internet
  @param p_visible TRUE se deve mostrar na systray, FALSE caso contrário
-------------------------------------------------------------------------------}
procedure TCACIC_Windows.showTrayIcon(p_visible:boolean);
 Var
   v_tray, v_child : hWnd;
   v_char : Array[0..127] of Char;
   v_string : String;

 Begin
   v_tray := FindWindow('Shell_TrayWnd', NIL);
   v_child := GetWindow(v_tray, GW_CHILD);
   While v_child <> 0
      do Begin
         If GetClassName(v_child, v_char, SizeOf(v_char)) > 0
            Then Begin
                v_string := StrPAS(v_char);
                If UpperCase(v_string) = 'TRAYNOTIFYWND'
                   then begin
                       If p_visible
                          then ShowWindow(v_child, 1)
                          else ShowWindow(v_child, 0);
                   end;
            End;
         v_child := GetWindow(v_child, GW_HWNDNEXT);
      End;
 End;

{*------------------------------------------------------------------------------
  Obter a chave para criptografia simétrica

  @return String contendo a chave simétrica
-------------------------------------------------------------------------------}
function TCACIC.getCipherKey(): string;
begin
   Result := CACIC_CIPHERKEY;
end;

{*------------------------------------------------------------------------------
  Obter o vetor de inicialização para criptografia

  @return String contendo o vetor de inicialização
-------------------------------------------------------------------------------}
function TCACIC.getIV(): string;
begin
   Result := CACIC_IV;
end;

{*------------------------------------------------------------------------------
  Obter o valor para tamanho da chave de criptografia

  @return Integer contendo o tamanho para chave de criptografia
-------------------------------------------------------------------------------}
function TCACIC.getKeySize(): Integer;
begin
   Result := CACIC_KEYSIZE;
end;

{*------------------------------------------------------------------------------
  Obter o valor para tamanho do bloco de criptografia

  @return Integer contendo o tamanho para bloco de criptografia
-------------------------------------------------------------------------------}
function TCACIC.getBlockSize(): Integer;
begin
   Result := CACIC_BLOCKSIZE;
end;

{*------------------------------------------------------------------------------
  Obter o nome do arquivo de informações

  @return String contendo o nome do arquivo de informações
-------------------------------------------------------------------------------}
function TCACIC.getInfFileName(): string;
begin
   Result := StringReplace(UpperCase(ExtractFileName(ParamStr(0))),'.EXE','.inf',[rfReplaceAll]);
end;
                                                                   
{*------------------------------------------------------------------------------
  Obter o nome do arquivo de configurações

  @return String contendo o nome do arquivo de configurações
-------------------------------------------------------------------------------}
function TCACIC.getIniFileName(): string;
begin
   Result := StringReplace(UpperCase(ExtractFileName(ParamStr(0))),'.EXE','.ini',[rfReplaceAll]);
end;


{*------------------------------------------------------------------------------
  Obter o separador para criação de listas locais

  @return String contendo o separador de campos e valores
-------------------------------------------------------------------------------}
function TCACIC.getSeparatorKey(): string;
begin
   Result := CACIC_SEPARATORKEY;
end;

// Encrypt a string and return the Base64 encoded result
function TCACIC.enCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    writeDebugLog('TCACIC.enCrypt - BEGIN');
    writeDebugLog('TCACIC.enCrypt - p_Data: "' + p_Data + '"');

    if self.g_boolCipher then
      Begin
        // Pad Key, IV and Data with zeros as appropriate
        l_Key   := PadWithZeros(CACIC_CIPHERKEY,CACIC_KEYSIZE);
        l_IV    := PadWithZeros(CACIC_IV,CACIC_BLOCKSIZE);
        l_Data  := PadWithZeros(p_Data,CACIC_BLOCKSIZE);

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);
        if Length(CACIC_CIPHERKEY) <= 16 then
          l_Cipher.Init(l_Key[1],128,@l_IV[1])
        else if Length(CACIC_CIPHERKEY) <= 24 then
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
      End
    Else
      // Return the original value
      Result := p_Data;
  Except
      Result := 'ERROR - Check TCACIC.enCrypt Function';
  End;

  writeDebugLog('TCACIC.enCrypt - Result: "' + Result + '"');
  writeDebugLog('TCACIC.enCrypt - END');
end;

function TCACIC.deCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data,
  l_Key,
  l_IV : string;
begin
  Try
    writeDebugLog('TCACIC.deCrypt - BEGIN');
    writeDebugLog('TCACIC.deCrypt - p_Data: "' + p_Data + '"');
    if self.g_boolCipher AND (trim(p_Data) <> '') then
      Begin
        // Pad Key and IV with zeros as appropriate
        l_Key := PadWithZeros(CACIC_CIPHERKEY,CACIC_KEYSIZE);
        l_IV  := PadWithZeros(CACIC_IV,CACIC_BLOCKSIZE);
        // Decode the Base64 encoded string
        l_Data := Base64DecodeStr(trim(p_Data));

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);

        if Length(CACIC_CIPHERKEY) <= 16 then
          l_Cipher.Init(l_Key[1],128,@l_IV[1])
        else if Length(CACIC_CIPHERKEY) <= 24 then
          l_Cipher.Init(l_Key[1],192,@l_IV[1])
        else
          l_Cipher.Init(l_Key[1],256,@l_IV[1]);

        // Decrypt the data
        l_Cipher.DecryptCBC(l_Data[1],l_Data[1],Length(l_Data));

        // Free the cipher and clear sensitive information
        l_Cipher.Free;

        FillChar(l_Key[1],Length(l_Key),0);

        // Return the result (unCrypted)
        Result := trim(l_Data);
      End
    Else
      // Return the original value
      Result := p_Data
  Except
      Result := 'ERROR - Check TCACIC.deCrypt Function';
  End;
  writeDebugLog('TCACIC.deCrypt - Result: "' + Result + '"');
  writeDebugLog('TCACIC.deCrypt - END');
end;

// Pad a string with zeros so that it is a multiple of size
function TCACIC.padWithZeros(const str : string; size : integer) : string;
var origsize, i : integer;
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

end.

