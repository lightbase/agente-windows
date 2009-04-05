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
  IniFiles,
  SysUtils,
  Classes,
  Registry,
  MSI_DISK,
  MSI_XML_Reports,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_strCipherClosed             : String;
  v_debugs                      : boolean;

var
  v_tstrCipherOpened,
  v_tstrCipherOpened1,
  tstrTripa1                  : TStrings;

var
  intAux     : integer;

var
  g_oCacic                      : TCACIC;

const
  CACIC_APP_NAME = 'col_undi';

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (g_oCacic.getCacicPath + 'cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,g_oCacic.getCacicPath + 'cacic2.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(g_oCacic.getCacicPath + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor UNDI] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
     log_diario('Erro na gravação do log!');
   end;
end;

Function CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings) : String;
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       // Criação do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       v_strCipherOpenImploded := g_oCacic.implode(p_tstrCipherOpened,g_oCacic.getSeparatorKey);
       v_strCipherClosed := g_oCacic.enCrypt(v_strCipherOpenImploded);

       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(v_DatFile);
   except
   end;
end;

Function CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
begin
  v_strCipherOpened    := '';
  if FileExists(p_DatFileName) then
    begin
      AssignFile(v_DatFile,p_DatFileName);
      {$IOChecks off}
      Reset(v_DatFile);
      {$IOChecks on}
      if (IOResult <> 0) then // Arquivo não existe, será recriado.
         begin
           Rewrite (v_DatFile);
           Append(v_DatFile);
         end;

      Readln(v_DatFile,v_strCipherClosed);
      while not EOF(v_DatFile) do Readln(v_DatFile,v_strCipherClosed);
      CloseFile(v_DatFile);
      v_strCipherOpened:= g_oCacic.deCrypt(v_strCipherClosed);
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := g_oCacic.explode(v_strCipherOpened,g_oCacic.getSeparatorKey)
    else
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey + g_oCacic.getWindowsStrId() +g_oCacic.getSeparatorKey+'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);

    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
begin
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(p_Valor);
      End;
end;

Function GetValorDatMemoria(p_Chave : String; p_tstrCipherOpened : TStrings) : String;
begin
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
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

function GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;

function GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := g_oCacic.explode(Chave, '\');

    strRootKey := ListaAuxGet[0];
    For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';
    strValue := ListaAuxGet[ListaAuxGet.Count - 1];
    if (strValue = '(Padrão)') then strValue := ''; //Para os casos de se querer buscar o valor default (Padrão)
    RegEditGet := TRegistry.Create;

        RegEditGet.Access := KEY_READ;
        RegEditGet.Rootkey := GetRootKey(strRootKey);
        if RegEditGet.OpenKeyReadOnly(strKey) then //teste
        Begin
             RegDataType := RegEditGet.GetDataType(strValue);
             if (RegDataType = rdString) or (RegDataType = rdExpandString) then Result := RegEditGet.ReadString(strValue)
             else if RegDataType = rdInteger then Result := RegEditGet.ReadInteger(strValue)
             else if (RegDataType = rdBinary) or (RegDataType = rdUnknown)
             then
             begin
               DataSize := RegEditGet.GetDataSize(strValue);
               if DataSize = -1 then exit;
               SetLength(s, DataSize);
               Len := RegEditGet.ReadBinaryData(strValue, PChar(s)^, DataSize);
               if Len <> DataSize then exit;
               Result := RemoveCaracteresEspeciais(s);
             end
        end;
    finally
    RegEditGet.CloseKey;
    RegEditGet.Free;
    ListaAuxGet.Free;

    end;
end;

procedure Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := g_oCacic.getCacicPath + '\Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt';
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
     log_diario('Erro na gravação do Debug!');
   end;
end;


procedure Executa_Col_undi;
var strTripaDados,  strAux, id_tipo_unid_disco, ValorChaveRegistro : String;
    I: Integer;
    v_DISK : TMiTeC_Disk;
    v_Report : TstringList;
Begin
  SetValorDatMemoria('Col_Undi.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
  log_diario('Coletando informações de Unidades de Disco.');
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
    if (v_Debugs) then
      Begin
        v_Report := TStringList.Create;
        //report(v_Report,false);
        MSI_XML_Reports.Disk_XML_Report(v_DISK,true,v_Report);
      End;

    v_DISK.Free;
    //strXML := strXML + '</unidades>';

    // Obtenho do registro o valor que foi previamente armazenado
    ValorChaveRegistro := Trim(GetValorDatMemoria('Coletas.UnidadesDisco',v_tstrCipherOpened));

    SetValorDatMemoria('Col_Undi.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

    // Se essas informações forem diferentes significa que houve alguma alteração
    // na configuração. Nesse caso, gravo as informações no BD Central e, se não houver
    // problemas durante esse procedimento, atualizo as informações no registro.
    If ((GetValorDatMemoria('Configs.IN_COLETA_FORCADA_UNDI',v_tstrCipherOpened)='S') or (strTripaDados <> ValorChaveRegistro)) and
       (strTripaDados <> '') Then
     Begin
       SetValorDatMemoria('Col_Undi.UVC', strTripaDados, v_tstrCipherOpened1);
       CipherClose(g_oCacic.getCacicPath + 'temp\col_undi.dat', v_tstrCipherOpened1);
     end
    else
      Begin
        SetValorDatMemoria('Col_Undi.nada', 'nada', v_tstrCipherOpened1);
        CipherClose(g_oCacic.getCacicPath + 'temp\col_undi.dat', v_tstrCipherOpened1);
      End;

    // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
    // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
    if (v_Debugs) then
      Begin
        for i:=0 to v_Report.count-1 do
          Begin
            Grava_Debugs(v_report[i]);
          End;
        v_report.Free;
      End;
  Except
    SetValorDatMemoria('Col_Undi.nada', 'nada', v_tstrCipherOpened1);
    SetValorDatMemoria('Col_Undi.Fim', '99999999', v_tstrCipherOpened1);
    CipherClose(g_oCacic.getCacicPath + 'temp\col_undi.dat', v_tstrCipherOpened1);
    log_diario('Problema na coleta de informações de discos.');
  End;
end;

var strAux : String;
begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          strAux := '';
          For intAux := 1 to ParamCount do
            Begin
              if LowerCase(Copy(ParamStr(intAux),1,11)) = '/cacicpath=' then
                begin
                  strAux := Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux)))));
                end;
            end;

          if (strAux <> '') then
            Begin
               g_oCacic.setCacicPath(strAux);

               v_tstrCipherOpened  := TStrings.Create;
               v_tstrCipherOpened  := CipherOpen(g_oCacic.getCacicPath + g_oCacic.getDatFileName);

               v_tstrCipherOpened1 := TStrings.Create;
               v_tstrCipherOpened1 := CipherOpen(g_oCacic.getCacicPath + 'temp\col_undi.dat');

               Try
                  v_Debugs := false;
                  if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
                    Begin
                      if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                        Begin
                          v_Debugs := true;
                          log_diario('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                        End;
                    End;

                  Executa_Col_undi;
               Except
                  SetValorDatMemoria('Col_Undi.nada', 'nada', v_tstrCipherOpened1);
                  CipherClose(g_oCacic.getCacicPath + 'temp\col_undi.dat', v_tstrCipherOpened1);
               End;
            End;
        End;
    g_oCacic.Free();

end.
