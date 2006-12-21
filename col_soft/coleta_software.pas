unit coleta_software;

interface

uses Windows, SysUtils, Classes, registry;

function GetWinVer: Integer;
function GetVersaoIE: string;
function GetVersaoJRE: String;
function GetVersaoAcrobatReader: String;
function GetVersaoMozilla: String;
procedure RealizarColetaSoftware;
procedure RealizarColetaSoftwareNaoOpcional;

implementation

Uses registro, main, comunicacao, utils;


function GetWinVer: Integer;
const
  { operating system (OS)constants }
  cOsUnknown = 0;
  cOsWin95 = 1;
  cOsWin95OSR2 = 2;  // Não implementado.
  cOsWin98 = 3;
  cOsWin98SE = 4;
  cOsWinME = 5;
  cOsWinNT = 6;
  cOsWin2000 = 7;
  cOsXP = 8;
var
  osVerInfo: TOSVersionInfo;
  majorVer, minorVer: Integer;
begin



{       Memo1.Lines.Add(OSVersion);
       Memo1.Lines.Add(CSD);
       Memo1.Lines.Add(Format('%d.%d.%d',[MSystemInfo.OS.MajorVersion,MSystemInfo.OS.MinorVersion,MSystemInfo.OS.BuildNumber]));
       Memo1.Lines.Add(MSystemInfo.OS.NTSpecific.HotFixes);
       Memo1.Lines.Add(MSystemInfo.OS.Version);
              Memo1.Lines.Add(MSystemInfo.OS.CSDEx);
              Memo1.Lines.Add(MSystemInfo.OS.ProductID);
              Memo1.Lines.Add(MSystemInfo.os.LanguageID);

}
  Result := cOsUnknown;
  { set operating system type flag }
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
  begin
    majorVer := osVerInfo.dwMajorVersion;
    minorVer := osVerInfo.dwMinorVersion;
    case osVerInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT: { Windows NT/2000 }
        begin
          if majorVer <= 4 then
            Result := cOsWinNT
          else if (majorVer = 5) and (minorVer = 0) then
            Result := cOsWin2000
          else if (majorVer = 5) and (minorVer = 1) then
            Result := cOsXP
          else
            Result := cOsUnknown;
        end;
      VER_PLATFORM_WIN32_WINDOWS:  { Windows 9x/ME }
        begin
          if (majorVer = 4) and (minorVer = 0) then
            Result := cOsWin95
          else if (majorVer = 4) and (minorVer = 10) then
          begin
            if osVerInfo.szCSDVersion[1] = 'A' then
              Result := cOsWin98SE
            else
              Result := cOsWin98;
          end
          else if (majorVer = 4) and (minorVer = 90) then
            Result := cOsWinME
          else
            Result := cOsUnknown;
        end;
      else
        Result := cOsUnknown;
    end;
  end
  else
    Result := cOsUnknown;
end;


function GetVersaoIE: string;
var strVersao: string;
begin
    // Detalhes das versões em http://support.microsoft.com/default.aspx?scid=KB;EN-US;Q164539&
    strVersao := '';
    strVersao := Trim(Registro.GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Version'));
    Result := strVersao;
end;



function GetVersaoAcrobatReader: String;
var Reg_GVAR : TRegistry;
    Lista_GVAR: TStringList;
    strChave : String;
Begin
      Reg_GVAR := TRegistry.Create;
      Reg_GVAR.LazyWrite := False;
      Lista_GVAR := TStringList.Create;
      Reg_GVAR.Rootkey := HKEY_LOCAL_MACHINE;
      strChave := '\Software\Adobe\Acrobat Reader';
      Reg_GVAR.OpenKeyReadOnly(strChave);
      Reg_GVAR.GetKeyNames(Lista_GVAR);
      Reg_GVAR.CloseKey;
      If Lista_GVAR.Count > 0 Then
      Begin
        Lista_GVAR.Sort;
        Result := Lista_GVAR.Strings[Lista_GVAR.Count - 1];
      end;
      Lista_GVAR.Free;
      Reg_GVAR.Free;
end;




function GetVersaoJRE: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(Registro.GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\JavaSoft\Java Runtime Environment\CurrentVersion'));
    Result := strVersao;
end;


function GetVersaoMozilla: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(Registro.GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\mozilla.org\Mozilla\CurrentVersion'));
    Result := strVersao;
end;



procedure RealizarColetaSoftware;
var Request_RCS: TStringList;
    te_versao_mozilla, te_versao_ie, te_versao_jre, te_versao_acrobat_reader,
    ValorChaveColetado, ValorChaveRegistro : String;
begin
   if (CS_COLETA_SOFTWARE) Then
   Begin
       main.frmMain.Log_Historico('* Coletando informações de software.');
       Try main.frmMain.MSystemInfo.Engines.GetInfo; except end;

       te_versao_mozilla := GetVersaoMozilla;
       te_versao_ie      := GetVersaoIE;
       te_versao_jre     := GetVersaoJRE;
       te_versao_acrobat_reader := GetVersaoAcrobatReader;


       // Monto a string que será comparada com o valor armazenado no registro.
       ValorChaveColetado := main.frmMain.MSystemInfo.Engines.ODBC  + ';' +
                             main.frmMain.MSystemInfo.Engines.BDE  + ';' +
                             main.frmMain.MSystemInfo.Engines.DAO  + ';' +
                             main.frmMain.MSystemInfo.Engines.ADO  + ';' +
                             main.frmMain.MSystemInfo.Engines.DirectX.Version  + ';' +
                             te_versao_mozilla + ';' +
                             te_versao_ie + ';' +
                             te_versao_acrobat_reader + ';' +
                             te_versao_jre;

       // Obtenho do registro o valor que foi previamente armazenado
       ValorChaveRegistro := Trim(Registro.GetValorChaveRegIni('Coleta','Software',p_path_cacic_ini));

       // Se essas informações forem diferentes significa que houve alguma alteração
       // na configuração. Nesse caso, gravo as informações no BD Central
       // e, se não houver problemas durante esse procedimento, atualizo as
       // informações no registro.
       If (IN_COLETA_FORCADA or (ValorChaveColetado <> ValorChaveRegistro)) Then
       Begin
          //Envio via rede para ao Agente Gerente, para gravação no BD.
          Request_RCS:=TStringList.Create;
          Request_RCS.Values['te_node_address']          := TE_NODE_ADDRESS;
          Request_RCS.Values['id_so']                    := ID_SO;
          Request_RCS.Values['te_nome_computador']      := TE_NOME_COMPUTADOR;
          Request_RCS.Values['te_versao_bde']            := main.frmMain.MSystemInfo.Engines.BDE;
          Request_RCS.Values['te_versao_dao']            := main.frmMain.MSystemInfo.Engines.DAO ;
          Request_RCS.Values['te_versao_ado']            := main.frmMain.MSystemInfo.Engines.ADO;
          Request_RCS.Values['te_versao_odbc']           := main.frmMain.MSystemInfo.Engines.ODBC;
          Request_RCS.Values['te_versao_directx']        := main.frmMain.MSystemInfo.Engines.DirectX.Version;
          Request_RCS.Values['te_versao_acrobat_reader'] := te_versao_acrobat_reader;
          Request_RCS.Values['te_versao_ie']             := te_versao_ie;
          Request_RCS.Values['te_versao_mozilla']        := te_versao_mozilla;
          Request_RCS.Values['te_versao_jre']            := te_versao_jre;

          // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
          //Sobreponho a informação no registro para posterior comparação, na próxima execução.
          if (comunicacao.ComunicaServidor('set_software.php', Request_RCS, '>> Enviando informações de software para o servidor.') <> '0') Then
          Begin
             Registro.SetValorChaveRegIni('Coleta','Software', ValorChaveColetado,p_path_cacic_ini);
          end;
          Request_RCS.Free;
       end;
   end
   else main.frmMain.Log_Historico('Coleta de informações de software não configurada.');
end;






// Essa coleta não é opcional, ou seja, o administrador não tem como desabilitá-la.
// Por isso foi necessário criá-la de forma independente da procedure RealizarColetaSoftware.
procedure RealizarColetaSoftwareNaoOpcional;
var Request_RCSN: TStringList;
    te_versao_cacic, ValorChaveColetado, ValorChaveRegistro : String;
begin

       main.frmMain.Log_Historico('* Coletando informações básicas de software.');
       te_versao_cacic := utils.getVersionInfo(ParamStr(0));

       // Monto a string que será comparada com o valor armazenado no registro.
       ValorChaveColetado := te_versao_cacic;

       // Obtenho do registro o valor que foi previamente armazenado
       ValorChaveRegistro := Trim(Registro.GetValorChaveRegIni('Coleta','SoftwareNaoOpcional',p_path_cacic_ini));

       // Se essas informações forem diferentes significa que houve alguma alteração
       // na configuração. Nesse caso, gravo as informações no BD Central
       // e, se não houver problemas durante esse procedimento, atualizo as
       // informações no registro.

       If (IN_COLETA_FORCADA or (ValorChaveColetado <> ValorChaveRegistro)) Then
       Begin
          //Envio via rede para ao Agente Gerente, para gravação no BD.
          Request_RCSN:=TStringList.Create;
          Request_RCSN.Values['te_node_address']    := TE_NODE_ADDRESS;
          Request_RCSN.Values['id_so']              := ID_SO;
          Request_RCSN.Values['te_nome_computador'] := TE_NOME_COMPUTADOR;
          Request_RCSN.Values['te_versao_cacic']    := te_versao_cacic;

          // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
          //Sobreponho a informação no registro para posterior comparação, na próxima execução.
          if (comunicacao.ComunicaServidor('set_software_nao_opcional.php', Request_RCSN, '>> Enviando informações básicas de software para o servidor.') <> '0') Then
          Begin
             Registro.SetValorChaveRegIni('Coleta','SoftwareNaoOpcional', ValorChaveColetado,p_path_cacic_ini);
          end;
          Request_RCSN.Free;
       end;
end;



end.
