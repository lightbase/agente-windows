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

program ini_cols;
{$R *.res}

uses
  Windows,
  SysUtils,
  Classes,
  idFTPCommon,
  idFTP,
  PJVersionInfo,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_te_senha_login_serv_updates,
  v_versao,
  v_ModulosOpcoes           : String;

var
  v_tstrCipherOpened,
  v_tstrModulosOpcoes,
  v_tstrModuloOpcao         : TStrings;

var
  intAux,
  v_ContaTempo,
  v_Tolerancia              : integer;

var
  v_Debugs                  : Boolean;
  v_Aguarde                 : TextFile;

var
   g_oCacic : TCACIC;

const
   CACIC_APP_NAME = 'ini_cols';

function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
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
       if (trim(strMsg) <> '') then
          begin
             DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(g_oCacic.getCacicPath + 'cacic2.log')));
             DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
             if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
                begin
                  Rewrite (HistoricoLog); //Cria/Recria o arquivo
                  Append(HistoricoLog);
                  Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
                end;
             Append(HistoricoLog);
             Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Inicializador de Coletas] '+strMsg); {Grava a string Texto no arquivo texto}
             CloseFile(HistoricoLog); {Fecha o arquivo texto}
          end
      else CloseFile(HistoricoLog);;

   except

   end;

end;

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

// Dica baixada de http://procedure.blig.ig.com.br/
procedure Matar(v_dir,v_files: string);
var
SearchRec: TSearchRec;
Result: Integer;
begin
  Result:=FindFirst(v_dir+v_files, faAnyFile, SearchRec);
  while result=0 do
    begin
      log_DEBUG('Excluindo: '+v_dir + SearchRec.Name);
      DeleteFile(v_dir+SearchRec.Name);
      Result:=FindNext(SearchRec);
    end;
end;

Function GetValorDatMemoria(p_Chave : String) : String;
begin
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
end;

Function CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
    oCacic : TCACIC;
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
      log_DEBUG('Rotina de Abertura do cacic2.dat RESTAURANDO estado da criptografia.');
    end;

    if (trim(v_strCipherOpened)<>'') then
      Result := g_oCacic.explode(v_strCipherOpened,g_oCacic.getSeparatorKey)
    else
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey+ oCacic.getWindowsStrId() +g_oCacic.getSeparatorKey+'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorkey);


    if Result.Count mod 2 <> 0 then
      Begin
        log_DEBUG('Vetor MemoryDAT com tamanho IMPAR... Ajustando.');
        Result.Add('');
      End;
end;

Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
var IdFTP : TIdFTP;
begin
  Try
    IdFTP               := TIdFTP.Create(IdFTP);
    IdFTP.Host          := p_Host;
    IdFTP.Username      := p_Username;
    IdFTP.Password      := p_Password;
    IdFTP.Port          := strtoint(p_Port);
    IdFTP.TransferType  := ftBinary;
    Try
      if IdFTP.Connected = true then
        begin
          IdFTP.Disconnect;
        end;
      IdFTP.Connect(true);
      IdFTP.ChangeDir(p_PathServer);
      Try
        IdFTP.Get(p_File, p_Dest + '\' + p_File, True);
        result := true;
      Except
        result := false;
      End;
    Except
        result := false;
    end;
  Except
    result := false;
  End;
end;

var strAux : String;
begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
      if ParamCount > 0 then
        Begin
          strAux := '';
          For intAux := 1 to ParamCount do
            Begin
              if LowerCase(Copy(ParamStr(intAux),1,11)) = '/cacicpath=' then
                begin
                  strAux := Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux)))));
                  log_DEBUG('Parâmetro /CacicPath recebido com valor="'+strAux+'"');
                end;
            end;

          if (strAux <> '') then
            Begin
             g_oCacic.setCacicPath(strAux);
             v_Debugs := false;
             if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
                Begin
                 if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                   Begin
                     v_Debugs := true;
                     log_DEBUG('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                   End;
                End;

             // A existência e bloqueio do arquivo abaixo evitará que Cacic2.exe chame o Ger_Cols quando a coleta ainda estiver sendo efetuada
             AssignFile(v_Aguarde,g_oCacic.getCacicPath + 'temp\aguarde_INI.txt'); {Associa o arquivo a uma variável do tipo TextFile}
             {$IOChecks off}
             Reset(v_Aguarde); {Abre o arquivo texto}
             {$IOChecks on}
             if (IOResult <> 0) then // Arquivo não existe, será recriado.
                  Rewrite (v_Aguarde);

             Append(v_Aguarde);
             Writeln(v_Aguarde,'Apenas um pseudo-cookie para o Cacic2 esperar o término de Ini_Cols');
             Append(v_Aguarde);

             Matar(g_oCacic.getCacicPath+'temp\','*.dat');
             Try
                  // Caso exista o Gerente de Coletas será verificada a versão...
                  // Devido a problemas na rotina de FTP na versão 2.0.1.2,
                  // que impossibilitava atualização de versões de todos os componentes, exceto INI_COLS
                  If (FileExists(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')) Then
                      Begin
                        v_versao := trim(GetVersionInfo(g_oCacic.getCacicPath +  'modulos\ger_cols.exe'));
                        if (v_versao = '0.0.0.0') then // Provavelmente arquivo corrompido ou versão muito antiga
                          Begin
                            Matar(g_oCacic.getCacicPath+'modulos\','ger_cols.exe');
                            Sleep(5000); // Pausa 5 segundos para total exclusão de GER_COLS
                            CipherOpen(g_oCacic.getCacicPath + g_oCacic.getDatFileName);
                            v_te_senha_login_serv_updates := GetValorDatMemoria('Configs.te_senha_login_serv_updates');

                            FTP(GetValorDatMemoria('Configs.te_serv_updates'),
                                GetValorDatMemoria('Configs.nu_porta_serv_updates'),
                                GetValorDatMemoria('Configs.nm_usuario_login_serv_updates'),
                                v_te_senha_login_serv_updates,
                                GetValorDatMemoria('Configs.te_path_serv_updates'),
                                'ger_cols.exe',
                                g_oCacic.getCacicPath + 'modulos');

                            // Pausa 5 segundos para total gravação de GER_COLS
                            Sleep(5000);

                          End;
                      End;

                  // Procuro pelo parâmetro p_ModulosOpcoes que deverá ter sido passado pelo Gerente de Coletas
                  // Contendo a formação: coletor1,wait#coletor2,nowait#coletorN,nowait#
                  // Observações:
                  // 1) Os valores "wait/nowait" determinam se o Inicializador de Coletas estará sujeito à tolerância de tempo para as coletas.
                  // 2) No caso de Coletor de Patrimônio, este depende de digitação e deverá trazer a opção "wait";
                  // 3) Ainda no caso de Coletor de Patrimônio, quando este for invocado através do menu, o Gerente de Coletas enviará a opção "user", ficando o parâmetro p_ModulosOpcoes = "col_patr,wait,user"
                  For intAux := 1 to ParamCount do
                    Begin
                      if LowerCase(Copy(ParamStr(intAux),1,17)) = '/p_modulosopcoes=' then
                        v_ModulosOpcoes := Trim(Copy(ParamStr(intAux),18,Length((ParamStr(intAux)))));
                    End;

                  log_DEBUG('Parâmetro p_ModulosOpcoes recebido: '+v_ModulosOpcoes);
                  v_tstrModulosOpcoes := g_oCacic.explode(v_ModulosOpcoes,'#');

                  // Tempo de tolerância para as coletas
                  v_Tolerancia := 5; // (minutos)

                  For intAux := 0 to v_tstrModulosOpcoes.Count -1 do
                    Begin
                      v_tstrModuloOpcao := g_oCacic.explode(v_tstrModulosOpcoes[intAux],',');
                      strAux := v_tstrModuloOpcao[0]+'.exe /CacicPath='+g_oCacic.getCacicPath+' /p_Option='+v_tstrModuloOpcao[2];
                      log_DEBUG('Chamando "' + v_tstrModuloOpcao[0]+'.exe " /p_Option='+v_tstrModuloOpcao[2]);

                      g_oCacic.createSampleProcess( g_oCacic.getCacicPath + '\modulos\' + strAux, CACIC_PROCESS_WAIT );
                      Sleep(500);
                    End;
             except
             end;
            End;
    End;
    g_oCacic.Free();
end.
