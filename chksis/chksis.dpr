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
  forms,
  SysUtils,
  Classes,
  IdHTTP,
  IdFTP,
  idFTPCommon,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  Winsock,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_strCommResponse         : String;

var
  v_intAux                  : integer;

var
  g_oCacic : TCACIC;

// Função para fixar o HomeDrive como letra para a pasta do CACIC
function TrataCacicDir(strCacicDir : String) : String;
var tstrCacicDir1,
    tstrCacicDir2 : TStrings;
    intAuxTCD : integer;
Begin
  Result := strCacicDir;
  // Crio um array separado por ":" (Para o caso de ter sido informada a letra da unidade)
  tstrCacicDir1 := TStrings.Create;
  tstrCacicDir1 := g_oCacic.explode(strCacicDir,':');

  if (tstrCacicDir1.Count > 1) then
    Begin
      tstrCacicDir2 := TStrings.Create;
      // Ignoro a letra informada...
      // Certifico-me de que as barras são invertidas... (erros acontecem)
      // Crio um array quebrado por "\"
      Result := StringReplace(tstrCacicDir1[1],'/','\',[rfReplaceAll]);
      tstrCacicDir2 := g_oCacic.explode(Result,'\');

      // Inicializo retorno com a unidade raiz do Sistema Operacional
      // Concateno ao retorno as partes que formarão o caminho completo do CACIC
      Result := g_oCacic.getHomeDrive;
      for intAuxTCD := 0 to (tstrCacicDir2.Count-1) do
        if (tstrCacicDir2[intAuxTCD] <> '') then
            Result := Result + tstrCacicDir2[intAuxTCD] + '\';
      tstrCacicDir2.Free;
    End
  else
    Result := g_oCacic.getHomeDrive + strCacicDir + '\';

  tstrCacicDir1.Free;

  Result := StringReplace(Result,'\\','\',[rfReplaceAll]);
End;

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
    msg_error : string;
begin
  g_oCacic.writeDebugLog('FTP => p_Host       : "'+p_Host+'"');
  g_oCacic.writeDebugLog('FTP => p_Port       : "'+p_Port+'"');
  g_oCacic.writeDebugLog('FTP => p_Username   : "'+p_Username+'"');
  g_oCacic.writeDebugLog('FTP => p_Password   : "'+p_Password+'"');
  g_oCacic.writeDebugLog('FTP => p_PathServer : "'+p_PathServer+'"');
  g_oCacic.writeDebugLog('FTP => p_File       : "'+p_File+'"');
  g_oCacic.writeDebugLog('FTP => p_Dest       : "'+p_Dest+'"');
  
  msg_error := '';
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
      msg_error := 'Falha ao tentar conexão com o servidor FTP: "' + p_Host + '"';
      IdFTP.Connect(true);
      msg_error := 'Falha ao tentar mudar diretório no servidor FTP: "' + p_PathServer + '"';
      IdFTP.ChangeDir(p_PathServer);
      Try
        g_oCacic.writeDebugLog('Size de "'+p_File+'" Antes do FTP => '+IntToSTR(IdFTP.Size(p_File)));
        msg_error := 'Falha ao tentar obter arquivo no servidor FTP: "' + p_File + '" para "'+p_Dest + '\' + p_File+'"';
        IdFTP.Get(p_File, p_Dest + '\' + p_File, True);
        g_oCacic.writeDebugLog('Size de "'+p_Dest + '\' + p_File +'" Após o FTP   => '+Get_File_Size(p_Dest + '\' + p_File,true));
      Finally
        g_oCacic.writeDebugLog('Size de "'+p_Dest + '\' + p_File +'" Após o FTP em Finally   => '+Get_File_Size(p_Dest + '\' + p_File,true));
        idFTP.Disconnect;
        result := true;
      End;
    Except
        g_oCacic.writeDailyLog(msg_error);
        result := false;
    end;
    idFTP.Free;
  Except
    result := false;
  End;
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

function verifyAndGet(p_strModuleName,
                      p_strFileHash,
                      p_strDestinationFolderName,
                      p_strTempDestinationFolderName : String) : boolean;
var v_strFileHash,
    v_strDestinationFolderName,
    v_strTempDestinationFolderName : String;
Begin
  Result := false;
  g_oCacic.writeDebugLog('VerifyAndGet => p_strModuleName                : "'+p_strModuleName+'"');
  g_oCacic.writeDebugLog('VerifyAndGet => p_strFileHash                  : "'+p_strFileHash+'"');
  g_oCacic.writeDebugLog('VerifyAndGet => p_strDestinationFolderName     : "'+p_strDestinationFolderName+'"');
  g_oCacic.writeDebugLog('VerifyAndGet => p_strTempDestinationFolderName : "'+p_strTempDestinationFolderName+'"');

  v_strDestinationFolderName     := p_strDestinationFolderName + '\';
  v_strDestinationFolderName     := StringReplace(v_strDestinationFolderName,'\\','\',[rfReplaceAll]);

  v_strTempDestinationFolderName := '';
  if (trim(p_strTempDestinationFolderName) <> '') then
    Begin
      v_strTempDestinationFolderName := p_strTempDestinationFolderName + '\';
      v_strTempDestinationFolderName := StringReplace(v_strTempDestinationFolderName,'\\','\',[rfReplaceAll]);
    End;

  g_oCacic.writeDebugLog('VerifyAndGet => v_strDestinationFolderName     : "'+v_strDestinationFolderName+'"');
  g_oCacic.writeDebugLog('VerifyAndGet => v_strTempDestinationFolderName : "'+v_strTempDestinationFolderName+'"');

  g_oCacic.writeDebugLog('Verificando módulo: ' + v_strDestinationFolderName + p_strModuleName);
  // Verifico validade do Módulo e mato-o em caso negativo.
  v_strFileHash := g_oCacic.GetFileHash(v_strDestinationFolderName + p_strModuleName);

  g_oCacic.writeDebugLog('verifyAndGet - HashCode Remot de "'+p_strModuleName+'": "'+p_strFileHash+'"');
  g_oCacic.writeDebugLog('verifyAndGet - HashCode Local de "'+v_strDestinationFolderName + p_strModuleName+'": "'+v_strFileHash+'"');

  If (v_strFileHash <> p_strFileHash) then
    g_oCacic.killFiles(v_strDestinationFolderName, p_strModuleName);


  If not FileExists(v_strDestinationFolderName + p_strModuleName) or
     (v_strFileHash <> p_strFileHash) Then
    Begin
      if (trim(v_strTempDestinationFolderName) <> '') then
        v_strDestinationFolderName := v_strTempDestinationFolderName;

      if (FileExists(ExtractFilePath(Application.Exename) + '\modulos\'+p_strModuleName)) then
        Begin
          g_oCacic.writeDebugLog('Copiando '+p_strModuleName+' de '+ExtractFilePath(Application.Exename)+'modulos\');

          CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\'+p_strModuleName), PChar(v_strDestinationFolderName + p_strModuleName),false);
          FileSetAttr (PChar(v_strDestinationFolderName + p_strModuleName),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED
          Result := true;
        End
      else
        begin

          Try
            if FTP(g_oCacic.xmlGetValue('te_serv_updates'              , v_strCommResponse),
                   g_oCacic.xmlGetValue('nu_porta_serv_updates'        , v_strCommResponse),
                   g_oCacic.xmlGetValue('nm_usuario_login_serv_updates', v_strCommResponse),
                   g_oCacic.xmlGetValue('te_senha_login_serv_updates'  , v_strCommResponse),
                   g_oCacic.xmlGetValue('te_path_serv_updates'         , v_strCommResponse),
                   p_strModuleName,
                   v_strDestinationFolderName) then
                   Result := true;
          Except
            g_oCacic.writeDebugLog('FTP de "'+ v_strDestinationFolderName + p_strModuleName+'" Interrompido.');
          End;

          if not FileExists(v_strDestinationFolderName + p_strModuleName) Then
            Begin
              g_oCacic.writeDebugLog('Problemas Efetuando Download de '+ v_strDestinationFolderName + p_strModuleName+' (FTP)');
              g_oCacic.writeDebugLog('Conexão:');
              g_oCacic.writeDebugLog(g_oCacic.xmlGetValue('te_serv_updates'              , v_strCommResponse)+', '+
                       g_oCacic.xmlGetValue('nu_porta_serv_updates'        , v_strCommResponse)+', '+
                       g_oCacic.xmlGetValue('nm_usuario_login_serv_updates', v_strCommResponse)+', '+
                       g_oCacic.xmlGetValue('te_senha_login_serv_updates'  , v_strCommResponse)+', '+
                       g_oCacic.xmlGetValue('te_path_serv_updates'         , v_strCommResponse));
            End
          else
              g_oCacic.writeDebugLog('Download Concluído de "'+p_strModuleName+'" (FTP)');
        end;
    End;
End;

procedure executa_chksis;
var
  v_te_serv_updates,
  v_nu_porta_serv_updates,
  v_nm_usuario_login_serv_updates,
  v_te_senha_login_serv_updates,
  v_te_path_serv_updates,
  strAuxLocalTempFolder : String;
  Request_Config : TStringList;
  Response_Config : TStringStream;
  IdHTTP1: TIdHTTP;
begin

  g_oCacic.writeDebugLog('getLocalFolder => "'+g_oCacic.getLocalFolder+'"');

  g_oCacic.writeDebugLog('Verificando existência da pasta "'+g_oCacic.getWinDir+'Temp"');
  // Verifico a existência do diretório temporário para operações de download do CACICservice
  if not DirectoryExists(g_oCacic.getWinDir + 'Temp') then
      begin
        g_oCacic.writeDebugLog('Criando diretório ' + g_oCacic.getWinDir + 'Temp');
        ForceDirectories(g_oCacic.getWinDir + 'Temp');
      end;

  g_oCacic.writeDebugLog('Verificando existência da pasta "'+g_oCacic.getLocalFolder+'"');
  // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(g_oCacic.getLocalFolder) then
      begin
        g_oCacic.writeDebugLog('Criando diretório ' + g_oCacic.getLocalFolder);
        ForceDirectories(g_oCacic.getLocalFolder);
      end;

  g_oCacic.writeDebugLog('Verificando existência da pasta "'+g_oCacic.getLocalFolder+'modulos"');
  // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
  if not DirectoryExists(g_oCacic.getLocalFolder+'Modulos') then
      begin
        g_oCacic.writeDebugLog('Excluindo '+ g_oCacic.getLocalFolder + g_oCacic.getMainProgramName);
        g_oCacic.killFiles(g_oCacic.getLocalFolder,g_oCacic.getMainProgramName);
        g_oCacic.writeDebugLog('Criando diretório ' + g_oCacic.getLocalFolder + 'Modulos');
        ForceDirectories(g_oCacic.getLocalFolder + 'Modulos');
      end;

  g_oCacic.writeDebugLog('Verificando existência da pasta "'+g_oCacic.getLocalFolder+'Temp"');
  // Crio o SubDiretório TEMP, caso não exista
  if not DirectoryExists(g_oCacic.getLocalFolder+'Temp') then
      begin
        g_oCacic.writeDebugLog('Criando diretório ' + g_oCacic.getLocalFolder + 'Temp');
        ForceDirectories(g_oCacic.getLocalFolder + 'Temp');
      end;

  // Busco as configurações para acesso ao ambiente FTP - Updates
  Request_Config                        := TStringList.Create;
  Request_Config.Values['in_chkcacic']  := 'chkcacic';
  Request_Config.Values['te_fila_ftp']  := '1'; // Indicativo para entrada no grupo FTP
  Request_Config.Values['id_ip_estacao']:= GetIP; // Informará o IP para registro na tabela redes_grupos_FTP
  Response_Config                       := TStringStream.Create('');

  Try
    g_oCacic.writeDebugLog('Tentando contato com ' + 'http://' + g_oCacic.getWebManagerAddress + '/ws/get_config.php');
    IdHTTP1 := TIdHTTP.Create(nil);
    IdHTTP1.Post('http://' + g_oCacic.getWebManagerAddress + '/ws/get_config.php', Request_Config, Response_Config);
    IdHTTP1.Disconnect;
    IdHTTP1.Free;
    v_strCommResponse := Response_Config.DataString;

    g_oCacic.writeDebugLog('Resposta: ' + v_strCommResponse);

    v_te_serv_updates               := g_oCacic.xmlGetValue('te_serv_updates'              , v_strCommResponse);
    v_nu_porta_serv_updates         := g_oCacic.xmlGetValue('nu_porta_serv_updates'        , v_strCommResponse);
    v_nm_usuario_login_serv_updates := g_oCacic.xmlGetValue('nm_usuario_login_serv_updates', v_strCommResponse);
    v_te_senha_login_serv_updates   := g_oCacic.xmlGetValue('te_senha_login_serv_updates'  , v_strCommResponse);
    v_te_path_serv_updates          := g_oCacic.xmlGetValue('te_path_serv_updates'         , v_strCommResponse);

    g_oCacic.setMainProgramName(g_oCacic.xmlGetValue('te_MainProgramName', v_strCommResponse));
    g_oCacic.setMainProgramHash(g_oCacic.xmlGetValue('te_MainProgramHash', v_strCommResponse));

    g_oCacic.SetValueToFile('Configs','TeMainProgramHash'    ,g_oCacic.enCrypt( g_oCacic.getMainProgramHash),g_oCacic.getWinDir + 'chksis.ini');
    g_oCacic.SetValueToFile('Configs','TeServiceProgramHash' ,g_oCacic.enCrypt( g_oCacic.xmlGetValue('TE_HASH_CACICSERVICE', v_strCommResponse)),g_oCacic.getWinDir + 'chksis.ini');

    g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
    g_oCacic.writeDebugLog(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
    g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
    g_oCacic.writeDebugLog('Servidor de updates......................: '+v_te_serv_updates);
    g_oCacic.writeDebugLog('Porta do servidor de updates.............: '+v_nu_porta_serv_updates);
    g_oCacic.writeDebugLog('Usuário para login no servidor de updates: '+v_nm_usuario_login_serv_updates);
    g_oCacic.writeDebugLog('Pasta no servidor de updates.............: '+v_te_path_serv_updates);
    g_oCacic.writeDebugLog(' ');
    g_oCacic.writeDebugLog('Versões dos Agentes Principais:');
    g_oCacic.writeDebugLog('------------------------------');
    g_oCacic.writeDebugLog(g_oCacic.getMainProgramName+ ' - Agente Principal........: '+g_oCacic.xmlGetValue(StringReplace(UpperCase( g_oCacic.xmlGetValue('te_MainProgramName', v_strCommResponse)),'.EXE','',[rfReplaceAll]), v_strCommResponse));
    g_oCacic.writeDebugLog('CACICservice - Serviço de Sustentação....: '+g_oCacic.xmlGetValue('CACICSERVICE', v_strCommResponse));
    g_oCacic.writeDebugLog('Ger_Cols - Gerente de Coletas........: '+g_oCacic.xmlGetValue('GER_COLS', v_strCommResponse));
    g_oCacic.writeDebugLog('ChkSis   - Verificador de Integridade: '+g_oCacic.xmlGetValue('CHKSIS', v_strCommResponse));
    g_oCacic.writeDebugLog(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
    g_oCacic.writeDebugLog('Verificando existência do agente "'+g_oCacic.getLocalFolder+ LowerCase( g_oCacic.getMainProgramName )+'"');

    g_oCacic.killFiles(g_oCacic.getLocalFolder,'aguarde_CACIC.txt');

    strAuxLocalTempFolder := '';

    if FileExists(g_oCacic.getLocalFolder + 'aguarde_CACIC.txt') then
      strAuxLocalTempFolder := g_oCacic.getLocalFolder + 'Temp\';

    // Verificação de versão do Agente Principal e download de nova versão se necessário
    if (verifyAndGet(LowerCase(g_oCacic.getMainProgramName),
                 g_oCacic.getMainProgramHash,
                 g_oCacic.getLocalFolder,
                 strAuxLocalTempFolder)) then
      Begin
        if (strAuxLocalTempFolder <> '') then
          g_oCacic.setMainProgramHash(g_oCacic.getFileHash(strAuxLocalTempFolder + LowerCase( g_oCacic.getMainProgramName )))
        else
          g_oCacic.setMainProgramHash(g_oCacic.getFileHash(g_oCacic.getLocalFolder + LowerCase( g_oCacic.getMainProgramName )));

        g_oCacic.SetValueToFile('Configs','TeMainProgramHash',g_oCacic.enCrypt( g_oCacic.getMainProgramHash),g_oCacic.getWinDir + 'chksis.ini');
      End;

    // Verificação de versão do Agente Gerente de Coletas e download de nova versão se necessário
    verifyAndGet('ger_cols.exe',
                 g_oCacic.xmlGetValue('TE_HASH_GER_COLS', v_strCommResponse),
                 g_oCacic.getLocalFolder + 'Modulos',
                 '');

    // Verificação de versão do Serviço de Sustentação do Agente CACIC e download de nova versão se necessário
    verifyAndGet('cacicservice.exe',
                  g_oCacic.xmlGetValue('TE_HASH_CACICSERVICE', v_strCommResponse),
                  g_oCacic.getWinDir,
                  g_oCacic.getWinDir+'Temp');

    // 5 segundos para espera de possível FTP em andamento...
    Sleep(5000);

  Except
    g_oCacic.writeDebugLog('Falha no contato com ' + 'http://' + g_oCacic.getWebManagerAddress + '/ws/get_config.php');
  End;

  Request_Config.Free;
  Response_Config.Free;

  g_oCacic.killFiles(g_oCacic.getLocalFolder,'aguarde_CACIC.txt');
  // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
  if Not FileExists(g_oCacic.getLocalFolder + 'aguarde_CACIC.txt') then
    Begin
      g_oCacic.writeDebugLog('Executando '+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /TeWebManagerAddress=' + g_oCacic.getWebManagerAddress+' /execute');
      g_oCacic.createOneProcess(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /TeWebManagerAddress=' + g_oCacic.getWebManagerAddress + ' /execute', false)
    End;
end;

const
  CACIC_APP_NAME = 'chksis';


begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
      Begin
       if (FindWindowByTitle('chkcacic') = 0) then
           if (FileExists(ExtractFilePath(ParamStr(0)) + 'chksis.ini')) and
              (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',ExtractFilePath(ParamStr(0)) + 'chksis.ini')) <> '') then
              Begin
                g_oCacic.setWebManagerAddress(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',ExtractFilePath(ParamStr(0)) + 'chksis.ini')));
                g_oCacic.setLocalFolder(g_oCacic.deCrypt(g_oCacic.GetValueFromFile('Configs','TeLocalFolder',ExtractFilePath(ParamStr(0)) + 'chksis.ini')));
                g_oCacic.setMainProgramName(g_oCacic.deCrypt(g_oCacic.GetValueFromFile('Configs','TeMainProgramName',ExtractFilePath(ParamStr(0)) + 'chksis.ini')));
                g_oCacic.setMainProgramHash(g_oCacic.deCrypt(g_oCacic.GetValueFromFile('Configs','TeMainProgramHash',ExtractFilePath(ParamStr(0)) + 'chksis.ini')));

                g_oCacic.checkDebugMode;
                g_oCacic.writeDebugLog('ChkSIS : Verificando chamada');

                v_intAux := 0;

                executa_chksis;
              End
           else
              Begin
                g_oCacic.killFiles(ExtractFilePath(ParamStr(0)),'chksis.ini');
                g_oCacic.writeDebugLog('Problema - Execução paralela ou inexistência de configurações!');
              End;
      End;

   g_oCacic.Free();

end.

