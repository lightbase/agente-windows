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
  Registry,
  Inifiles,
  XML,
  LibXmlParser,
  strUtils,
  IdHTTP,
  IdFTP,
  idFTPCommon,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  PJVersionInfo,
  Winsock,
  Tlhelp32,
  CACIC_Library in '..\CACIC_Library.pas';

var
  PJVersionInfo1: TPJVersionInfo;
  v_strCipherClosed,
  v_versao_local,
  v_versao_remota,
  v_retorno                 : String;
  v_Debugs                  : Boolean;

var
  v_tstrCipherOpened        : TStrings;

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
    strDataArqLocal,
    strDataAtual,
    v_path : string;
begin
   try
       v_path := g_oCacic.getWinDir + 'chksis.log';
       FileSetAttr (v_path,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,v_path); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(v_path)));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Verif.Integr.Sistema] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
     log_diario('Erro na gravação do log!');
   end;
end;
function GetVersionInfo(p_File: string):string;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(PJVersionInfo1);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
end;

// Função para fixar o HomeDrive como letra para a pasta do CACIC
function TrataCacicDir(strCacicDir : String) : String;
var tstrCacicDir1,
    tstrCacicDir2 : TStrings;
    intAUX : integer;
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
      for intAux := 0 to (tstrCacicDir2.Count-1) do
        if (tstrCacicDir2[intAux] <> '') then
            Result := Result + tstrCacicDir2[intAux] + '\';
      tstrCacicDir2.Free;
    End
  else
    Result := g_oCacic.getHomeDrive + strCacicDir + '\';

  tstrCacicDir1.Free;

  Result := StringReplace(Result,'\\','\',[rfReplaceAll]);
End;

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

Function CipherClose(p_DatFileName : string) : String;
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try

       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       {$IOChecks off}
       ReWrite(v_DatFile); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then
        Begin
         // Recriação do arquivo .DAT
         Rewrite (v_DatFile);
         Append(v_DatFile);
        End;

       v_strCipherOpenImploded := g_oCacic.implode(v_tstrCipherOpened,g_oCacic.getSeparatorKey);
       v_strCipherClosed := g_oCacic.enCrypt(v_strCipherOpenImploded);

       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}

       CloseFile(v_DatFile);
   except
        log_diario('Problema na gravação do arquivo de configurações.');
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
      Result := g_oCacic.explode('Configs.ID_SO' + g_oCacic.getSeparatorKey + g_oCacic.getWindowsStrId() + g_oCacic.getSeparatorKey + 'Configs.Endereco_WS' + g_oCacic.getSeparatorKey + '/cacic2/ws/',g_oCacic.getSeparatorKey);

    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String);
begin
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        v_tstrCipherOpened.Add(p_Chave);
        v_tstrCipherOpened.Add(p_Valor);
      End;
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

function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
var RegEditSet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue : String;
    ListaAuxSet : TStrings;
    I : Integer;
begin
    ListaAuxSet := g_oCacic.explode(Chave, '\');
    strRootKey := ListaAuxSet[0];
    For I := 1 To ListaAuxSet.Count - 2 Do strKey := strKey + ListaAuxSet[I] + '\';
    strValue := ListaAuxSet[ListaAuxSet.Count - 1];

    RegEditSet := TRegistry.Create;
    try
        RegEditSet.Access := KEY_WRITE;
        RegEditSet.Rootkey := GetRootKey(strRootKey);

        if RegEditSet.OpenKey(strKey, True) then
        Begin
            RegDataType := RegEditSet.GetDataType(strValue);
            if RegDataType = rdString then
              begin
                RegEditSet.WriteString(strValue, Dado);
              end
            else if RegDataType = rdExpandString then
              begin
                RegEditSet.WriteExpandString(strValue, Dado);
              end
            else if RegDataType = rdInteger then
              begin
                RegEditSet.WriteInteger(strValue, Dado);
              end
            else
              begin
                RegEditSet.WriteString(strValue, Dado);
              end;

        end;
    finally
      RegEditSet.CloseKey;
    end;
    ListaAuxSet.Free;
    RegEditSet.Free;
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

//Para buscar do RegEdit...
function GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    ListaAuxGet := g_oCacic.explode(Chave, '\');

    strRootKey := ListaAuxGet[0];
    For I := 1 To ListaAuxGet.Count - 2 Do strKey := strKey + ListaAuxGet[I] + '\';
    strValue := ListaAuxGet[ListaAuxGet.Count - 1];
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


function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
//function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
    v_SectionName := '[' + p_Secao + ']';
    v_Size_Section := strLen(PChar(v_SectionName));
    v_KeyName := p_Chave + '=';
    v_Size_Key     := strLen(PChar(v_KeyName));
    FileText := TStringList.Create;
    if (FileExists(p_File)) then
      Begin
        try
          FileText.LoadFromFile(p_File);
          For i := 0 To FileText.Count - 1 Do
            Begin
              if (LowerCase(Trim(PChar(Copy(FileText[i],1,v_Size_Section)))) = LowerCase(Trim(PChar(v_SectionName)))) then
                Begin
                  For j := i to FileText.Count - 1 Do
                    Begin
                      if (LowerCase(Trim(PChar(Copy(FileText[j],1,v_Size_Key)))) = LowerCase(Trim(PChar(v_KeyName)))) then
                        Begin
                          Result := PChar(Copy(FileText[j],v_Size_Key + 1,strLen(PChar(FileText[j]))-v_Size_Key));
                          Break;
                        End;
                    End;
                End;
              if (Result <> '') then break;
            End;
        finally
          FileText.Free;
        end;
      end
    else FileText.Free;
  end;


Procedure DelValorReg(Chave: String);
var RegDelValorReg: TRegistry;
    strRootKey, strKey, strValue : String;
    ListaAuxDel : TStrings;
    I : Integer;
begin
    ListaAuxDel := g_oCacic.explode(Chave, '\');
    strRootKey := ListaAuxDel[0];
    For I := 1 To ListaAuxDel.Count - 2 Do strKey := strKey + ListaAuxDel[I] + '\';
    strValue := ListaAuxDel[ListaAuxDel.Count - 1];
    RegDelValorReg := TRegistry.Create;

    try
        RegDelValorReg.Access := KEY_WRITE;
        RegDelValorReg.Rootkey := GetRootKey(strRootKey);

        if RegDelValorReg.OpenKey(strKey, True) then
        RegDelValorReg.DeleteValue(strValue);
    finally
      RegDelValorReg.CloseKey;
    end;
    RegDelValorReg.Free;
    ListaAuxDel.Free;
end;
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
        log_DEBUG('Size de "'+p_File+'" Antes do FTP => '+IntToSTR(IdFTP.Size(p_File)));
        msg_error := 'Falha ao tentar obter arquivo no servidor FTP: "' + p_File + '"';
        IdFTP.Get(p_File, p_Dest + '\' + p_File, True);
        log_DEBUG('Size de "'+p_Dest + '\' + p_File +'" Após o FTP   => '+Get_File_Size(p_Dest + '\' + p_File,true));
      Finally
        log_DEBUG('Size de "'+p_Dest + '\' + p_File +'" Após o FTP em Finally   => '+Get_File_Size(p_Dest + '\' + p_File,true));
        idFTP.Disconnect;
        result := true;
      End;
    Except
        log_diario(msg_error);
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

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{For Windows 9x/ME/2000/XP }
function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

// Rotina obtida em http://www.swissdelphicenter.ch/torry/showcode.php?id=266
{ For Windows NT/2000/XP }
procedure KillProcess(hWindowHandle: HWND);
var
  hprocessID: INTEGER;
  processHandle: THandle;
  DWResult: DWORD;
begin
  SendMessageTimeout(hWindowHandle, WM_DDE_TERMINATE, 0, 0,
    SMTO_ABORTIFHUNG or SMTO_NORMAL, 5000, DWResult);

  if isWindow(hWindowHandle) then
  begin
    // PostMessage(hWindowHandle, WM_QUIT, 0, 0);

    { Get the process identifier for the window}
    GetWindowThreadProcessID(hWindowHandle, @hprocessID);
    if hprocessID <> 0 then
    begin
      { Get the process handle }
      processHandle := OpenProcess(PROCESS_TERMINATE or PROCESS_QUERY_INFORMATION,
        False, hprocessID);
      if processHandle <> 0 then
      begin
        { Terminate the process }
        TerminateProcess(processHandle, 0);
        CloseHandle(ProcessHandle);
      end;
    end;
  end;
end;


// Dica baixada de http://procedure.blig.ig.com.br/
// Adaptada por Anderson Peterle - v:2.2.0.16 - 03/2007
procedure Matar(v_dir,v_files: string);
var SearchRec: TSearchRec;
    Result: Integer;
    strFileName : String;
begin
  strFileName := StringReplace(v_dir + '\' + v_files,'\\','\',[rfReplaceAll]);
  Result:=FindFirst(strFileName, faAnyFile, SearchRec);

  while result=0 do
    begin
      strFileName := StringReplace(v_dir + '\' + SearchRec.Name,'\\','\',[rfReplaceAll]);

      if not DeleteFile(strFileName) then
        Begin
          if (not g_oCacic.isWindowsNTPlataform()) then // Menor que NT Like
            KillTask(SearchRec.Name)
          else
            KillProcess(FindWindow(PChar(SearchRec.Name),nil));
            DeleteFile(strFileName);
        End;

      Result:=FindNext(SearchRec);
    end;
end;

function Posso_Rodar_CACIC : boolean;
Begin
  result := false;

  // Se o aguarde_CACIC.txt existir é porque refere-se a uma versão mais atual: 2.2.0.20 ou maior
  if  (FileExists(g_oCacic.getCacicPath + 'aguarde_CACIC.txt')) then
    Begin
      // Se eu conseguir matar o arquivo abaixo é porque não há outra sessão deste agente aberta... (POG? Nããão!  :) )
      Matar(g_oCacic.getCacicPath,'aguarde_CACIC.txt');
      if  (not (FileExists(g_oCacic.getCacicPath + 'aguarde_CACIC.txt'))) then
        result := true;
    End;
End;

Function ChecaVersoesAgentes(p_strNomeAgente : String) : integer;
var v_versao_REM,
    v_versao_LOC,
    strNomeAgente : String;
    v_array_NomeAgente : TStrings;
    intAux : integer;
Begin
  v_array_NomeAgente := g_oCacic.explode(p_strNomeAgente,'\');

  v_versao_REM := XML_RetornaValor(StringReplace(StrUpper(PChar(v_array_NomeAgente[v_array_NomeAgente.count-1])),'.EXE','',[rfReplaceAll]), v_retorno);
  v_versao_LOC := GetVersionInfo(p_strNomeAgente);

  log_diario('Checando versão de "'+p_strNomeAgente+'"');

  intAux := v_array_NomeAgente.Count;

  // V: 2.2.0.16
  // Verifico existência do arquivo "versoes_agentes.ini" para comparação das versões dos agentes principais
  if (v_versao_REM = '') AND FileExists(ExtractFilePath(Application.Exename)+'versoes_agentes.ini') then
    Begin
      if (GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
        Begin
          log_diario('Encontrado arquivo "'+(ExtractFilePath(Application.Exename)+'versoes_agentes.ini')+'"');
          v_versao_REM := GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
        End;
    End;

  log_diario('Versão Remota: "'+v_versao_REM+'" - Versão Local: "'+v_versao_LOC+'"');

  if (v_versao_REM + v_versao_LOC <> '') and
     (v_versao_LOC <> '0000') then
    Begin
      if (v_versao_REM = v_versao_LOC) then
        Result := 1
      else
        Result := 2;
    End
  else
    Result := 0;
End;

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

procedure executa_chksis;
var
  bool_download_CACIC2,
  bool_ExistsAutoRun : boolean;
  v_ip_serv_cacic, v_cacic_dir, v_rem_cacic_v0x,
  v_te_serv_updates, v_nu_porta_serv_updates, v_nm_usuario_login_serv_updates,
  v_te_senha_login_serv_updates, v_te_path_serv_updates : String;
  Request_Config : TStringList;
  Response_Config : TStringStream;
  IdHTTP1: TIdHTTP;
  intAux : integer;
begin

  bool_download_CACIC2  := false;
  v_ip_serv_cacic    := GetValorChaveRegIni('Cacic2', 'ip_serv_cacic', ExtractFilePath(ParamStr(0)) + 'chksis.ini');
  v_cacic_dir        := GetValorChaveRegIni('Cacic2', 'cacic_dir'    , ExtractFilePath(ParamStr(0)) + 'chksis.ini');
  v_rem_cacic_v0x    := GetValorChaveRegIni('Cacic2', 'rem_cacic_v0x', ExtractFilePath(ParamStr(0)) + 'chksis.ini');

  g_oCacic.setCacicPath(TrataCacicDir(v_cacic_dir));

  v_Debugs := false;
  if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
      Begin
       if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
         Begin
           v_Debugs := true;
           log_DEBUG('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
         End;
      End;

  log_DEBUG('setCacicPath "'+g_oCacic.getCacicPath+'"');

  log_DEBUG('Verificando recepção do parâmetro rem_cacic_v0x...');
  // Caso o parâmetro rem_cacic_v0x seja "S/s" removo a chave/valor de execução do Cacic antigo
  if (LowerCase(v_rem_cacic_v0x)='s') then
      begin
        log_DEBUG('Excluindo chave de execução do CACIC');
        DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic');
      end;

  log_DEBUG('Verificando existência da pasta "'+g_oCacic.getCacicPath+'"');
  // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(g_oCacic.getCacicPath) then
      begin
        log_DEBUG('Criando diretório ' + g_oCacic.getCacicPath);
        ForceDirectories(g_oCacic.getCacicPath);
      end;

  log_DEBUG('Verificando existência da pasta "'+g_oCacic.getCacicPath+'modulos"');
  // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
  if not DirectoryExists(g_oCacic.getCacicPath+'modulos') then
      begin
        log_DEBUG('Excluindo '+ g_oCacic.getCacicPath + 'cacic2.exe');
        Matar(g_oCacic.getCacicPath,'cacic2.exe');
        log_DEBUG('Criando diretório ' + g_oCacic.getCacicPath + 'modulos');
        ForceDirectories(g_oCacic.getCacicPath + 'modulos');
      end;

  log_DEBUG('Verificando existência da pasta "'+g_oCacic.getCacicPath+'temp"');
  // Crio o SubDiretório TEMP, caso não exista
  if not DirectoryExists(g_oCacic.getCacicPath+'temp') then
      begin
        log_DEBUG('Criando diretório ' + g_oCacic.getCacicPath + 'temp');
        ForceDirectories(g_oCacic.getCacicPath + 'temp');
      end;

  log_DEBUG('Verificando existência dos agentes principais "'+g_oCacic.getCacicPath+'cacic2.exe" e "'+g_oCacic.getCacicPath + 'modulos\ger_cols.exe"');
  // Verifico existência dos dois principais objetos
  If (not FileExists(g_oCacic.getCacicPath + 'cacic2.exe')) or (not FileExists(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')) Then
      Begin
        // Busco as configurações para acesso ao ambiente FTP - Updates
        Request_Config                        := TStringList.Create;
        Request_Config.Values['in_chkcacic']  := 'chkcacic';
        Request_Config.Values['te_fila_ftp']  := '1'; // Indicará que o agente quer entrar no grupo para FTP
        Request_Config.Values['id_ip_estacao']:= GetIP; // Informará o IP para registro na tabela redes_grupos_FTP
        Response_Config                       := TStringStream.Create('');

        Try
          log_diario('Tentando contato com ' + 'http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php');
          IdHTTP1 := TIdHTTP.Create(nil);
          IdHTTP1.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php', Request_Config, Response_Config);
          IdHTTP1.Disconnect;
          IdHTTP1.Free;
          v_retorno := Response_Config.DataString;
          v_te_serv_updates               := XML_RetornaValor('te_serv_updates'              , Response_Config.DataString);
          v_nu_porta_serv_updates         := XML_RetornaValor('nu_porta_serv_updates'        , Response_Config.DataString);
          v_nm_usuario_login_serv_updates := XML_RetornaValor('nm_usuario_login_serv_updates', Response_Config.DataString);
          v_te_senha_login_serv_updates   := XML_RetornaValor('te_senha_login_serv_updates'  , Response_Config.DataString);
          v_te_path_serv_updates          := XML_RetornaValor('te_path_serv_updates'         , Response_Config.DataString);

          log_DEBUG(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          log_DEBUG(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
          log_DEBUG(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          log_DEBUG('Servidor de updates......................: '+v_te_serv_updates);
          log_DEBUG('Porta do servidor de updates.............: '+v_nu_porta_serv_updates);
          log_DEBUG('Usuário para login no servidor de updates: '+v_nm_usuario_login_serv_updates);
          log_DEBUG('Pasta no servidor de updates.............: '+v_te_path_serv_updates);
          log_DEBUG(' ');
          log_DEBUG('Versões dos Agentes Principais:');
          log_DEBUG('------------------------------');
          log_DEBUG('Cacic2   - Agente do Systray.........: '+XML_RetornaValor('CACIC2', v_retorno));
          log_DEBUG('Ger_Cols - Gerente de Coletas........: '+XML_RetornaValor('GER_COLS', v_retorno));
          log_DEBUG('ChkSis   - Verificador de Integridade: '+XML_RetornaValor('CHKSIS', v_retorno));
          log_DEBUG(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

        Except log_DEBUG('Falha no contato com ' + 'http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php');
        End;

        Request_Config.Free;
        Response_Config.Free;

  log_DEBUG('Verificando existência do agente "'+g_oCacic.getCacicPath+'cacic2.exe"');
  // Verificação de versão do cacic2.exe e exclusão em caso de versão antiga
  If (FileExists(g_oCacic.getCacicPath + 'cacic2.exe')) Then
      Begin
        intAux := ChecaVersoesAgentes(g_oCacic.getCacicPath + 'cacic2.exe');
        // 0 => Arquivo de versões ou informação inexistente
        // 1 => Versões iguais
        // 2 => Versões diferentes
        if (intAux = 0) then
          Begin
            v_versao_local  := StringReplace(trim(GetVersionInfo(g_oCacic.getCacicPath + 'cacic2.exe')),'.','',[rfReplaceAll]);
            v_versao_remota := StringReplace(XML_RetornaValor('CACIC2' , v_retorno),'0103','',[rfReplaceAll]);
          End;

        if (intAux = 2) or // Caso haja diferença na comparação de versões com "versoes_agentes.ini"...
           (v_versao_local ='0000') or // Provavelmente versão muito antiga ou corrompida
           (v_versao_local ='2208') then
           Matar(g_oCacic.getCacicPath, 'cacic2.exe');
      End;

    log_DEBUG('Verificando existência do agente "'+g_oCacic.getCacicPath+'modulos\ger_cols.exe"');
    // Verificação de versão do ger_cols.exe e exclusão em caso de versão antiga
    If (FileExists(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')) Then
        Begin
          intAux := ChecaVersoesAgentes(g_oCacic.getCacicPath + 'modulos\ger_cols.exe');
          // 0 => Arquivo de versões ou informação inexistente
          // 1 => Versões iguais
          // 2 => Versões diferentes
          if (intAux = 0) then
            Begin
              v_versao_local  := StringReplace(trim(GetVersionInfo(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')),'.','',[rfReplaceAll]);
              v_versao_remota := StringReplace(XML_RetornaValor('GER_COLS' , v_retorno),'0103','',[rfReplaceAll]);
            End;

          if (intAux = 2) or // Caso haja diferença na comparação de versões com "versoes_agentes.ini"...
             (v_versao_local ='0000') then // Provavelmente versão muito antiga ou corrompida
             Matar(g_oCacic.getCacicPath + 'modulos\', 'ger_cols.exe');

        End;

      log_DEBUG('Nova Verificação de existência do agente "'+g_oCacic.getCacicPath+'cacic2.exe"');
      // Tento detectar o Agente Principal e faço FTP caso não exista
      If not FileExists(g_oCacic.getCacicPath + 'cacic2.exe') Then
          begin
            log_diario('Fazendo FTP de cacic2.exe a partir de ' + v_te_serv_updates + '/' +
                                                                  v_nu_porta_serv_updates+'/'+
                                                                  v_nm_usuario_login_serv_updates + '/' +
                                                                  v_te_path_serv_updates + ' para a pasta ' + g_oCacic.getCacicPath);
            FTP(v_te_serv_updates,
                v_nu_porta_serv_updates,
                v_nm_usuario_login_serv_updates,
                v_te_senha_login_serv_updates,
                v_te_path_serv_updates,
                'cacic2.exe',
                g_oCacic.getCacicPath);
            bool_download_CACIC2 := true;
          end;

      log_DEBUG('Nova Verificação de existência do agente "'+g_oCacic.getCacicPath+'modulos\ger_cols.exe"');
      // Tento detectar o Gerente de Coletas e faço FTP caso não exista
      If (not FileExists(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')) Then
          begin
            log_diario('Fazendo FTP de ger_cols.exe a partir de ' + v_te_serv_updates + '/' +
                                                                    v_nu_porta_serv_updates+'/'+
                                                                    v_nm_usuario_login_serv_updates + '/' +
                                                                    v_te_path_serv_updates + ' para a pasta ' + g_oCacic.getCacicPath + 'modulos');

            FTP(v_te_serv_updates,
                v_nu_porta_serv_updates,
                v_nm_usuario_login_serv_updates,
                v_te_senha_login_serv_updates,
                v_te_path_serv_updates,
                'ger_cols.exe',
                g_oCacic.getCacicPath + 'modulos');
          end;


      End;

  // 5 segundos para espera de possível FTP...
  Sleep(5000);

  // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
  if Posso_Rodar_CACIC or not bool_ExistsAutoRun then
    Begin
      log_diario('Executando '+g_oCacic.getCacicPath + 'cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic);

      // Caso tenha havido download de agentes principais, executar coletas imediatamente...
      if (bool_download_CACIC2) then
        g_oCacic.createSampleProcess(g_oCacic.getCacicPath + 'cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic+ ' /execute', false)
      else
        g_oCacic.createSampleProcess(g_oCacic.getCacicPath + 'cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic             , false);
    End;
end;

const
  CACIC_APP_NAME = 'chksis';

begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) )
     then begin
       if (FindWindowByTitle('chkcacic') = 0) and (FindWindowByTitle('cacic2') = 0)
         then
           if (FileExists(ExtractFilePath(ParamStr(0)) + 'chksis.ini'))
              then executa_chksis
              else log_diario('Não executei devido execução em paralelo de "chkcacic" ou "cacic2"!');
     end;

   g_oCacic.Free();

end.

