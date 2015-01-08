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

uses
  Windows,
  SysUtils,
  Classes,
  CACIC_Library in '..\CACIC_Library.pas',
  CACIC_Comm in '..\CACIC_Comm.pas',
  CACIC_VerifyAndGetModules in '..\CACIC_VerifyAndGetModules.pas',
  CACIC_WMI in '..\CACIC_WMI.pas';

var   objCacic                                : TCACIC;
      strChkSisInfFileName,
      strFieldsAndValuesToRequest,
      strGerColsInfFileName,
      strCommResponse                         : String;

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

procedure executeChkSIS;
begin
  objCacic.writeDebugLog('executeChkSIS: getLocalFolderName => "'+objCacic.getLocalFolderName+'"');

  objCacic.writeDebugLog('executeChkSIS: Verificando existência da pasta "' + objCacic.getLocalFolderName+'"');
  // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(objCacic.getLocalFolderName) then
      begin
        objCacic.writeDebugLog('executeChkSIS: Criando diretório ' + objCacic.getLocalFolderName);
        ForceDirectories(objCacic.getLocalFolderName);
      end;

  objCacic.writeDebugLog('executeChkSIS: Verificando existência da pasta "' + objCacic.getLocalFolderName + 'Modules"');
  // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
  if not DirectoryExists(objCacic.getLocalFolderName + 'Modules') then
      begin
        objCacic.writeDebugLog('executeChkSIS: Excluindo '+ objCacic.getLocalFolderName + objCacic.getMainProgramName);
        objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + objCacic.getMainProgramName);
        objCacic.writeDebugLog('executeChkSIS: Criando diretório ' + objCacic.getLocalFolderName + 'Modules');
        ForceDirectories(objCacic.getLocalFolderName + 'Modules');
      end;

  objCacic.writeDebugLog('executeChkSIS: Verificando existência da pasta "' + objCacic.getLocalFolderName + 'Temp"');
  // Crio o SubDiretório TEMP, caso não exista
  if not DirectoryExists(objCacic.getLocalFolderName + 'Temp') then
      begin
        objCacic.writeDebugLog('executeChkSIS: Criando diretório ' + objCacic.getLocalFolderName + 'Temp');
        ForceDirectories(objCacic.getLocalFolderName + 'Temp');
      end;

  Try
     // Busco as configurações para acesso ao ambiente FTP - Updates
     strFieldsAndValuesToRequest :=                               'in_instalacao=OK,';
     strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'te_fila_ftp=1'; // Indicativo para entrada no grupo FTP

     objCacic.writeDebugLog('executeChkSIS: Efetuando chamada ao Gerente WEB com valores: "' + objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config' + '", "' + objCacic.getLocalFolderName + '" e lista interna');
		 strCommResponse := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);

     if (strCommResponse <> '0') then
      Begin
        objCacic.setBoolCipher(not objCacic.isInDebugMode);
        objCacic.setMainProgramName(      objCacic.deCrypt(objCacic.getValueFromTags('MainProgramName'                     , strCommResponse, '<>')));
        objCacic.setMainProgramHash(      objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH' , strCommResponse, '<>'),true,true));
        objCacic.setWebManagerAddress(    objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'                   , strCommResponse, '<>')));
        objCacic.setWebServicesFolderName(objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'               , strCommResponse, '<>')));
        objCacic.setLocalFolderName(      objCacic.deCrypt(objCacic.getValueFromTags('LocalFolderName'                     , strCommResponse, '<>')));

        objCacic.writeDebugLog('executeChkSIS: Resposta: ' + strCommResponse);

        objCacic.setValueToFile('Configs'   ,'NmUsuarioLoginServUpdates', objCacic.getValueFromTags('nm_usuario_login_serv_updates'      , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'NuPortaServUpdates'       , objCacic.getValueFromTags('nu_porta_serv_updates'              , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'TePathServUpdates'        , objCacic.getValueFromTags('te_path_serv_updates'               , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'TeSenhaLoginServUpdates'  , objCacic.getValueFromTags('te_senha_login_serv_updates'        , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'TeServUpdates'            , objCacic.getValueFromTags('te_serv_updates'                    , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'WebManagerAddress'        , objCacic.getValueFromTags('WebManagerAddress'                  , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'WebServicesFolderName'    , objCacic.getValueFromTags('WebServicesFolderName'              , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'apikey'                   , objCacic.getValueFromTags('apikey'                             , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','CACICSERVICE.EXE'         , objCacic.getValueFromTags('CACICSERVICE.EXE_HASH'              , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','CHKSIS.EXE'               , objCacic.getValueFromTags('CHKSIS.EXE_HASH'                    , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','GERCOLS.EXE'              , objCacic.getValueFromTags('GERCOLS.EXE_HASH'                   , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','MAPACACIC.EXE'            , objCacic.getValueFromTags('MAPACACIC.EXE_HASH'                 , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName, objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH', strCommResponse, '<>'), strChkSisInfFileName);

        // Crio/Recrio/Atualizo o arquivo de configurações do Agente Principal
        objCacic.writeDebugLog('executeChkSIS: Criando/Recriando ' + objCacic.getLocalFolderName + ChangeFileExt(LowerCase(objCacic.getMainProgramName) ,'.inf'));

        objCacic.writeDebugLog('executeChkSIS: :::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
        objCacic.writeDebugLog('executeChkSIS: Endereço no Servidor de aplicação........: ' + objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'               , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Nome de Pasta para Interface com Agentes.: ' + objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'           , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Servidor de updates......................: ' + objCacic.deCrypt(objCacic.getValueFromTags('te_serv_updates'                 , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Porta do servidor de updates.............: ' + objCacic.deCrypt(objCacic.getValueFromTags('nu_porta_serv_updates'           , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Usuário para login no servidor de updates: ' + objCacic.deCrypt(objCacic.getValueFromTags('nm_usuario_login_serv_updates'   , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Pasta no servidor de updates.............: ' + objCacic.deCrypt(objCacic.getValueFromTags('te_path_serv_updates'            , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS:  ');
        objCacic.writeDebugLog('executeChkSIS: Versões dos Agentes Principais:');
        objCacic.writeDebugLog('executeChkSIS: ------------------------------');
        objCacic.writeDebugLog('executeChkSIS: ' + objCacic.getMainProgramName+ ' - Agente Principal........: ' + objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_VER', strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: CACICservice - Serviço de Sustentação: '                    + objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_VER'              , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: GerCols - Gerente de Coletas.........: '                    + objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_VER'                   , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: ChkSis   - Verificador de Integridade: '                    + objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_VER'                    , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: ------------------------------');
        objCacic.writeDebugLog('executeChkSIS: Verificando existência do agente "' + objCacic.getLocalFolderName + LowerCase(objCacic.getMainProgramName)+'"');

        objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');

        // Auto verificação de versão
        verifyAndGetModules('chksis.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getWinDir,
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        // Verificação de versão do Agente Principal
        verifyAndGetModules(LowerCase(objCacic.getMainProgramName),
                                      objCacic.getMainProgramHash,
                                      objCacic.getLocalFolderName,
                                      objCacic.getLocalFolderName,
                                      objCacic,
                                      strChkSisInfFileName);

        // Verificação de versão do Agente Gerente de Coletas
        verifyAndGetModules('gercols.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getLocalFolderName + 'Modules',
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        // Verificação de versão do Serviço de Sustentação do Agente CACIC
        verifyAndGetModules('cacicservice.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getWinDir,
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        // Verificação de versão do Mapa Cacic
        verifyAndGetModules('mapacacic.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('MAPACACIC.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getLocalFolderName + 'Modules',
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        verifyAndGetModules('Cacic.msi',
                              '0',
                              objCacic.getLocalFolderName + 'Modules',
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);                            


        // 5 segundos para espera de possível FTP em andamento...
        Sleep(5000);
      End
      else
      begin
        strCommResponse := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/update', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);
        if (strCommResponse <> '0') then
        begin
          objCacic.writeDailyLog('executeChkSIS: Iniciando segunda tentativa de comunicação sem a obrigatoriedade do MAC');
          objCacic.setBoolCipher(not objCacic.isInDebugMode);
          objCacic.setMainProgramName(      objCacic.deCrypt(objCacic.getValueFromTags('MainProgramName'                     , strCommResponse, '<>')));
          objCacic.setMainProgramHash(      objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH' , strCommResponse, '<>'),true,true));
          objCacic.setWebManagerAddress(    objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'                   , strCommResponse, '<>')));
          objCacic.setWebServicesFolderName(objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'               , strCommResponse, '<>')));
          objCacic.setLocalFolderName(      objCacic.deCrypt(objCacic.getValueFromTags('LocalFolderName'                     , strCommResponse, '<>')));

          objCacic.writeDebugLog('executeChkSIS: Resposta: ' + strCommResponse);

          objCacic.setValueToFile('Configs'   ,'NmUsuarioLoginServUpdates', objCacic.getValueFromTags('nm_usuario_login_serv_updates'      , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'NuPortaServUpdates'       , objCacic.getValueFromTags('nu_porta_serv_updates'              , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'TePathServUpdates'        , objCacic.getValueFromTags('te_path_serv_updates'               , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'TeSenhaLoginServUpdates'  , objCacic.getValueFromTags('te_senha_login_serv_updates'        , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'TeServUpdates'            , objCacic.getValueFromTags('te_serv_updates'                    , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'WebManagerAddress'        , objCacic.getValueFromTags('WebManagerAddress'                  , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'WebServicesFolderName'    , objCacic.getValueFromTags('WebServicesFolderName'              , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'apikey'                   , objCacic.getValueFromTags('apikey'                             , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','CACICSERVICE.EXE'         , objCacic.getValueFromTags('CACICSERVICE.EXE_HASH'              , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','CHKSIS.EXE'               , objCacic.getValueFromTags('CHKSIS.EXE_HASH'                    , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','GERCOLS.EXE'              , objCacic.getValueFromTags('GERCOLS.EXE_HASH'                   , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','MAPACACIC.EXE'            , objCacic.getValueFromTags('MAPACACIC.EXE_HASH'                 , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName, objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH', strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');

          // Auto verificação de versão
          verifyAndGetModules('chksis.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getWinDir,
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // Verificação de versão do Agente Principal
          verifyAndGetModules(LowerCase(objCacic.getMainProgramName),
                                        objCacic.getMainProgramHash,
                                        objCacic.getLocalFolderName,
                                        objCacic.getLocalFolderName,
                                        objCacic,
                                        strChkSisInfFileName);

          // Verificação de versão do Agente Gerente de Coletas
          verifyAndGetModules('gercols.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getLocalFolderName + 'Modules',
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // Verificação de versão do Serviço de Sustentação do Agente CACIC
          verifyAndGetModules('cacicservice.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getWinDir,
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // Verificação de versão do Mapa Cacic
          verifyAndGetModules('mapacacic.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('MAPACACIC.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getLocalFolderName + 'Modules',
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          verifyAndGetModules('Cacic.msi',
                              '0',
                              objCacic.getLocalFolderName,
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // 5 segundos para espera de possível FTP em andamento...
          Sleep(5000);
        end;
      end;
           
  Except
    on E : Exception do
      Begin
        objCacic.writeExceptionLog(E.Message,E.ClassName,'Falha no contato com ' + objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config');
        objCacic.writeDebugLog('executeChkSIS: Falha no contato com ' + objCacic.getWebManagerAddress  + objCacic.getWebServicesFolderName + 'get/config');
      End;
  End;

  //inicia instalação do cacic se existir.
  if FileExists(objCacic.getLocalFolderName + 'Cacic.msi') and objCacic.getValueFromFile('Configs', 'apikey', strChkSisInfFileName) <> '' then
  begin
//  msiexec /i Cacic.msi /quiet /qn /norestart HOST=teste.cacic.cc USER=cacic PASS=cacic123
      objCacic.createOneProcess('msiexec /i ' + objCacic.getLocalFolderName + 'Cacic.msi' +
                                  ' /quiet /qn /norestart HOST=' + objCacic.getWebManagerAddress +
                                  ' USER=cacic' +
                                  ' PASS=' + objCacic.getValueFromFile('Configs', 'apikey', strChkSisInfFileName),
                                false);
  end;

  objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');
  // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
  if Not FileExists(objCacic.getLocalFolderName + 'aguarde_CACIC.txt') then
    Begin
      if (objCacic.GetValueFromFile('Configs','NuExecApos', ChangeFileExt(objCacic.getMainProgramName,'.inf')) = '') then // Verifico se é uma primeira execução depois da instalação
        strChkSisInfFileName := ''
      else
        strChkSisInfFileName := ' /execute';

      objCacic.writeDebugLog('executeChkSIS: Executando '+objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /WebManagerAddress=' + objCacic.getWebManagerAddress + ' /WebServicesFolderName=' + objCacic.getWebServicesFolderName + strChkSisInfFileName);
      objCacic.createOneProcess(objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /WebManagerAddress=' + objCacic.getWebManagerAddress + ' /WebServicesFolderName=' + objCacic.getWebServicesFolderName + strChkSisInfFileName, false)
    End;
end;

const APP_NAME = 'chksis.exe';

begin
   objCacic              := TCACIC.Create();
   objCacic.setBoolCipher(true);
   strChkSisInfFileName  := objCacic.getWinDir + 'chksis.inf';
   if( not objCacic.isAppRunning(PChar(APP_NAME) ) ) then
      Begin
       if (not objCacic.isAppRunning(PChar('installcacic'))) then
          Begin
            if(FileExists(strChkSisInfFileName)) and
              (objCacic.getValueFromFile('Configs','WebManagerAddress',strChkSisInfFileName) <> '') then
              Begin
                objCacic.setWebManagerAddress(objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName));
                objCacic.setWebServicesFolderName(objCacic.GetValueFromFile('Configs','WebServicesFolderName', strChkSisInfFileName));
                objCacic.setLocalFolderName(objCacic.GetValueFromFile('Configs','LocalFolderName', strChkSisInfFileName));
                objCacic.writeDebugLog('chkSIS: Verificando chamada');

                strGerColsInfFileName := objCacic.getLocalFolderName + 'gercols.inf';
                executeChkSIS;
              End
           else
              objCacic.writeDebugLog('chkSIS: Problema - Execução paralela ou inexistência de configurações! É necessária a execução do InstallCACIC!');
          End
       else
          objCacic.writeDebugLog('chkSIS: Oops! Encontrei Execução de InstallCACIC!');
      End
   else
      objCacic.writeDebugLog('chkSIS: Oops! Execução paralela!');
   objCacic.Free();
   Halt(0);
end.

