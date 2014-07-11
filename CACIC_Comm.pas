unit CACIC_Comm;
interface

uses  IdTCPConnection,
      IdTCPClient,
      IdHTTP,
      IdFTP,
      IdFTPCommon,
      IdBaseComponent,
      IdComponent,
      Classes,
      StrUtils,
      WinSock,
      SysUtils,
      CACIC_Library,
      CACIC_WMI;

function Comm(pStrFullURL, pStrFieldsAndValuesToRequest, pStrLocalFolderName : String; pStrActionMessage : String = '') : String;
function FTPdown(pStrHost, pStrUser, pStrPass, pStrSourcePath, pStrFileNameAtSource, pStrTargetPath, pStrFileNameAtTarget, pStrTransferType, pStrLocalFolderName : String; pIntPort : integer) : String;

var   objCacicCOMM          : TCACIC;
      strGerColsInfFileName,
      strChkSisInfFileName  : String;

implementation

uses DateUtils;

function Comm(pStrFullURL, pStrFieldsAndValuesToRequest, pStrLocalFolderName : String; pStrActionMessage : String = '') : String;
var tStringStrResponseCS                 : TStringStream;
    tstrRequest                          : TStrings;
    idHTTP1                              : TIdHTTP;
    intLoopComm                          : integer;
    strWin32_ComputerSystem,
    strWin32_NetworkAdapterConfiguration,
    strWin32_OperatingSystem,
    strWin32_SoftwareFeature,
    strTeDebugging                       : String;
Begin
    Try
      tStringStrResponseCS                     := TStringStream.Create('');
      idHTTP1                                  := TIdHTTP.Create(nil);

      objCacicCOMM := TCACIC.Create;
      objCacicCOMM.setBoolCipher(not objCacicCOMM.isInDebugMode);
      objCacicCOMM.setLocalFolderName(pStrLocalFolderName);
      strGerColsInfFileName := objCacicCOMM.getLocalFolderName + 'GerCols.inf';
      strChkSisInfFileName  := objCacicCOMM.getWinDir          + 'chksis.inf';
      objCacicCOMM.setMainProgramName(objCacicCOMM.getValueFromFile('Configs','MainProgramName', strChkSisInfFileName));

      tstrRequest :=  objCacicCOMM.explode(pStrFieldsAndValuesToRequest,',');

      strWin32_OperatingSystem             := fetchWmiValues('Win32_OperatingSystem'            ,objCacicCOMM.getLocalFolderName);
      strWin32_ComputerSystem              := fetchWmiValues('Win32_ComputerSystem'             ,objCacicCOMM.getLocalFolderName);
      strWin32_NetworkAdapterConfiguration := fetchWmiValues('Win32_NetworkAdapterConfiguration',objCacicCOMM.getLocalFolderName);

//      if (not (pos('get/test', pStrFullURL) > 0)) and (not (pos('get/config', pStrFullURL) > 0)) then
//      begin
//        strWin32_SoftwareFeature             := fetchWmiValues('Win32_SoftwareFeature'            ,objCacicCOMM.getLocalFolderName);
//        tstrRequest.Values['SoftwareFeature']:= objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt(strWin32_SoftwareFeature));
//      end;

      objCacicCOMM.writeDebugLog('Comm: Povoando lista com valores padrão para cabeçalho de comunicação');
      objCacicCOMM.writeDebugLog('Comm: pStrActionMessage: "' + pStrActionMessage + '"');

      With tstrRequest do
      Begin
        Values['OperatingSystem'            ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt(strWin32_OperatingSystem                                                ));
        Values['ComputerSystem'             ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt(strWin32_ComputerSystem                                                 ));
        Values['cs_cipher'                  ] := '1';
        Values['cs_debug'                   ] := '0';
        Values['cs_compress'                ] := '0';
        Values['HTTP_USER_AGENT'            ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt('AGENTE_CACIC',true,true                                                ));
        Values['ModuleFolderName'           ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt(ExtractFilePath(ParamStr(0))                                            ));
        Values['ModuleProgramName'          ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt(ExtractFileName(ParamStr(0))                                            ));
        Values['NetworkAdapterConfiguration'] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt(strWin32_NetworkAdapterConfiguration                                    ));
        Values['PHP_AUTH_PW'                ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt('PW_CACIC',true,true                                                    ));
        Values['PHP_AUTH_USER'              ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.enCrypt('USER_CACIC',true,true                                                  ));
        Values['te_so'                      ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.getWindowsStrId()                                                                );
        Values['te_versao_cacic'            ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.getVersionInfo(objCacicCOMM.getLocalFolderName + objCacicCOMM.getMainProgramName));
        Values['te_versao_gercols'          ] := objCacicCOMM.replaceInvalidHTTPChars(objCacicCOMM.getVersionInfo(objCacicCOMM.getLocalFolderName + 'Modules\gercols.exe'          ));
      End;

      if objCacicCOMM.isInDebugMode then
        Begin
          tstrRequest.Values['ComputerSystem'             ] := objCacicCOMM.replaceInvalidHTTPChars(strWin32_ComputerSystem);
          tstrRequest.Values['cs_cipher'                  ] := '0';
          tstrRequest.Values['cs_debug'                   ] := '1';
          tstrRequest.Values['NetworkAdapterConfiguration'] := objCacicCOMM.replaceInvalidHTTPChars(strWin32_NetworkAdapterConfiguration);
          tstrRequest.Values['OperatingSystem'            ] := objCacicCOMM.replaceInvalidHTTPChars(strWin32_OperatingSystem);


          objCacicCOMM.writeDebugLog('Comm: ' + DupeString('*',100));
          objCacicCOMM.writeDebugLog('Comm: Valores POST para contato com "' + pStrFullURL + '":');

          for intLoopComm := 0 to tstrRequest.Count -1 do
            objCacicCOMM.writeDebugLog('Comm: tstrRequest[' + intToStr(intLoopComm) + '] = "' + tstrRequest[intLoopComm] + '"');

          objCacicCOMM.writeDebugLog('Comm: ' + DupeString('*',100));
        End;


      objCacicCOMM.writeDebugLog('Comm: ***** Iniciando Comunicação *****');
      objCacicCOMM.writeDebugLog('Comm: Requisitando Endereço: ' + pStrFullURL);
      Try
         idHTTP1.AllowCookies                     := true;
         idHTTP1.AuthRetries                      := 1;
         idHTTP1.HandleRedirects                  := false;
         idHTTP1.ProxyParams.BasicAuthentication  := false;
         idHTTP1.ProxyParams.ProxyPort            := 0;
         idHTTP1.ReadTimeout                      := 0;
         idHTTP1.RedirectMaximum                  := 15;
         idHTTP1.Request.Accept                   := 'text/html, */*';
         idHTTP1.Request.BasicAuthentication      := true;
         idHTTP1.Request.ContentLength            := -1;
         idHTTP1.Request.ContentRangeStart        := 0;
         idHTTP1.Request.ContentRangeEnd          := 0;
         idHTTP1.Request.ContentType              := 'text/html';
         idHTTP1.Tag                              := 0;

         // ATENÇÃO: Substituo os sinais de "+" acima por [[MAIS]] devido a problemas encontrados no envio POST (vide HTMLentities)
         Result := '0';
         Try
           IdHTTP1.Post(pStrFullURL, tstrRequest, tStringStrResponseCS);
         Except
          on E : Exception do
                Begin
                 objCacicCOMM.writeExceptionLog(E.Message,E.ClassName,'ERRO! Comunicação impossível com o endereço ' + pStrFullURL);
                End;
         End;
         objCacicCOMM.writeDebugLog('Comm: Retorno -> ' + tStringStrResponseCS.DataString);
         idHTTP1.Disconnect;
      Except
        on E : Exception do
          Begin
             objCacicCOMM.writeExceptionLog(E.Message,E.ClassName,'ERRO! Comunicação impossível com o endereço ' + pStrFullURL);
             objCacicCOMM.writeDailyLog('Comm: ERRO! Comunicação impossível com o endereço ' + pStrFullURL);
          End;
      end;
          objCacicCOMM.writeDebugLog(tStringStrResponseCS.DataString);  //Adicionada 10/07
      Try
        if (objCacicCOMM.getValueFromTags('Comm_Status', tStringStrResponseCS.DataString, '<>') <> 'OK') Then
          Begin
             objCacicCOMM.writeDailyLog('Comm: PROBLEMAS DURANTE A COMUNICAÇÃO:');
             objCacicCOMM.writeDailyLog('Comm: Endereço: ' + pStrFullURL);
             objCacicCOMM.writeDailyLog('Comm: Mensagem: ' + tStringStrResponseCS.DataString);
          end
        Else
          Begin
            Result         := objCacicCOMM.replacePseudoTagsWithCorrectChars(tStringStrResponseCS.DataString);
            strTeDebugging := objCacicCOMM.getValueFromTags('TeDebugging', Result, '<>');
            objCacicCOMM.deleteFileOrFolder(objCacicCOMM.getLocalFolderName + 'Temp\Debugging');
            if (strTeDebugging <> '') then
               Begin
                 ForceDirectories(objCacicCOMM.getLocalFolderName + 'Temp\Debugging');
                 objCacicCOMM.setValueToFile('Configs','TeDebugging', strTeDebugging, objCacicCOMM.getLocalFolderName + 'Temp\Debugging\Debugging.conf');
                 objCacicCOMM.writeDebugLog('Comm: ' + DupeString('*',100));
                 objCacicCOMM.writeDebugLog('Comm: Pasta "' + objCacicCOMM.getLocalFolderName + 'Temp\Debugging' + '" Criada!!!');
                 objCacicCOMM.writeDebugLog('Comm: TeDebugging => "' + strTeDebugging + '"');
                 objCacicCOMM.writeDebugLog('Comm: ' + DupeString('*',100));
               End;
          End;
      Except
        on E : Exception do
          Begin
             objCacicCOMM.writeExceptionLog(E.Message,E.ClassName,'Comm: PROBLEMAS DURANTE A COMUNICAÇÃO');
             objCacicCOMM.writeDailyLog('Comm: PROBLEMAS DURANTE A COMUNICAÇÃO:');
             objCacicCOMM.writeDailyLog('Comm: Endereço: ' + pStrFullURL);
             objCacicCOMM.writeDailyLog('Comm: Mensagem: ' + tStringStrResponseCS.DataString);
          End;
      End;
  Finally
    idHTTP1.Free;
    tstrRequest.Free;
    tStringStrResponseCS.Free;
    objCacicCOMM.Free;
  End;
end;

function FTPdown(pStrHost, pStrUser, pStrPass, pStrSourcePath, pStrFileNameAtSource, pStrTargetPath, pStrFileNameAtTarget, pStrTransferType, pStrLocalFolderName : String; pIntPort : integer) : String;
var IdFTP1      : TIdFTP;
begin
  Try
    IdFTP1                := TIdFTP.Create(IdFTP1);
    objCacicCOMM          := TCACIC.Create;
    objCacicCOMM.setLocalFolderName(pStrLocalFolderName);
    strGerColsInfFileName := objCacicCOMM.getLocalFolderName + 'gercols.inf';

    objCacicCOMM.writeDebugLog('FTPdown: Objeto FTP instanciado!');
    IdFTP1.Host           := pStrHost;
    IdFTP1.Username       := pStrUser;
    IdFTP1.Password       := pStrPass;
    IdFTP1.Port           := pIntPort;
    IdFTP1.Passive        := true;
    if (pStrTransferType = 'ASC') then
      IdFTP1.TransferType := ftASCII
    else
      IdFTP1.TransferType := ftBinary;

    objCacicCOMM.writeDebugLog('FTPdown: Iniciando FTP de ' + pStrSourcePath + '/' + pStrFileNameAtSource + ' para '+StringReplace(pStrTargetPath + '\' + pStrFileNameAtTarget,'\\','\',[rfReplaceAll]));
    objCacicCOMM.writeDebugLog('FTPdown: Host........ ='    + IdFTP1.Host);
    objCacicCOMM.writeDebugLog('FTPdown: UserName.... ='    + IdFTP1.Username);
    objCacicCOMM.writeDebugLog('FTPdown: Port........ ='    + inttostr(IdFTP1.Port));
    objCacicCOMM.writeDebugLog('FTPdown: Transfer Type='    + pStrTransferType);
    objCacicCOMM.writeDebugLog('FTPdown: Pasta Origem ='    + pStrSourcePath);

    Try
      if IdFTP1.Connected = true then
        begin
          objCacicCOMM.writeDebugLog('FTPdown: Objeto FTP já conectado!!! DESCONECTANDO!');
          IdFTP1.Disconnect;
        end;

      objCacicCOMM.writeDebugLog('FTPdown: Conectando objeto FTP.');
      IdFTP1.Connect;

      objCacicCOMM.writeDebugLog('FTPdown: Fazendo ChangeDir para "' + pStrSourcePath + '"');
      IdFTP1.ChangeDir(pStrSourcePath);

      objCacicCOMM.writeDebugLog('FTPdown: ChangeDir OK!');
      Try
        objCacicCOMM.writeDebugLog('FTPdown: Baixando "' + pStrSourcePath + '/' + pStrFileNameAtSource+'"');
        IdFTP1.Get(pStrFileNameAtSource, StringReplace(pStrTargetPath + '\' + pStrFileNameAtTarget,'\\','\',[rfReplaceAll]), True);
        objCacicCOMM.writeDebugLog('FTPdown: Download normal!');
      Finally
        result := 'Download de "' + pStrFileNameAtSource + '" Efetuado com Sucesso!';
        objCacicCOMM.writeDebugLog('FTPdown: Size de "'+pStrTargetPath + '\' + pStrFileNameAtTarget +'" Após em Finally => ' + objCacicCOMM.getFileSize(pStrTargetPath + '\' + pStrFileNameAtTarget,true));
      End;
    Except
      on E : Exception do
        Begin
          objCacicCOMM.writeExceptionLog(E.Message,E.ClassName,'FTP: Erro Baixando "'+pStrSourcePath + '/' + pStrFileNameAtSource +'" para "'+pStrTargetPath + '\' + pStrFileNameAtTarget);
          objCacicCOMM.writeDebugLog('FTPdown: Erro Baixando "'+pStrSourcePath + '/' + pStrFileNameAtSource +'" para "'+pStrTargetPath + '\' + pStrFileNameAtTarget);
          result := 'Download de "' + pStrFileNameAtSource + '" Não Efetuado!';
        End;
    end;
  Finally
    objCacicCOMM.writeDebugLog('FTPdown: Desconectando objeto FTP');
    IdFTP1.Disconnect;

    objCacicCOMM.writeDebugLog('FTPdown: Liberando objeto FTP');
    IdFTP1.Free;

    objCacicCOMM.writeDebugLog('FTPdown: Liberando objCacicCOMM');
    objCacicCOMM.Free;
  End;
end;
end.
