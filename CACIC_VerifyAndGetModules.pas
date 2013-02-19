unit CACIC_VerifyAndGetModules;
interface
uses      CACIC_Library,
          CACIC_Comm,
          SysUtils,
          Forms,
          Windows;

function  verifyAndGetModules(pStrFileName,
                              pStrFileHash,
                              pStrTargetFolderName,
                              pStrLocalFolderName : String;
                              pObjCacicVGM : TCACIC;
                              pStrIniFileName : String = '') : String;
implementation

function verifyAndGetModules(pStrFileName,
                             pStrFileHash,
                             pStrTargetFolderName,
                             pStrLocalFolderName : String;
                             pObjCacicVGM : TCACIC;
                             pStrIniFileName : String = '') : String;
var strTargetFolderName : String;
Begin
  Result := 'Oops! "' + pStrTargetFolderName + '\' + pStrFileName + '" Já Existe!';

  Try
    strTargetFolderName := pStrTargetFolderName;

    pObjCacicVGM.writeDebugLog('verifyAndGetModules: pStrFileName         -> "'+pStrFileName+'"');
    pObjCacicVGM.writeDebugLog('verifyAndGetModules: pStrFileHash         -> "'+pStrFileHash+'"');
    pObjCacicVGM.writeDebugLog('verifyAndGetModules: oCacicVGM.getFileHash-> "'+pObjCacicVGM.getFileHash(pStrTargetFolderName + '\' + pStrFileName)+'"');
    pObjCacicVGM.writeDebugLog('verifyAndGetModules: pStrTargetFolderName -> "'+strTargetFolderName+'"');

    If (pObjCacicVGM.getFileHash(pStrTargetFolderName + '\' + pStrFileName) <> pStrFileHash) then
      Begin
        pObjCacicVGM.deleteFileOrFolder(strTargetFolderName + '\' + pStrFileName);
        sleep(1000);

        If FileExists(strTargetFolderName + '\' + pStrFileName) Then
          strTargetFolderName := pStrLocalFolderName + 'Temp';

        Result := FTPdown(                     pObjCacicVGM.getValueFromFile('Configs', 'TeServUpdates'            , pStrIniFileName),
                          pObjCacicVGM.deCrypt(pObjCacicVGM.getValueFromFile('Configs', 'NmUsuarioLoginServUpdates', pStrIniFileName),false,true),
                          pObjCacicVGM.deCrypt(pObjCacicVGM.getValueFromFile('Configs', 'TeSenhaLoginServUpdates'  , pStrIniFileName),false,true),
                                               pObjCacicVGM.getValueFromFile('Configs', 'TePathServUpdates'        , pStrIniFileName),
                          pStrFileName,
                          strTargetFolderName,
                          pStrFileName,
                          'BIN',
                          pStrLocalFolderName,
                          strToInt(pObjCacicVGM.deCrypt(pObjCacicVGM.getValueFromFile('Configs', 'NuPortaServUpdates', pStrIniFileName))));

         if not FileExists(strTargetFolderName + '\' + pStrFileName) Then
           Begin
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: Problemas Efetuando Download de '+ strTargetFolderName + '\' + pStrFileName+' (FTP)');
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: Conexão:');
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: TeServUpdates             => ' +                      pObjCacicVGM.getValueFromFile('Configs', 'TeServUpdates'             , pStrIniFileName)            );
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: NmUsuarioLoginServUpdates => ' + pObjCacicVGM.deCrypt(pObjCacicVGM.getValueFromFile('Configs', 'NmUsuarioLoginServUpdates' , pStrIniFileName),false,true));
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: TeSenhaLoginServUpdates   => ' + pObjCacicVGM.deCrypt(pObjCacicVGM.getValueFromFile('Configs', 'TeSenhaLoginServUpdates'   , pStrIniFileName),false,true));
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: TePathServUpdates         => ' +                      pObjCacicVGM.getValueFromFile('Configs', 'TePathServUpdates'         , pStrIniFileName)            );
             pObjCacicVGM.writeDebugLog('verifyAndGetModules: NuPortaServUpdates        => ' +                      pObjCacicVGM.getValueFromFile('Configs', 'NuPortaServUpdates'        , pStrIniFileName)            );
           End
         else
            pObjCacicVGM.setValueToFile('Hash-Codes',pStrFileName , pObjCacicVGM.enCrypt(pObjCacicVGM.getFileHash(strTargetFolderName + '\' + pStrFileName),false,true), pStrIniFileName);

      End;
  Finally
      pObjCacicVGM.writeDebugLog('verifyAndGetModules: Liberando objeto oCacicVGM');
  End;

End;
end.
