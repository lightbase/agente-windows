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
======================================================================================================
ChkCacic.exe : Verificador/Instalador dos agentes principais Cacic2.exe, Ger_Cols.exe e SrCacicSrv.exe
======================================================================================================

v 2.2.0.38
+ Acrescentado a obtenção de versão interna do S.O.
+ Acrescentado a inserção dos agentes principais nas exceções do FireWall interno do MS-Windows VISTA...
.
Diversas rebuilds...
.
v 2.2.0.17
+ Acrescentado o tratamento da passagem de opções em linha de comando
  * chkcacic /serv=<ip_server> /dir=<local_path>c:\%windir%\cacic
  Exemplo de uso: chkcacic /serv=UXbra001 /dir=Cacic

v 2.2.0.16
* Corrigido o fechamento do arquivo de configurações de ChkSis

v 2.2.0.15
* Substituída a mensagem "File System diferente de "NTFS" por 'File System: "<NomeFileSystem>" - Ok!'

v 2.2.0.14
+ Críticas/mensagens:
  "ATENÇÃO! Não foi possível estabelecer comunicação com o módulo Gerente WEB em <servidor>." e
  "ATENÇÃO: Não foi possível efetuar FTP para <agente>. Verifique o Servidor de Updates."
+ Opção checkbox "Exibe informações sobre o processo de instalação" ao formulário de configuração;
+ Botão "Sair" ao formulário de configuração;
+ Execução automática do Agente Principal ao fim da instalação quando a unidade origem do ChkCacic não
  for mapeamento de rede ou unidade inválida.

- Retirados os campos "Frase para Sucesso na Instalação" e "Frase para Insucesso na Instalação"
  do formulário de configuração, passando essas frases a serem fixas na aplicação.
- Retirada a opção radiobutton "Remove Versão Anterior?";

=====================================================================================================
*)


unit main;

interface

uses
  Windows,
  strUtils,
  SysUtils,
  Classes,
  Forms,
  Registry,
  Inifiles,
  idFTPCommon,
  XML,
  LibXmlParser,
  idHTTP,
  PJVersionInfo,
  Controls,
  StdCtrls,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  variants,
  NTFileSecurity,
  IdFTP,
  Tlhelp32,
  ExtCtrls,
  Dialogs,
  CACIC_Library,
  WinSvc;

var
  v_ip_serv_cacic,
  v_te_instala_frase_sucesso,
  v_te_instala_frase_insucesso,
  v_te_instala_informacoes_extras,
  v_exibe_informacoes,
  v_versao_local,
  v_versao_remota,
  v_strCipherClosed,
  v_strCipherOpened,
  v_versao_REM,
  v_versao_LOC,
  v_retorno                 : String;

var
  v_Debugs                  : boolean;

var
  v_tstrCipherOpened        : TStrings;

var
  g_oCacic: TCACIC;  /// Biblioteca CACIC_Library

Procedure chkcacic;
procedure ComunicaInsucesso(strIndicador : String); //2.2.0.32
Procedure CriaFormConfigura;
Procedure DelValorReg(Chave: String);
Procedure GravaConfiguracoes;
procedure GravaIni(strFullPath : STring);
procedure KillProcess(hWindowHandle: HWND); // 2.2.0.15
procedure LogDebug(p_msg:string);
procedure LogDiario(strMsg : String);
procedure Matar(v_dir,v_files: string); // 2.2.0.16
Procedure MostraFormConfigura;

Function ChecaVersoesAgentes(p_strNomeAgente : String) : integer; // 2.2.0.16
Function FindWindowByTitle(WindowTitle: string): Hwnd;
Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
function GetFolderDate(Folder: string): TDateTime;
function GetNetworkUserName : String; // 2.2.0.32
Function GetRootKey(strRootKey: String): HKEY;
Function GetValorChaveRegEdit(Chave: String): Variant;
Function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
Function GetVersionInfo(p_File: string):string;
Function KillTask(ExeFileName: string): Integer;
Function ListFileDir(Path: string):string;
function Posso_Rodar_CACIC : boolean;
Function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
Function SetValorChaveRegIni(p_Secao, p_Chave, p_Valor, p_File : String): String;
Function RemoveCaracteresEspeciais(Texto : String) : String;
Function VerFmt(const MS, LS: DWORD): string;
function ServiceStart(sService : string ) : boolean;
function ServiceRunning(sMachine, sService: PChar): Boolean;
function ServiceStopped(sMachine, sService: PChar): Boolean;

type
  TForm1 = class(TForm)
    PJVersionInfo1: TPJVersionInfo;
    IdFTP1: TIdFTP;
    FS: TNTFileSecurity;
    procedure FormCreate(Sender: TObject);
    procedure FS_SetSecurity(p_Target : String);
  end;

var
  Form1: TForm1;
  ENDERECO_SERV_CACIC : string;
implementation

uses FormConfig;

{$R *.dfm}

function ServiceGetStatus(sMachine, sService: PChar): DWORD;
  {******************************************}
  {*** Parameters: ***}
  {*** sService: specifies the name of the service to open
  {*** sMachine: specifies the name of the target computer
  {*** ***}
  {*** Return Values: ***}
  {*** -1 = Error opening service ***}
  {*** 1 = SERVICE_STOPPED ***}
  {*** 2 = SERVICE_START_PENDING ***}
  {*** 3 = SERVICE_STOP_PENDING ***}
  {*** 4 = SERVICE_RUNNING ***}
  {*** 5 = SERVICE_CONTINUE_PENDING ***}
  {*** 6 = SERVICE_PAUSE_PENDING ***}
  {*** 7 = SERVICE_PAUSED ***}
  {******************************************}
var
  SCManHandle, SvcHandle: SC_Handle;
  SS: TServiceStatus;
  dwStat: DWORD;
begin
  dwStat := 0;
  // Open service manager handle.
  LogDEBUG('Executando OpenSCManager.SC_MANAGER_CONNECT');
  SCManHandle := OpenSCManager(sMachine, nil, SC_MANAGER_CONNECT);
  if (SCManHandle > 0) then
  begin
    LogDEBUG('Executando OpenService.SERVICE_QUERY_STATUS');
    SvcHandle := OpenService(SCManHandle, sService, SERVICE_QUERY_STATUS);
    // if Service installed
    if (SvcHandle > 0) then
    begin
      LogDEBUG('O serviço "'+ sService +'" já está instalado.');
      // SS structure holds the service status (TServiceStatus);
      if (QueryServiceStatus(SvcHandle, SS)) then
        dwStat := ss.dwCurrentState;
      CloseServiceHandle(SvcHandle);
    end;
    CloseServiceHandle(SCManHandle);
  end;
  Result := dwStat;
end;

// start service
//
// return TRUE if successful
//
// sService
//   service name, ie: Alerter
//
function ServiceStart(sService : string ) : boolean;
var schm,
    schs   : SC_Handle;

    ss     : TServiceStatus;
    psTemp : PChar;
    dwChkP : DWord;
begin
  ss.dwCurrentState := 0;

  logDEBUG('Executando Service Start');

  // connect to the service control manager
  schm := OpenSCManager(Nil,Nil,SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
    begin
      // open a handle to the specified service
      schs := OpenService(schm,PChar(sService),SERVICE_START or SERVICE_QUERY_STATUS);

      // if successful...
    if(schs > 0)then
      begin
        logDEBUG('Open Service OK');
        psTemp := Nil;
        if(StartService(schs,0,psTemp)) then
          begin
            logDEBUG('Entrando em Start Service');
            // check status
            if(QueryServiceStatus(schs,ss))then
              begin
                while(SERVICE_RUNNING <> ss.dwCurrentState)do
                  begin
                  // dwCheckPoint contains a value that the service increments periodically
                  // to report its progress during a lengthy operation.
                  dwChkP := ss.dwCheckPoint;

                  // wait a bit before checking status again
                  // dwWaitHint is the estimated amount of time the calling program should wait before calling
                  // QueryServiceStatus() again idle events should be handled here...

                  Sleep(ss.dwWaitHint);

                  if(not QueryServiceStatus(schs,ss))then
                    begin
                      break;
                    end;

                  if(ss.dwCheckPoint < dwChkP)then
                    begin
                      // QueryServiceStatus didn't increment dwCheckPoint as it should have.
                      // avoid an infinite loop by breaking
                      break;
                    end;
                end;
            end
        else
           logDEBUG('Oops! Problema com StartService!');
        end;

        // close service handle
        CloseServiceHandle(schs);
      end;

      // close service control manager handle
      CloseServiceHandle(schm);
    end
  else
    Configs.Memo_te_instala_informacoes_extras.Lines.Add('Oops! Problema com o Service Control Manager!');
    // return TRUE if the service status is running
    Result := SERVICE_RUNNING = ss.dwCurrentState;
end;

function GetNetworkUserName : String;
  //  Gets the name of the user currently logged into the network on
  //  the local PC
var
  temp: PChar;
  Ptr: DWord;
const
  buff = 255;
begin
  ptr := buff;
  temp := StrAlloc(buff);
  GetUserName(temp, ptr);
  Result := string(temp);
  StrDispose(temp);
end;

procedure ComunicaInsucesso(strIndicador : String);
var IdHTTP2: TIdHTTP;
    Request_Config  : TStringList;
    Response_Config : TStringStream;
begin

  // Envio notificação de insucesso para o Módulo Gerente Centralizado
  Request_Config                                 := TStringList.Create;
  Request_Config.Values['cs_indicador']          := strIndicador;
  Request_Config.Values['id_usuario']            := GetNetworkUserName();
  Request_Config.Values['te_so']                 := g_oCacic.getWindowsStrId();
  Response_Config                                := TStringStream.Create('');
  Try
    Try
      IdHTTP2 := TIdHTTP.Create(nil);
      IdHTTP2.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/instalacacic.php', Request_Config, Response_Config);
      IdHTTP2.Free;
      Request_Config.Free;
      Response_Config.Free;
    Except
    End;
  finally
    Begin
      IdHTTP2.Free;
      Request_Config.Free;
      Response_Config.Free;
    End;
  End;
end;

procedure LogDiario(strMsg : String);
var
    HistoricoLog : TextFile;
begin
   try
       FileSetAttr (g_oCacic.getHomeDrive + 'chkcacic.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,g_oCacic.getHomeDrive + 'chkcacic.log'); {Associa o arquivo a uma variável do tipo TextFile}

       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}

       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Instalador] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
       //Erro na gravação do log!
   end;
   try
      Configs.Memo_te_instala_informacoes_extras.Lines.Add(strMsg);
   except
   end;
end;

procedure LogDebug(p_msg:string);
Begin
  if v_Debugs then
    Begin
      LogDiario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
    End;
End;

Function CipherClose(p_DatFileName : string) : String;
var v_strCipherOpenImploded : string;
    v_DatFile : TextFile;
begin
   try
       FileSetAttr (p_DatFileName,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(v_DatFile,p_DatFileName); {Associa o arquivo a uma variável do tipo TextFile}

       // Recriação do arquivo .DAT
       Rewrite (v_DatFile);
       Append(v_DatFile);

       v_strCipherOpenImploded := g_oCacic.implode(v_tstrCipherOpened,g_oCacic.getSeparatorKey);
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
  LogDebug('Tentando acessar configurações em '+g_oCacic.getCacicPath + g_oCacic.getDatFileName);
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
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey+ g_oCacic.getWindowsStrId() +g_oCacic.getSeparatorKey+'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);

    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String);
begin
    LogDebug('Setando Chave "'+p_Chave+'" com "'+p_Valor+'"');
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        v_tstrCipherOpened.Add(p_Chave);
        v_tstrCipherOpened.Add(p_Valor);
      End;
end;

Function GetValorDatMemoria(p_Chave : String) : String;
begin
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
end;


function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;



function GetVersionInfo(p_File: string):string;
begin
  Form1.PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(Form1.PJVersionInfo1.FixedFileInfo.dwFileVersionMS, Form1.PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
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
    For I := 1 To ListaAuxSet.Count - 2 do
      strKey := strKey + ListaAuxSet[I] + '\';
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
    LogDebug('Setando valor "'+Dado+'" para chave "'+Chave+'"');
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
    ListaAuxGet := g_oCacic.Explode(Chave, '\');

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

//Para gravar no Arquivo INI...
function SetValorChaveRegIni(p_Secao, p_Chave, p_Valor, p_File : String): String;
var Reg_Ini     : TIniFile;
begin
    if (FileGetAttr(p_File) and faReadOnly) > 0 then
      FileSetAttr(p_File, FileGetAttr(p_File) xor faReadOnly);

    Reg_Ini := TIniFile.Create(p_File);
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
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

Procedure CriaFormConfigura;
begin
  LogDebug('Chamando Criação do Formulário de Configurações - 1');
  Application.CreateForm(TConfigs, FormConfig.Configs);
  FormConfig.Configs.lbVersao.Caption := 'v: ' + getVersionInfo(ParamStr(0));
end;

Procedure MostraFormConfigura;
begin
  LogDebug('Exibindo formulário de configurações');
  FormConfig.Configs.ShowModal;
end;

Function Explode(Texto, Separador : String) : TStrings;
var
    strItem       : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres,
    TamanhoSeparador,
    I : Integer;
Begin
    ListaAuxUTILS    := TStringList.Create;
    strItem          := '';
    NumCaracteres    := Length(Texto);
    TamanhoSeparador := Length(Separador);
    I                := 1;
    While I <= NumCaracteres Do
      Begin
        If ((Copy(Texto,I,TamanhoSeparador) = Separador) and (Texto[I-1]<>'?')) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + Texto[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
          if (Texto[I]<>'?') then strItem := strItem + Texto[I];
        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
end;

Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
var IdFTP : TIdFTP;
begin
  Try
    LogDebug('FTP: Criando instance');

    IdFTP               := TIdFTP.Create(nil);

    LogDebug('FTP: Host       => "'+p_Host+'"');
    IdFTP.Host          := p_Host;

    LogDebug('FTP: UserName   => "'+p_Username+'"');
    IdFTP.Username      := p_Username;

    LogDebug('FTP: PassWord   => "**********"');
    IdFTP.Password      := p_Password;

    LogDebug('FTP: PathServer => "'+p_PathServer+'"');
    IdFTP.Port          := strtoint(p_Port);

    LogDebug('FTP: Setando TransferType para "ftBinary"');
    IdFTP.TransferType  := ftBinary;

    LogDebug('FTP: Setando Passive para "true"');
    IdFTP.Passive := true;

    LogDebug('FTP: Change to "'+p_PathServer+'"');
    Try
      if IdFTP.Connected = true then
        begin
          LogDebug('FTP: Connected => Desconectando...');
          IdFTP.Disconnect;
        end;
      LogDebug('FTP: Efetuando Conexão...');
      IdFTP.Connect(true);
      LogDebug('FTP: Change to "'+p_PathServer+'"');
      IdFTP.ChangeDir(p_PathServer);
      Try
        LogDebug('Iniciando FTP de "'+p_Dest + p_File+'"');
        LogDebug('HashCode de "'+p_File+'" Antes do FTP => '+g_oCacic.GetFileHash(p_Dest + p_File));
        IdFTP.Get(p_File, p_Dest + p_File, True, True);
        LogDebug('HashCode de "'+p_Dest + p_File +'" Após o FTP   => '+g_oCacic.GetFileHash(p_Dest + p_File));
      Finally
          LogDebug('HashCode de "'+p_Dest + p_File +'" Após o FTP em Finally   => '+g_oCacic.GetFileHash(p_Dest + p_File));
          IdFTP.Disconnect;
          IdFTP.Free;
          result := true;
      End;
    Except
      Begin
        LogDebug('Oops! Problemas Sem Início de FTP...');
        result := false;
      End;
    end;
  Except
    result := false;
  End;
end;

procedure GravaConfiguracoes;
var chkcacic_ini : TextFile;
begin
   try
       LogDebug('g_ocacic => setCacicpath => '+Configs.Edit_cacic_dir.text+'\');

       FileSetAttr (ExtractFilePath(Application.Exename) + '\chkcacic.ini',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(chkcacic_ini,ExtractFilePath(Application.Exename) + '\chkcacic.ini'); {Associa o arquivo a uma variável do tipo TextFile}
       Rewrite (chkcacic_ini); // Recria o arquivo...
       Append(chkcacic_ini);
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# A edição deste arquivo também pode ser feita com o comando "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OBRIGATÓRIOS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# ip_serv_cacic');
       Writeln(chkcacic_ini,'#          Endereço IP ou Nome(DNS) do servidor onde o Módulo Gerente do CACIC foi instalado');
       Writeln(chkcacic_ini,'#          Ex1.: ip_serv_cacic=10.xxx.yyy.zzz');
       Writeln(chkcacic_ini,'#          Ex2.: ip_serv_cacic=uxesa001');
       Writeln(chkcacic_ini,'# cacic_dir');
       Writeln(chkcacic_ini,'#          Pasta a ser criada na estação para instalação do CACIC agente');
       Writeln(chkcacic_ini,'#          Ex.: cacic_dir=Cacic');
       Writeln(chkcacic_ini,'# exibe_informacoes');
       Writeln(chkcacic_ini,'#          Indicador de exibicao de informações sobre o processo de instalação');
       Writeln(chkcacic_ini,'#          Ex.: exibe_informacoes=N');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# CHAVES E VALORES OPCIONAIS PARA USO DO CHKCACIC.EXE');
       Writeln(chkcacic_ini,'# (ATENÇÃO: NÃO PREENCHER EM CASO DE CHKCACIC.INI PARA O NETLOGON!)');
       Writeln(chkcacic_ini,'# ===================================================================================');
       Writeln(chkcacic_ini,'# te_instala_informacoes_extras');
       Writeln(chkcacic_ini,'#          Informações a serem mostradas na janela de Instalação/Recuperação');
       Writeln(chkcacic_ini,'#          Ex.: Empresa-UF / Suporte Técnico');
       Writeln(chkcacic_ini,'#                  Emails: email_do_suporte@xxxxxx.yyy.zz, outro_email@outro_dominio.xxx.yy');
       Writeln(chkcacic_ini,'#                  Telefones: (xx) yyyy-zzzz  /  (xx) yyyy-zzzz');
       Writeln(chkcacic_ini,'#                  Endereço: Rua Nome_da_Rua, Nº 99999');
       Writeln(chkcacic_ini,'#                            Cidade/UF');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# Recomendação Importante:');
       Writeln(chkcacic_ini,'# =======================');
       Writeln(chkcacic_ini,'# Para benefício da rede local, criar uma pasta "modulos" no mesmo nível do chkcacic.exe, onde deverão');
       Writeln(chkcacic_ini,'# ser colocados todos os arquivos executáveis para uso do CACIC, pois, quando da necessidade de download');
       Writeln(chkcacic_ini,'# de módulo, o arquivo será apenas copiado e não será necessário o FTP:');
       Writeln(chkcacic_ini,'# cacic2.exe ............=> Agente Principal');
       Writeln(chkcacic_ini,'# ger_cols.exe ..........=> Gerente de Coletas');
       Writeln(chkcacic_ini,'# srcacicsrv.exe ........=> Suporte Remoto Seguro');
       Writeln(chkcacic_ini,'# chksis.exe ............=> Check System Routine (chkcacic residente)');
       Writeln(chkcacic_ini,'# ini_cols.exe ..........=> Inicializador de Coletas');
       Writeln(chkcacic_ini,'# wscript.exe ...........=> Motor de Execução de Scripts VBS');
       Writeln(chkcacic_ini,'# col_anvi.exe ..........=> Agente Coletor de Informações de Anti-Vírus');
       Writeln(chkcacic_ini,'# col_comp.exe ..........=> Agente Coletor de Informações de Compartilhamentos');
       Writeln(chkcacic_ini,'# col_hard.exe ..........=> Agente Coletor de Informações de Hardware');
       Writeln(chkcacic_ini,'# col_moni.exe ..........=> Agente Coletor de Informações de Sistemas Monitorados');
       Writeln(chkcacic_ini,'# col_patr.exe ..........=> Agente Coletor de Informações de Patrimônio e Localização Física');
       Writeln(chkcacic_ini,'# col_soft.exe ..........=> Agente Coletor de Informações de Software');
       Writeln(chkcacic_ini,'# col_undi.exe ..........=> Agente Coletor de Informações de Unidades de Disco');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Exemplo de estrutura para KIT (CD) de instalação');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# d:\chkcacic.exe');
       Writeln(chkcacic_ini,'# d:\chkcacic.ini');
       Writeln(chkcacic_ini,'#        \modulos');
       Writeln(chkcacic_ini,'#             cacic2.exe');
       Writeln(chkcacic_ini,'#             chksis.exe');
       Writeln(chkcacic_ini,'#             col_anvi.exe');
       Writeln(chkcacic_ini,'#             col_comp.exe');
       Writeln(chkcacic_ini,'#             col_hard.exe');
       Writeln(chkcacic_ini,'#             col_moni.exe');
       Writeln(chkcacic_ini,'#             col_patr.exe');
       Writeln(chkcacic_ini,'#             col_soft.exe');
       Writeln(chkcacic_ini,'#             col_undi.exe');
       Writeln(chkcacic_ini,'#             ger_cols.exe');
       Writeln(chkcacic_ini,'#             srcacicsrv.exe');
       Writeln(chkcacic_ini,'#             ini_cols.exe');
       Writeln(chkcacic_ini,'#             wscript.exe');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'# Obs.: Antes da gravação do CD ou imagem, é necessário executar "chkcacic.exe /config"');
       Writeln(chkcacic_ini,'# ===================================================================================================================');
       Writeln(chkcacic_ini,'');
       Writeln(chkcacic_ini,'[Cacic2]');

       // Atribuição dos valores do form FormConfig às variáveis...
       if Configs.ckboxExibeInformacoes.Checked then
         v_exibe_informacoes             := 'S'
       else
         v_exibe_informacoes             := 'N';

       v_ip_serv_cacic                 := Configs.Edit_ip_serv_cacic.text;
       v_te_instala_informacoes_extras := Configs.Memo_te_instala_informacoes_extras.Text;

       // Escrita dos parâmetros obrigatórios
       Writeln(chkcacic_ini,'ip_serv_cacic='+v_ip_serv_cacic);
       Writeln(chkcacic_ini,'cacic_dir='+g_oCacic.getHomeDrive + Configs.Edit_cacic_dir.text+'\');
       Writeln(chkcacic_ini,'exibe_informacoes='+v_exibe_informacoes);

       // Escrita dos valores opcionais quando existirem
       if (v_te_instala_informacoes_extras <>'') then
          Writeln(chkcacic_ini,'te_instala_informacoes_extras='+ StringReplace(v_te_instala_informacoes_extras,#13#10,'*13*10',[rfReplaceAll]));
       CloseFile(chkcacic_ini); {Fecha o arquivo texto}

       g_oCacic.setCacicPath(g_oCacic.getHomeDrive + Configs.Edit_cacic_dir.text+'\');
   except
   end;
end;

procedure GravaIni(strFullPath : STring);
var iniFile : TextFile;
begin
   try
       FileSetAttr (strFullPath,0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(iniFile,strFullPath); {Associa o arquivo a uma variável do tipo TextFile}
       Rewrite (iniFile); // Recria o arquivo...
       Append(iniFile);
       Writeln(iniFile,'');
       Writeln(iniFile,'[Cacic2]');
       Writeln(iniFile,'ip_serv_cacic='+v_ip_serv_cacic);
       Writeln(iniFile,'cacic_dir='+g_oCacic.getCacicPath);
       CloseFile(iniFile); {Fecha o arquivo texto}
   except
   end;
end;

Function ListFileDir(Path: string):string;
var
  SR: TSearchRec;
  FileList : string;
begin
  if FindFirst(Path, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) then
      begin
        if (FileList<>'') then FileList := FileList + '#';
        FileList := FileList + SR.Name;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
    Result := FileList;
  end;
end;
procedure LiberaFireWall(p_objeto:string);
begin
  LogDebug('Rotina para Liberação de FireWall...');
  Try
    if (g_oCacic.isWindowsGEVista()) then // Se >= WinVISTA...
      Begin
        if (trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll])))='') then
          Begin
            SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll]),p_objeto+'.exe:*:Enabled:'+p_objeto);
          End
        else
          LogDebug('Exceção para "'+p_objeto+'" já existente.');
      End
    else
      if (trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll])))='') then
        Begin
          SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List\'+StringReplace(p_objeto+'.exe','\','?\',[rfReplaceAll]),p_objeto+'.exe:*:Enabled:'+p_objeto);
        End
      else
        LogDebug('Exceção para "'+p_objeto+'" já existente.');
  Except
    LogDebug('Problema adicionando "'+p_objeto+'" à lista de exceções do FireWall!');
  End;
end;

Function ChecaVersoesAgentes(p_strNomeAgente : String) : integer; // 2.2.0.16
var strNomeAgente : String;
    v_array_NomeAgente : TStrings;
    intAux : integer;
Begin
  v_array_NomeAgente := explode(p_strNomeAgente,'\');

  v_versao_REM := XML_RetornaValor(StringReplace(StrUpper(PChar(v_array_NomeAgente[v_array_NomeAgente.count-1])),'.EXE','',[rfReplaceAll]), v_retorno);
  v_versao_LOC := GetVersionInfo(p_strNomeAgente);

  LogDebug('Checando versão de "'+p_strNomeAgente+'"');

  intAux := v_array_NomeAgente.Count;

  // V: 2.2.0.16
  // Verifico existência do arquivo "versoes_agentes.ini" para comparação das versões dos agentes principais
  if (v_versao_REM = '') AND FileExists(ExtractFilePath(Application.Exename)+'versoes_agentes.ini') then
    Begin
      if (GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
        Begin
          LogDebug('Encontrado arquivo "'+(ExtractFilePath(Application.Exename)+'versoes_agentes.ini')+'"');
          v_versao_REM := GetValorChaveRegIni('versoes_agentes',v_array_NomeAgente[intAux-1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
        End;
    End;

  LogDebug('Versão Remota: "'+v_versao_REM+'" - Versão Local: "'+v_versao_LOC+'"');

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

// Dica baixada de http://procedure.blig.ig.com.br/
// Adaptada por Anderson Peterle - v:2.2.0.16 - 03/2007
procedure Matar(v_dir,v_files: string);
var SearchRec: TSearchRec;
    Result: Integer;
    strFileName : String;
begin

  strFileName := StringReplace(v_dir + '\' + v_files,'\\','\',[rfReplaceAll]);
  LogDebug('Matando: '+strFileName);
  Result:=FindFirst(strFileName, faAnyFile, SearchRec);

  while result=0 do
    begin
      strFileName := StringReplace(v_dir + '\' + SearchRec.Name,'\\','\',[rfReplaceAll]);
      LogDebug('Tentando Excluir: '+strFileName);
      if DeleteFile(strFileName) then
        LogDebug('Exclusão de ' + strFileName + ' efetuada com sucesso!')
      else
        Begin
          LogDebug('Exclusão não efetuada! Provavelmente já esteja sendo executado...');
          LogDebug('Tentarei finalizar Tarefa/Processo...');
          if (not g_oCacic.isWindowsNTPlataform()) then // Menor que NT Like
            KillTask(SearchRec.Name)
          else
            KillProcess(FindWindow(PChar(SearchRec.Name),nil));

            if DeleteFile(strFileName) then
              LogDebug('Exclusão Impossibilitada de ' + strFileName + '!');
        End;

      Result:=FindNext(SearchRec);
    end;
end;

function Posso_Rodar_CACIC : boolean;
Begin
  result := false;

  // Se eu conseguir matar o arquivo abaixo é porque não há outra sessão deste agente aberta... (POG? Nããão!  :) )
  Matar(g_oCacic.getCacicPath,'aguarde_CACIC.txt');

  // Se o aguarde_CACIC.txt existir é porque refere-se a uma versão mais atual: 2.2.0.20 ou maior
  if  not (FileExists(g_oCacic.getCacicPath() + '\aguarde_CACIC.txt')) then
    result := true;
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

procedure verifyAndGet(p_strModuleName,
                       p_strFileHash,
                       p_strDestinationFolderName : String);
var v_strFileHash,
    v_strDestinationFolderName : String;
Begin
    v_strDestinationFolderName := p_strDestinationFolderName + '\';
    v_strDestinationFolderName := StringReplace(v_strDestinationFolderName,'\\','\',[rfReplaceAll]);

    LogDebug('Verificando módulo: '+v_strDestinationFolderName +p_strModuleName);
    // Verifico validade do Módulo e mato-o em caso negativo.
    v_strFileHash := g_oCacic.GetFileHash(v_strDestinationFolderName + p_strModuleName);

    LogDebug('verifyAndGet - HashCode Remot: "'+p_strFileHash+'"');
    LogDebug('verifyAndGet - HashCode Local: "'+v_strFileHash+'"');

    If (v_strFileHash <> p_strFileHash) then
      Matar(v_strDestinationFolderName, p_strModuleName);

    If not FileExists(v_strDestinationFolderName + p_strModuleName) Then
      Begin
        if (FileExists(ExtractFilePath(Application.Exename) + '\modulos\'+p_strModuleName)) then
          Begin
            LogDebug('Copiando '+p_strModuleName+' de '+ExtractFilePath(Application.Exename)+'modulos\');
            CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\'+p_strModuleName), PChar(v_strDestinationFolderName + p_strModuleName),false);
            FileSetAttr (PChar(v_strDestinationFolderName + p_strModuleName),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED
          End
        else
          begin

            Try
              if not FTP(XML_RetornaValor('te_serv_updates'              , v_retorno),
                         XML_RetornaValor('nu_porta_serv_updates'        , v_retorno),
                         XML_RetornaValor('nm_usuario_login_serv_updates', v_retorno),
                         XML_RetornaValor('te_senha_login_serv_updates'  , v_retorno),
                         XML_RetornaValor('te_path_serv_updates'         , v_retorno),
                         p_strModuleName,
                         v_strDestinationFolderName) then
                  Configs.Memo_te_instala_informacoes_extras.Lines.add(#13#10+'ATENÇÃO! Não foi possível efetuar FTP para "'+v_strDestinationFolderName + p_strModuleName+'".'+#13#10+'Verifique o Servidor de Updates.');
            Except
              LogDebug('FTP de "'+ v_strDestinationFolderName + p_strModuleName+'" Interrompido.');
            End;

            if not FileExists(v_strDestinationFolderName + p_strModuleName) Then
              Begin
                LogDebug('Problemas Efetuando Download de '+ v_strDestinationFolderName + p_strModuleName+' (FTP)');
                LogDebug('Conexão:');
                LogDebug(XML_RetornaValor('te_serv_updates',v_retorno)               +', '+
                         XML_RetornaValor('nu_porta_serv_updates'        , v_retorno)+', '+
                         XML_RetornaValor('nm_usuario_login_serv_updates', v_retorno)+', '+
                         XML_RetornaValor('te_senha_login_serv_updates'  , v_retorno)+', '+
                         XML_RetornaValor('te_path_serv_updates'         , v_retorno));
              End
            else
                LogDiario('Download Concluído de "'+p_strModuleName+'" (FTP)');
          end;
      End;
  End;

procedure chkcacic;
var bool_configura,
    bool_ExistsAutoRun,
    bool_ArquivoINI,
    bool_CommandLine : boolean;

    v_cacic_dir,
    v_te_serv_updates,
    v_nu_porta_serv_updates,
    v_nm_usuario_login_serv_updates,
    v_te_senha_login_serv_updates,
    v_te_path_serv_updates,
    v_te_texto_janela_instalacao,
    v_modulos,
    strAux,
    strDataHoraCACIC2_INI,
    strDataHoraGERCOLS_INI,
    strDataHoraCACIC2_FIM,
    strDataHoraGERCOLS_FIM : String;

    Request_Config  : TStringList;
    v_array_modulos : TStrings;
    Response_Config : TStringStream;
    IdHTTP1: TIdHTTP;
    intDownload_CACIC2,
    intDownload_GER_COLS,
    intAux : integer;

    wordServiceStatus : DWORD;
begin
  strDataHoraCACIC2_INI           := '';
  strDataHoraCACIC2_FIM           := '';
  strDataHoraGERCOLS_INI          := '';
  strDataHoraGERCOLS_FIM          := '';
  v_te_instala_frase_sucesso      := 'INSTALAÇÃO/ATUALIZAÇÃO EFETUADA COM SUCESSO!';
  v_te_instala_frase_insucesso    := '*****  INSTALAÇÃO/ATUALIZAÇÃO NÃO EFETUADA COM SUCESSO  *****';
  bool_CommandLine                := false;
  bool_ArquivoINI                 := FileExists(ExtractFilePath(Application.Exename) + '\chkcacic.ini');

  g_oCacic := TCACIC.Create();
  g_oCacic.setBoolCipher(true);
  Try

  // 2.2.0.17 - Tratamento de opções passadas em linha de comando
  // Grande dica do grande Cláudio Filho (OpenOffice.org)
  if (ParamCount > 0) then
    Begin
      For intAux := 1 to ParamCount do
        Begin
          if LowerCase(Copy(ParamStr(intAux),1,6)) = '/serv=' then
            begin
              strAux := Trim(Copy(ParamStr(intAux),7,Length((ParamStr(intAux)))));
              v_ip_serv_cacic := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
              If v_ip_serv_cacic = '' Then v_ip_serv_cacic := strAux;
            end;
          if LowerCase(Copy(ParamStr(intAux),1,5)) = '/dir=' then
            begin
              strAux := Trim(Copy(ParamStr(intAux),6,Length((ParamStr(intAux)))));
              v_cacic_dir := Trim(Copy(strAux,0,Pos('/', strAux) - 1));
              If v_cacic_dir = '' Then v_cacic_dir := strAux;
            end;

        end;
        if not(v_ip_serv_cacic='') and
           not(v_cacic_dir='')then
           bool_CommandLine := true;
    End;


  // ATENÇÃO: Trecho para uso exclusivo no âmbito da DATAPREV a nível Brasil, para internalização maciça.
  //          Para envio à Comunidade, retirar as chaves mais abaixo, para que o código padrão seja descomentado.
  //          Anderson Peterle - FEV2008
  //v_ip_serv_cacic                 := 'UXRJO115';
  //v_cacic_dir                     := 'Cacic';
  //v_exibe_informacoes             := 'N'; // Manter o "N", pois, esse mesmo ChkCacic será colocado em NetLogons!

  // Se a chamada ao chkCACIC não passou parâmetros de IP do Servidor nem Pasta Padrão...
  // Obs.: Normalmente a chamada com passagem de parâmetros é feita por script em servidor de domínio, para automatização do processo
  if not bool_CommandLine then
    Begin
      If not bool_ArquivoINI then
          Begin
              CriaFormConfigura;
              MostraFormConfigura;
          End;
      v_ip_serv_cacic                 := GetValorChaveRegIni('Cacic2', 'ip_serv_cacic'    , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_cacic_dir                     := GetValorChaveRegIni('Cacic2', 'cacic_dir'        , ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_exibe_informacoes             := GetValorChaveRegIni('Cacic2', 'exibe_informacoes', ExtractFilePath(Application.Exename) + '\chkcacic.ini');
      v_te_instala_informacoes_extras := StringReplace(GetValorChaveRegIni('Cacic2', 'te_instala_informacoes_extras', ExtractFilePath(Application.Exename) + '\chkcacic.ini'),'*13*10',#13#10,[rfReplaceAll]);
    End;

  g_oCacic.setCacicPath(v_cacic_dir);

  if DirectoryExists(g_oCacic.getCacicPath + 'Temp\Debugs') then
    Begin
     if (FormatDateTime('ddmmyyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
       Begin
         v_Debugs := true;
         LogDebug('Pasta "' + g_oCacic.getCacicPath + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(g_oCacic.getCacicPath + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
       End;
    End;

  LogDebug('Tipo de Drive: '+intToStr(GetDriveType(nil)));

  if not (GetDriveType(nil) = DRIVE_REMOTE) then
    Begin
      CriaFormConfigura;
      Configs.Visible := true;

      Configs.gbObrigatorio.BringToFront;
      Configs.gbOpcional.BringToFront;

      Configs.Label_ip_serv_cacic.BringToFront;
      Configs.Edit_ip_serv_cacic.Text                     := v_ip_serv_cacic;
      Configs.Edit_ip_serv_cacic.ReadOnly                 := true;
      Configs.Edit_ip_serv_cacic.BringToFront;

      Configs.Label_cacic_dir.BringToFront;
      Configs.Edit_cacic_dir.Text                         := v_cacic_dir;
      Configs.Edit_cacic_dir.ReadOnly                     := true;
      configs.Edit_cacic_dir.BringToFront;

      Configs.Label_te_instala_informacoes_extras.Visible := false;

      Configs.ckboxExibeInformacoes.Checked               := true;
      Configs.ckboxExibeInformacoes.Visible               := false;

      Configs.Height                                      := 350;
      Configs.lbMensagemNaoAplicavel.Visible              := false;

      Configs.Memo_te_instala_informacoes_extras.Clear;
      Configs.Memo_te_instala_informacoes_extras.Top      := 15;
      Configs.Memo_te_instala_informacoes_extras.Height   := 196;

      Configs.gbObrigatorio.Caption          := 'Configuração';
      Configs.gbObrigatorio.Visible          := true;

      Configs.gbOpcional.Caption             := 'Andamento da Instalação/Atualização';
      Configs.gbOpcional.Visible             := true;

      Configs.Refresh;
      Configs.Show;
    End;

  // Verifica se o S.O. é NT Like e se o Usuário está com privilégio administrativo...
  if (g_oCacic.isWindowsNTPlataform()) and (g_oCacic.isWindowsAdmin()) then
    Begin
      LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      LogDebug(':::::::::::::: OBTENDO VALORES DO "chkcacic.ini" ::::::::::::::');
      LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      LogDebug('Drive de instalação......................: '+g_oCacic.getHomeDrive);
      LogDebug('Pasta para instalação....................: '+g_oCacic.getCacicPath);
      LogDebug('IP do servidor...........................: '+v_ip_serv_cacic);
      LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      bool_configura := false;

      //chave AES. Recomenda-se que cada empresa/órgão altere a sua chave.
      v_tstrCipherOpened := CipherOpen(g_oCacic.getCacicPath + g_oCacic.getDatFileName);

      if (g_oCacic.isWindowsGEXP()) then // Se >= Maior ou Igual ao WinXP...
        Begin
          Try
            // Libero as policies do FireWall Interno
            if (g_oCacic.isWindowsGEVista()) then // Maior ou Igual ao VISTA...
              Begin
                Try
                  Begin
                    // Liberando as conexões de Saída para o FTP
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getHomeDrive+'system32\\ftp.exe|Name=Programa de transferência de arquivos|Desc=Programa de transferência de arquivos|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\FTP-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getHomeDrive+'system32\\ftp.exe|Name=Programa de transferência de arquivos|Desc=Programa de transferência de arquivos|Edge=FALSE|');

                    // Liberando as conexões de Saída para o Ger_Cols
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getCacicPath+'modulos\\ger_cols.exe|Name=Módulo Gerente de Coletas do Sistema CACIC|Desc=Módulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-GERCOLS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getCacicPath+'modulos\\ger_cols.exe|Name=Módulo Gerente de Coletas do Sistema CACIC|Desc=Módulo Gerente de Coletas do Sistema CACIC|Edge=FALSE|');

                    // Liberando as conexões de Saída para o SrCACICsrv
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-SRCACICSRV-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getCacicPath+'modulos\\srcacicsrv.exe|Name=Módulo Suporte Remoto Seguro do Sistema CACIC|Desc=Módulo Suporte Remoto Seguro do Sistema CACIC|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-SRCACICSRV-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getCacicPath+'modulos\\srcacicsrv.exe|Name=Módulo Suporte Remoto Seguro do Sistema CACIC|Desc=Módulo Suporte Remoto Seguro do Sistema CACIC|Edge=FALSE|');

                    // Liberando as conexões de Saída para o ChkCacic
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkcacic.exe|Desc=chkcacic.exe|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKCACIC-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+ExtractFilePath(Application.Exename) + '\chkcacic.exe|Name=chkcacic.exe|Desc=chkcacic.exe|Edge=FALSE|');

                    // Liberando as conexões de Saída para o ChkSis
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-TCP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=6|Profile=Private|App='+g_oCacic.getWinDir + 'chksis.exe|Name=Módulo Verificador de Integridade do Sistema CACIC|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                    SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules\CACIC-CHKSIS-Out-UDP','v2.0|Action=Allow|Active=TRUE|Dir=Out|Protocol=17|Profile=Private|App='+g_oCacic.getWinDir + 'chksis.exe|Name=Módulo Verificador de Integridade do Sistema CACIC|Desc=Módulo Verificador de Integridade do Sistema CACIC|Edge=FALSE|');
                  End
                Except
                  LogDebug('Problema Liberando Policies de FireWall!');
                End;
              End
            else
              Begin
                // Acrescento o ChkCacic às exceções do FireWall nativo...
                {chkcacic}
                LogDebug('Inserindo "'+ExtractFilePath(Application.Exename) + 'chkcacic" nas exceções do FireWall!');
                LiberaFireWall(ExtractFilePath(Application.Exename) + 'chkcacic');
              End;
          Except
          End;
        End;


      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then bool_configura := true;

      while (v_ip_serv_cacic = '') or (v_cacic_dir = '') or bool_configura do
          Begin
              bool_configura := false;
              CriaFormConfigura;

              Configs.Edit_ip_serv_cacic.text                 := v_ip_serv_cacic;
              Configs.Edit_cacic_dir.text                     := v_cacic_dir;
              if v_exibe_informacoes = 'S' then
                Configs.ckboxExibeInformacoes.Checked   := true
              else
                Configs.ckboxExibeInformacoes.Checked   := false;
              Configs.Memo_te_instala_informacoes_extras.text := v_te_instala_informacoes_extras;
              MostraFormConfigura;
          End;

      if (ParamCount > 0) and (LowerCase(Copy(ParamStr(1),1,7)) = '/config') then begin
         try
             g_oCacic.Free();
         except
         end;
         Application.Terminate;
      end;

      LogDebug('Verificando pasta "'+g_oCacic.getCacicPath+'"');
      // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
      if not DirectoryExists(g_oCacic.getCacicPath) then
          begin
            LogDiario('Criando pasta '+g_oCacic.getCacicPath);
            ForceDirectories(g_oCacic.getCacicPath);
          end;

      LogDebug('Verificando pasta "'+g_oCacic.getCacicPath+'modulos'+'"');
      // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
      if not DirectoryExists(g_oCacic.getCacicPath+'modulos') then
          begin
            Matar(g_oCacic.getCacicPath, 'cacic2.exe');
            ForceDirectories(g_oCacic.getCacicPath + 'modulos');
            LogDiario('Criando pasta '+g_oCacic.getCacicPath+'modulos');
          end;

      LogDebug('Verificando pasta "'+g_oCacic.getCacicPath+'Temp'+'"');
      // Crio o SubDiretório TEMP, caso não exista
      if not DirectoryExists(g_oCacic.getCacicPath+'Temp') then
          begin
            ForceDirectories(g_oCacic.getCacicPath + 'Temp');
            LogDiario('Criando pasta '+g_oCacic.getCacicPath+'Temp');
          end;


      // Tento o contato com o módulo gerente WEB para obtenção de
      // dados para conexão FTP e relativos às versões atuais dos principais agentes
      // Busco as configurações para acesso ao ambiente FTP - Updates
      Request_Config                       := TStringList.Create;
      Request_Config.Values['in_chkcacic'] := 'chkcacic';
      Response_Config                      := TStringStream.Create('');

      Try
        LogDiario('Iniciando comunicação com Servidor Gerente WEB do CACIC');
        IdHTTP1 := TIdHTTP.Create(IdHTTP1);
        idHTTP1.AllowCookies                     := true;
        idHTTP1.ASCIIFilter                      := false;
        idHTTP1.AuthRetries                      := 1;
        idHTTP1.BoundPort                        := 0;
        idHTTP1.HandleRedirects                  := false;
        idHTTP1.ProxyParams.BasicAuthentication  := false;
        idHTTP1.ProxyParams.ProxyPort            := 0;
        idHTTP1.ReadTimeout                      := 0;
        idHTTP1.RecvBufferSize                   := 32768;
        idHTTP1.RedirectMaximum                  := 15;
        idHTTP1.Request.Accept                   := 'text/html, */*';
        idHTTP1.Request.BasicAuthentication      := true;
        idHTTP1.Request.ContentLength            := -1;
        idHTTP1.Request.ContentRangeStart        := 0;
        idHTTP1.Request.ContentRangeEnd          := 0;
        idHTTP1.Request.ContentType              := 'text/html';
        idHTTP1.SendBufferSize                   := 32768;
        idHTTP1.Tag                              := 0;

        IdHTTP1.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php', Request_Config, Response_Config);
        idHTTP1.Disconnect;
        idHTTP1.Free;

        v_retorno := Response_Config.DataString;
        LogDebug('Retorno de comunicação com servidor: '+v_retorno);

        LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        LogDebug(':::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
        LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        LogDebug('Servidor de updates......................: '+XML_RetornaValor('te_serv_updates'              , v_retorno));
        LogDebug('Porta do servidor de updates.............: '+XML_RetornaValor('nu_porta_serv_updates'        , v_retorno));
        LogDebug('Usuário para login no servidor de updates: '+XML_RetornaValor('nm_usuario_login_serv_updates', v_retorno));
        LogDebug('Pasta no servidor de updates.............: '+XML_RetornaValor('te_path_serv_updates'         , v_retorno));
        LogDebug(' ');
        LogDebug('Versões dos Agentes Principais:');
        LogDebug('------------------------------');
        LogDebug('Cacic2   - Agente do Systray.........: '+XML_RetornaValor('CACIC2', v_retorno));
        LogDebug('Ger_Cols - Gerente de Coletas........: '+XML_RetornaValor('GER_COLS', v_retorno));
        LogDebug('ChkSis   - Verificador de Integridade: '+XML_RetornaValor('CHKSIS', v_retorno));
        LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
      Except
        Begin
          Configs.Memo_te_instala_informacoes_extras.Lines.Add(#13#10+'ATENÇÃO! Não foi possível estabelecer comunicação com o módulo Gerente WEB em "'+v_ip_serv_cacic+'".');
          LogDiario('**********************************************************');
          LogDiario('Oops! Não Foi Possível Comunicar com o Módulo Gerente WEB!');
          LogDiario('**********************************************************');
        End
      End;
      Request_Config.Free;
      Response_Config.Free;

      // Se NTFS em NT/2K/XP...
      // If NTFS on NT Like...
      if (g_oCacic.isWindowsNTPlataform()) then
        Begin
          LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
          LogDebug('::::::: VERIFICANDO FILE SYSTEM E ATRIBUINDO PERMISSÕES :::::::');
          LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');

          // Atribuição de acesso ao módulo principal e pastas
          Form1.FS_SetSecurity(g_oCacic.getCacicPath);
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'cacic2.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + g_oCacic.getDatFileName);
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'cacic2.log');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'temp');

          // Atribuição de acesso aos módulos de gerenciamento de coletas e coletas para permissão de atualizações de versões
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\ger_cols.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\srcacicsrv.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_anvi.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_comp.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_hard.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_moni.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_patr.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_soft.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\col_undi.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\ini_cols.exe');
          Form1.FS_SetSecurity(g_oCacic.getCacicPath + 'modulos\wscript.exe');

          // Atribuição de acesso para atualização do módulo verificador de integridade do sistema e seus arquivos
          Form1.FS_SetSecurity(g_oCacic.getWinDir + 'chksis.exe');
          Form1.FS_SetSecurity(g_oCacic.getWinDir + 'chksis.log');
          Form1.FS_SetSecurity(g_oCacic.getWinDir + 'chksis.dat');

          // Atribuição de acesso para atualização/exclusão de log do instalador
          Form1.FS_SetSecurity(g_oCacic.getHomeDrive + 'chkcacic.log');
          LogDebug(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
        End;

      // Verificação de versão do cacic2.exe e exclusão em caso de versão antiga/diferente da atual
      If (FileExists(g_oCacic.getCacicPath + 'cacic2.exe')) Then
          Begin
            // Pego as informações de dia/mês/ano/horas/minutos/segundos/milésimos que identificam o agente Cacic2
            strDataHoraCACIC2_INI := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(g_oCacic.getCacicPath + 'cacic2.exe'));

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

      // Verificação de versão do ger_cols.exe e exclusão em caso de versão antiga/diferente da atual
      If (FileExists(g_oCacic.getCacicPath + 'modulos\ger_cols.exe')) Then
        Begin
          // Pego as informações de dia/mês/ano/horas/minutos/segundos/milésimos que identificam o agente Ger_Cols
          strDataHoraGERCOLS_INI := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(g_oCacic.getCacicPath + 'modulos\ger_cols.exe'));

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

        // Verificação de versão do chksis.exe e exclusão em caso de versão antiga/diferente da atual
        If (FileExists(g_oCacic.getWinDir + 'chksis.exe')) Then
          Begin
            intAux := ChecaVersoesAgentes(g_oCacic.getWinDir + 'chksis.exe');
            // 0 => Arquivo de versões ou informação inexistente
            // 1 => Versões iguais
            // 2 => Versões diferentes
            if (intAux = 0) then
              Begin
                v_versao_local  := StringReplace(trim(GetVersionInfo(g_oCacic.getWinDir + 'chksis.exe')),'.','',[rfReplaceAll]);
                v_versao_remota := StringReplace(XML_RetornaValor('CHKSIS' , v_retorno),'0103','',[rfReplaceAll]);
              End;

            if (intAux = 2) or // Caso haja diferença na comparação de versões com "versoes_agentes.ini"...
               (v_versao_local ='0000') then // Provavelmente versão muito antiga ou corrompida
              Matar(g_oCacic.getWinDir,'chksis.exe');
          End;

        // Tento detectar o ChkSis.EXE e copio ou faço FTP caso não exista
        verifyAndGet('chksis.exe',
                      XML_RetornaValor('TE_HASH_CHKSIS', v_retorno),
                      g_oCacic.getWinDir);

      // Tento detectar o ChkSis.INI e crio-o caso necessário
      If not FileExists(g_oCacic.getWinDir + 'chksis.ini') Then
        begin
          LogDebug('Criando '+g_oCacic.getWinDir + 'chksis.ini');
          GravaIni(g_oCacic.getWinDir + 'chksis.ini');
          FileSetAttr ( PChar(g_oCacic.getWinDir + 'chksis.ini'),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
        end;


      // Verificação de existência do CacicSvc.exe
      If (g_oCacic.isWindowsNTPlataform()) then
        Begin
          // Tento detectar o CACICsvc.EXE e copio ou faço FTP caso não exista
          verifyAndGet('cacicsvc.exe',
                        XML_RetornaValor('TE_HASH_CACICSVC', v_retorno),
                        g_oCacic.getWinDir);

          // O CACICsvc usará o arquivo de configurações \Windows\chksis.ini
        End;

      // Tento detectar o cacic2.INI e crio-o caso necessário
      If not FileExists(g_oCacic.getCacicPath + 'cacic2.ini') Then
          begin
            LogDebug('Criando/Recriando '+g_oCacic.getCacicPath + 'cacic2.ini');
            GravaIni(g_oCacic.getCacicPath + 'cacic2.ini');
          end;

      // Verifico se existe a pasta "modulos"
      v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'\modulos\*.exe');
      if (v_modulos <> '') then LogDiario('Pasta "Modulos" encontrada..');

      // Tento detectar o Agente Principal e copio ou faço FTP caso não exista
      verifyAndGet('cacic2.exe',
                   XML_RetornaValor('TE_HASH_CACIC2', v_retorno),
                   g_oCacic.getCacicPath);

      verifyAndGet('ger_cols.exe',
                   XML_RetornaValor('TE_HASH_GER_COLS', v_retorno),
                   g_oCacic.getCacicPath + 'modulos');

        // Caso exista a pasta "modulos", copio todos os executáveis para a pasta Cacic\modulos, exceto cacic2.exe, ger_cols.exe e chksis.exe
        if (v_modulos <> '') then
          Begin
            v_array_modulos := explode(v_modulos,'#');
            For intAux := 0 To v_array_modulos.count -1 Do
              Begin
                if (v_array_modulos[intAux]<>'cacic2.exe') and
                   (v_array_modulos[intAux]<>'ger_cols.exe') and
                   (v_array_modulos[intAux]<>'chksis.exe') then
                  Begin
                    LogDiario('Copiando '+v_array_modulos[intAux]+' de '+ExtractFilePath(Application.Exename)+'modulos\');
                    CopyFile(PChar(ExtractFilePath(Application.Exename) + 'modulos\'+v_array_modulos[intAux]), PChar(g_oCacic.getCacicPath + 'modulos\'+v_array_modulos[intAux]),false);
                    FileSetAttr (PChar(g_oCacic.getCacicPath + 'modulos\'+v_array_modulos[intAux]),0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
                  End;
              End;
          End;

      // ATENÇÃO:
      // Após testes no Vista, percebí que o firewall nativo interrompia o FTP e truncava o agente com tamanho zero...
      // A nova tentativa abaixo ajudará a sobrepor o agente truncado e corrompido

      // Tento detectar (de novo) o ChkSis.EXE e copio ou faço FTP caso não exista
      verifyAndGet('chksis.exe',
                    XML_RetornaValor('TE_HASH_CHKSIS', v_retorno),
                    g_oCacic.getWinDir);

      // Tento detectar (de novo) o Agente Principal e copio ou faço FTP caso não exista
      verifyAndGet('cacic2.exe',
                   XML_RetornaValor('TE_HASH_CACIC2', v_retorno),
                   g_oCacic.getCacicPath);

      verifyAndGet('ger_cols.exe',
                   XML_RetornaValor('TE_HASH_GER_COLS', v_retorno),
                   g_oCacic.getCacicPath + 'modulos');

      if (g_oCacic.isWindowsNTPlataform) then
        Begin
          Try
            // Acrescento o Ger_Cols e srCacicSrv às exceções do FireWall nativo...

            {chksis}
            LogDebug('Inserindo "'+g_oCacic.getWinDir + 'chksis" nas exceções do FireWall!');
            LiberaFireWall(g_oCacic.getWinDir + 'chksis');

            {ger_cols}
            LogDebug('Inserindo "'+g_oCacic.getCacicPath + 'modulos\ger_cols" nas exceções do FireWall!');
            LiberaFireWall(g_oCacic.getCacicPath + 'modulos\ger_cols');

            {srcacicsrv}
            LogDebug('Inserindo "'+g_oCacic.getCacicPath + 'modulos\srcacicsrv" nas exceções do FireWall!');
            LiberaFireWall(g_oCacic.getCacicPath + 'modulos\srcacicsrv');

          Except
          End;
        End;

      LogDebug('Gravando registros para auto-execução');

      // Somente para S.O. NOT NT LIKE
      if NOT (g_oCacic.isWindowsNTPlataform) then
        Begin
          // Crio a chave/valor cacic2 para autoexecução do Cacic, caso não exista esta chave/valor
          // Crio a chave/valor chksis para autoexecução do ChkSIS, caso não exista esta chave/valor
          SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', g_oCacic.getWinDir + 'chksis.exe');

          bool_ExistsAutoRun := false;
          if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=g_oCacic.getCacicPath + 'cacic2.exe') then
            bool_ExistsAutoRun := true
          else
            SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', g_oCacic.getCacicPath + 'cacic2.exe');
        End
      else
        Begin
          DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2');
          DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine');
        End;

      // Igualo as chaves ip_serv_cacic dos arquivos chksis.ini e cacic2.ini!
      SetValorDatMemoria('Configs.EnderecoServidor', v_ip_serv_cacic);
      LogDebug('Fechando Arquivo de Configurações do Cacic');
      CipherClose(g_oCacic.getCacicPath + g_oCacic.getDatFileName);

      LogDebug('Abrindo Arquivo de Configurações do ChkSis');
      CipherOpen(g_oCacic.getWinDir + 'chksis.dat');
      SetValorDatMemoria('Cacic2.ip_serv_cacic', v_ip_serv_cacic);
      SetValorDatMemoria('Cacic2.cacic_dir'    , g_oCacic.getCacicPath);
      CipherClose(g_oCacic.getWinDir + 'chksis.dat');

      // Volto a gravar o chksis.ini para o difícil caso de leitura por versões antigas
      SetValorChaveRegIni('Cacic2', 'ip_serv_cacic', v_ip_serv_cacic, g_oCacic.getWinDir + 'chksis.ini');
      LogDebug('Fechando Arquivo de Configurações do ChkSis');

      LogDebug('Resgatando informações para identificação de alteração do agente CACIC2');
      // Pego as informações de dia/mês/ano/horas/minutos/segundos/milésimos que identificam os agentes
      strDataHoraCACIC2_FIM  := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(g_oCacic.getCacicPath + 'cacic2.exe'));
      LogDebug('Inicial => "' + strDataHoraCACIC2_INI  + '" Final => "' + strDataHoraCACIC2_FIM  + '"');

      LogDebug('Resgatando informações para identificação de alteração do agente GER_COLS');
      strDataHoraGERCOLS_FIM := FormatDateTime('ddmmyyyyhhnnsszzz', GetFolderDate(g_oCacic.getCacicPath + 'modulos\ger_cols.exe'));
      LogDebug('Inicial => "' + strDataHoraGERCOLS_INI + '" Final => "' + strDataHoraGERCOLS_FIM + '"');

      // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
      if ((strDataHoraCACIC2_INI <> strDataHoraCACIC2_FIM) OR
          (strDataHoraGERCOLS_INI <> strDataHoraGERCOLS_FIM)) then
          Begin
            v_te_texto_janela_instalacao := v_te_instala_informacoes_extras;

            if (GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2')=g_oCacic.getCacicPath + 'cacic2.exe') and
               (not g_oCacic.isWindowsNTPlataform()) or
               (g_oCacic.isWindowsNTPlataform()) then
              Begin
                configs.Memo_te_instala_informacoes_extras.Lines.Add(#13#10+#13#10+'Sistema CACIC'+#13#10+#13#10+v_te_instala_frase_sucesso);
              End
            else
              Begin
                Configs.Memo_te_instala_informacoes_extras.Lines.Add(#13#10+#13#10+'Sistema CACIC'+#13#10+#13#10+v_te_instala_frase_insucesso);
                ComunicaInsucesso('1'); // O indicador "1" sinalizará que não foi devido a privilégio na estação
              End;
          End
      else
        LogDiario('ATENÇÃO: Instalação NÃO REALIZADA ou ATUALIZAÇÃO DESNECESSÁRIA!');

      if Posso_Rodar_CACIC or
         not bool_ExistsAutoRun or
         (strDataHoraCACIC2_INI <> strDataHoraCACIC2_FIM) then
        Begin
          // Se não for plataforma NT executo o agente principal
          if not (g_oCacic.isWindowsNTPlataform()) then
            Begin
              LogDebug('Executando '+g_oCacic.getCacicPath + 'cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic);
              if (strDataHoraCACIC2_INI <> strDataHoraCACIC2_FIM) then
                g_oCacic.createSampleProcess(g_oCacic.getCacicPath + 'cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic+ ' /execute', false)
              else
                g_oCacic.createSampleProcess(g_oCacic.getCacicPath + 'cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic             , false);
            End
          else
            Begin

              {*** 1 = SERVICE_STOPPED ***}
              {*** 2 = SERVICE_START_PENDING ***}
              {*** 3 = SERVICE_STOP_PENDING ***}
              {*** 4 = SERVICE_RUNNING ***}
              {*** 5 = SERVICE_CONTINUE_PENDING ***}
              {*** 6 = SERVICE_PAUSE_PENDING ***}
              {*** 7 = SERVICE_PAUSED ***}

              // Verifico se o serviço está instalado/rodando,etc.
              wordServiceStatus := ServiceGetStatus(nil,'cacicservice');
              if (wordServiceStatus = 0) then
                Begin
                  // Instalo e Habilito o serviço
                  LogDiario('Instalando/Iniciando CACICservice...');
                  g_oCacic.createSampleProcess(g_oCacic.getWinDir + 'cacicsvc.exe -install',false);
                End
              else if ((wordServiceStatus < 4) or
                       (wordServiceStatus > 4))  then
                Begin
                  LogDiario('Iniciando CACICservice');
                  g_oCacic.createSampleProcess(g_oCacic.getWinDir + 'cacicsvc.exe -start', false);
                End
              else
                  LogDiario('Não instalei o CACICservice. Já está rodando...');
            End;
        End
      else
        LogDebug('Chave de Auto-Execução já existente ou Execução já iniciada...');
    End
  else
    Begin // Se NT/2000/XP/...
      if (v_exibe_informacoes = 'S') and not bool_CommandLine then
        MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);
      LogDiario('Sem Privilégios: Necessário ser administrador "local" da estação');
      ComunicaInsucesso('0'); // O indicador "0" (zero) sinalizará falta de privilégio na estação
    End;
  Except
    LogDiario('Falha na Instalação/Atualização');
  End;

  try
    g_oCacic.Free;
  except
  end;

  Application.Terminate;
end;

function ServiceRunning(sMachine, sService: PChar): Boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(sMachine, sService);
end;

function ServiceStopped(sMachine, sService: PChar): Boolean;
begin
  Result := SERVICE_STOPPED = ServiceGetStatus(sMachine, sService);
end;

function FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..260] of char;
begin
  // Get the first window
  NextHandle := GetWindow(Application.Handle, GW_HWNDFIRST);
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.ShowMainForm:=false;
  v_Debugs := false;

  chkcacic;

  Application.Terminate;
end;

procedure TForm1.FS_SetSecurity(p_Target : String);
var intAux : integer;
    v_FS_Security : TNTFileSecurity;
begin
  v_FS_Security := TNTFileSecurity.Create(nil);
  v_FS_Security.FileName := '';
  v_FS_Security.FileName := p_Target;
  v_FS_Security.RefreshSecurity;

  if (v_FS_Security.FileSystemName='NTFS')then
    Begin
      for intAux := 0 to Pred(v_FS_Security.EntryCount) do
        begin
          case v_FS_Security.EntryType[intAux] of seAlias, seDomain, seGroup :
            Begin   // If local group, alias or user...
              v_FS_Security.FileRights[intAux]       := [faAll];
              v_FS_Security.DirectoryRights[intAux]  := [faAll];
              LogDebug(p_Target + ' [Full Access] >> '+v_FS_Security.EntryName[intAux]);
              //Setting total access on p_Target to local groups.
            End;
          End;
        end;

      // Atribui permissão total aos grupos locais
      // Set total permissions to local groups
      v_FS_Security.SetSecurity;
    end
  else LogDiario('File System: "' + v_FS_Security.FileSystemName+'" - Ok!');

  v_FS_Security.Free;
end;
end.
