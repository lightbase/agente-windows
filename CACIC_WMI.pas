(*
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

NOTA: O componente MiTeC System Information Component (MSIC) é baseado na classe TComponent e contém alguns subcomponentes baseados na classe TPersistent
      Este componente é apenas freeware e não open-source, e foi baixado de http://www.mitec.cz/Downloads/MSIC.zip
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)
unit CACIC_WMI;
interface
uses  Windows,
      Classes,
      ActiveX,
      SysUtils,
      StrUtils,
      MagWMI,
      MagSubs1,
      CACIC_Library;

function  fetchWMIvalues(pStrWin32ClassName, pStrLocalFolderName : String; pStrColumnsNames : String = ''; pStrWhereClause : String = '') : String;
procedure fixNetworkAdapterConfigurationInformations(var pStrWin32_NetworkAdapterConfigurationInformations : String; pStrLocalFolderName : String);

implementation

// Procedimento para encontrar o DefaultIPGateway diferente de ""
procedure fixNetworkAdapterConfigurationInformations(var pStrWin32_NetworkAdapterConfigurationInformations : String; pStrLocalFolderName : String);
var intFNACI_CorrectIndex,
    intFNACI_Loop                     : integer;
    tstrFNACI_AUX                     : TStrings;
    objCacicFNACI                     : TCACIC;
Begin
  Try
    objCacicFNACI := TCACIC.Create;
    objCacicFNACI.setLocalFolderName(pStrLocalFolderName);
    objCacicFNACI.setBoolCipher(true);

    if (pos('[[REG]]',objCacicFNACI.getValueFromTags('DefaultIPGateway',pStrWin32_NetworkAdapterConfigurationInformations)) > 0) then
      Begin
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: ' + DupeString('-',100));
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: Tratando NetworkAdapterConfiguration com Múltiplas Instances');
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: pStrWin32_NetworkAdapterConfigurationInformations => "'+pStrWin32_NetworkAdapterConfigurationInformations+'"');
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: ' + DupeString('-',100));
        tstrFNACI_AUX         := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('DefaultIPGateway',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');

        intFNACI_CorrectIndex := 0;
        intFNACI_Loop         := 0;
        while (intFNACI_Loop < tstrFNACI_AUX.Count -1) do
          Begin
            objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: Checando se "' + tstrFNACI_AUX[intFNACI_Loop] + '" <> ""');
            if (tstrFNACI_AUX[intFNACI_Loop] <> '') then
              Begin
                objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: "' + tstrFNACI_AUX[intFNACI_Loop] + '" <> ""');
                intFNACI_CorrectIndex := intFNACI_Loop;
                objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: intFNACI_CorrectIndex -> ' + intToStr(intFNACI_CorrectIndex));
                intFNACI_Loop         := tstrFNACI_AUX.Count;
              End;
            inc(intFNACI_Loop);
          End;

        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: Iniciando Processo de Correção...');

        objCacicFNACI.setValueToTags('DefaultIPGateway',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: Win32_NetworkAdapterConfiguration_DefaultIPGateway: "' + objCacicFNACI.getValueFromTags('DefaultIPGateway',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('DHCPServer',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('DHCPServer',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_DHCPServer: "' + objCacicFNACI.getValueFromTags('DHCPServer',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('DNSDomain',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('DNSDomain',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_DNSDomain: "' + objCacicFNACI.getValueFromTags('DNSDomain',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('DNSHostName',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('DNSHostName',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_DNSHostName: "' + objCacicFNACI.getValueFromTags('DNSHostName',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('DNSServerSearchOrder',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('DNSServerSearchOrder',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_DNSServerSearchOrder: "' + objCacicFNACI.getValueFromTags('DNSServerSearchOrder',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('IPAddress',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('IPAddress',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_IPAddress: "' + objCacicFNACI.getValueFromTags('IPAddress',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('IPSubnet',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('IPSubnet',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_IPSubnet: "' + objCacicFNACI.getValueFromTags('IPSubnet',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('MACAddress',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('MACAddress',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_MACAddress: "' + objCacicFNACI.getValueFromTags('MACAddress',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('WINSPrimaryServer',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('WINSPrimaryServer',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_WINSPrimaryServer: "' + objCacicFNACI.getValueFromTags('WINSPrimaryServer',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        tstrFNACI_AUX := objCacicFNACI.explode(objCacicFNACI.getValueFromTags('WINSSecondaryServer',pStrWin32_NetworkAdapterConfigurationInformations),'[[REG]]');
        if (tstrFNACI_AUX.Count > 0) then
          objCacicFNACI.setValueToTags('WINSSecondaryServer',tstrFNACI_AUX[intFNACI_CorrectIndex], pStrWin32_NetworkAdapterConfigurationInformations);
        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: strWin32_NetworkAdapterConfiguration_WINSSecondaryServer: "' + objCacicFNACI.getValueFromTags('WINSSecondaryServer',pStrWin32_NetworkAdapterConfigurationInformations) + '"');

        objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: ' + DupeString('-',100));
      End;
  Finally
    objCacicFNACI.writeDebugLog('fixNetworkAdapterConfigurationInformations: Esvaziando WMIResults.');
    objCacicFNACI.Free;
  End;
End;

function fetchWMIvalues(pStrWin32ClassName, pStrLocalFolderName : String; pStrColumnsNames : String = ''; pStrWhereClause : String = '') : String;
  var   intLoopInstances,
        intLoopRows,
        intTotalOfInstances,
        intTotalOfRows                    : integer;
        strWhereClause,
        strColumnsNames,
        strValueToSet,
        strWMIQuery                       : string;
        arrWMIResults                     : T2DimStrArray;
        objCacicWMI                       : TCACIC;
        tstrValues                        : TStrings;
Begin
  Try
    objCacicWMI := TCACIC.Create;
    objCacicWMI.setLocalFolderName(pStrLocalFolderName);
    objCacicWMI.setBoolCipher(true);

    Try
      objCacicWMI.writeDebugLog('fetchWMIvalues: Montando ambiente para consultas WMI.');
      strWhereClause := pStrWhereClause;
      strColumnsNames := pStrColumnsNames;

      {Classes de envio incondicional}
      if      (pStrWin32ClassName = 'Win32_ComputerSystem') and (pStrColumnsNames = '') then
        strColumnsNames := 'Caption,Domain,TotalPhysicalMemory,UserName'
      else if (pStrWin32ClassName = 'Win32_NetworkAdapterConfiguration')  and (pStrColumnsNames = '') then
        Begin
          strColumnsNames := 'DefaultIPGateway,Description,DHCPServer,DNSDomain,DNSHostName,DNSServerSearchOrder,IPAddress,IPSubnet,MACAddress,WINSPrimaryServer,WINSSecondaryServer';
          strWhereClause  := 'DHCPEnabled=TRUE and IPEnabled=TRUE';
        End
      else if (pStrWin32ClassName = 'Win32_OperatingSystem') and (pStrColumnsNames = '') then
        strColumnsNames := 'Caption,CSDVersion,InstallDate,LastBootUpTime,NumberOfLicensedUsers,OSArchitecture,OSLanguage,ProductType,SerialNumber,Version';

      if (strWhereClause <> '') then
        strWhereClause := ' WHERE ' + strWhereClause;

      strWMIQuery := 'SELECT ' + strColumnsNames + ' FROM ' + pStrWin32ClassName + strWhereClause;

      objCacicWMI.writeDebugLog('fetchWMIvalues: query dinâmica => "' + strWMIQuery + '"');
      Try
        Try
          CoInitialize(nil);
          intTotalOfRows := MagWmiGetInfo('.','root/CIMV2','','',strWMIQuery, arrWMIResults, intTotalOfInstances);
        Finally
          CoUninitialize;
        End;
      Except
        on E : Exception do
          Begin
             objCacicWMI.writeExceptionLog(E.Message,E.ClassName,'ERRO em MagWmiGetInfo');
          End;
      End;

      objCacicWMI.writeDebugLog('fetchWMIvalues: Total de linhas (campos) da consulta: '    + intToStr(intTotalOfRows));
      objCacicWMI.writeDebugLog('fetchWMIvalues: Total de instances (colunas de ítens) retornado na consulta: ' + intToStr(intTotalOfInstances));

      Result := '';
      if not (intTotalOfInstances = 0) then
          for intLoopRows := 1 to intTotalOfRows do
            Begin
              objCacicWMI.writeDebugLog('fetchWMIvalues: Verificando se a coluna "' + arrWMIResults[0, intLoopRows] + '" foi solicitada na classe "' + pStrWin32ClassName + '"');
              if (pos(',' + arrWMIResults[0, intLoopRows] + ',', ',' + strColumnsNames + ',') > 0) then
                Begin
                  objCacicWMI.writeDebugLog('fetchWMIvalues: Ok! A coluna "' + arrWMIResults[0, intLoopRows] + '" foi solicitada!');
                  strValueToSet := '';
                  for intLoopInstances := 1 to intTotalOfInstances do
                    Begin
                      objCacicWMI.writeDebugLog('fetchWMIvalues: Tratando instância ' + intToStr(intLoopInstances) + ': "' + arrWMIResults[intLoopInstances,intLoopRows] + '"');
                      if (strValueToSet <> '') then
                        strValueToSet := strValueToSet + '[[REG]]';

                      if (arrWMIResults[0, intLoopRows] <> 'DNSServerSearchOrder') and (arrWMIResults[intLoopInstances,intLoopRows] <> '') then
                        Begin
                          tstrValues := objCacicWMI.explode(arrWMIResults[intLoopInstances,intLoopRows],'|');
                          strValueToSet := strValueToSet + tstrValues[0];
                        End
                      else
                        strValueToSet := strValueToSet + arrWMIResults[intLoopInstances,intLoopRows];

                      objCacicWMI.writeDebugLog('fetchWMIvalues: strValueToSet -> "' + strValueToSet + '"');
                    End;
                  strValueToSet := StringReplace(strValueToSet,'NULL','',[rfReplaceAll]);
                  strValueToSet := StringReplace(strValueToSet,','   ,'[[COMMA]]',[rfReplaceAll]);
                  objCacicWMI.replaceEnvironmentVariables(strValueToSet);
                  Result := Result + '[' + arrWMIResults[0, intLoopRows] + ']' + strValueToSet + '[/' + arrWMIResults[0, intLoopRows] + ']';
                End
              else
                objCacicWMI.writeDebugLog('fetchWMIvalues: Oops! A coluna "' + arrWMIResults[0, intLoopRows] + '" NÃO FOI solicitada!');
            End;
    Except
    End;
  Finally
    if (pStrWin32ClassName = 'Win32_NetworkAdapterConfiguration') then
      fixNetworkAdapterConfigurationInformations(Result,objCacicWMI.getLocalFolderName);

    objCacicWMI.writeDebugLog('fetchWMIvalues: Esvaziando WMIResults.');
    objCacicWMI.Free;
    arrWMIResults := Nil;
  End;

End;

end.

