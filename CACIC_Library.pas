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
        function getCacicPath() : string;
        procedure setCacicPath( pPath: string );
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
    DCPbase64;
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
         /// Mantem a identificação do sistema operacional
         g_osVersionInfo: TOSVersionInfo;
         /// Mantem a identificação extendida do sistema operacional
         g_osVersionInfoEx: TOSVersionInfoEx;
         /// TRUE se houver informação extendida do SO, FALSE caso contrário
         g_osVersionInfoExtended: boolean;

       public
         function  isWindowsVista()                                     : boolean;
         function  isWindowsGEVista()                                   : boolean;
         function  isWindowsXP()                                        : boolean;
         function  isWindowsGEXP()                                      : boolean;
         function  isWindowsNTPlataform()                               : boolean;
         function  isWindows2000()                                      : boolean;
         function  isWindowsNT()                                        : boolean;
         function  isWindows9xME()                                      : boolean;
         function  getWindowsStrId()                                    : string;
         function  getWinDir()                                          : string;
         function  getHomeDrive()                                         : string;
         function  isWindowsAdmin()                                     : boolean;
         function  createSampleProcess(p_cmd: string; p_wait: boolean; p_showWindow : word = SW_HIDE): boolean;
         procedure showTrayIcon(p_visible:boolean);
   end;

{*------------------------------------------------------------------------------
 Classe para tratamento de debug
-------------------------------------------------------------------------------}
   TCACIC_Debug = class
       private

       protected
         /// TRUE se em mode de debug, FALSE caso contrário
         g_debug: boolean;

       public
         procedure debugOn();
         procedure debugOff();
         function inDebugMode() : boolean;
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
         g_cacic_path: string;
         g_boolCipher : boolean;

       public
         Windows : TCACIC_Windows; /// objeto de informacoes de windows
         Debug   : TCACIC_Debug; /// objeto de tratamento de debug
         procedure setCacicPath(p_cacic_path: string);
         procedure setBoolCipher(p_boolCipher : boolean);
         function  deCrypt(p_Data : String)                           : String;
         function  enCrypt(p_Data : String)                           : String;
         function  explode(p_String, p_Separador : String)            : TStrings;
         function  implode(p_Array : TStrings ; p_Separador : String) : String;
         function  getCacicPath()                                     : String;
         function  getCipherKey()                                     : String;
         function  getBoolCipher()                                    : boolean;
         function  getIV()                                            : String;
         function  getKeySize()                                       : integer;
         function  getBlockSize()                                     : integer;
         function  getDatFileName()                                   : String;
         function  getSeparatorKey()                                  : String;
         function  getFileHash(strFileName : String)                  : String;
         function  isAppRunning( p_app_name: PAnsiChar )              : boolean;
         function  padWithZeros(const str : string; size : integer)   : String;
         function  trimEspacosExcedentes(p_str: string)               : String;

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
// Esta chave é passada como parâmetro para o Gerente de Coletas que, por sua vez,
// passa para o Inicializador de Coletas e este passa para os coletores...
const
  CACIC_CIPHERKEY      = 'CacicBrasil';
  CACIC_IV             = 'abcdefghijklmnop';
  CACIC_SEPARATORKEY   = '=CacicIsFree='; // Usada apenas para o cacic2.dat

// Arquivo local para armazenamento de configurações e informações coletadas
const
  CACIC_DATFILENAME    = 'cacic2.dat';


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
  Self.Debug := TCACIC_Debug.Create();
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
  Atribui o caminho físico de instalação do agente cacic

  @param p_cacic_path Caminho físico de instalação do agente cacic
-------------------------------------------------------------------------------}
procedure TCACIC.setCacicPath(p_cacic_path: string);
begin
  Self.g_cacic_path := p_cacic_path;
end;

{*------------------------------------------------------------------------------
  Obter o caminho fisico de instalacao do agente cacic

  @return String contendo o caminho físico
-------------------------------------------------------------------------------}
function TCACIC.getCacicPath(): string;
begin
   Result := Self.g_cacic_path;
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
procedure TCACIC_Debug.debugOn();
begin
  Self.g_debug := true;
end;

{*------------------------------------------------------------------------------
  Desliga o modo de debug do sistema

-------------------------------------------------------------------------------}
procedure TCACIC_Debug.debugOff();
begin
  Self.g_debug := false;
end;

{*------------------------------------------------------------------------------
  Coloca o sistema em modo de debug

  @return String contendo o caminho físico
-------------------------------------------------------------------------------}
function TCACIC_Debug.inDebugMode() : boolean;
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
var
   v_version_id: string;
begin
  v_version_id := 'S.O.unknown';
  try
	  if (Self.g_osVersionInfoExtended) then
		 if(Self.isWindows9xME) then
			v_version_id := IntToStr(Self.g_osVersionInfoEx.dwPlatformId) + '.' +
				   IntToStr(Self.g_osVersionInfoEx.dwMajorVersion) + '.' +
				   IntToStr(Self.g_osVersionInfoEx.dwMinorVersion) +
				   ifThen(trim(Self.g_osVersionInfoEx.szCSDVersion)='',
						 '',
						 '.'+trim(Self.g_osVersionInfoEx.szCSDVersion))
		 else
			v_version_id := IntToStr(Self.g_osVersionInfoEx.dwPlatformId) + '.' +
				   IntToStr(Self.g_osVersionInfoEx.dwMajorVersion) + '.' +
				   IntToStr(Self.g_osVersionInfoEx.dwMinorVersion) + '.' +
				   IntToStr(Self.g_osVersionInfoEx.wProductType) + '.' +
				   IntToStr(Self.g_osVersionInfoEx.wSuiteMask)
	  else
		 v_version_id := IntToStr(Self.g_osVersionInfo.dwPlatformId) + '.' +
				   IntToStr(Self.g_osVersionInfo.dwMajorVersion) + '.' +
				   IntToStr(Self.g_osVersionInfo.dwMinorVersion) +
				   ifThen(trim(Self.g_osVersionInfo.szCSDVersion)='',
						 '',
						 '.'+trim(Self.g_osVersionInfo.szCSDVersion));
  except
  end;
  Result := v_version_id;

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
function TCACIC_Windows.createSampleProcess(p_cmd: string; p_wait: boolean; p_showWindow : word = SW_HIDE): boolean;
var
  SUInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
begin
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
end;

{*------------------------------------------------------------------------------
  Para cálculo de HASH de determinado arquivo.

  @autor: Anderson Peterle
  @param p_strFileName - Nome do arquivo para extração do HashCode
-------------------------------------------------------------------------------}
function TCACIC.GetFileHash(strFileName : String) : String;
Begin
  Result := 'Arquivo "'+strFileName+'" Inexistente!';
  if (FileExists(strFileName)) then
    Result := MD5Print(MD5File(strFileName));
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
  Obter o nome do arquivo de informações de configurações e dados locais

  @return String contendo o nome do arquivo de configurações e dados locais
-------------------------------------------------------------------------------}
function TCACIC.getDatFileName(): string;
begin
   Result := CACIC_DATFILENAME;
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
//    LogDiario('Erro no Processo de Criptografia');
  End;
end;

function TCACIC.deCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    if self.g_boolCipher then
      Begin
        // Pad Key and IV with zeros as appropriate
        l_Key := PadWithZeros(CACIC_CIPHERKEY,CACIC_KEYSIZE);
        l_IV  := PadWithZeros(CACIC_IV,CACIC_BLOCKSIZE);

        // Decode the Base64 encoded string
        l_Data := Base64DecodeStr(p_Data);

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
//    LogDiario('Erro no Processo de Decriptografia');
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

end.
