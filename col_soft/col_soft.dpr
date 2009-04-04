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

program col_soft;
{$R *.res}
{$APPTYPE CONSOLE}
uses
  Windows,
  Classes,
  SysUtils,
  Registry,
  MSI_SOFTWARE,
  MSI_ENGINES,
  MSI_OS,
  MSI_XML_Reports,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_strCipherClosed           : String;
  v_Debugs                    : boolean;

var
  v_tstrCipherOpened,
  v_tstrCipherOpened1,
  tstrTripa1                  : TStrings;

var
  intAux                      : integer;

var
  g_oCacic                    : TCACIC;

const
  CACIC_APP_NAME              = 'col_soft';

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
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor SOFT] '+strMsg); {Grava a string Texto no arquivo texto}
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
      Result := g_oCacic.explode('Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);

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



// Converte caracteres básicos da tabela Ansi para Ascii
// Solução temporária.
function AnsiToAscii( StrANSI: String ): String;
var i: Integer;
    StrASCII, Carac : string;
    Letras_ANSI : array[150..255] of String;
begin
  Letras_ANSI[150] := ' ';
  Letras_ANSI[169] := '©';
  Letras_ANSI[174] := '®';
  Letras_ANSI[181] := 'µ';
  Letras_ANSI[192] := 'A';
  Letras_ANSI[193] := 'A';
  Letras_ANSI[194] := 'A';
  Letras_ANSI[195] := 'A';
  Letras_ANSI[196] := 'A';
  Letras_ANSI[197] := 'A';
  Letras_ANSI[198] := 'A';
  Letras_ANSI[199] := 'C';
  Letras_ANSI[200] := 'E';
  Letras_ANSI[201] := 'E';
  Letras_ANSI[202] := 'E';
  Letras_ANSI[203] := 'E';
  Letras_ANSI[204] := 'I';
  Letras_ANSI[205] := 'I';
  Letras_ANSI[206] := 'I';
  Letras_ANSI[207] := 'I';
  Letras_ANSI[208] := 'D';
  Letras_ANSI[209] := 'N';
  Letras_ANSI[210] := 'O';
  Letras_ANSI[211] := 'O';
  Letras_ANSI[212] := 'O';
  Letras_ANSI[213] := 'O';
  Letras_ANSI[214] := 'O';
  Letras_ANSI[215] := 'x';
  Letras_ANSI[216] := 'O';
  Letras_ANSI[217] := 'U';
  Letras_ANSI[218] := 'U';
  Letras_ANSI[219] := 'U';
  Letras_ANSI[220] := 'U';
  Letras_ANSI[221] := 'Y';
  Letras_ANSI[222] := 'd';
  Letras_ANSI[223] := 'b';
  Letras_ANSI[224] := 'a';
  Letras_ANSI[225] := 'a';
  Letras_ANSI[226] := 'a';
  Letras_ANSI[227] := 'a';
  Letras_ANSI[228] := 'a';
  Letras_ANSI[229] := 'a';
  Letras_ANSI[230] := 'a';
  Letras_ANSI[231] := 'c';
  Letras_ANSI[232] := 'e';
  Letras_ANSI[233] := 'e';
  Letras_ANSI[234] := 'e';
  Letras_ANSI[235] := 'e';
  Letras_ANSI[236] := 'i';
  Letras_ANSI[237] := 'i';
  Letras_ANSI[238] := 'i';
  Letras_ANSI[239] := 'i';
  Letras_ANSI[240] := 'o';
  Letras_ANSI[241] := 'n';
  Letras_ANSI[242] := 'o';
  Letras_ANSI[243] := 'o';
  Letras_ANSI[244] := 'o';
  Letras_ANSI[245] := 'o';
  Letras_ANSI[246] := 'o';
  Letras_ANSI[247] := 'o';
  Letras_ANSI[248] := 'o';
  Letras_ANSI[249] := 'u';
  Letras_ANSI[250] := 'u';
  Letras_ANSI[251] := 'u';
  Letras_ANSI[252] := 'u';
  Letras_ANSI[253] := 'y';
  Letras_ANSI[254] := 'b';
  Letras_ANSI[255] := 'y';

  i := 1;
  StrASCII := '';
  while (i <= Length(StrANSI)) do
    begin
      if (Copy(StrANSI,i,2)='&#') then
        Begin
          Carac := Letras_ANSI[StrToInt(Copy(StrANSI,i+2,3))];
          i := i+ 5;
        End
      else if (Copy(StrANSI,i,4)='&gt;') then
        Begin
          Carac := '?';
          i := i+ 3;
        End
      else if (Copy(StrANSI,i,6)='&quot;') then
        Begin
          Carac := '-';
          i := i+ 5;
        End
      else if (Copy(StrANSI,i,6)='&apos;') then
        Begin
          Carac := '';
          i := i+ 5;
        End
      else if (Copy(StrANSI,i,5)='&amp;') then
        Begin
          Carac := '';
          i := i+ 4;
        End
      else Carac := Copy(StrANSI,i,1);
      StrASCII := StrASCII + Carac;
      i := i+1;
    End;
  Result := StrASCII;
end;

procedure Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := g_oCacic.getCacicPath + 'Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt';
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


function GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

// Função adaptada de http://www.latiumsoftware.com/en/delphi/00004.php
//Para buscar do RegEdit...
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

function GetAllEnvVars():String;
var
  Variable: Boolean;
  Str: PChar;
  Res, Retorno: string;
begin
  Str     :=GetEnvironmentStrings;
  Res     :='';
  Retorno := '';
  Variable:=False;
  while True do begin
    if Str^=#0 then
    begin
      if Variable then Retorno := Retorno + Res + '#';
      Variable:=True;
      Inc(Str);
      Res:='';
      if Str^=#0 then
        Break
      else
        Res:=Res+str^;
    end
    else
      if Variable then Res:=Res+Str^;
    Inc(str);
  end;
  Result := Retorno;
end;



function GetVersaoIE: string;
var strVersao: string;
begin
    // Detalhes das versões em http://support.microsoft.com/default.aspx?scid=KB;EN-US;Q164539&
    strVersao := '';
    strVersao := Trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Version'));
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
    strVersao := Trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\JavaSoft\Java Runtime Environment\CurrentVersion'));
    Result := strVersao;
end;

function GetVersaoMozilla: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\mozilla.org\Mozilla\CurrentVersion'));
    Result := strVersao;
end;

procedure Executa_Col_Soft;
var te_versao_mozilla, te_versao_ie, te_versao_jre, te_versao_acrobat_reader,
    UVC,ValorChaveRegistro, te_inventario_softwares, te_variaveis_ambiente : String;
    InfoSoft, v_Report : TStringList;
    i : integer;
    v_SOFTWARE      : TMiTeC_Software;
    v_ENGINES       : TMiTeC_Engines;
    v_OS            : TMiTeC_OperatingSystem;
begin
 Try
   log_diario('Coletando informações de Softwares Básicos.');
   SetValorDatMemoria('Col_Soft.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
   te_versao_mozilla        := GetVersaoMozilla;
   te_versao_ie             := GetVersaoIE;
   te_versao_jre            := GetVersaoJRE;
   te_versao_acrobat_reader := GetVersaoAcrobatReader;
   te_inventario_softwares  := '';

   Try
      InfoSoft := TStringList.Create;
      v_SOFTWARE := TMiTeC_Software.Create(nil);
      v_SOFTWARE.RefreshData;
      MSI_XML_Reports.Software_XML_Report(v_SOFTWARE,true,InfoSoft);

      // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
      // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
      if v_Debugs then
        Begin
          v_Report := TStringList.Create;

          MSI_XML_Reports.Software_XML_Report(v_SOFTWARE,true,v_Report);
          v_SOFTWARE.Free;

          v_OS := TMiTeC_OperatingSystem.Create(nil);
          v_OS.RefreshData;

          MSI_XML_Reports.OperatingSystem_XML_Report(v_OS,true,v_Report);
          v_OS.Free;
        End

   except
      log_diario('Problema em Software Report!');
   end;

   for i := 0 to v_SOFTWARE.Count - 1 do
      begin
          if (trim(Copy(InfoSoft[i],1,14))='<section name=') then
              Begin
                if (te_inventario_softwares <> '') then
                    te_inventario_softwares := te_inventario_softwares + '#';
                te_inventario_softwares := te_inventario_softwares + Copy(InfoSoft[i],16,Pos('">',InfoSoft[i])-16);
              End;
      end;

   v_SOFTWARE.Free;

   try
      te_inventario_softwares := AnsiToAscii(te_inventario_softwares);
   except
      log_diario('Falha após a Conversão ANSIxASCII');
   end;

   InfoSoft.Free;

   // Pego todas as variáveis de ambiente.
   te_variaveis_ambiente := GetAllEnvVars();

   v_ENGINES := TMiTeC_Engines.Create(nil);
   v_ENGINES.RefreshData;

   // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
   // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
   if (v_Debugs) then
     Begin
       MSI_XML_Reports.Engines_XML_Report(v_ENGINES,true,v_Report);
     End;

   // Monto a string que será comparada com o valor armazenado no registro.
   UVC := v_Engines.ODBC  + ';' +
                         v_Engines.BDE  + ';' +
                         v_Engines.DAO  + ';' +
                         v_Engines.ADO  + ';' +
                         v_Engines.DirectX.Version  + ';' +
                         te_versao_mozilla + ';' +
                         te_versao_ie + ';' +
                         te_versao_acrobat_reader + ';' +
                         te_versao_jre + ';' +
                         te_inventario_softwares +
                         te_variaveis_ambiente;


   // Obtenho do registro o valor que foi previamente armazenado
   ValorChaveRegistro := Trim(GetValorDatMemoria('Coletas.Software',v_tstrCipherOpened));

   SetValorDatMemoria('Col_Soft.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

   // Se essas informações forem diferentes significa que houve alguma alteração
   // na configuração. Nesse caso, gravo as informações no BD Central
   // e, se não houver problemas durante esse procedimento, atualizo as
   // informações no registro.
   If (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_SOFT',v_tstrCipherOpened)='S') or
      (UVC <> ValorChaveRegistro) Then
    Begin
      //Envio via rede para ao Agente Gerente, para gravação no BD.
      SetValorDatMemoria('Col_Soft.te_versao_bde'           , v_ENGINES.BDE            , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_dao'           , v_ENGINES.DAO            , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_ado'           , v_ENGINES.ADO            , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_odbc'          , v_ENGINES.ODBC           , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_directx'       , v_ENGINES.DirectX.Version, v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_acrobat_reader', te_versao_acrobat_reader , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_ie'            , te_versao_ie             , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_mozilla'       , te_versao_mozilla        , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_versao_jre'           , te_versao_jre            , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_inventario_softwares' , te_inventario_softwares  , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.te_variaveis_ambiente'   , te_variaveis_ambiente    , v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Soft.UVC'                     , UVC                      , v_tstrCipherOpened1);
      CipherClose(g_oCacic.getCacicPath + 'temp\col_soft.dat', v_tstrCipherOpened1);
    end
   else
    Begin
     SetValorDatMemoria('Col_Soft.nada', 'nada', v_tstrCipherOpened1);
     CipherClose(g_oCacic.getCacicPath + 'temp\col_soft.dat', v_tstrCipherOpened1);
    End;
   v_ENGINES.Free;

   // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
   // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
   if v_Debugs then
      Begin
        for i:=0 to v_Report.count-1 do
          Begin
            Grava_Debugs(v_report[i]);
          End;
        v_report.Free;
      End;
 Except
  Begin
   SetValorDatMemoria('Col_Soft.nada', 'nada', v_tstrCipherOpened1);
   SetValorDatMemoria('Col_Soft.Fim' , '99999999', v_tstrCipherOpened1);
   CipherClose(g_oCacic.getCacicPath + 'temp\col_soft.dat', v_tstrCipherOpened1);
  End;
 End;
end;

var v_path_cacic : String;
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

       v_tstrCipherOpened  := TStrings.Create;
       v_tstrCipherOpened  := CipherOpen(g_oCacic.getDatFileName);

       v_tstrCipherOpened1 := TStrings.Create;
       v_tstrCipherOpened1 := CipherOpen(g_oCacic.getCacicPath + 'temp\col_soft.dat');

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

          Executa_Col_Soft;
       Except
          SetValorDatMemoria('Col_Soft.nada', 'nada', v_tstrCipherOpened1);
          CipherClose(g_oCacic.getCacicPath + 'temp\col_soft.dat', v_tstrCipherOpened1);
       End;
    End;

   g_oCacic.Free();

end.
