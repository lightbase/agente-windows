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
        function getLocalFolderName() : string;
        procedure setLocalFolderName( pPath: string );
-------------------------------------------------------------------------------}
unit CACIC_Library;

interface

uses	Windows,
      Classes,
      SysUtils,
      StrUtils,
      MD5,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64,
      ActiveX,
      PJVersionInfo,
      Registry,
      IniFiles,
      Tlhelp32,
      ComObj,
      ShellAPI,
      Variants;

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
       protected
         g_strAcao    :string;
         g_local_folder_name: string;
         /// Mantem a identificação do sistema operacional
         g_osVersionInfo: TOSVersionInfo;
         /// Mantem a identificação extendida do sistema operacional
         g_osVersionInfoEx: TOSVersionInfoEx;
         /// TRUE se houver informação extendida do SO, FALSE caso contrário
         g_osVersionInfoExtended: boolean;
       public
         function  explode(p_String, p_Separador : String)                                                                              : TStrings; virtual; abstract;
         function  getBitPlatform()                                                                                                     : string;
         function  getBoolToString(pBoolQuestion : boolean)                                                                             : string;   virtual; abstract;
         function  getHomeDrive()                                                                                                       : string;
         function  getLocalFolderName()                                                                                                 : string;
         function  getVersionFromHCR(pStrToProcess : String)                                                                            : string;
         function  getVersionInfo(pStrFileName: string)                                                                                 : string;
         function  getWindowsStrId()                                                                                                    : string;
         function  getWinDir()                                                                                                          : string;
         function  implode(const pTStrArray: TStrings; const pStrSeparator: string)                                                     : string;  virtual; abstract;
         function  isWindowsAdmin()                                                                                                     : boolean;
         function  isWindowsGEVista()                                                                                                   : boolean;
         function  isWindowsGEXP()                                                                                                      : boolean;
         function  isWindowsNT()                                                                                                        : boolean;
         function  isWindowsNTPlataform()                                                                                               : boolean;
         function  isWindowsVista()                                                                                                     : boolean;
         function  isWindowsXP()                                                                                                        : boolean;
         function  isWindows2000()                                                                                                      : boolean;
         function  isWindows9xME()                                                                                                      : boolean;
         function  verFmt(const MS, LS: DWORD)                                                                                          : string;
         procedure writeDebugLog(pStrDebugMessage:string);                                                                                          virtual; abstract;
         procedure writeExceptionLog(pStrExceptionMessage, pStrExceptionClassName : String; pStrAddedMessage : String = '');                        virtual; abstract;
   end;

{*------------------------------------------------------------------------------
 Classe geral da biblioteca
-------------------------------------------------------------------------------}
   TCACIC = class(TCACIC_Windows)
       constructor Create();
       destructor Destroy; override;
       private
       protected
         g_web_manager_address,
         g_web_services_folder_name,
         g_main_program_name,
         g_main_program_hash,
         g_details_to_debugging     : string;
         g_boolCipher               : boolean;

       public
         Windows : TCACIC_Windows; /// objeto de informacoes de windows
         function  checkIfFileDateIsToday(pStrFileName : String)                                                            : Boolean;
         function  countOccurences(const strSubText, strText: string)                                                       : Integer;
         function  createOneProcess(pStrCmd: string; pBoolWait: boolean; pWordShowWindow : word = SW_HIDE)                  : Boolean;
         function  capitalize (CONST s: STRING)                                                                             : String;
         function  checkModule(pStrModuleFileName, pStrModuleHashCode : String)                                             : String;
         function  deCrypt(pStrCipheredText : String; pBoolShowInLog : boolean = true; pBoolForceDecrypt : boolean = false) : String;
         function  deleteFileOrFolder(pStrFileOrFolderName : string)                                                        : Boolean;
         function  enCrypt(pStrPlainText : String; pBoolShowInLog : boolean = true; pBoolForceEncrypt : boolean = false)    : String;
         function  explode(p_String, p_Separador : String)                                                                  : TStrings; override;
         function  fixFolderAtHomeDrive(pStrFolderName : String)                                                            : String;
         function  fixWebAddress(pStrWebAddress : String)                                                                   : String;
         function  getBlockSize()                                                                                           : Integer;
         function  getBoolCipher()                                                                                          : Boolean;
         function  getBoolToString(pBoolQuestion : boolean)                                                                 : String;   override;
         function  getCipherKey()                                                                                           : String;
         function  getDetailsToDebugging()                                                                                  : String;
         function  getFileSize(pStrFileNameToExamine: string; boolShowInKBytes: Boolean)                                    : String;
         function  getInfFileName()                                                                                         : String;
         function  getFileHash(pStrFileName : String)                                                                       : String;
         function  getFolderDate(var p_FolderName: string)                                                                  : TDateTime;
         function  getIV()                                                                                                  : String;
         function  getKeySize()                                                                                             : Integer;
         function  getMainProgramName()                                                                                     : String;
         function  getMainProgramHash()                                                                                     : String;
         function  getParam(pStrParamName : string)                                                                         : String;
         function  getRootKey(strRootKey: String)                                                                           : HKEY;
         function  getSeparatorKey()                                                                                        : String;
         function  getTagsFromValues(pStrSource : String; pStrTags : String = '[]')                                         : TStrings;
         function  getValueFromFile(pStrSectionName, pStrKeyName, pStrFileName : String; pBoolShowInDebug : boolean = true) : String;
         function  getValueFromTags(pStrTagLabel, pStrSource : String; pStrTags : String = '[]')                            : String;
         function  getValueRegistryKey(p_KeyName : String)                                                                  : Variant;
         function  getWebManagerAddress()                                                                                   : String;
         function  getWebServicesFolderName()                                                                               : String;
         function  implode(const pTStrArray: TStrings; const pStrSeparator: string)                                         : String;   override;
         function  isAppRunning(pStrAppName: PAnsiChar )                                                                    : Boolean;
         function  isInDebugMode(pStrDetailName : String = '')                                                              : Boolean;
         function  listParams                                                                                               : String;
         function  padWithZeros(const str : string; size : integer)                                                         : String;
         function  removeSpecialsCharacters(p_Text : String)                                                                : String;
         function  removeZerosFimString(Texto : String)                                                                     : String;
         function  replaceInvalidHTTPChars(p_String : String)                                                               : String;
         function  replacePseudoTagsWithCorrectChars(pStrString : String)                                                   : String;
         function  setValueRegistryKey(p_KeyName: String; p_Data: Variant)                                                  : Variant;
         function  trimEspacosExcedentes(p_str: string)                                                                     : String;
         procedure addApplicationToFirewall(p_EntryName:string;p_ApplicationPathAndExe:string; p_Enabled : boolean);
         procedure criaTXT(p_Dir, p_File : String; pStrTextToWrite : String = '');
         procedure killProcess(p_HWindowHandle: HWND);
         procedure killTask(p_ExeFileName: string);
         procedure replaceEnvironmentVariables(var pStrText : String; pStrTag : String = '%');
         procedure setBoolCipher(p_boolCipher : boolean);
         procedure setDetailsToDebugging(pStrDetailsToDebugging: String);         
         procedure setLocalFolderName(pStrLocalFolderName: string = 'Cacic');
         procedure setMainProgramName(p_main_program_name: string);
         procedure setMainProgramHash(p_main_program_hash: string);
         procedure setValueToFile(pStrSectionName, pStrKeyName, pStrValue, pStrFileName : String);
         procedure setValueToTags(pStrTagLabel, pStrTagValue : String; var pStrSource : String; pStrTags : String = '[]');
         procedure setWebManagerAddress(pStrWebManagerAddress: string);
         procedure setWebServicesFolderName(pStrWebServicesFolderName: string);
         procedure writeDailyLog(pStrLogMessage : String; pStrFileNameSuffix : String = '');
         procedure writeDebugLog(pStrDebugMessage : String); override;
         procedure writeExceptionLog(pStrExceptionMessage, pStrExceptionClassName : String; pStrAddedMessage : String = ''); override;
   end;

// Declaração de constantes para a biblioteca
const CACIC_PROCESS_WAIT   = true; // aguardar fim do processo
      CACIC_PROCESS_NOWAIT = false; // não aguardar o fim do processo

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const CACIC_KEYSIZE        = 32; // 32 bytes = 256 bits
      CACIC_BLOCKSIZE      = 16; // 16 bytes = 128 bits

// Chave AES. Recomenda-se que cada empresa altere a sua chave.
// Esta chave é passada como parâmetro para o Gerente de Coletas
const CACIC_CIPHERKEY      = 'CacicBrasil';
      CACIC_IV             = 'abcdefghijklmnop';
      CACIC_SEPARATORKEY   = '=CacicIsFree='; // Usada apenas para os arquivos de controle (.INF)

{
 Controle de prioridade de processo
 http://msdn.microsoft.com/en-us/library/ms683211(VS.85).aspx
}
const BELOW_NORMAL_PRIORITY_CLASS = $00004000;
  {$EXTERNALSYM BELOW_NORMAL_PRIORITY_CLASS}

var   P_OSVersionInfo: POSVersionInfo;

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
   Try
     FreeMemory(P_OSVersionInfo);
   Except
   End;
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

function TCACIC.deleteFileOrFolder(pStrFileOrFolderName: String) : boolean;
var OS: TSHFileOpStruct;
begin
  Result := true;
  if Length(pStrFileOrFolderName) > 0 then
    begin
      FillChar(OS, sizeof(OS),0);
      OS.pFrom := PChar(pStrFileOrFolderName + #0);
      OS.wFunc := FO_DELETE;
      OS.fFlags := FOF_NOCONFIRMATION or FOF_SILENT;
      Result := (SHFileOperation(OS)=0);
    end
end;

{ Returns a count of the number of occurences of SubText in Text }
function TCACIC.CountOccurences(const strSubText, strText: string): Integer;
begin
  if (strSubText = '') OR (strText = '') OR (Pos(strSubText, strText) = 0) then
    Result := 0
  else
    Result := (Length(strText) - Length(StringReplace(strText, strSubText, '', [rfReplaceAll]))) div  Length(strSubText);
end;  { CountOccurences }

{*------------------------------------------------------------------------------------
 Transformar as variáveis de ambiente existentes no Texto em seus respectivos valores
-------------------------------------------------------------------------------------}
procedure TCACIC.replaceEnvironmentVariables(var pStrText : String; pStrTag : String = '%');
var intLoop            : integer;
    strVariableName    : String;
    tstrVariablesNames : TStrings;
begin
  // Somente trato as variáveis de ambiente se as tags estiverem em número par!
  if (countOccurences(pStrTag,pStrText) mod 2 = 0) then
    Begin
      tstrVariablesNames := explode(pStrText, pStrTag);
      intloop := 1;
      while (intLoop < tstrVariablesNames.Count) do
        Begin
          if strVariableName <> '' then
            strVariableName := strVariableName + ',';

          strVariableName := strVariableName + tstrVariablesNames[intLoop];
          inc(intLoop,2);
        End;

      tstrVariablesNames := explode(strVariableName,',');
      for intLoop := 0 to tstrVariablesNames.Count - 1 do
        pStrText := StringReplace(pStrText,pStrTag + tstrVariablesNames[intLoop] + pStrTag, GetEnvironmentVariable(tstrVariablesNames[intLoop]),[rfReplaceAll]);
    End;
  writeDebugLog('replaceEnvironmentVariables: Final: "' + pStrText + '"');
end;

{*------------------------------------------------------------------------------------
 Retornar o endereço Web devidamente formatado
-------------------------------------------------------------------------------------}
function TCACIC.fixWebAddress(pStrWebAddress : String): String;
Begin
  Result := '';
  if (pStrWebAddress <> '') then
    Begin
      Result := StringReplace(pStrWebAddress,'//'   ,'',[rfReplaceAll]);        // Substituo possíveis "//" por nada
      Result := StringReplace(Result          ,'http:','',[rfReplaceAll]);      // Substituo possível "http:" por nada
      Result := Result + '/';                                                   // Acrescento "/"
      Result := StringReplace(Result          ,'//'   ,'',[rfReplaceAll]);      // Substituo possíveis "//" por nada
      Result := Result + '/';                                                   // Acrescento "/'
      Result := 'http://' + StringReplace(Result, '//', '/', [rfReplaceAll]);   // Precedo com "http://"
    End;
End;


{*------------------------------------------------------------------------------------
Retornar para fixar um nome de pasta no HomeDrive
-------------------------------------------------------------------------------------}
function TCACIC.fixFolderAtHomeDrive(pStrFolderName : String) : String;
var tstrFolderName1,
    tstrFolderName2 : TStrings;
    intAUX : integer;
Begin
  Result := pStrFolderName;

  // Crio um array separado por ":" (Para o caso de ter sido informada a letra da unidade)
  //tstrLocalFolder1 := TStrings.Create;

  tstrFolderName1 := explode(StringReplace(pStrFolderName,'/','\',[rfReplaceAll]),':');

  if (tstrFolderName1.Count > 1) then
    Begin
      tstrFolderName2 := TStrings.Create;
      // Ignoro a letra informada...
      // Certifico-me de que as barras são invertidas... (erros acontecem)
      // Crio um array quebrado por "\"
      Result := tstrFolderName1[1];

      tstrFolderName2 := explode(Result,'\');

      // Inicializo retorno com a unidade raiz do Sistema Operacional
      // Concateno ao retorno as partes que formarão o caminho completo do CACIC
      Result := getHomeDrive;
      for intAux := 0 to (tstrFolderName2.Count-1) do
        if (tstrFolderName2[intAux] <> '') then
            Result := Result + tstrFolderName2[intAux];
      tstrFolderName2.Free;
    End
  else
    Result := getHomeDrive + pStrFolderName + '\';

  tstrFolderName1.Free;
End;

{*------------------------------------------------------------------------------------
  Retornar Boolean TRUE caso as informações de executável e hash-code estejam corretas
-------------------------------------------------------------------------------------}
function  TCACIC.checkModule(pStrModuleFileName, pStrModuleHashCode : String) : String;
Begin
  if (getFileHash(pStrModuleFileName) = pStrModuleHashCode) then
    Result := 'Ok!'
  else if FileExists(pStrModuleFileName) then
    Result := 'Módulo Corrompido!'
  else
    Result := 'Módulo Não Baixado!';
End;
function TCACIC.getFileSize(pStrFileNameToExamine: string; boolShowInKBytes: Boolean): string;
var
  SearchRec: TSearchRec;
  strPath: string;
  intRetval,
  intFileSize,
  intKbytes : Integer;
begin
  Try
    intKbytes := StrToInt(IfThen(boolShowInKBytes,'1024','1'));
    strPath := ExpandFileName(pStrFileNameToExamine);
    try
      intRetval := FindFirst(ExpandFileName(pStrFileNameToExamine), faAnyFile, SearchRec);
      if intRetval = 0 then
        intFileSize := SearchRec.Size
      else
        intFileSize := -1;
    finally
      SysUtils.FindClose(SearchRec);
    end;

    Result := IntToStr(intFileSize);
    if intFileSize > -1 then
      Result := IntToStr((StrToInt(Result) div intKbytes)) ;
  Except
  End;
end;

function TCACIC.getParam(pStrParamName : string) : String;
var strAuxParamName : String;
    intAuxLoop : integer;
Begin
  Result          := '';
  strAuxParamName := '/' + Trim(pStrParamName) + '=';
  intAuxLoop      := 1;
  while (intAuxLoop <= ParamCount) do
    Begin
      if (LowerCase(Copy(ParamStr(intAuxLoop),1,StrLen(PAnsiChar(strAuxParamName)))) = LowerCase(strAuxParamName)) then
        Result     := Copy(ParamStr(intAuxLoop),StrLen(PAnsiChar(strAuxParamName))+1,StrLen(PChar(ParamStr(intAuxLoop))));

      inc(intAuxLoop);
    End;
End;

function TCACIC.listParams : String;
var intAuxLoop : integer;
Begin
  Result := Concat('Nenhum Parâmetro Recebido na Chamada a "' + ParamStr(0) + '"' , chr(13) ,DupeString('=',100));
  if (ParamCount > 1) then
    Begin
      Result := Concat('Lista de Parâmetros Recebidos' , chr(13) , DupeString('-',50) , chr(13));
      for intAuxLoop := 1 to ParamCount - 1 do
        Result := Concat(Result,ParamStr(intAuxLoop),chr(13));
      Result := Concat(Result,DupeString('=',100),chr(13));
    End;
End;

function TCACIC.removeSpecialsCharacters(p_Text : String) : String;
var I : Integer;
    strAuxRSC : String;
Begin
   For I := 0 To Length(p_Text) Do
     if ord(p_Text[I]) in [32..126] Then
        strAuxRSC := strAuxRSC + p_Text[I]
     else
        strAuxRSC := strAuxRSC + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAuxRSC;
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
    strAuxRZFS  : string;
Begin
   strAuxRZFS := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         strAuxRZFS := Texto[I] + strAuxRZFS;
   Result := trim(strAuxRZFS);
end;

procedure TCACIC.criaTXT(p_Dir, p_File : String; pStrTextToWrite : String = '');
var v_TXT : TextFile;
begin
  AssignFile(v_TXT,p_Dir + '\' + p_File + '.txt'); {Associa o arquivo a uma variável do tipo TextFile}
  Rewrite (v_TXT);

  if (pStrTextToWrite <> '') then
    Begin
      Append(v_TXT);
      Writeln(v_TXT,pStrTextToWrite);
    End;

  Closefile(v_TXT);
end;
{
    function RetornaValorShareNT(pStrKey, pStrText : String) : String;
    var intPosKey,
        intLoop    : integer;
    Begin
      Result := '';
      intPosKey := pos(' ' + pStrKey + '=',pStrText);
      if (intPosKey > 0) then
        Begin
          intLoop   := length(pStrText);
          while (intLoop > intPosKey) do
            Begin
              if (copy(pStrText,intLoop,1) <> '=') then
                Result := copy(pStrText,intLoop,1) + Result
              else
                Begin
                  if (copy(pStrText,intLoop - length(pStrKey),length(pStrKey)) = pStrKey) then
                    exit
                  else
                    Begin
                      Result := '';
                      while (copy(pStrText,intLoop,1) <> ' ') do
                        dec(intLoop);
                    End;
                End;
              dec(intLoop);
            End;
        End;
    End;
}

// Função para recuperar valor delimitado por tags "[" e "]"
function TCACIC.getValueFromTags(pStrTagLabel, pStrSource : String; pStrTags : String = '[]'): String;
var strTagInicio,
    strTagFim,
    strSource : String;
begin
  Result       := '';
  strSource    := LowerCase(pStrSource);
  strTagInicio := copy(pStrTags,1,1)       + LowerCase(pStrTagLabel) + copy(pStrTags,2,1);
  strTagFim    := copy(pStrTags,1,1) + '/' + LowerCase(pStrTagLabel) + copy(pStrTags,2,1);

  if (pos(strTagInicio,strSource) > 0) and (pos(strTagFim,strSource) > 0) then
    Result := copy(pStrSource,pos(strTagInicio,strSource)+length(strTagInicio),pos(strTagFim,strSource) - pos(strTagInicio,strSource) - length(strTagInicio));

  writeDebugLog('getValueFromTags: "'+pStrTagLabel+'" => "' + Result + '"');
End;

// Função para obter nomes de tags existentes em pStrSource
function TCACIC.getTagsFromValues(pStrSource : String; pStrTags : String = '[]') : TStrings;
var intLoopTags  : integer;
    strTagsNames : String;
    tstrTags     : TStrings;
Begin
  tstrTags     := explode(pStrSource,copy(pStrTags,2,1));
  strTagsNames := '';
  for intLoopTags := 0 to tstrTags.Count -1 do
    Begin
      if (copy(tstrTags[intLoopTags],1,1) = copy(pStrTags,1,1)) and (copy(tstrTags[intLoopTags],2,1) <> '/') then
        Begin
          if (strTagsNames <> '') then
            strTagsNames := strTagsNames + ',';

          strTagsNames := strTagsNames + copy(tstrTags[intLoopTags],2,length(tstrTags[intLoopTags]));
        End;
    End;

  Result := explode(strTagsNames,',');
End;

// Procedure para atribuir valor delimitados por tags "[" e "]"
procedure TCACIC.setValueToTags(pStrTagLabel, pStrTagValue : String; var pStrSource : String; pStrTags : String = '[]');
var strAuxSVTT       : String;
begin
  strAuxSVTT := getValueFromTags(pStrTagLabel,pStrSource,pStrTags);
  pStrSource := StringReplace(pStrSource, copy(pStrTags,1,1) + pStrTagLabel + copy(pStrTags,2,1) + strAuxSVTT + copy(pStrTags,1,1) + '/' + pStrTagLabel + copy(pStrTags,2,1), '' , [rfReplaceAll]);
  pStrSource := pStrSource + copy(pStrTags,1,1) + pStrTagLabel + copy(pStrTags,2,1) + pStrTagValue + copy(pStrTags,1,1) + '/' + pStrTagLabel + copy(pStrTags,2,1);
End;

function TCACIC.getValueFromFile(pStrSectionName, pStrKeyName, pStrFileName : String; pBoolShowInDebug : boolean = true): String;
//Para buscar do Arquivo INF...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
var textFileText    : TStringList;
    intFileLine,
    intSectionSize,
    intKeySize      : integer;
    strSectionName,
    strKeyName      : string;
begin
  if pBoolShowInDebug then // Para evitar EStackOverflow devido a requisição recursiva!
    Begin
      writeDebugLog('getValueFromFile: pStrSectionName: "' + pStrSectionName + '"');
      writeDebugLog('getValueFromFile: pStrKeyName: "'     + pStrKeyName     + '"');
      writeDebugLog('getValueFromFile: pStrFileName: "'    + pStrFileName    + '"');
    End;

  Result         := '';
  strSectionName := '[' + pStrSectionName + ']';
  intSectionSize := strLen(PChar(strSectionName));
  strKeyName     := pStrKeyName + '=';
  intKeySize     := strLen(PChar(strKeyName));
  textFileText   := TStringList.Create;
  intFileLine    := 0;
  if (FileExists(pStrFileName)) then
    Begin
      try
        textFileText.LoadFromFile(pStrFileName);
        While (intFileLine < textFileText.Count) Do
          Begin
            if (LowerCase(Trim(PChar(Copy(textFileText[intFileLine],1,intSectionSize)))) = LowerCase(Trim(PChar(strSectionName)))) then
               Begin
                  inc(intFileLine);
                  While (intFileLine < textFileText.Count) and (Trim(PChar(Copy(textFileText[intFileLine],1,1)))<>'[') Do
                    Begin
                      if (LowerCase(Trim(PChar(Copy(textFileText[intFileLine],1,intKeySize)))) = LowerCase(Trim(PChar(strKeyName)))) then
                          Begin
                            Result := PChar(Copy(textFileText[intFileLine],intKeySize + 1,strLen(PChar(textFileText[intFileLine]))-intKeySize));
                            intFileLine := textFileText.Count;
                          End;
                      inc(intFileLine);
                    End;
               End;
            inc(intFileLine);
          End;
      finally
        textFileText.Free;
      end;
    end
  else
    textFileText.Free;

  if pBoolShowInDebug then
    Begin
      writeDebugLog('getValueFromFile: Result: "' + Result + '"');
      writeDebugLog('getValueFromFile: ' + DupeString(':',100));
    End;
end;

// Para gravar no Arquivo INF...
procedure TCACIC.setValueToFile(pStrSectionName, pStrKeyName, pStrValue, pStrFileName : String);
var InfFile : TIniFile;
begin
  self.writeDebugLog('setValueToFile: pStrSectionName: "' + pStrSectionName + '"');
  self.writeDebugLog('setValueToFile: pStrKeyName: "'     + pStrKeyName     + '"');
  self.writeDebugLog('setValueToFile: pStrValue: "'       + pStrValue       + '"');
  self.writeDebugLog('setValueToFile: pStrFileName: "'    + pStrFileName    + '"');
  self.writeDebugLog('setValueToFile: ' + DupeString(':',100));
  if (FileGetAttr(pStrFileName) and faReadOnly) > 0 then
    FileSetAttr(pStrFileName, FileGetAttr(pStrFileName) xor faReadOnly);

  InfFile := TIniFile.Create(pStrFileName);
  InfFile.WriteString(pStrSectionName, pStrKeyName, pStrValue);
  InfFile.Free;
end;

{*------------------------------------------------------------------------------
  Insere exceção na FireWall nativa do MS-Windows

  @param p_EntryName             String  Nome da exceção
  @param p_ApplicationPathAndExe String  Caminho e nome da aplicação
  @param p_Enabled               Boolean Estado da exceção
-------------------------------------------------------------------------------}
procedure TCACIC.addApplicationToFirewall(p_EntryName:string;p_ApplicationPathAndExe:string; p_Enabled : boolean);
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
  Try
    if FileExists(p_EntryName) then
      Begin
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
      End;
  Except
    on E : Exception do
      writeExceptionLog(E.Message,E.ClassName,'addApplicationToFirewall: EntryName="'+p_EntryName+'" ApplicationPathAndExe="'+p_ApplicationPathAndExe+'"');
  End;
end;

{*------------------------------------------------------------------------------
  Retorna string de valores separados pelo caracter indicado

  @param pTstrArray    TStrings contendo os valores
  @param pStrSeparator String   separadora de valores
-------------------------------------------------------------------------------}
Function TCACIC.implode(const pTStrArray: TStrings; const pStrSeparator: string): String;
var i: Integer;
begin
  Result := pTStrArray[0];
  for i := 0 to pTStrArray.Count - 1 do
    Result := Result + pStrSeparator + pTStrArray[i];
end;
{*------------------------------------------------------------------------------
  Retorna array de elementos com base em separador

  @param p_String    String contendo campos e valores separados por caracter ou string
  @param p_Separador String separadora de campos e valores
-------------------------------------------------------------------------------}
Function TCACIC.explode(p_String, p_Separador : String) : TStrings;
var strItem       : String;
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
  Atribui nomes de métodos para DEBUG

  @param pStrWhatToDebug Valor string para atribuição à variável de nomes de
                         functions e procedures para DEBUG.
-------------------------------------------------------------------------------}
procedure TCACIC.setDetailsToDebugging(pStrDetailsToDebugging: String);
Begin
  Self.g_details_to_debugging := pStrDetailsToDebugging;
End;
{*------------------------------------------------------------------------------
  Obtém os nomes das functions e procedures indicadas para DEBUG

  @return String contendo os nomes das functions e procedures para DEBUG
-------------------------------------------------------------------------------}
function TCACIC.getDetailsToDebugging() : String;
Begin
  Result := Self.g_details_to_debugging;
End;

{*------------------------------------------------------------------------------
  Atribui o nome da pasta do Gerente WEB

  @param p_web_manager_address Nome da Pasta do Gerente WEB
-------------------------------------------------------------------------------}
procedure TCACIC.setWebManagerAddress(pStrWebManagerAddress: string);
begin
  Self.g_web_manager_address := self.fixWebAddress(pStrWebManagerAddress);
end;

{*------------------------------------------------------------------------------
  Atribui o nome da pasta dos scripts de comunicação do Gerente WEB

  @param p_web_services_folder_name Nome da Pasta dos scripts de comunicação do Gerente WEB
-------------------------------------------------------------------------------}
procedure TCACIC.setWebServicesFolderName(pStrWebServicesFolderName: string);
begin
  Self.g_web_services_folder_name := pStrWebServicesFolderName;
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
  Obtém o nome da pasta dos scripts de comunicação do Gerente WEB

  @return String Nome da Pasta dos scripts de comunicação do Gerente WEB
-------------------------------------------------------------------------------}
function TCACIC.getWebServicesFolderName() : string;
begin
  Result := IfThen(Self.g_web_services_folder_name <> '', Self.g_web_services_folder_name , 'ws/');
end;

{*------------------------------------------------------------------------------
  Atribui o caminho físico de instalação do agente cacic

  @param p_local_folder_name Caminho físico de instalação do agente cacic
-------------------------------------------------------------------------------}
procedure TCACIC.setLocalFolderName(pStrLocalFolderName: string = 'Cacic');
begin
  Self.g_local_folder_name := self.fixFolderAtHomeDrive(pStrLocalFolderName);

  // DEBUG - Escrevendo lista de parâmetros recebidos
  writeDebugLog('setLocalFolderName: "' + Self.g_local_folder_name + '"');
  writeDebugLog('setLocalFolderName: ' + listParams);
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
  Obtém o nome do programa principal do CACIC

  @return String  Nome do programa principal do CACIC
-------------------------------------------------------------------------------}
function TCACIC.getMainProgramName() : String;
begin
  Result := Self.g_main_program_name;
end;
{*------------------------------------------------------------------------------
  Obtém o hash-code do programa principal do CACIC

  @return String  Hash-Code do programa principal do CACIC
-------------------------------------------------------------------------------}
function TCACIC.getMainProgramHash() : String;
begin
  Result := Self.g_main_program_hash;
end;

{*------------------------------------------------------------------------------
  Verifica se a aplicação está em execução

  @param pStrAppName Nome da aplicação a ser verificada
  @return TRUE se em execução, FALSE caso contrário
-------------------------------------------------------------------------------}
function TCACIC.isAppRunning( pStrAppName: PAnsiChar ): boolean;
var MutexHandle: THandle;
begin
   MutexHandle := CreateMutex(nil, TRUE, pStrAppName);
   Result := ((MutexHandle = 0) OR (GetLastError = ERROR_ALREADY_EXISTS));
end;

{*------------------------------------------------------------------------------
  Verifica quais programas do sistema estão em modo de debug

  @return Boolean contendo status do DEBUG
-------------------------------------------------------------------------------}
function TCACIC.isInDebugMode(pStrDetailName : String = '') : boolean;
var strTeDebugging : String;
begin
  Result := checkIfFileDateIsToday(getLocalFolderName + 'Temp\Debugging');
  if Result and FileExists(getLocalFolderName + 'Temp\Debugging\Debugging.conf') and (pStrDetailName <> '') then
    Begin
      strTeDebugging := getValueFromFile('Configs','TeDebugging',getLocalFolderName + 'Temp\Debugging\Debugging.conf',false);
      if (pos(ExtractFileName(ParamStr(0)) + '.' + pStrDetailName, strTeDebugging) = 0) and
         (pos(ExtractFileName(ParamStr(0)) + '.*'                , strTeDebugging) = 0) then
          Result := false;
    End;
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
end;

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{ For Windows NT/2000/XP }
procedure TCACIC.KillProcess(p_HWindowHandle: HWND);
var
  hprocessID: INTEGER;
  processHandle: THandle;
  DWResult: DWORD;
begin
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
end;

procedure TCACIC.writeDebugLog(pStrDebugMessage : String);
Begin
  if isInDebugMode(copy(pStrDebugMessage,1,pos(':',pStrDebugMessage)-1)) then
      writeDailyLog('[DEBUG] - v.' + getVersionInfo(ParamStr(0)) + ' - ' + pStrDebugMessage,'Debugs');
End;

function TCACIC.checkIfFileDateIsToday(pStrFileName : String) : boolean;
var strFileDate,
    strTodayDate : String;
Begin
  DateTimeToString(strTodayDate, 'yyyymmdd', date);

  if FileExists(pStrFileName) then
    DateTimeToString(strFileDate, 'yyyymmdd', FileDateToDateTime(Fileage(pStrFileName)))
  else if DirectoryExists(pStrFileName) then
    DateTimeToString(strFileDate, 'yyyymmdd', GetFolderDate(pStrFileName));

  Result := (strTodayDate = strFileDate);
End;

procedure TCACIC.writeDailyLog(pStrLogMessage : String; pStrFileNameSuffix : String = '');
var DailyLogFile   : TextFile;
    strLogFileName,
    strDateTimeAux : string;
    strAUXDEBUG : String;
begin
   try
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
      if (getLocalFolderName <> '') then
        Begin
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          strDateTimeAux := FormatDateTime('dd/mm hh:nn:ss ', Now);
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          if not DirectoryExists(getLocalFolderName + 'Logs') then
            ForceDirectories(getLocalFolderName + 'Logs');
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          strLogFileName := getLocalFolderName + 'Logs\' + ChangeFileExt(UpperCase(ExtractFileName(ParamStr(0))),'.log');
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          if (pStrFileNameSuffix <> '') then
            strLogFileName := StringReplace(strLogFileName,'.log','_' + pStrFileNameSuffix + '.log',[rfReplaceAll]);
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          FileSetAttr (strLogFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          AssignFile(DailyLogFile,strLogFileName); {Associa o arquivo a uma variável do tipo TextFile}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          {$IOChecks off}
          Reset(DailyLogFile); {Abre o arquivo texto}
          {$IOChecks on}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          if (IOResult <> 0) or                    // Arquivo de log diário não existe
             not checkIfFileDateIsToday(strLogFileName) then // Arquivo de log diário não tem data atual
            Begin
              Rewrite (DailyLogFile); // Recriação do arquivo de log diário
              Append(DailyLogFile);
              Writeln(DailyLogFile,'===========================================> Inicio de Log para ' + UpperCase(ExtractFileName(ParamStr(0))) + ' <===========================================');
            End;
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          Append(DailyLogFile);
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          Writeln(DailyLogFile,strDateTimeAux + pStrLogMessage); {Escreve uma linha com a mensagem}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          CloseFile(DailyLogFile); {Fecha o arquivo de log diário}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
          if (pStrFileNameSuffix = '') and isInDebugMode then // Caso esteja em modo DEBUG e seja uma mensagem para o log diário, escrevo também a mensagem no log de DEBUG.
            Begin
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              strLogFileName := getLocalFolderName + 'Logs\' + ChangeFileExt(UpperCase(ExtractFileName(ParamStr(0))),'_Debugs.log');
              FileSetAttr (strLogFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              AssignFile(DailyLogFile,strLogFileName); {Associa o arquivo a uma variável do tipo TextFile}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              {$IOChecks off}
              Reset(DailyLogFile); {Abre o arquivo texto}
              {$IOChecks on}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              if (IOResult <> 0) or                    // Arquivo de log não existe
                 not checkIfFileDateIsToday(strLogFileName) then // Arquivo de log não tem data atual
                Begin
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
                  Rewrite (DailyLogFile); // Recriação do arquivo de log diário
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
                  Append(DailyLogFile);
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
                  Writeln(DailyLogFile,'===========================================> Inicio de DEBUG para ' + UpperCase(ExtractFileName(ParamStr(0))) + ' <===========================================');
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
                End;
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              Append(DailyLogFile);
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              Writeln(DailyLogFile,strDateTimeAux + pStrLogMessage); {Escreve uma linha com a mensagem}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
              CloseFile(DailyLogFile); {Fecha o arquivo de log diário}
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
            End;

          if (trim(g_strAcao)='') then g_strAcao := pStrLogMessage;
   strAUXDEBUG := 'WriteDailyLog - DEBUG #1';
        End;
   except
      on E : Exception do
        writeExceptionLog(E.Message,E.ClassName,strAUXDEBUG);
   end;
end;

{*------------------------------------------------------------------------------
  Cria um arquivo texto contendo informações de exceções
-------------------------------------------------------------------------------}
procedure TCACIC.writeExceptionLog(pStrExceptionMessage, pStrExceptionClassName : String; pStrAddedMessage : String = '');
Begin
  writeDailyLog('[EXCEPTION] - v.' + getVersionInfo(ParamStr(0)) + chr(13) + 'Erro: '      + pStrExceptionMessage   + chr(13) +
                                                                             'Classe: '    + pStrExceptionClassName + chr(13) +
                                                                             'Mensagem: '  + pStrAddedMessage       + chr(13) +
                                                                             DupeString('-',100),'Exceptions');
End;
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
function TCACIC.createOneProcess(pStrCmd: string; pBoolWait: boolean; pWordShowWindow : word = SW_HIDE): boolean;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
begin
  FillChar(SUInfo, SizeOf(SUInfo), #0);
  SUInfo.cb      := SizeOf(SUInfo);
  SUInfo.dwFlags := STARTF_USESHOWWINDOW;
  SUInfo.wShowWindow := pWordShowWindow;

  writeDebugLog('createOneProcess: ' + DupeString('*',100));
  writeDebugLog('createOneProcess: pStrCmd   => "' + pStrCmd                    + '"');
  writeDebugLog('createOneProcess: pBoolWait => "' + getBoolToString(pBoolWait) + '"');
  writeDebugLog('createOneProcess: ' + DupeString('*',100));
  Result := CreateProcess(nil,
                          PChar(pStrCmd),
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
    if(pBoolWait) then begin
       WaitForSingleObject(ProcInfo.hProcess, INFINITE);
       CloseHandle(ProcInfo.hProcess);
       CloseHandle(ProcInfo.hThread);
    end;
  end;
end;

{*------------------------------------------------------------------------------
  Para cálculo de HASH de determinado arquivo.

  @autor: Anderson Peterle
  @param p_strFileName - Nome do arquivo para extração do HashCode
-------------------------------------------------------------------------------}
function TCACIC.getFileHash(pStrFileName : String) : String;
Begin
  Result := 'Arquivo "'+pStrFileName+'" Inexistente!';
  if (FileExists(pStrFileName)) then
    Result := MD5Print(MD5File(pStrFileName));
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
  Obter o nome do arquivo de configurações

  @return String contendo o nome do arquivo de configurações
-------------------------------------------------------------------------------}
function TCACIC.getInfFileName(): string;
begin
   Result := ChangeFileExt( UpperCase(ExtractFileName(ParamStr(0))),'.inf');
end;


{*------------------------------------------------------------------------------
  Obter o separador para criação de listas locais

  @return String contendo o separador de campos e valores
-------------------------------------------------------------------------------}
function TCACIC.getSeparatorKey(): string;
begin
   Result := CACIC_SEPARATORKEY;
end;

{*------------------------------------------------------------------------------
  Substituir alguns valores inválidos ao tráfego HTTP

  @return String contendo o string com valores inválidos substituidos por válidos
------------------------------------------------------------------------------}
function TCACIC.replaceInvalidHTTPChars(p_String : String) : String;
var v_strNewString : String;
begin
  Try
    v_strNewString := StringReplace(p_String      ,'+' ,'[[MAIS]]'    ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,' ' ,'[[ESPACE]]'  ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'"' ,'[[AD]]'      ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'''','[[AS]]'      ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'\' ,'[[BarrInv]]' ,[rfReplaceAll]);

    Result := v_strNewString;
  Except
    on E : Exception do
       Begin
         writeExceptionLog(E.Message,E.ClassName,'TCACIC.replaceInvalidHTTPChars');
         Result := 'ERROR - Check TCACIC.replaceInvalidHTTPChars Function';
       End;
  End;
end;

{*------------------------------------------------------------------------------
  Repor valores substituidos durante tráfego HTTP

  @return String contendo o string com valores substituidos
------------------------------------------------------------------------------}
function TCACIC.replacePseudoTagsWithCorrectChars(pStrString : String) : String;
var v_strNewString : String;
begin
  Try
    v_strNewString := StringReplace(pStrString    ,'[[MAIS]]'   ,'+' ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'[[ESPACE]]' ,' ' ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'[[AD]]'     ,'"' ,[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'[[AS]]'     ,'''',[rfReplaceAll]);
    v_strNewString := StringReplace(v_strNewString,'[[BarrInv]]','\' ,[rfReplaceAll]);

    Result := v_strNewString;
  Except
    on E : Exception do
       Begin
         writeExceptionLog(E.Message,E.ClassName,'TCACIC.replacePseudoTagsWithCorrectValuesChars');
         Result := 'ERROR - Check TCACIC.replacePseudoTagsWithCorrectValuesChars Function';
       End;
  End;
end;

{*------------------------------------------------------------------------------
  Obter a capitalização de uma string

  @return String contendo capitalizado
-------------------------------------------------------------------------------}
function TCACIC.capitalize (const s: String): String;
var flag: BOOLEAN;
    i : Byte;
    t,strAuxCapitalize : string;
Begin
  flag := TRUE;
  t := '';
  strAuxCapitalize := LowerCase(s);
  For i := 1 TO LENGTH(strAuxCapitalize) DO
    Begin
      If flag Then
        AppendStr(t, UpCase(strAuxCapitalize[i]))
      Else
        AppendStr(t, strAuxCapitalize[i]);
      flag := (strAuxCapitalize[i] = ' ')
    End;
  Result := t;
End {Capitalize};

// Encrypt a string and return the Base64 encoded result
function TCACIC.enCrypt(pStrPlainText : String; pBoolShowInLog : boolean = true; pBoolForceEncrypt : boolean = false) : String;
var l_Cipher : TDCP_rijndael;
    l_Data,
    l_Key,
    l_IV     : string;
begin
  Try
    if self.g_boolCipher or pBoolForceEncrypt then
      Begin
        // Pad Key, IV and Data with zeros as appropriate
        l_Key   := PadWithZeros(CACIC_CIPHERKEY, CACIC_KEYSIZE);
        l_IV    := PadWithZeros(CACIC_IV       , CACIC_BLOCKSIZE);
        l_Data  := PadWithZeros(pStrPlainText  , CACIC_BLOCKSIZE);

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);

        if      Length(CACIC_CIPHERKEY) <= 16 then
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
        Result := Result + '__CRYPTED__';
      End
    Else
      // Return the original value
      Result := pStrPlainText;
  Except
    on E : Exception do
       Begin
         writeExceptionLog(E.Message,E.ClassName,'TCACIC.enCrypt');
          Result := 'ERROR - Check TCACIC.enCrypt Function';
        End;
  End;
end;

function TCACIC.deCrypt(pStrCipheredText : String; pBoolShowInLog : boolean = true; pBoolForceDecrypt : boolean = false) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data,
  l_Key,
  l_IV : string;
begin
  Try

    if (RightStr(pStrCipheredText,11) = '__CRYPTED__') and (self.g_boolCipher or pBoolForceDecrypt) then
      Begin
        // Pad Key and IV with zeros as appropriate
        l_Key := PadWithZeros(CACIC_CIPHERKEY , CACIC_KEYSIZE);
        l_IV  := PadWithZeros(CACIC_IV        , CACIC_BLOCKSIZE);

        l_Data := StringReplace(pStrCipheredText,'__CRYPTED__','',[rfReplaceAll]);

        // Decode the Base64 encoded string
        l_Data := Base64DecodeStr(trim(replacePseudoTagsWithCorrectChars(l_Data)));

        // Create the cipher and initialise according to the key length
        l_Cipher := TDCP_rijndael.Create(nil);

        if      Length(CACIC_CIPHERKEY) <= 16 then
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
      Result := pStrCipheredText
  Except
    on E : Exception do
       Begin
         writeExceptionLog(E.Message,E.ClassName,'TCACIC.deCrypt');
         Result :='ERROR - Check TCACIC.deCrypt Function';
       End;
  End;
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

{*------------------------------------------------------------------------------
  Retorna "False" ou "True" para uma questão lógica
-------------------------------------------------------------------------------}
function TCACIC.getBoolToString(pBoolQuestion : boolean) : string;
const arrBool : array[boolean] of String = ('False','True');
begin
  Result := arrBool[pBoolQuestion];
end;

{*===========================================================================================================
                                        TCACIC_WINDOWS Methods
=============================================================================================================}
{*------------------------------------------------------------------------------
  Retorna a versão a partir de uma CLSID
  Anderson PETERLE - 31JAN2013
-------------------------------------------------------------------------------}
function TCACIC_Windows.getVersionFromHCR(pStrToProcess : String): string;
var regRegistry : TRegistry;
    intLen,
    intPos      : Integer;
    strCLSID    : String;
begin
  Result      := '';

  intPos    := Pos('{',pStrToProcess);
  strCLSID    := copy(pStrToProcess,intPos,length(pStrToProcess));
  intPos    := Pos('}',strCLSID);
  strCLSID    := copy(strCLSID,1,intPos);

  regRegistry := TRegistry.Create;

  with regRegistry do
    begin
      try
        RootKey := HKEY_CLASSES_ROOT;
        try
          if OpenKeyReadOnly('CLSID\' + strCLSID + '\InprocServer32') OR
             OpenKeyReadOnly('CLSID\' + strCLSID + '\LocalServer32')  THEN
            Result := GetVersionInfo(ReadString(''));
        finally
          CloseKey;
          intLen := Length(Result);

          if intLen >= 2 then
            begin
              if(Result[intLen] = '"') then
                Delete(Result, intLen, 1);

              if(Result[1] = '"') then
                Delete(Result, 1, 1);
            end;
        end;
      finally
      end;
    end;

  // Caso a busca acima resulte em VAZIO, alternativamente verifico a partir de estrutura 64Bits
  if (Result = '') then
    Begin
      with regRegistry do
        begin
          try
            RootKey := HKEY_CLASSES_ROOT;
            try
              if OpenKeyReadOnly('Wow6432Node\CLSID\' + strCLSID + '\InprocServer32') OR
                 OpenKeyReadOnly('Wow6432Node\CLSID\' + strCLSID + '\LocalServer32')  THEN
                Result := GetVersionInfo(ReadString(''));
            finally
              CloseKey;
              intLen := Length(Result);

              if intLen >= 2 then
                begin
                  if(Result[intLen] = '"') then
                    Delete(Result, intLen, 1);

                  if(Result[1] = '"') then
                    Delete(Result, 1, 1);
                end;
            end;
          finally
          end;
        end;
    End;

  regRegistry.Free;
end;

{*------------------------------------------------------------------------------
 Format the version number from the given DWORDs containing the info
-------------------------------------------------------------------------------}
function TCACIC_Windows.verFmt(const MS, LS: DWORD): string;
begin
  Result := Format('%d.%d.%d.%d',[HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)]);
end;

{*------------------------------------------------------------------------------
  Retorna a pasta de instalação do MS-Windows
-------------------------------------------------------------------------------}
function TCACIC_Windows.getVersionInfo(pStrFileName: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(pStrFileName);

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
  Obter o caminho fisico de instalacao do agente cacic

  @return String contendo o caminho físico
-------------------------------------------------------------------------------}
function TCACIC_Windows.getLocalFolderName(): string;
begin
   Result :=  Self.g_local_folder_name ;
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
    on E : Exception do
      writeExceptionLog(E.Message,E.ClassName,'getWindowsStrId');
  end;

  Result := Result + getBitPlatform;

end;

{*------------------------------------------------------------------------------
  Returns String with bit platform information

  @return String
  @example .64
-------------------------------------------------------------------------------}
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
    End;
//  else
//    s := 'IsWow64Process not present in kernel32.dll';

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
end.

