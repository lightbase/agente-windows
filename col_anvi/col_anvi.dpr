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

program col_anvi;
{$R *.res}

uses
  Windows,
  classes,
  sysutils,
  Registry,
  TLHELP32,
  ShellAPI,
  PJVersionInfo,
  CACIC_Library in '..\CACIC_Library.pas';

var  v_strCipherClosed         : String;

var v_Debugs                   : boolean;

var v_tstrCipherOpened,
    v_tstrCipherOpened1        : TStrings;

var
  g_oCacic : TCACIC;

function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (g_oCacic.getCacicPath + '\cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,g_oCacic.getCacicPath + '\cacic2.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(g_oCacic.getCacicPath + '\cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '[Coletor ANVI] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
//       FileSetAttr (ExtractFilePath(Application.Exename) + '\cacic2.log',6); // Muda o atributo para arquivo de SISTEMA e OCULTO

   except
     log_diario('Erro na gravação do log!');
   end;
end;

function GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;


// Pad a string with zeros so that it is a multiple of size
function PadWithZeros(const str : string; size : integer) : string;
var
  origsize, i : integer;
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

Procedure CipherClose(p_DatFileName : string; p_tstrCipherOpened : TStrings);
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try
       FileSetAttr (p_DatFileName,0); //  Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
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
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey+ g_oCacic.getWindowsStrId() + g_oCacic.getSeparatorKey + 'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);

    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
begin
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[p_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(p_Valor);
      End;
end;

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

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

function ProgramaRodando(NomePrograma: String): Boolean;
var
  IsRunning, ContinueTest: Boolean;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  IsRunning := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueTest := Process32First(FSnapshotHandle, FProcessEntry32);
  while ContinueTest do
  begin
    IsRunning :=  UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(NomePrograma);
    if IsRunning then  ContinueTest := False
    else ContinueTest := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
  Result := IsRunning;
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

procedure Executa_Col_Anvi;
var Lista1_RCO : TStringList;
    Lista2_RCO : TStrings;
    nu_versao_engine, dt_hr_instalacao, nu_versao_pattern, ChaveRegistro, te_servidor, in_ativo,
    NomeExecutavel, UVC, ValorChaveRegistro, strAux, strDirTrend : String;
    searchResult : TSearchRec;  // Necessário apenas para Win9x
begin
  Try
       SetValorDatMemoria('Col_Anvi.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
       nu_versao_engine   := '';
       nu_versao_pattern  := '';
       log_diario('Coletando informações de Antivírus OfficeScan.');
       If g_oCacic.isWindows9xME() Then { Windows 9x/ME }
       Begin
           ChaveRegistro := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\OfficeScanCorp\CurrentVersion';
           NomeExecutavel := 'pccwin97.exe';
           dt_hr_instalacao  := GetValorChaveRegEdit(ChaveRegistro + '\Install Date') + GetValorChaveRegEdit(ChaveRegistro + '\Install Time');
           log_DEBUG('Data/Hora de Instalação: '+dt_hr_instalacao);
           strDirTrend := GetValorChaveRegEdit(ChaveRegistro + '\Application Path');
           If FileExists(strDirTrend + '\filter32.vxd') Then
           Begin
             // Em máquinas Windows 9X a versão do engine e do pattern não são gravadas no registro. Tenho que pegar direto dos arquivos.
             Lista2_RCO := g_oCacic.explode(getVersionInfo(strDirTrend + 'filter32.vxd'), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
             nu_versao_engine := Lista2_RCO[0] + '.' + Lista2_RCO[1];
             Lista2_RCO.Free;
           end
           Else nu_versao_engine := '0';

           // A gambiarra para coletar a versão do pattern é obter a maior extensão do arquivo lpt$vpn
           if FindFirst(strDirTrend + '\lpt$vpn.*', faAnyFile, searchResult) = 0 then
           begin
             Lista1_RCO := TStringList.Create;
             repeat Lista1_RCO.Add(ExtractFileExt(searchResult.Name));
             until FindNext(searchResult) <> 0;
             Sysutils.FindClose(searchResult);
             Lista1_RCO.Sort; // Ordeno, para, em seguida, obter o último.
             strAux := Lista1_RCO[Lista1_RCO.Count - 1];
             Lista1_RCO.Free;
             nu_versao_pattern := Copy(strAux, 2, Length(strAux)); // Removo o '.' da extensão.
           end;

       end
       Else
       Begin  // NT a XP
           ChaveRegistro := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\PC-cillinNTCorp\CurrentVersion';
           NomeExecutavel := 'ntrtscan.exe';
           dt_hr_instalacao  := GetValorChaveRegEdit(ChaveRegistro + '\InstDate') + GetValorChaveRegEdit(ChaveRegistro + '\InstTime');
           nu_versao_engine  := GetValorChaveRegEdit(ChaveRegistro + '\Misc.\EngineZipVer');
           nu_versao_pattern := GetValorChaveRegEdit(ChaveRegistro + '\Misc.\PatternVer');
           nu_versao_pattern := Copy(nu_versao_pattern, 2, Length(nu_versao_pattern)-3);
       end;

       log_DEBUG('Versão de Engine obtida.: '+nu_versao_engine);
       log_DEBUG('Versão de Pattern obtida: '+nu_versao_pattern);

       te_servidor       := GetValorChaveRegEdit(ChaveRegistro + '\Server');
       If (ProgramaRodando(NomeExecutavel)) Then in_ativo := '1' Else in_ativo := '0';

       log_DEBUG('Valor para Estado Ativo.: ' + in_ativo);

       // Monto a string que será comparada com o valor armazenado no registro.
       UVC := Trim(nu_versao_engine + ';' +
                   nu_versao_pattern  + ';' +
                   te_servidor + ';' +
                   dt_hr_instalacao + ';' +
                   in_ativo);
       // Obtenho do registro o valor que foi previamente armazenado
       ValorChaveRegistro := Trim(GetValorDatMemoria('Coletas.OfficeScan',v_tstrCipherOpened));

       SetValorDatMemoria('Col_Anvi.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

       log_DEBUG('Registro Anterior: ' + ValorChaveRegistro);
       log_DEBUG('Registro Atual...: ' + UVC);
       // Se essas informações forem diferentes significa que houve alguma alteração
       // na configuração. Nesse caso, gravo as informações no BD Central
       // e, se não houver problemas durante esse procedimento, atualizo as
       // informações no registro.
       If (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_ANVI',v_tstrCipherOpened)='S') or (UVC <> ValorChaveRegistro) Then
        Begin
             SetValorDatMemoria('Col_Anvi.nu_versao_engine'  , nu_versao_engine , v_tstrCipherOpened1);
             SetValorDatMemoria('Col_Anvi.nu_versao_pattern' , nu_versao_pattern, v_tstrCipherOpened1);
             SetValorDatMemoria('Col_Anvi.dt_hr_instalacao'  , dt_hr_instalacao , v_tstrCipherOpened1);
             SetValorDatMemoria('Col_Anvi.te_servidor'       , te_servidor      , v_tstrCipherOpened1);
             SetValorDatMemoria('Col_Anvi.in_ativo'          , in_ativo         , v_tstrCipherOpened1);
             SetValorDatMemoria('Col_Anvi.UVC'               , UVC              , v_tstrCipherOpened1);
             CipherClose(g_oCacic.getCacicPath + '\temp\col_anvi.dat'  , v_tstrCipherOpened1);
        end
        else
          Begin
            SetValorDatMemoria('Col_Anvi.nada', 'nada', v_tstrCipherOpened1);
            CipherClose(g_oCacic.getCacicPath + '\temp\col_anvi.dat', v_tstrCipherOpened1);
          End;
  Except
    Begin
      SetValorDatMemoria('Col_Anvi.nada', 'nada', v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Anvi.Fim', '99999999', v_tstrCipherOpened1);
      CipherClose(g_oCacic.getCacicPath + '\temp\col_anvi.dat', v_tstrCipherOpened1);
    End;
  End;
end;

var tstrTripa1 : TStrings;
    intAux     : integer;
    v_path_cacic : String;
const
  CACIC_APP_NAME = 'col_anvi';

begin
   g_oCacic := TCACIC.Create();

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
    Begin
       //Pegarei o nível anterior do diretório, que deve ser, por exemplo \Cacic, para leitura do cacic2.ini
       tstrTripa1 := g_oCacic.explode(ExtractFilePath(ParamStr(0)),'\');
       v_path_cacic := '';
       For intAux := 0 to tstrTripa1.Count -2 do
         v_path_cacic := v_path_cacic + tstrTripa1[intAux] + '\';

       g_oCacic.setCacicPath(v_path_cacic);

       v_Debugs := false;
       if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
         Begin
          if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
            Begin
              v_Debugs := true;
              log_diario('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
            End;
        End;
    
       v_tstrCipherOpened  := TStrings.Create;
       v_tstrCipherOpened  := CipherOpen(g_oCacic.getDatFileName);

       v_tstrCipherOpened1 := TStrings.Create;
       v_tstrCipherOpened1 := CipherOpen(g_oCacic.getCacicPath + 'temp\col_anvi.dat');

       Try
          Executa_Col_Anvi;
       Except
          Begin
            SetValorDatMemoria('Col_Anvi.nada', 'nada', v_tstrCipherOpened1);
            CipherClose(g_oCacic.getCacicPath + 'temp\col_anvi.dat', v_tstrCipherOpened1);
          End;
       End;
    End;
    g_oCacic.Free();
end.
