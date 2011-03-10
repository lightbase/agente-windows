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

NOTA: O componente MiTeC System Information Component (MSIC) é baseado na classe TComponent e contém alguns subcomponentes baseados na classe TPersistent
      Este componente é apenas freeware e não open-source, e foi baixado de http://www.mitec.cz/Downloads/MSIC.zip
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

program col_undi;
{$R *.res}
{$APPTYPE CONSOLE}
uses
  Windows,
  SysUtils,
  Classes,
  MSI_DISK,
  MSI_XML_Reports,
  CACIC_Library in '..\CACIC_Library.pas';

var
  g_oCacic                      : TCACIC;

const
  CACIC_APP_NAME = 'col_undi';

procedure Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := g_oCacic.getLocalFolder + '\Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt';
       FileSetAttr (v_file_debugs,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(DebugsFile,v_file_debugs); {Associa o arquivo a uma variável do tipo TextFile}

       {$IOChecks off}
       Reset(DebugsFile); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite(DebugsFile);
            Append(DebugsFile);
            Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Debug <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(v_file_debugs)));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);

       if (strDataAtual <> strDataArqLocal) then // Se o arquivo não é da data atual...
          begin
            Rewrite(DebugsFile); //Cria/Recria o arquivo
            Append(DebugsFile);
            Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Debug <=======================');
          end;

       Append(DebugsFile);
       Writeln(DebugsFile,FormatDateTime('dd/mm hh:nn:ss : ', Now) + strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(DebugsFile); {Fecha o arquivo texto}
   except
     g_oCacic.writeDailyLog('Erro na gravação do Debug!');
   end;
end;


procedure Executa_Col_undi;
var strTripaDados,  strAux, id_tipo_unid_disco, ValorChaveRegistro : String;
    I: Integer;
    v_DISK : TMiTeC_Disk;
    v_Report : TstringList;
Begin
  g_oCacic.setValueToFile('Col_Undi','Inicio',g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
  g_oCacic.writeDailyLog('Coletando informações de Unidades de Disco.');
  Try
    //strXML := '<?xml version="1.0" encoding="ISO-8859-1"?><unidades>';
    strTripaDados := '';
    v_DISK := TMiTeC_Disk.Create(nil);

    with v_DISK do
    begin
      RefreshData;
      for i:=1 to length(AvailableDisks) do
      begin
         strAux := UpperCase(Copy(AvailableDisks,i,1) + ':\');
         Drive := copy(strAux,1,2);
         id_tipo_unid_disco := GetMediaTypeStr(MediaType);

         // Coleta de informações sobre unidades de HD.
         if (UpperCase(id_tipo_unid_disco) = 'FIXED') then
         Begin
             id_tipo_unid_disco := '2';
             if (strTripaDados <> '') then
                strTripaDados := strTripaDados + '<REG>'; // Delimitador de REGISTRO

             //strXML := strXML + '<unidade>' +
             //                      '<te_letra>' + Drive + '</te_letra>';
             strTripaDados := strTripaDados + Drive + '<FIELD>';

             strTripaDados := strTripaDados + id_tipo_unid_disco + '<FIELD>';

             if ((id_tipo_unid_disco = '2') or (id_tipo_unid_disco = '4')) then
                strTripaDados := strTripaDados + FileSystem                             + '<FIELD>' +
                                                 SerialNumber                           + '<FIELD>' +
                                                 IntToStr(Capacity  div 10485760) + '0' + '<FIELD>' +  // Em MB  - Coleta apenas de 10 em 10 MB
                                                 IntToStr(FreeSpace div 10485760) + '0' + '<FIELD>' // Em MB  - Coleta apenas de 10 em 10 MB
             else
                strTripaDados := strTripaDados + '' + '<FIELD>' +
                                                 '' + '<FIELD>' +
                                                 '' + '<FIELD>' +  // Em MB  - Coleta apenas de 10 em 10 MB
                                                 '' + '<FIELD>'; // Em MB  - Coleta apenas de 10 em 10 MB
             if (id_tipo_unid_disco = '4') then
                strTripaDados := strTripaDados + ExpandUNCFilename(Drive)
             else
                strTripaDados := strTripaDados + '';

         end;
      end;

      // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
      // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
    end;
    if g_oCacic.inDebugMode then
      Begin
        v_Report := TStringList.Create;
        //report(v_Report,false);
        MSI_XML_Reports.Disk_XML_Report(v_DISK,true,v_Report);
      End;

    v_DISK.Free;
    //strXML := strXML + '</unidades>';

    // Obtenho do registro o valor que foi previamente armazenado
    ValorChaveRegistro := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','UnidadesDisco',g_oCacic.getLocalFolder + 'GER_COLS.inf')));

    g_oCacic.setValueToFile('Col_Undi','Fim',g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

    // Se essas informações forem diferentes significa que houve alguma alteração
    // na configuração. Nesse caso, gravo as informações no BD Central e, se não houver
    // problemas durante esse procedimento, atualizo as informações no registro local.
    If ((g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_COLETA_FORCADA_UNDI',g_oCacic.getLocalFolder + 'GER_COLS.inf'))='S') or (strTripaDados <> ValorChaveRegistro)) and
       (strTripaDados <> '') Then
       g_oCacic.setValueToFile('Col_Undi','UVC',g_oCacic.enCrypt( strTripaDados), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName)
    else
        g_oCacic.setValueToFile('Col_Undi','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

    // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
    // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
    if g_oCacic.inDebugMode then
      Begin
        for i:=0 to v_Report.count-1 do
          Begin
            Grava_Debugs(v_report[i]);
          End;
        v_report.Free;
      End;
  Except
    g_oCacic.setValueToFile('Col_Undi','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    g_oCacic.setValueToFile('Col_Undi','Fim' ,g_oCacic.enCrypt( '99999999'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    g_oCacic.writeDailyLog('Problema na coleta de informações de discos.');
  End;
end;

begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          g_oCacic.setLocalFolder( g_oCacic.GetParam('LocalFolder') );

          if (g_oCacic.getLocalFolder <> '') then
            Begin
               g_oCacic.checkDebugMode;

               Try
                  if g_oCacic.inDebugMode then
                    g_oCacic.writeDailyLog('As informações para DEBUG de coletas internas serão gravadas em "' + g_oCacic.getLocalFolder + 'Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt');

                  Executa_Col_undi;
               Except
                  g_oCacic.setValueToFile('Col_Undi','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
               End;
            End;
        End;
    g_oCacic.Free();

end.
