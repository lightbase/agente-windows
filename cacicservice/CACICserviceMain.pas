(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)
unit CACICserviceMain;

interface
uses  Windows,
      Messages,
      SysUtils,
      Classes,
      SvcMgr,
      ExtCtrls,
      CACIC_Library,
      tlhelp32,
      JwaWinNT,    { As units com prefixo Jwa constam do Pacote Jedi_API22a }
      JwaWinBase,  { que pode ser obtido em  http://sourceforge.net/projects/jedi-apilib/files/JEDI%20Windows%20API/JEDI%20API%202.2a%20and%20WSCL%200.9.2a/jedi_api22a_jwscl092a.zip/download }
      JwaWtsApi32,
      JwaWinSvc,
      JwaWinType,
      JwaNtStatus,
      Registry;

var   intContaMinutos      : integer;
      g_oCacic             : TCACIC;
      strChkSisInfFileName : String;

const SE_DEBUG_NAME = 'SeDebugPrivilege';

type
  TCacicSustainService = class(TService)
    timerToCHKSIS: TTimer;
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure timerToCHKSISTimer(Sender: TObject);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceShutdown(Sender: TService);
  private
    { Internal Start & Stop methods }
    Procedure WMEndSession(var Msg : TWMEndSession) ;  message WM_ENDSESSION;
    procedure ExecutaCACIC;
    function  startapp(p_TargetFolderName, p_ApplicationName : String) : integer;

  public
    { Public declarations }
    function GetServiceController: TServiceController; override;
  end;

var
  CacicSustainService: TCacicSustainService;

function  CreateEnvironmentBlock(var lpEnvironment: Pointer;
                                 hToken: THandle;
                                 bInherit: BOOL): BOOL; stdcall; external 'userenv';
function  DestroyEnvironmentBlock(pEnvironment: Pointer): BOOL; stdcall; external 'userenv';

implementation

uses ComObj;

{$R *.DFM}

// Solução adaptada a partir do exemplo contido em http://www.codeproject.com/KB/vista-security/VistaSessions.aspx?msg=2750630
// para execução a partir de token do WinLogon, possibilitando a exibição do ícone da aplicação na bandeja do systray em plataforma Microsoft Windows VISTA.
function TCacicSustainService.startApp(p_TargetFolderName, p_ApplicationName : String) : integer;
var
   pi : PROCESS_INFORMATION;
   si : STARTUPINFO;
   bresult : boolean;
   dwSessionId,winlogonPid : DWORD;
   hUserToken,hUserTokenDup,hPToken,hProcess,hsnap : THANDLE;
   dwCreationFlags : DWORD;
   procEntry : TPROCESSENTRY32;
   winlogonSessId : DWORD;
   tp : TOKEN_PRIVILEGES;
   abcd, abc, dup : integer;
   lpenv : pointer;
   iResultOfCreateProcessAsUser : integer;

begin
  g_oCacic.writeDebugLog('startApp: ' + p_TargetFolderName + p_ApplicationName);
  Result := 0;
  bresult := false;

  //TOKEN_ADJUST_SESSIONID := 256;

  // Log the client on to the local computer.
  ServiceType := stWin32;
  dwSessionId := WTSGetActiveConsoleSessionId();
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnap = INVALID_HANDLE_VALUE) then
    begin
      result := 1;
      g_oCacic.writeDebugLog('startApp: Error => INVALID_HANDLE_VALUE');
      exit;
    end;

  procEntry.dwSize := sizeof(TPROCESSENTRY32);

  if (not Process32First(hSnap, procEntry)) then
    begin
      result := 1;
      g_oCacic.writeDebugLog('startApp: Error => not Process32First');
      exit;
    end;

  repeat;
  if (comparetext(procEntry.szExeFile, 'winlogon.exe') = 0) then
    begin
      g_oCacic.writeDebugLog('startApp: Winlogon Founded');
      // We found a winlogon process...

      // make sure it's running in the console session

      winlogonSessId := 0;
      if (ProcessIdToSessionId(procEntry.th32ProcessID, winlogonSessId) and (winlogonSessId = dwSessionId)) then
        begin
          winlogonPid := procEntry.th32ProcessID;
          g_oCacic.writeDebugLog('startApp: ProcessIdToSessionId OK => ' + IntToStr(winlogonPid));
          break;
        end;
    end;

  until (not Process32Next(hSnap, procEntry));

  ////////////////////////////////////////////////////////////////////////

  WTSQueryUserToken(dwSessionId, hUserToken);
  dwCreationFlags := NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE;
  ZeroMemory(@si, sizeof(STARTUPINFO));
  si.cb := sizeof(STARTUPINFO);
  si.lpDesktop := 'winsta0\default';
  ZeroMemory(@pi, sizeof(pi));
  hProcess := OpenProcess(MAXIMUM_ALLOWED,FALSE,winlogonPid);

  if(not OpenProcessToken(hProcess,TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY
                 or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_ADJUST_SESSIONID
                          or TOKEN_READ or TOKEN_WRITE, hPToken)) then
    begin
      abcd := GetLastError();
      g_oCacic.writeDebugLog('startApp: Process token open Error => ' + inttostr(GetLastError()));
    end;

  if (not LookupPrivilegeValue(nil,SE_DEBUG_NAME,tp.Privileges[0].Luid)) then
      g_oCacic.writeDebugLog('startApp: Lookup Privilege value Error => ' + inttostr(GetLastError()));

  tp.PrivilegeCount := 1;
  tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

  DuplicateTokenEx(hPToken,MAXIMUM_ALLOWED,Nil,SecurityIdentification,TokenPrimary,hUserTokenDup);
  dup := GetLastError();

  // Adjust Token privilege

  SetTokenInformation(hUserTokenDup,TokenSessionId,pointer(dwSessionId),sizeof(DWORD));

  if (not AdjustTokenPrivileges(hUserTokenDup,FALSE,@tp,sizeof(TOKEN_PRIVILEGES),nil,nil)) then
    begin
      abc := GetLastError();
      g_oCacic.writeDebugLog('startApp: Adjust Privilege value Error => ' + inttostr(GetLastError()));
    end;

  if (GetLastError() = ERROR_NOT_ALL_ASSIGNED) then
      g_oCacic.writeDebugLog('startApp: Token does not have the provilege');

  lpEnv := nil;

  if(CreateEnvironmentBlock(lpEnv,hUserTokenDup,TRUE)) then
      dwCreationFlags := dwCreationFlags or CREATE_UNICODE_ENVIRONMENT
  else
    lpEnv := nil;

  // Launch the process in the client's logon session.
  bResult := CreateProcessAsUser( hUserTokenDup,                        // client's access token
                                  PAnsiChar(p_TargetFolderName + p_ApplicationName), // file to execute
                                  nil,                                  // command line
                                  nil,                                  // pointer to process SECURITY_ATTRIBUTES
                                  nil,                                  // pointer to thread SECURITY_ATTRIBUTES
                                  FALSE,                                // handles are not inheritable
                                  dwCreationFlags,                      // creation flags
                                  lpEnv,                                // pointer to new environment block
                                  PAnsiChar(p_TargetFolderName),   // name of current directory
                                  si,                                   // pointer to STARTUPINFO structure
                                  pi                                    // receives information about new process
                                 );

  // End impersonation of client.
  //GetLastError Shud be 0
  iResultOfCreateProcessAsUser := GetLastError();

  //Perform All the Close Handles tasks
  CloseHandle(hProcess);
  CloseHandle(hUserToken);
  CloseHandle(hUserTokenDup);
  CloseHandle(hPToken);
end;
//
procedure TCacicSustainService.WMEndSession(var Msg : TWMEndSession) ;
begin
  if Msg.EndSession = TRUE then
    g_oCacic.writeDailyLog('WMEndSession: Windows finalizado em ' + FormatDateTime('dd/mm hh:nn:ss : ', Now)) ;
  inherited;
  Application.Free;
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  CacicSustainService.Controller(CtrlCode);
end;

function TCacicSustainService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TCacicSustainService.ServiceExecute(Sender: TService);
begin
  Try
    Application.Initialize;

    { Loop while service is active in SCM }
    While NOT Terminated do
      Begin
        { Process Service Requests }
        ServiceThread.ProcessRequests( False );
        { Allow system some time }
        Sleep(1);
      End;
  Except
    on e: exception do
      Begin
        g_oCacic.writeDebugLog('ServiceExecute: Erro => ' + e.Message);
      End;
  End;
end;

procedure TCacicSustainService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  g_oCacic := TCACIC.Create;
  g_oCacic.setBoolCipher(true);

  strChkSisInfFileName := g_oCacic.getWinDir + 'chksis.inf';
  g_oCacic.setLocalFolderName(g_oCacic.GetValueFromFile('Configs', 'LocalFolderName', strChkSisInfFileName));

  Started := False;
  try
    Started := True;
  except
    on E : Exception do
         g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ServiceStart');
  end;

  // ATENÇÃO: A propriedade "Interactive" em FALSE para S.O. menor que VISTA inibe a exibição gráfica para o serviço e seus herdeiros,
  //          e assim o ícone da aplicação não é mostrado na bandeja do sistema.
  Self.Interactive   := not g_oCacic.isWindowsGEVista;
  g_oCacic.setMainProgramName(g_oCacic.GetValueFromFile('Configs'   ,'MainProgramName'           , strChkSisInfFileName));
  g_oCacic.setMainProgramHash(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes',g_oCacic.getMainProgramName , strChkSisInfFileName),false,true));


  g_oCacic.writeDebugLog('ServiceStart: O.S. Identification');
  g_oCacic.writeDebugLog('ServiceStart: ************************************************');
  g_oCacic.writeDebugLog('ServiceStart: isWindowsVista => '        + g_oCacic.getBoolToString(g_oCacic.isWindowsVista       ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsGEVista => '      + g_oCacic.getBoolToString(g_oCacic.isWindowsGEVista     ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsXP => '           + g_oCacic.getBoolToString(g_oCacic.isWindowsXP          ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsGEXP => '         + g_oCacic.getBoolToString(g_oCacic.isWindowsGEXP        ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsNTPlataform => '  + g_oCacic.getBoolToString(g_oCacic.isWindowsNTPlataform ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindows2000 => '         + g_oCacic.getBoolToString(g_oCacic.isWindows2000        ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsNT => '           + g_oCacic.getBoolToString(g_oCacic.isWindowsNT          ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindows9xME => '         + g_oCacic.getBoolToString(g_oCacic.isWindows9xME        ) );
  g_oCacic.writeDebugLog('ServiceStart: ************************************************');

  g_oCacic.writeDebugLog('ServiceStart: Interactive Mode=> '       + g_oCacic.getBoolToString(Self.Interactive));
  g_oCacic.writeDebugLog('ServiceStart: LocalFolderName => '       + g_oCacic.getLocalFolderName);
  g_oCacic.writeDebugLog('ServiceStart: MainProgramName => '       + g_oCacic.getMainProgramName);
  g_oCacic.writeDebugLog('ServiceStart: MainProgramHash => '       + g_oCacic.getMainProgramHash);

  // Caso exista uma cópia do chkSIS.exe supostamente baixada do servidor de updates, movo-a para a devida pasta
  if FileExists(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') then
    Begin
      g_oCacic.writeDebugLog('ServiceStart: Encontrado "' + g_oCacic.getLocalFolderName + 'Temp\chksis.exe" com versão "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') + '"');

      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CHKSIS.EXE', strChkSisInfFileName),false,true)  = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\chksis.exe')) then
        Begin
          g_oCacic.writeDebugLog('ServiceStart: Hash Code conferido! Movendo para ' + g_oCacic.getWinDir);

          CopyFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\chksis.exe'),PAnsiChar(g_oCacic.getWinDir + 'chksis.exe'),false);
          Sleep(2000);

          // A função MoveFile não estava excluindo o arquivo da origem. (???)
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\chksis.exe');
          Sleep(2000);
        End;
    End;

  // Como o serviço está iniciando, executo o Verificador de Integridade...
  Try
    if (g_oCacic.isWindowsGEVista) then
      Begin
        g_oCacic.writeDebugLog('ServiceStart: Ativando StartAPP('+g_oCacic.getWinDir+',chksis.exe)');
        CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
      End
    else
      Begin
        g_oCacic.writeDebugLog('ServiceStart: Ativando CreateSampleProcess(' + g_oCacic.getWinDir + 'chksis.exe)');
        g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
      End;
  Except
    on E : Exception do
       g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ExecutaCACIC');
  End;

  Sleep(5000); // Espera de 5 segundos para o caso de ter sido baixado o Agente Principal...

  ExecutaCACIC;

  // Intervalo de 1 minuto (60 segundos)
  // Normalmente a cada 120 minutos (2 horas) acontecerá a chamada ao chkSIS
  timerToCHKSIS.Interval := 60000;
  timerToCHKSIS.Enabled  := true;
end;

procedure TCacicSustainService.ExecutaCACIC;
Begin
  g_oCacic.writeDebugLog('ExecutaCACIC: BEGIN');

  g_oCacic.writeDebugLog('ExecutaCACIC: deleteFile => '+g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt');
  DeleteFile(PAnsiChar(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt'));
  DeleteFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\aguarde_UPDATE.txt'));
  Sleep(2000);

  // Caso exista uma cópia do chkSIS.exe supostamente baixada do servidor de updates, movo-a para a devida pasta
  if FileExists(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') then
    Begin
      g_oCacic.writeDebugLog('ExecutaCACIC: Encontrado "' + g_oCacic.getLocalFolderName + 'Temp\chksis.exe" com versão "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') + '"');

      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CHKSIS.EXE', strChkSisInfFileName),false,true)  = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\chksis.exe')) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Hash Code conferido! Movendo para ' + g_oCacic.getWinDir);

          CopyFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\chksis.exe'),PAnsiChar(g_oCacic.getWinDir + 'chksis.exe'),false);
          Sleep(2000);

          // A função MoveFile não estava excluindo o arquivo da origem. (???)
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\chksis.exe');
          Sleep(2000);
        End
      else
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: HASH Codes diferentes: "'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CHKSIS.EXE', strChkSisInfFileName),false,true) + '" e "'+g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\chksis.exe')+'"');
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\chksis.exe');
          Sleep(2000);
          g_oCacic.writeDebugLog('ExecutaCACIC: Cópia não efetuada e arquivo apagado!');
        End;
    End;

  g_oCacic.writeDebugLog('ExecutaCACIC: Verificando "aguarde_CACIC.txt" e "aguarde_UPDATE.txt"');
  if (not (FileExists(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt')) and
      not (FileExists(g_oCacic.getLocalFolderName + 'Temp\aguarde_UPDATE.txt'))) or
      not FileExists(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName) or
     ((FileExists(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt')) and
      (FileExists(g_oCacic.getLocalFolderName + 'normal_CACIC.txt'))) then
    Begin
      g_oCacic.writeDebugLog('ExecutaCACIC: Verificando situação estranha com indicador de atividades e finalização normal!');

      // Verifico se o arquivo indicador de finalização normal também inexiste...
      if not FileExists(g_oCacic.getLocalFolderName + 'normal_CACIC.txt') or
         not FileExists(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName) or
            ((FileExists(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt')) and
             (FileExists(g_oCacic.getLocalFolderName + 'normal_CACIC.txt'))) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Invocando "chkSIS.exe" para verificação.');
          // Executo o CHKsis, verificando a estrutura do sistema
          Try
            if (g_oCacic.isWindowsGEVista) then
              Begin
                g_oCacic.writeDebugLog('ExecutaCACIC: Ativando StartAPP('+g_oCacic.getWinDir+',chksis.exe)');
                CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
              End
            else
              Begin
                g_oCacic.writeDebugLog('ExecutaCACIC: Ativando CreateSampleProcess(' + g_oCacic.getWinDir + 'chksis.exe)');
                g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
              End;
          Except
            on E : Exception do
               g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ExecutaCACIC');
          End;
      Sleep(5000); // Espera de 5 segundos para o caso de ter sido baixado o Agente Principal...

      if FileExists(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Encontrado Agente Principal (' + g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName + ') com versão "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName) + '" para atualização');

          CopyFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName),PAnsiChar(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName),false);
          Sleep(2000);

          // A função MoveFile não estava excluindo o arquivo da origem. (???)
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName);
          Sleep(2000);

          // VERIFICO O HASH CODE DO AGENTE PRINCIPAL...
          g_oCacic.writeDebugLog('ExecutaCACIC: HASH Code do INI: "'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', g_oCacic.getMainProgramName , strChkSisInfFileName ),false,true)+'"');
          g_oCacic.writeDebugLog('ExecutaCACIC: HASH Code de      "'+g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName+'": "'+g_oCacic.getFileHash(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName)+'"');
        End
      else
        g_oCacic.writeDebugLog('ExecutaCACIC: Arquivo "'+g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName+'" NÃO ENCONTRADO!');

      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', g_oCacic.getMainProgramName, strChkSisInfFileName),false,true) = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName) ) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Agente Principal válido para execução!');
          // Executo o Agente Principal do CACIC
          if (g_oCacic.isWindowsGEVista) then
            CacicSustainService.startapp(g_oCacic.getLocalFolderName,g_oCacic.getMainProgramName)
          else
            g_oCacic.createOneProcess(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName,false,SW_NORMAL);
          end;
        End
      else
        g_oCacic.writeDebugLog('ExecutaCACIC: HASH Code do Agente Principal INVÁLIDO ou DIFERENTE');
    End
  else
    g_oCacic.writeDebugLog('ExecutaCACIC: Cookie Bloqueado pelo Agente Principal ENCONTRADO - CACIC em Execução!');

  g_oCacic.writeDebugLog('ExecutaCACIC: Verificando existência de nova versão deste serviço para atualização.');
  // Verifico a existência de nova versão do serviço e finalizo em caso positivo...
  if (FileExists(g_oCacic.getLocalFolderName + 'Temp\cacicservice.exe')) and
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CACICSERVICE.EXE', strChkSisInfFileName),false,true) = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\cacicservice.exe')) then
    Begin
        g_oCacic.writeDebugLog('ExecutaCACIC: CACICSERVICE.EXE_HASH => '+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CACICSERVICE.EXE', strChkSisInfFileName),false,true) );
        g_oCacic.writeDebugLog('ExecutaCACIC: Terminando para execução de atualização...');
        CacicSustainService.ServiceThread.ProcessRequests(true);
        CacicSustainService.ServiceThread.Terminate;
    End
  else
    g_oCacic.writeDebugLog('ExecutaCACIC: Não foi encontrada nova versão disponibilizada deste serviço.');

  g_oCacic.writeDebugLog('ExecutaCACIC: END');
End;

procedure TCacicSustainService.timerToCHKSISTimer(Sender: TObject);
begin
  timerToCHKSIS.Enabled := false;

  g_oCacic.writeDebugLog('Timer_CHKsisTimer: BEGIN');

  inc(intContaMinutos);

  // A cada 2 horas o Verificador de Integridade do Sistema será chamado
  // Caso o DEBUG esteja ativo esse intervalo se reduz a 2 minutos
  if (intContaMinutos = 120) or (g_oCacic.isInDebugMode and (intContaMinutos = 2))then
    Begin
      intContaMinutos := 0;
      g_oCacic.writeDebugLog('Timer_CHKsisTimer: Criando processo "'+g_oCacic.getWinDir + 'chksis.exe');
      Try
        if (g_oCacic.isWindowsGEVista) then
            CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
        else
            g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
      Except
        on E : Exception do
            g_oCacic.writeExceptionLog(E.Message,E.ClassName,'timerToChkSIS');
      End;
    End;

  g_oCacic.writeDebugLog('Timer_CHKsisTimer: Chamando ExecutaCACIC...');

  ExecutaCACIC;

  if timerToCHKSIS.Interval <> 60000 then
    timerToCHKSIS.Interval := 60000;
    
  timerToCHKSIS.Enabled := true;
  g_oCacic.writeDebugLog('Timer_CHKsisTimer: END');
end;

procedure TCacicSustainService.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  g_oCacic.writeDebugLog('ServiceStop: BEGIN');
  try
    Stopped := True; // always stop service, even if we had exceptions, this is to prevent "stuck" service (must reboot then)
  except
    on E : Exception do
       g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ServiceStop');
  end;
  g_oCacic.writeDebugLog('ServiceStop: END');
end;

procedure TCacicSustainService.ServiceShutdown(Sender: TService);
var Stopped : boolean;
begin
  // is called when windows shuts down
  ServiceStop(Self, Stopped);
end;

end.
