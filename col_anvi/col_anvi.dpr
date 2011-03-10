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
  TLHELP32,
  ShellAPI,
  CACIC_Library in '..\CACIC_Library.pas';

var
  g_oCacic : TCACIC;

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

procedure Executa_Col_Anvi;
var Lista1_RCO : TStringList;
    Lista2_RCO : TStrings;
    nu_versao_engine, dt_hr_instalacao, nu_versao_pattern, ChaveRegistro, te_servidor, in_ativo,
    NomeExecutavel, UVC, ValorChaveRegistro, strAux, strDirTrend : String;
    searchResult : TSearchRec;  // Necessário apenas para Win9x
begin
  Try
       g_oCacic.setValueToFile('Col_Anvi','Inicio', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
       nu_versao_engine   := '';
       nu_versao_pattern  := '';
       g_oCacic.writeDailyLog('Coletando informações de Antivírus OfficeScan.');
       If g_oCacic.isWindows9xME() Then { Windows 9x/ME }
       Begin
           ChaveRegistro := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\OfficeScanCorp\CurrentVersion';
           NomeExecutavel := 'pccwin97.exe';
           dt_hr_instalacao  := g_oCacic.getValueRegistryKey(ChaveRegistro + '\Install Date') + g_oCacic.getValueRegistryKey(ChaveRegistro + '\Install Time');
           g_oCacic.writeDebugLog('Data/Hora de Instalação: '+dt_hr_instalacao);
           strDirTrend := g_oCacic.getValueRegistryKey(ChaveRegistro + '\Application Path');
           If FileExists(strDirTrend + '\filter32.vxd') Then
           Begin
             // Em máquinas Windows 9X a versão do engine e do pattern não são gravadas no registro. Tenho que pegar direto dos arquivos.
             Lista2_RCO := g_oCacic.explode(g_oCacic.getVersionInfo(strDirTrend + 'filter32.vxd'), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
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
           dt_hr_instalacao  := g_oCacic.getValueRegistryKey(ChaveRegistro + '\InstDate') + g_oCacic.getValueRegistryKey(ChaveRegistro + '\InstTime');
           nu_versao_engine  := g_oCacic.getValueRegistryKey(ChaveRegistro + '\Misc.\EngineZipVer');
           nu_versao_pattern := g_oCacic.getValueRegistryKey(ChaveRegistro + '\Misc.\PatternVer');
           nu_versao_pattern := Copy(nu_versao_pattern, 2, Length(nu_versao_pattern)-3);
       end;

       g_oCacic.writeDebugLog('Versão de Engine obtida.: '+nu_versao_engine);
       g_oCacic.writeDebugLog('Versão de Pattern obtida: '+nu_versao_pattern);

       te_servidor       := g_oCacic.getValueRegistryKey(ChaveRegistro + '\Server');
       If (ProgramaRodando(NomeExecutavel)) Then in_ativo := '1' Else in_ativo := '0';

       g_oCacic.writeDebugLog('Valor para Estado Ativo.: ' + in_ativo);

       // Monto a string que será comparada com o valor armazenado no registro.
       UVC := Trim(nu_versao_engine + ';' +
                   nu_versao_pattern  + ';' +
                   te_servidor + ';' +
                   dt_hr_instalacao + ';' +
                   in_ativo);
       // Obtenho do registro o valor que foi previamente armazenado
       ValorChaveRegistro :=  Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','OfficeScan',g_oCacic.getLocalFolder + 'GER_COLS.inf')));

       g_oCacic.setValueToFile('Col_Anvi','Fim' , g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

       g_oCacic.writeDebugLog('Registro Anterior: ' + ValorChaveRegistro);
       g_oCacic.writeDebugLog('Registro Atual...: ' + UVC);
       // Se essas informações forem diferentes significa que houve alguma alteração
       // na configuração. Nesse caso, gravo as informações no BD Central
       // e, se não houver problemas durante esse procedimento, atualizo o registro local.
       If (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_COLETA_FORCADA_ANVI',g_oCacic.getLocalFolder + 'GER_COLS.inf'))='S') or (UVC <> ValorChaveRegistro) Then
        Begin
             g_oCacic.setValueToFile('Col_Anvi','nu_versao_engine'  , g_oCacic.enCrypt(nu_versao_engine) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
             g_oCacic.setValueToFile('Col_Anvi','nu_versao_pattern' , g_oCacic.enCrypt(nu_versao_pattern), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
             g_oCacic.setValueToFile('Col_Anvi','dt_hr_instalacao'  , g_oCacic.enCrypt(dt_hr_instalacao) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
             g_oCacic.setValueToFile('Col_Anvi','te_servidor'       , g_oCacic.enCrypt(te_servidor)      , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
             g_oCacic.setValueToFile('Col_Anvi','in_ativo'          , g_oCacic.enCrypt(in_ativo)         , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
             g_oCacic.setValueToFile('Col_Anvi','UVC'               , g_oCacic.enCrypt(UVC)              , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        end
        else
          g_oCacic.setValueToFile('Col_Anvi','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
  Except
    Begin
      g_oCacic.setValueToFile('Col_Anvi','nada', g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Anvi','Fim', g_oCacic.enCrypt( '99999999'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    End;
  End;
end;

const
  CACIC_APP_NAME = 'col_anvi';

begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          g_oCacic.setLocalFolder(g_oCacic.GetParam('LocalFolder'));

          if (g_oCacic.getLocalFolder <> '') then
            Begin
               g_oCacic.checkDebugMode;

               Try
                  Executa_Col_Anvi;
               Except
                  g_oCacic.setValueToFile('Col_Anvi','nada', g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
               End;
            End;
        End;
    g_oCacic.Free();
end.
