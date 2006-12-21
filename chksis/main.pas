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

unit main;

interface

uses Windows, SysUtils, Classes, Forms, Registry, Inifiles, XML, LibXmlParser, strUtils,IdHTTP, IdFTP, idFTPCommon,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, PJVersionInfo;

Procedure chksis;
Procedure DelValorReg(Chave: String);
Function FTP(p_Host : String; p_Port : String; p_Username : String; p_Password : String; p_PathServer : String; p_File : String; p_Dest : String) : Boolean;
Function Explode(Texto, Separador : String) : TStrings;
Function GetRootKey(strRootKey: String): HKEY;
Function SetValorChaveRegEdit(Chave: String; Dado: Variant): Variant;
Function GetValorChaveRegEdit(Chave: String): Variant;
function SetValorChaveRegIni(p_Secao, p_Chave, p_Valor, p_File : String): String;
function GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
function HomeDrive : string;
Function RemoveCaracteresEspeciais(Texto : String) : String;
function FindWindowByTitle(WindowTitle: string): Hwnd;
function GetVersionInfo(p_File: string):string;
function VerFmt(const MS, LS: DWORD): string;

type
  TForm1 = class(TForm)
    IdFTP1: TIdFTP;
    IdHTTP1: TIdHTTP;
    PJVersionInfo1: TPJVersionInfo;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Dir, ENDERECO_SERV_CACIC : string;
implementation

{$R *.dfm}
function VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

{ TMainForm }

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
    ListaAuxSet := Explode(Chave, '\');
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
    ListaAuxGet := Explode(Chave, '\');

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
    FileSetAttr (p_File,0);
    Reg_Ini := TIniFile.Create(p_File);
//    Reg_Ini.WriteString(utils_cacic.Crip(p_Secao), utils_cacic.Crip(p_Chave), utils_cacic.Crip(p_Valor));
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
    ListaAuxDel := Explode(Chave, '\');
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


Function Explode(Texto, Separador : String) : TStrings;
var
    strItem : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres, I : Integer;
Begin
    ListaAuxUTILS := TStringList.Create;
    strItem := '';
    NumCaracteres := Length(Texto);
    For I := 0 To NumCaracteres Do
    If (Texto[I] = Separador) or (I = NumCaracteres) Then
    Begin
       If (I = NumCaracteres) then strItem := strItem + Texto[I];
       ListaAuxUTILS.Add(Trim(strItem));
       strItem := '';
    end
    Else strItem := strItem + Texto[I];
      Explode := ListaAuxUTILS;
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


function HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
end;

procedure chksis;
var
  v_download_CACIC2 : boolean;
  v_home_drive, v_ip_serv_cacic, v_cacic_dir, v_rem_cacic_v0x,
  v_var_inst_cac, v_te_serv_updates, v_nu_porta_serv_updates, v_nm_usuario_login_serv_updates,
  v_te_senha_login_serv_updates, v_te_path_serv_updates,strDataCACIC2 : String;
  BatchFile, Request_Config : TStringList;
  Response_Config : TStringStream;
  IdHTTP1: TIdHTTP;
begin
  v_download_CACIC2  := false;
  v_home_drive       := MidStr(HomeDrive,1,3); //x:\
  v_ip_serv_cacic    := GetValorChaveRegIni('Cacic2', 'ip_serv_cacic', ExtractFilePath(Application.Exename) + '\chksis.ini');
  v_cacic_dir        := GetValorChaveRegIni('Cacic2', 'cacic_dir', ExtractFilePath(Application.Exename) + '\chksis.ini');
  v_rem_cacic_v0x    := GetValorChaveRegIni('Cacic2', 'rem_cacic_v0x', ExtractFilePath(Application.Exename) + '\chksis.ini');
  Dir                := v_home_drive + v_cacic_dir;

  // Caso o parâmetro rem_cacic_v0x seja "S/s" removo a chave/valor de execução do Cacic antigo
  if (LowerCase(v_rem_cacic_v0x)='s') then
      begin
        DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic');
      end;

  // Verifico a existência do diretório configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(Dir) then
      begin
        ForceDirectories(Dir);
      end;

  // Para eliminar versão 20014 e anteriores que provavelmente não fazem corretamente o AutoUpdate
  if not DirectoryExists(Dir+'\modulos') then
      begin
        DeleteFile(Dir + '\cacic2.exe');
        ForceDirectories(Dir + '\modulos');
      end;

  // Crio o SubDiretório TEMP, caso não exista
  if not DirectoryExists(Dir+'\temp') then
      begin
        ForceDirectories(Dir + '\temp');
      end;

  // Exclusão do arquivo cacic2.exe para que seja baixado novamente, devido a problema com versão 2.0.0.23
  // após alteração do método de leitura de arquivos INI.
  If (FileExists(Dir + '\cacic2.exe')) Then
      Begin
       if (StrToInt(StringReplace(GetVersionInfo(Dir + '\cacic2.exe'),'.','',[rfReplaceAll]))>20000) or
          (trim(GetVersionInfo(Dir + '\cacic2.exe'))='0.0.0.0') then
          Begin
            DeleteFile(Dir + '\cacic2.exe');
          End;
      End;

  If (FileExists(Dir + '\modulos\ger_cols.exe')) Then
      Begin
       if (StrToInt(StringReplace(GetVersionInfo(Dir + '\modulos\ger_cols.exe'),'.','',[rfReplaceAll]))>20000) or
          (trim(GetVersionInfo(Dir + '\modulos\ger_cols.exe'))='0.0.0.0') then
          Begin
            DeleteFile(Dir + '\modulos\ger_cols.exe');
          End;
      End;

  // Igualo as chaves ip_serv_cacic dos arquivos chksis.ini e cacic2.ini!
  SetValorChaveRegIni('Configs', 'EnderecoServidor', v_ip_serv_cacic, Dir + '\cacic2.ini');

  // Verifico existência dos dois principais objetos
  If (not FileExists(Dir + '\cacic2.exe')) or (not FileExists(Dir + '\modulos\ger_cols.exe')) Then
      Begin
        // Busco as configurações para acesso ao ambiente FTP - Updates
        Request_Config                       := TStringList.Create;
        Request_Config.Values['in_chkcacic'] := 'chkcacic';
        Response_Config                      := TStringStream.Create('');

        Try
          IdHTTP1 := TIdHTTP.Create(IdHTTP1);
          IdHTTP1.Post('http://' + v_ip_serv_cacic + '/cacic2/ws/get_config.php', Request_Config, Response_Config);

          v_te_serv_updates               := XML_RetornaValor('te_serv_updates'              , Response_Config.DataString);
          v_nu_porta_serv_updates         := XML_RetornaValor('nu_porta_serv_updates'        , Response_Config.DataString);
          v_nm_usuario_login_serv_updates := XML_RetornaValor('nm_usuario_login_serv_updates', Response_Config.DataString);
          v_te_senha_login_serv_updates   := XML_RetornaValor('te_senha_login_serv_updates'  , Response_Config.DataString);
          v_te_path_serv_updates          := XML_RetornaValor('te_path_serv_updates'         , Response_Config.DataString);
        Except
        End;
        Request_Config.Free;
        Response_Config.Free;

        // Tento detectar o Agente Principal e faço FTP caso não exista
        If not FileExists(Dir + '\cacic2.exe') Then
            begin
              FTP(v_te_serv_updates,
                  v_nu_porta_serv_updates,
                  v_nm_usuario_login_serv_updates,
                  v_te_senha_login_serv_updates,
                  v_te_path_serv_updates,
                  'cacic2.exe',
                  Dir);
              v_download_CACIC2 := true;
            end;

        // Tento detectar o Gerente de Coletas e faço FTP caso não exista
        If (not FileExists(Dir + '\modulos\ger_cols.exe')) Then
            begin
              FTP(v_te_serv_updates,
                  v_nu_porta_serv_updates,
                  v_nm_usuario_login_serv_updates,
                  v_te_senha_login_serv_updates,
                  v_te_path_serv_updates,
                  'ger_cols.exe',
                  Dir + '\modulos');
            end;
      End;

  // Crio a chave/valor cacic2 para autoexecução do Cacic, caso não exista esta chave/valor
  // Crio a chave/valor chksis para autoexecução do Cacic, caso não exista esta chave/valor
        SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine', HomeDrive + '\chksis.exe');
        SetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2', Dir + '\cacic2.exe');

  // Caso o Cacic tenha sido baixado executo-o com parâmetro de configuração de servidor
  if (v_download_CACIC2) then
      Begin
        WinExec(PChar(Dir + '\cacic2.exe /ip_serv_cacic=' + v_ip_serv_cacic), SW_HIDE);
      End
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.ShowMainForm:=false;
  if (FindWindowByTitle('chkcacic') = 0) then
    Begin
      chksis;
    End;
  Application.Terminate;
end;

end.
