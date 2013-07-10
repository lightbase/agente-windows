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
===============================================================================================================
InstallCACIC.exe : Verificador/Instalador do Serviço de Sustentação e Verificador de Estrutura do Sistema CACIC
===============================================================================================================

v 2.8.0.3
  * O módulo ChkCACIC teve seu nome alterado para InstallCACIC, visando primeiramente facilitar o entendimento quanto à sua finalidade;
  * A forma de instalação foi otimizada, ficando o InstallCACIC responsável em instalar e executar apenas o chkSIS.exe caso seja instalação "silenciosa".;

v 2.6.0.0
+ Acrescentado suporte à plataforma Microsoft 64Bits

v 2.2.0.38
+ Acrescentado a obtenção de versão interna do S.O.
+ Acrescentado a inserção dos agentes principais nas exceções do FireWall interno do MS-Windows VISTA...
.
Diversas rebuilds...
.
v 2.2.0.17
+ Acrescentado o tratamento da passagem de opções em linha de comando (sugestão do Cláudio Filho - BrOffice.org)
  * chkcacic /serv=<WebManagerAddress> /dir=<LocalFolder>
  Exemplo de uso: chkcacic /serv=UXbra001 /dir=Cacic /silent

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

unit uInstallCACIC;

interface

uses  Windows,
      Messages,
      SysUtils,
      StrUtils,
      Variants,
      Classes,
      Graphics,
      Controls,
      Forms,
      Dialogs,
      NTFileSecurity,
      WinSvc,
      StdCtrls,
      ExtCtrls,
      ComCtrls,
      ShellAPI,
      CACIC_Library,
      CACIC_WMI,
      CACIC_Comm,
      CACIC_VerifyAndGetModules;

function IsUserAnAdmin() : boolean; external shell32;

type
  TfrmInstallCACIC = class(TForm)
    pnVersao: TPanel;
    gbMandatory: TGroupBox;
    lbWebManagerAddress: TLabel;
    lbInformeEndereco: TLabel;
    edWebManagerAddress: TEdit;
    btConfirmProcess: TButton;
    btExit: TButton;
    lbActionsLog: TStaticText;
    gbProgress: TGroupBox;
    richProgress: TRichEdit;
    staticStatus: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure comunicaInsucesso(strIndicador : String); //2.2.0.32
    procedure FS_SetSecurity(p_Target : String);
    procedure gravaConfiguracoes;
    procedure informaProgresso(pStrMessage : String; pBoolAlert : boolean = false);
    procedure installCACIC;
    procedure btConfirmProcessClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);

    function  boolCanRunCACIC                                           : boolean;
    function  findWindowByTitle(pStrWindowTitle: string)                : Hwnd;
    function  listFileDir(pStrPath: string)                             : string;
    function  serviceGetStatus(sMachine, sService: PChar)               : DWORD;
    function  serviceStart(pStrServiceName : string )                   : boolean;
    function  serviceRunning(pCharMachineName, pCharServiceName: PChar) : boolean;
    function  serviceStopped(pCharMachineName, pCharServiceName: PChar) : boolean;
  private
  public
    strTeSuccessPhrase,
    strTeInsuccessPhrase,
    strCommResponse,
    strChkSisInfFileName,
    strFieldsAndValuesToRequest,
    strMainProgramInfFileName,
    strGerColsInfFileName       : String;
    boolShowForm                : boolean;
    objCACIC                    : TCACIC;
  end;

var frmInstallCACIC : TfrmInstallCACIC;

implementation

{$R *.dfm}

procedure TfrmInstallCACIC.FormCreate(Sender: TObject);
begin
  Try
    boolShowForm := true;
    objCacic     := TCACIC.Create();

    objCacic.setBoolCipher(true);
    objCacic.setLocalFolderName('Cacic');
    objCacic.setWebServicesFolderName('ws/');

    if IsUserAnAdmin then
      Begin
        objCacic.setWebManagerAddress(objCacic.getParam('Serv'));
        boolShowForm := not FindCmdLineSwitch('silent',true);

        // Verifico se foi uma execução duvidosa e mostro o diálogo
        if (ParamCount > 0) and (objCacic.getWebManagerAddress = '') then
           Begin
             boolShowForm := true;
             ShowMessage('Forma de Uso COM PASSAGEM DE PARÂMETROS:' + #13#10 +
                         '-------------------------------------------------'  + #13#10 +
                         'installcacic.exe   < /serv=NomeOuIpDoServidorDeAplicacao >  [/silent]'+ #13#10 + #13#10 +
                         '1) O parâmetro "/serv" é obrigatório;' + #13#10 +
                         '2) A opção /silent é opcional e não exibirá o processo de instalação. Ideal para uso em scripts de logon.' + #13#10 + #13#10);
           End
        else
           Begin
              strChkSisInfFileName     := objCacic.getWinDir          + 'chksis.inf';
              strGerColsInfFileName    := objCacic.getLocalFolderName + 'gercols.inf';

              if boolShowForm then
                Begin
                  Visible     := true;
                  WindowState := wsNormal;
                  gbMandatory.BringToFront;

                  lbWebManagerAddress.BringToFront;
                  edWebManagerAddress.BringToFront;

                  edWebManagerAddress.Text := objCacic.getWebManagerAddress;

                  self.Refresh;

                  edWebManagerAddress.SetFocus;
                End
              else if (objCacic.getWebManagerAddress <> '') then
                installCACIC
              else
                objCacic.writeDailyLog('ATENÇÃO: InstallCACIC chamado com opção "/silent" mas sem a opção "/serv"!');
           End;
      End
    else
      Begin // Se NT/2000/XP/...
        if boolShowForm then
          MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);

        objCacic.writeDailyLog('SEM PRIVILÉGIOS: Necessário ser administrador "local" ou de Domínio!');
        ComunicaInsucesso('0'); // O indicador "0" (zero) sinalizará falta de privilégio na estação
      End;
  Finally
  End;
end;

function TfrmInstallCACIC.ServiceGetStatus(sMachine, sService: PChar): DWORD;
  {*******************************************}
  {*** Parameters: ***}
  {*** sService: specifies the name of the service to open
  {*** sMachine: specifies the name of the target computer
  {*** ***}
  {*** Return Values: ***}
  {*** -1 = Error opening service ***}
  {*** 1 = SERVICE_STOPPED ***}
  {*** 2 = SERVICE_START_PENDING ***}
  {*** 3 = SERVICE_STOP_PENDING ***}
  {*** 4 = SERVICE_RUNNING ***}
  {*** 5 = SERVICE_CONTINUE_PENDING ***}
  {*** 6 = SERVICE_PAUSE_PENDING ***}
  {*** 7 = SERVICE_PAUSED ***}
  {******************************************}
var
  SCManHandle, SvcHandle: SC_Handle;
  SS: TServiceStatus;
  dwStat: DWORD;
begin
  dwStat := 0;
  // Open service manager handle.
  objCacic.writeDebugLog('ServiceGetStatus: Executando OpenSCManager.SC_MANAGER_CONNECT');
  SCManHandle := OpenSCManager(sMachine, nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    objCacic.writeDebugLog('ServiceGetStatus: Executando OpenService.SERVICE_QUERY_STATUS');
    SvcHandle := OpenService(SCManHandle, sService, SERVICE_QUERY_STATUS);
    // if Service installed
    if (SvcHandle > 0) then
    begin
      objCacic.writeDebugLog('ServiceGetStatus: O serviço "'+ sService +'" já está instalado.');
      // SS structure holds the service status (TServiceStatus);
      if (QueryServiceStatus(SvcHandle, SS)) then
        dwStat := ss.dwCurrentState;
      CloseServiceHandle(SvcHandle);
    end;
    CloseServiceHandle(SCManHandle);
  end;
  Result := dwStat;
end;

// start service
//
// return TRUE if successful
//
// sService
//   service name, ie: Alerter
//
function TfrmInstallCACIC.ServiceStart(pStrServiceName : string ) : boolean;
var schm,
    schs   : SC_Handle;

    ss     : TServiceStatus;
    psTemp : PChar;
    dwChkP : DWord;
begin
  ss.dwCurrentState := 0;

  objCacic.writeDebugLog('ServiceStart: BEGIN');

  // connect to the service control manager
  schm := OpenSCManager(Nil,Nil,SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
    begin
      // open a handle to the specified service
      schs := OpenService(schm,PChar(pStrServiceName),SERVICE_START or SERVICE_QUERY_STATUS);

      // if successful...
    if(schs > 0)then
      begin
        objCacic.writeDebugLog('ServiceStart: Open Service OK');
        psTemp := Nil;
        if(StartService(schs,0,psTemp)) then
          begin
            objCacic.writeDebugLog('ServiceStart: Entrando em Start Service');
            // check status
            if(QueryServiceStatus(schs,ss))then
              begin
                while(SERVICE_RUNNING <> ss.dwCurrentState)do
                  begin
                  // dwCheckPoint contains a value that the service increments periodically
                  // to report its progress during a lengthy operation.
                  dwChkP := ss.dwCheckPoint;

                  // wait a bit before checking status again
                  // dwWaitHint is the estimated amount of time the calling program should wait before calling
                  // QueryServiceStatus() again idle events should be handled here...

                  Sleep(ss.dwWaitHint);

                  if(not QueryServiceStatus(schs,ss))then
                    begin
                      break;
                    end;

                  if(ss.dwCheckPoint < dwChkP)then
                    begin
                      // QueryServiceStatus didn't increment dwCheckPoint as it should have.
                      // avoid an infinite loop by breaking
                      break;
                    end;
                end;
            end
        else
           objCacic.writeDebugLog('ServiceStart: Oops! Problema com StartService!');
        end;

        // close service handle
        CloseServiceHandle(schs);
      end;

      // close service control manager handle
      CloseServiceHandle(schm);
    end
  else
    richProgress.Lines.Add('Oops! Problema com o Service Control Manager!');
    // return TRUE if the service status is running
    Result := SERVICE_RUNNING = ss.dwCurrentState;
end;

procedure TfrmInstallCACIC.ComunicaInsucesso(strIndicador : String);
begin
  Try
    // Envio notificação de insucesso para o Módulo Gerente Centralizado
    strFieldsAndValuesToRequest :=                               'cs_indicador='  + strIndicador + ',';
    strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'id_usuario='    + objCACIC.getValueFromTags('UserName',fetchWMIvalues('Win32_ComputerSystem',objCACIC.getLocalFolderName,'UserName'));

      Try
        Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'installcacic.php', strFieldsAndValuesToRequest, objCACIC.getLocalFolderName, 'Enviando informação de insucesso ao Gerente WEB');
      Except
        on E : Exception do
          objCacic.writeExceptionLog(E.Message,E.ClassName,'ComunicaInsucesso');
      End;
  finally
  End;
end;

procedure TfrmInstallCACIC.GravaConfiguracoes;
var textFileChkSisInf : TextFile;
begin
   try
       FileSetAttr (strChkSisInfFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(textFileChkSisInf,strChkSisInfFileName); {Associa o arquivo a uma variável do tipo TextFile}
       Rewrite(textFileChkSisInf); // Recria o arquivo...
       Writeln(textFileChkSisInf,'[Configs]');
       // Escrita dos parâmetros obrigatórios
       Append(textFileChkSisInf);
       Writeln(textFileChkSisInf,'WebManagerAddress='       + objCacic.getWebManagerAddress);
       Append(textFileChkSisInf);
       Writeln(textFileChkSisInf,'WebServicesFolderName='   + objCacic.getWebServicesFolderName);
       CloseFile(textFileChkSisInf); {Fecha o arquivo texto}
       objCacic.writeDebugLog('GravaConfiguracoes: Concluindo geração do arquivo de configurações chkSIS.ini');
   except
     on E : Exception do
       Begin
          objCacic.writeExceptionLog(E.Message,E.ClassName,'GravaConfiguracoes');
       End;
   end;
end;

Function TfrmInstallCACIC.listFileDir(pStrPath: string):string;
var
  SR: TSearchRec;
  FileList : string;
begin
  if FindFirst(pStrPath, faAnyFile, SR) = 0 then
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

function TfrmInstallCACIC.boolCanRunCACIC : boolean;
Begin
  // Se eu conseguir matar o arquivo abaixo é porque não há outra sessão deste agente aberta... (POG? Nããão!  :) )
  objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');

  // Se o aguarde_CACIC.txt existir é porque refere-se a uma versão mais atual: 2.8.x ou maior
  Result := not (FileExists(objCacic.getLocalFolderName + 'aguarde_CACIC.txt'));
End;

procedure TfrmInstallCACIC.installCACIC;
var wordServiceStatus                      : DWORD;
    tstrRequest_ConfigIC                   : TStringList;
    strAuxInstallCACIC                     : String;
begin
  strTeSuccessPhrase      := 'INSTALAÇÃO/ATUALIZAÇÃO EFETUADA COM SUCESSO!';
  strTeInsuccessPhrase    := '*****  INSTALAÇÃO/ATUALIZAÇÃO NÃO EFETUADA COM SUCESSO  *****';
  richProgress.ScrollBars := ssNone;

  btConfirmProcess.Enabled := false;
  btExit.Enabled           := false;

  frmInstallCACIC.Visible := boolShowForm;
  Try
      if (objCacic.getValueFromFile('Hash-Codes', UpperCase(objCacic.getValueFromFile('Configs','MainProgramName',strChkSisInfFileName)), strChkSisInfFileName) = '') then
          Begin
            objCacic.deleteFileOrFolder(objCacic.getWinDir + 'chksis.exe');
            objCacic.deleteFileOrFolder(objCacic.getWinDir + 'chksis.ini');
            objCacic.deleteFileOrFolder(objCacic.getWinDir + 'chksis.dat');
            objCacic.deleteFileOrFolder(objCacic.getWinDir + 'chksis.log');
          End;

      objCacic.writeDebugLog('installCACIC: Verificando pasta "' + objCacic.getLocalFolderName + '"');
      // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
      if not DirectoryExists(objCacic.getLocalFolderName) then
          begin
            informaProgresso('Criando pasta '+objCacic.getLocalFolderName);
            ForceDirectories(objCacic.getLocalFolderName);
          end;

      objCacic.writeDebugLog('installCACIC: Verificando pasta "'+objCacic.getLocalFolderName+'Temp'+'"');
      // Crio o SubDiretório TEMP, caso não exista
      if not DirectoryExists(objCacic.getLocalFolderName+'Temp') then
          begin
            ForceDirectories(objCacic.getLocalFolderName + 'Temp');
            informaProgresso('Criando pasta '+objCacic.getLocalFolderName+'Temp');
          end;

      objCacic.writeDebugLog('installCACIC: Verificando pasta "' + objCacic.getLocalFolderName + 'Modules' + '"');
      // Crio o SubDiretório TEMP, caso não exista
      if not DirectoryExists(objCacic.getLocalFolderName + 'Modules') then
          begin
            ForceDirectories(objCacic.getLocalFolderName + 'Modules');
            informaProgresso('Criando pasta ' + objCacic.getLocalFolderName + 'Modules');
          end;

      objCacic.writeDebugLog('installCACIC: isWindowsNTPlataform => ' + objCacic.getBoolToString(objCacic.isWindowsNTPlataform()));
      objCacic.writeDebugLog('installCACIC: isWindowsAdmin       => ' + objCacic.getBoolToString(objCacic.isWindowsAdmin()));
      objCacic.writeDebugLog('installCACIC: isUserAnAdmin        => ' + objCacic.getBoolToString(IsUserAnAdmin()));

      // Verifica se o S.O. é NT Like e se o Usuário está com privilégio administrativo...
      {
      if ((objCacic.isWindowsNTPlataform()) and (objCacic.isWindowsAdmin())) or
         not objCacic.isWindowsNTPlataform then
         }

      objCacic.writeDebugLog('installCACIC: Drive de Instalação......................: ' + objCacic.getHomeDrive);
      objCacic.writeDebugLog('installCACIC: Pasta para Instalação Local..............: ' + objCacic.getLocalFolderName);
      objCacic.writeDebugLog('installCACIC: Endereço de Acesso ao Gerente WEB........: ' + objCacic.getWebManagerAddress);
      objCacic.writeDebugLog('installCACIC: Pasta para WebServices no Gerente WEB....: ' + objCacic.getWebServicesFolderName);
      objCacic.writeDebugLog('installCACIC: ' + DupeString(':',100));

      objCacic.writeDebugLog('installCACIC: :::::::::::::::::::: LIBERAÇÃO DE FIREWALL ::::::::::::::::::::');

      objCacic.writeDebugLog('installCACIC: isWindowsGEXP => ' + objCacic.getBoolToString(objCacic.isWindowsGEXP()));
      if (objCacic.isWindowsGEXP()) then // Se >= Maior ou Igual ao WinXP...
        Begin
          objCacic.writeDebugLog('installCACIC:  => S.O. Maior/Igual a WinXP <=');
          Try
            // Libero as policies do FireWall Interno
            objCacic.writeDebugLog('installCACIC: isWindowsGEVista => ' + objCacic.getBoolToString(objCacic.isWindowsGEVista()));
            if (objCacic.isWindowsGEVista()) then // Maior ou Igual ao VISTA...
              Begin
                objCacic.writeDebugLog('installCACIC: => S.O. Maior/Igual a WinVISTA <=');
                Try
                  Begin
                    // Liberando as conexões de Saída para o FTP
                    informaProgresso('Liberando as conexões de Saída para o serviço FTP');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='             + objCacic.getHomeDrive + 'system32\\ftp.exe|Name=FTP|Desc=Programa de transferência de arquivos|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='            + objCacic.getHomeDrive + 'system32\\ftp.exe|Name=FTP|Desc=Programa de transferência de arquivos|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='                 + objCacic.getHomeDrive + 'system32\\ftp.exe|Name=FTP|Desc=Programa de transferência de arquivos|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='                + objCacic.getHomeDrive + 'system32\\ftp.exe|Name=FTP|Desc=Programa de transferência de arquivos|Edge=FALSE|');

                    // Liberando as conexões de Saída para o InstallCACIC
                    informaProgresso('Liberando as conexões de Saída para o InstallCACIC');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-INSTALLCACIC-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='  + ExtractFilePath(Application.Exename) + '\installcacic.exe|Name=InstallCACIC|Desc=Módulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-INSTALLCACIC-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App=' + ExtractFilePath(Application.Exename) + '\installcacic.exe|Name=InstallCACIC|Desc=Módulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-INSTALLCACIC-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='      + ExtractFilePath(Application.Exename) + '\installcacic.exe|Name=InstallCACIC|Desc=Módulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-INSTALLCACIC-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='     + ExtractFilePath(Application.Exename) + '\installcacic.exe|Name=InstallCACIC|Desc=Módulo Verificador de Integridade e Instalador do Sistema CACIC|Edge=FALSE|');


                    // Liberando as conexões de Saída para o ChkSis
                    informaProgresso('Liberando as conexões de Saída para o ChkSIS');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='    + objCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='   + objCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='        + objCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='       + objCacic.getWinDir + 'chksis.exe|Name=chkSIS|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                  End
                Except
                  on E : Exception do
                    Begin
                      objCacic.writeExceptionLog(E.Message,E.ClassName,'Escrevendo Firewallpolicies para liberações de conexões. (1)');
                      informaProgresso('Oops! Problema Liberando Policies de FireWall!',true);
                      objCacic.writeDebugLog('installCACIC: Problema Liberando Policies de FireWall!');
                    End;
                End;
              End
            else
              Begin
                objCacic.writeDebugLog('installCACIC: => S.O. Menor que WinVISTA <=');
                // Acrescento o InstallCacic e srCACICsrv às exceções do FireWall nativo...
                {installcacic}
                informaProgresso('Inserindo o InstallCACIC.exe nas exceções do FireWall!');
                objCacic.writeDebugLog('installCACIC: Inserindo "'+ExtractFilePath(Application.Exename) + 'installcacic.exe" nas exceções do FireWall!');
                objCacic.addApplicationToFirewall('InstallCACIC - Instalador do Sistema CACIC',ExtractFilePath(Application.Exename) + Application.Exename,true);
              End;
          Except
            on E : Exception do
              Begin
                informaProgresso('Oops! Problemas ao escrever Firewallpolicies para liberações de conexões. (2)',true);
                objCacic.writeExceptionLog(E.Message,E.ClassName,'Escrevendo Firewallpolicies para liberações de conexões. (2)');
                objCacic.writeDebugLog('installCACIC: Problema Liberando Policies de FireWall!');
              End;
          End;
        End;

      objCacic.writeDebugLog('installCACIC: ' + DupeString(':',100));

      Try
        // Tento o contato com o módulo gerente WEB para obtenção de
        // dados para conexão FTP e relativos às versões atuais dos principais agentes
        // Busco as configurações para acesso ao ambiente FTP - Updates
        strFieldsAndValuesToRequest := 'in_instalacao=OK';

        objCacic.writeDebugLog('installCACIC: Preparando Chamada ao Gerente WEB: "' + objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName +'get_config.php"');
        informaProgresso('Fazendo contato com Gerente WEB.');

        strCommResponse := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get_config.php', strFieldsAndValuesToRequest, objCACIC.getLocalFolderName);
        if (strCommResponse <> '0') then
          Begin
            { Já realizados na chamada ao get_test.php
              objCacic.setBoolCipher
              objCacic.setMainProgramName
              objCacic.setMainProgramHash
              objCacic.setLocalFolderName
              objCacic.setWebManagerAddress
              objCacic.setWebServicesFolderName
            }

            FileSetAttr ( PChar(strChkSisInfFileName),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000

            objCACIC.setMainProgramName(objCacic.getValueFromTags('MainProgramName', strCommResponse,'<>'));
            strMainProgramInfFileName := ChangeFileExt(objCacic.getMainProgramName,'.inf');

            objCacic.setValueToFile('Configs'   ,'NmUsuarioLoginServUpdates' , objCacic.getValueFromTags('nm_usuario_login_serv_updates'      , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'NuPortaServUpdates'        , objCacic.getValueFromTags('nu_porta_serv_updates'              , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'LocalFolderName'           , objCacic.getValueFromTags('LocalFolderName'                    , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'MainProgramName'           , objCacic.getValueFromTags('MainProgramName'                    , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'TePathServUpdates'         , objCacic.getValueFromTags('te_path_serv_updates'               , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'TeServUpdates'             , objCacic.getValueFromTags('te_serv_updates'                    , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'TeSenhaLoginServUpdates'   , objCacic.getValueFromTags('te_senha_login_serv_updates'        , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'WebManagerAddress'         , objCacic.getWebManagerAddress                                                          , strChkSisInfFileName);
            objCacic.setValueToFile('Configs'   ,'WebServicesFolderName'     , objCacic.getWebServicesFolderName                                                      , strChkSisInfFileName);
            objCacic.setValueToFile('Hash-Codes','CHKSIS.EXE'                , objCacic.getValueFromTags('CHKSIS.EXE_HASH'                    , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Hash-Codes','CACICSERVICE.EXE'          , objCacic.getValueFromTags('CACICSERVICE.EXE_HASH'              , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Hash-Codes','GERCOLS.EXE'               , objCacic.getValueFromTags('GERCOLS.EXE_HASH'                   , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Hash-Codes','SRCACICSRV.EXE'            , objCacic.getValueFromTags('SRCACICSRV.EXE_HASH'                , strCommResponse,'<>') , strChkSisInfFileName);
            objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName , objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH', strCommResponse,'<>') , strChkSisInfFileName);

            informaProgresso('Informações obtidas:');
            informaProgresso('Servidor de updates.........................................: ' +               objCACIC.deCrypt(objCacic.getValueFromTags('te_serv_updates'              , strCommResponse,'<>')));
            informaProgresso('Porta do servidor de updates................................: ' +               objCACIC.deCrypt( objCacic.getValueFromTags('nu_porta_serv_updates'       , strCommResponse,'<>')));
            informaProgresso('Usuário para login no servidor de updates...................: ' +               objCacic.deCrypt(objCacic.getValueFromTags('nm_usuario_login_serv_updates', strCommResponse,'<>'),true,true));
            informaProgresso('Pasta no servidor de updates................................: ' +               objCACIC.deCrypt(objCacic.getValueFromTags('te_path_serv_updates'         , strCommResponse,'<>')));
            informaProgresso('Versão do Serviço para Sustentação do Sistema (CACICSERVICE): ' +               objCACIC.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_VER'         , strCommResponse,'<>')));
            informaProgresso('Versão do Verificador de Integridade do Sistema (CHKSIS)....: ' +               objCACIC.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_VER'               , strCommResponse,'<>')));
            informaProgresso('Versão do Agente Principal do Sistema ('                        + ChangeFileExt(objCacic.getMainProgramName,'') + ')....: '  + objCACIC.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_VER', strCommResponse,'<>')));

            objCacic.writeDebugLog('installCACIC: :::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
            objCacic.writeDebugLog('installCACIC: Endereço do Servidor de Aplicações..........................: ' + objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'                              , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Pasta WebServices no Servidor de Aplicações.................: ' + objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'                          , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Servidor de updates.........................................: ' + objCacic.deCrypt(objCacic.getValueFromTags('te_serv_updates'                                , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Porta do servidor de updates................................: ' + objCacic.deCrypt(objCacic.getValueFromTags('nu_porta_serv_updates'                          , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Usuário para login no servidor de updates...................: ' + objCacic.deCrypt(objCacic.getValueFromTags('nm_usuario_login_serv_updates'                  , strCommResponse,'<>'),true,true));
            objCacic.writeDebugLog('installCACIC: Pasta no servidor de updates................................: ' + objCacic.deCrypt(objCacic.getValueFromTags('te_path_serv_updates'                           , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Versão do Serviço para Sustentação do Sistema (CACICSERVICE): ' + objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_VER'                           , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Versão do Verificador de Integridade do Sistema (CHKSIS)....: ' + objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_VER'                                 , strCommResponse,'<>'))           );
            objCacic.writeDebugLog('installCACIC: Versão do Agente Principal do Sistema ('                        + ChangeFileExt(objCacic.getMainProgramName,'') + ')....: '  + objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_VER', strCommResponse,'<>')));
            objCacic.writeDebugLog('installCACIC: ' + DupeString(':',100));

            // Verificar existência do AGENTE PRINCIPAL!!!!!!
            if FileExists(objCacic.getLocalFolderName + objCacic.getMainProgramName) then
              if (objCacic.getFileHash(objCacic.getLocalFolderName + objCacic.getMainProgramName) =  objCacic.getValueFromFile('Hash-Codes', objCacic.getMainProgramName,strChkSisInfFileName) ) then
                Begin
                  if boolShowForm then
                    Begin
                      informaProgresso('Agente principal encontrado localmente com versão atual!');
                      ShowMessage('ATENÇÃO: Para desinstalação do CACIC faz-se necessária a parada e desinstalação do serviço "CacicService" em modo de segurança.');
                    End
                End
              else
                Begin
                  informaProgresso('Versão divergente de Agente Principal encontrada. Excluindo...');
                  objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + objCacic.getMainProgramName);
                  sleep(2000);
                  // Faço FTP do Agente Principal
                  strAuxInstallCACIC := verifyAndGetModules(objCacic.getMainProgramName,
                                                       objCacic.getMainProgramHash,
                                                       objCacic.getLocalFolderName,
                                                       objCacic.getLocalFolderName,
                                                       objCacic,
                                                       strChkSisInfFileName);
                  informaProgresso(strAuxInstallCACIC);
                End;

            // Verificação de versão do agente principal e exclusão em caso de versão antiga/diferente da atual
            objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'cacic2.exe');

            // Tento detectar o GerCols.EXE e faço FTP caso não exista ou tenha o Hash-Code diferente do repositório
            strAuxInstallCACIC := verifyAndGetModules('gercols.exe',
                                                      objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_HASH', strCommResponse,'<>'),true,true),
                                                      objCacic.getLocalFolderName + 'Modules',
                                                      objCacic.getLocalFolderName,
                                                      objCacic,
                                                      strChkSisInfFileName);
            informaProgresso(strAuxInstallCACIC);

            // Tento detectar o Agente Principal e faço FTP caso não exista ou tenha o Hash-Code diferente do repositório
            strAuxInstallCACIC := verifyAndGetModules(objCacic.getMainProgramName,
                                                      objCacic.getMainProgramHash,
                                                      objCacic.getLocalFolderName,
                                                      objCacic.getLocalFolderName,
                                                      objCacic,
                                                      strChkSisInfFileName);
            informaProgresso(strAuxInstallCACIC);

            // Tento detectar o Servidor de Suporte Remoto e faço FTP caso não exista ou tenha o Hash-Code diferente do repositório
            strAuxInstallCACIC := verifyAndGetModules('srcacicsrv.exe',
                                                      objCacic.deCrypt(objCacic.getValueFromTags('SRCACICSRV.EXE_HASH', strCommResponse,'<>'),true,true),
                                                      objCacic.getLocalFolderName + 'Modules',
                                                      objCacic.getLocalFolderName,
                                                      objCacic,
                                                      strChkSisInfFileName);
            informaProgresso(strAuxInstallCACIC);

            // Tento detectar o ChkSis.EXE e faço FTP caso não exista ou tenha o Hash-Code diferente do repositório
            strAuxInstallCACIC := verifyAndGetModules('chksis.exe',
                                                      objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse,'<>'),true,true),
                                                      objCacic.getWinDir,
                                                      objCacic.getLocalFolderName,
                                                      objCacic,
                                                      strChkSisInfFileName);
            informaProgresso(strAuxInstallCACIC);

            // Se NTFS em NT/2K/XP...
            // If NTFS on NT Like...
            If (objCacic.isWindowsNTPlataform()) then
              Begin
                Try
                  strAuxInstallCACIC := verifyAndGetModules('cacicservice.exe',
                                                           objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_HASH', strCommResponse,'<>'),true,true),
                                                           objCacic.getWinDir,
                                                           objCacic.getLocalFolderName,
                                                           objCacic,
                                                           strChkSisInfFileName);
                  informaProgresso(strAuxInstallCACIC);

                  objCacic.setValueToFile('Installation','CacicService.exe' , objCacic.checkModule(objCacic.getWinDir + 'cacicservice.exe', objCACIC.deCrypt( objCacic.getValueFromTags('CACICSERVICE.EXE_HASH', strCommResponse,'<>'),false,true)), strChkSisInfFileName);

                  informaProgresso('Atribuindo permissões de acessos a instalador e verificador de integridade.');
                  objCacic.writeDebugLog('installCACIC: ::::::: VERIFICANDO FILE SYSTEM E ATRIBUINDO PERMISSÕES :::::::');
                  objCacic.writeDebugLog('installCACIC: ' + DupeString(':',100));

                  // Atribuição de acesso para atualização do módulo verificador de integridade do sistema e seus arquivos
                  FS_SetSecurity(objCacic.getWinDir + ChangeFileExt(strChkSisInfFileName,'.exe'));
                  FS_SetSecurity(objCacic.getLocalFolderName + 'Logs\' + ChangeFileExt(strChkSisInfFileName,'.log'));
                  FS_SetSecurity(strChkSisInfFileName);

                  // Atribuição de acesso para atualização/exclusão de log do instalador
                  FS_SetSecurity(objCacic.getLocalFolderName + 'Logs\installcacic.log');
                  objCacic.writeDebugLog('installCACIC: ' + DupeString(':',100));

                  // Acrescento o chkSIS às exceções do FireWall nativo...

                  {chksis}
                  objCacic.writeDebugLog('installCACIC: Inserindo "'+objCacic.getWinDir + 'chksis" nas exceções do FireWall!');
                  objCacic.addApplicationToFirewall('chkSIS - Módulo Verificador de Integridade do Sistema CACIC',objCacic.getWinDir + 'chksis.exe',true);
                Except
                  on E : Exception do
                    Begin
                      objCacic.writeExceptionLog(E.Message,E.ClassName,'Criando exceções na FireWall (isWindowsNTPlatform)');
                    End;
                End;
              End;

            objCacic.writeDebugLog('installCACIC: Gravando registros para auto-execução');

            // Somente para S.O. NOT NT LIKE
            if NOT (objCacic.isWindowsNTPlataform) then
              Begin
                // Crio a chave/valor chksis para autoexecução do ChkSIS, caso não exista esta chave/valor
                objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', objCacic.getWinDir + 'chksis.exe');
              End;

            // ATENÇÃO:
            // Após testes no Vista, percebí que o firewall nativo interrompia o FTP e truncava o agente com tamanho zero...
            // A nova tentativa abaixo ajudará a sobrepor o agente truncado e corrompido

            // Tento detectar (de novo) o ChkSis.EXE e faço FTP caso não exista
            verifyAndGetModules('chksis.exe',
                                objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse,'<>'),true,true),
                                objCacic.getWinDir,
                                objCacic.getLocalFolderName,
                                objCacic,
                                strChkSisInfFileName);

            objCacic.setValueToFile('Installation','chkSIS.exe', objCacic.checkModule(objCacic.getWinDir + 'chksis.exe', objCACIC.deCrypt( objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse,'<>'),false,true)), strChkSisInfFileName);

            // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
            if  (objCacic.getValueFromFile('Installation','CacicService.exe' , strChkSisInfFileName) = 'Ok!') and
                (objCacic.getValueFromFile('Installation','ChkSIS.exe'       , strChkSisInfFileName) = 'Ok!') then
                Begin
                  informaProgresso(strTeSuccessPhrase);
                  informaProgresso('A Estrutura do Sistema encontra-se Ok!');
                End
            else
                Begin
                  informaProgresso(DupeString('*',100),true);
                  informaProgresso('A Estrutura do Sistema encontra-se Inconsistente!',true);
                  informaProgresso(DupeString('*',100),true);
                  informaProgresso('Recomendação Principal:',true);
                  informaProgresso(DupeString('-',15),true);
                  informaProgresso('Acessar a opção Manutenção / Atualização de SubRedes e atualizar devidamente o Servidor de Updates.',true);
                  informaProgresso(DupeString('-',15),true);
                  informaProgresso(strTeInsuccessPhrase,true);
                  ComunicaInsucesso('1'); // O indicador "1" sinalizará que não foi devido a privilégio na estação
                End;

            if boolCanRunCACIC and
               (objCacic.getValueFromFile('Installation','ChkSIS.exe', strChkSisInfFileName) = 'Ok!') then
              Begin
                // Se não for plataforma NT executo o agente principal
                if not (objCacic.isWindowsNTPlataform()) then
                  Begin
                    if boolShowForm then
                      objCacic.writeDebugLog('installCACIC: Executando ' + objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /WebManagerAddress=' + objCacic.getWebManagerAddress+ ' /WebServicesFolderName=' + objCacic.getWebServicesFolderName)
                    else
                      objCacic.writeDebugLog('installCACIC: Executando ' + objCacic.getWinDir + 'chksis.exe /WebManagerAddress=' + objCacic.getWebManagerAddress + ' /WebServicesFolderName=' + objCacic.getWebServicesFolderName);
                  End
                else
                  Begin

                    {*** 1 = SERVICE_STOPPED ***}
                    {*** 2 = SERVICE_START_PENDING ***}
                    {*** 3 = SERVICE_STOP_PENDING ***}
                    {*** 4 = SERVICE_RUNNING ***}
                    {*** 5 = SERVICE_CONTINUE_PENDING ***}
                    {*** 6 = SERVICE_PAUSE_PENDING ***}
                    {*** 7 = SERVICE_PAUSED ***}

                    // Verifico se o serviço está instalado/rodando,etc.
                    wordServiceStatus := ServiceGetStatus(nil,'CacicSustainService');
                    if (wordServiceStatus = 0) then
                      Begin
                        // Instalo e Habilito o serviço
                        informaProgresso('Instalando o CACICservice em modo silencioso.');
                        objCacic.createOneProcess(objCacic.getWinDir + 'cacicservice.exe /install /silent',true);
                      End
                    else if (wordServiceStatus < 4)  then
                      Begin
                        informaProgresso('Iniciando o CACICservice');
                        objCacic.createOneProcess(objCacic.getWinDir + 'cacicservice.exe -start', true);
                      End
                    else if (wordServiceStatus > 4)  then
                      Begin
                        informaProgresso('Continuando o CACICservice');
                        objCacic.createOneProcess(objCacic.getWinDir + 'cacicservice.exe -continue', true);
                      End
                    else
                        informaProgresso('CACICservice não foi instalado por já estar rodando!');
                  End;

                if boolShowForm then
                  Begin
                    MessageDLG(#13#10+'ATENÇÃO!'+#13#10+#13#10+'Se o ícone do CACIC não for exibido na bandeja do sistema, é recomendável a reinicialização da máquina.',mtInformation,[mbOK],0);
                    informaProgresso('Executando o Agente Principal do CACIC.');
                  End;
                objCacic.createOneProcess(objCacic.getLocalFolderName + objCACIC.getMainProgramName, false);
              End
            else
              if FileExists(objCacic.getLocalFolderName + 'aguarde_CACIC.txt') then
                objCacic.writeDebugLog('installCACIC: CACIC em Execução!')
              else
                objCacic.writeDebugLog('installCACIC: Problema no Download do Verificador de Integridade do Sistema (ChkSIS)');
          End;
      Except
        on E : Exception do
          Begin
            objCacic.writeExceptionLog(E.Message,E.ClassName,'Falha no processo de Instalação/Atualização');
            informaProgresso('Falha no processo de Instalação/Atualização',true);
          End;
      End;
  Except
    on E : Exception do
      Begin
        objCacic.writeExceptionLog(E.Message,E.ClassName,'Falha na Instalação/Atualização');
        informaProgresso('Falha na Instalação/Atualização',true);
      End;
  End;

  if boolShowForm then
    Begin
      richProgress.ScrollBars := ssBoth;
      richProgress.Perform(EM_SCROLLCARET,0,0);
    End
  else
    btExitClick(nil);
end;

function TfrmInstallCACIC.serviceRunning(pCharMachineName, pCharServiceName: PChar): Boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(pCharMachineName, pCharServiceName);
end;

function TfrmInstallCACIC.serviceStopped(pCharMachineName, pCharServiceName: PChar): Boolean;
begin
  Result := SERVICE_STOPPED = ServiceGetStatus(pCharMachineName, pCharServiceName);
end;

function TfrmInstallCACIC.findWindowByTitle(pStrWindowTitle: string): Hwnd;
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

    if (trim(StrPas(NextTitle))<> '') and (Pos(strlower(pchar(pStrWindowTitle)), strlower(PChar(StrPas(NextTitle)))) <> 0) then
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

procedure TfrmInstallCACIC.informaProgresso(pStrMessage : String; pBoolAlert : boolean = false);
Begin
  if boolShowForm then
    Begin
      staticStatus.Font.Size            := 8;
      staticStatus.Font.Style           := staticStatus.Font.Style - [fsBold];
      staticStatus.Font.Color           := clBlack;
      richProgress.SelAttributes.Color  := clWhite;

      if pBoolAlert then
        Begin
          staticStatus.Font.Color           := clMaroon;
          richProgress.SelAttributes.Color  := clYellow;
        End;

      staticStatus.Caption              := pStrMessage;
      richProgress.Lines.Add(pStrMessage);
      richProgress.Perform(EM_SCROLLCARET,0,0);
      richProgress.Repaint;

      Application.ProcessMessages;
      Application.ProcessMessages;
    End;
  objCacic.writeDailyLog(pStrMessage);
End;

procedure TfrmInstallCACIC.FS_SetSecurity(p_Target : String);
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
          case v_FS_Security.EntryType[intAux] of seAlias, seDomain, seGroup :
            Begin   // If local group, alias or user...
              v_FS_Security.FileRights[intAux]       := [faAll];
              v_FS_Security.DirectoryRights[intAux]  := [faAll];
              objCacic.writeDebugLog('FS_SetSecurity: ' + p_Target + ' [Full Access] >> '+v_FS_Security.EntryName[intAux]);
              //Setting total access on p_Target to local groups.
            End;
          End;
        end;

      // Atribui permissão total aos grupos locais
      // Set total permissions to local groups
      v_FS_Security.SetSecurity;
end
  else
    objCacic.writeDailyLog('File System: "' + v_FS_Security.FileSystemName+'" - Ok!');

  v_FS_Security.Free;
end;

procedure TfrmInstallCACIC.btConfirmProcessClick(Sender: TObject);
var strCommResponseTest         : String;
begin
  if (trim(edWebManagerAddress.Text)<> '') then
    Begin
      Try
        edWebManagerAddress.Text := objCacic.fixWebAddress(edWebManagerAddress.Text);
        objCacic.setWebManagerAddress(edWebManagerAddress.text);

        informaProgresso('Efetuando comunicação com o endereço informado...');

        strCommResponseTest := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/test', strFieldsAndValuesToRequest, objCACIC.getLocalFolderName,'>> Testando conexão');

        if (strCommResponseTest <> '0') then
          Begin
           objCacic.setBoolCipher(not objCacic.isInDebugMode);
           if (objCacic.getFileHash(ParamStr(0)) = objCacic.deCrypt(objCacic.getValueFromTags('INSTALLCACIC.EXE_HASH',strCommResponseTest,'<>'),true,true)) then
              Begin
                objCacic.setLocalFolderName(objCacic.deCrypt(objCacic.getValueFromTags('LocalFolderName'            ,strCommResponseTest,'<>')));
                objCacic.setMainProgramName(objCacic.deCrypt(objCacic.getValueFromTags('MainProgramName'            ,strCommResponseTest,'<>')));
                objCacic.setWebManagerAddress(objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'        ,strCommResponseTest,'<>')));
                objCacic.setWebServicesFolderName(objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName',strCommResponseTest,'<>')));

                staticStatus.Font.Size   := 12;
                staticStatus.Font.Style  := [fsBold];

                richProgress.Lines.Add('>> Teste de Conexão OK!');
                staticStatus.Caption    := 'Teste de Comunicação Efetuado Com Sucesso!';
                staticStatus.Font.Color := clGreen;

                frmInstallCACIC.btConfirmProcess.Enabled := false;
                frmInstallCACIC.btExit.Enabled           := false;
                installCACIC;
                frmInstallCACIC.btConfirmProcess.Enabled := true;
                frmInstallCACIC.btExit.Enabled           := true;
              End
           else
              Begin
                 ShowMessage('ATENÇÃO:' + #13#10 +
                             '-------'  + #13#10 + #13#10 +
                             'A estrutura deste instalador encontra-se diferente da estrutura disponibilizada no servidor "' + objCacic.getWebManagerAddress + '"'+ #13#10 + #13#10 + #13#10 +
                             'Parâmetro Local.: "' + objCacic.getFileHash(ParamStr(0)) + '"' + #13#10 +
                             'Parâmetro Remoto: "' + objCacic.deCrypt(objCacic.getValueFromTags('INSTALLCACIC.EXE_HASH',strCommResponseTest,'<>'),true,true) + '"' + #13#10 + #13#10 + #13#10 +
                             'Acesse ao servidor e baixe um novo executável através do link "Repositório" da página principal do Sistema CACIC.' + #13#10 + #13#10 + #13#10 +
                             'A EXECUÇÃO SERÁ FINALIZADA!' + #13#10 + #13#10 + #13#10);
                 btExitClick(nil);
              End;
          End
        else
          Begin
            richProgress.Lines.Add('>> Teste de Conexão Negativo!');
            staticStatus.Caption    := 'Insucesso no Teste de Comunicação com o Endereço Informado!';
            staticStatus.Font.Color := clRed;
            edWebManagerAddress.SetFocus;
          End;
      Except
        on E : Exception do
          Begin
            objCacic.writeExceptionLog(E.Message,E.ClassName,'Processo de instalação.');
          End;
      End;
    End
  else
    Begin
      staticStatus.Caption := 'Endereço de Acesso ao Gerente WEB Não Informado!';
      staticStatus.Font.Color := clMaroon;

      edWebManagerAddress.SetFocus;
    End;

end;

procedure TfrmInstallCACIC.btExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmInstallCACIC.FormActivate(Sender: TObject);
begin
  pnVersao.Caption := objCacic.getVersionInfo(ParamStr(0));
end;

end.
