(*
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

program ger_cols;
{$R *.res}

uses
  Windows,
  SysUtils,
  Classes,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  IdFTP,
  idFTPCommon,
  IdBaseComponent,
  IdComponent,
  MSI_Machine,
  MSI_NETWORK,
  MSI_XML_Reports,
  StrUtils,
  Math,
  WinSock,
  NB30,
  CACIC_Library in '..\CACIC_Library.pas';
{
type
  TServerBrowseDialogA0 = function(hwnd: HWND; pchBuffer: Pointer;
    cchBufSize: DWORD): bool;
  stdcall;
  ATStrings = array of string;
}


{$APPTYPE CONSOLE}
var
  v_scripter,
  p_Shell_Command,
  v_acao_gercols,
  v_Tamanho_Arquivo,
  v_TeWebManagerAddress,
  v_Aux,
  strAux,
  strUSBinfo,
  v_ModulosOpcoes : string;

var
  v_Aguarde                 : TextFile;

var
  CountUPD,
  intAux,
  intMontaBatch,
  intLoop : integer;

var
  v_CS_AUTO_UPDATE          : boolean;

var
  BatchFile,
  Request_Ger_Cols          : TStringList;

var
  tstrModuloOpcao,
  tstrModulosOpcoes         : TStrings;

var
  g_oCacic: TCACIC;

const
  CACIC_APP_NAME            = 'ger_cols';



// Gerador de Palavras-Chave
function GeraPalavraChave: String;
var intLimite,
    intContaLetras : integer;
    strPalavra,
    strCaracter    : String;
begin
  g_oCacic.writeDailyLog('Regerando palavra-chave...');
  Randomize;
  strPalavra  := '';
  intLimite  := RandomRange(10,30); // Gerarei uma palavra com tamanho mínimo 10 e máximo 30
  for intContaLetras := 1 to intLimite do
    Begin
      strCaracter := '.';
      while not (strCaracter[1] in ['0'..'9','A'..'Z','a'..'z']) do
        Begin
          if (strCaracter = '.') then strCaracter := '';
          Randomize;
          strCaracter := chr(RandomRange(1,250));
        End;

      strPalavra := strPalavra + strCaracter;
    End;
  Result := strPalavra;
  g_oCacic.writeDebugLog('Nova Palavra-Chave gerada "'+Result+'"');
end;

function StringtoHex(Data: string): string;
var
  i, i2: Integer;
  s: string;
begin
  i2 := 1;
  for i := 1 to Length(Data) do
  begin
    Inc(i2);
    if i2 = 2 then
    begin
      s  := s + ' ';
      i2 := 1;
    end;
    s := s + IntToHex(Ord(Data[i]), 2);
  end;
  Result := s;
end;

procedure Apaga_Temps;
begin
  g_oCacic.killFiles(g_oCacic.getLocalFolder + 'temp\','*.vbs');
  g_oCacic.killFiles(g_oCacic.getLocalFolder + 'temp\','*.txt');
end;

procedure Sair;
Begin
  g_oCacic.Free;
  Halt(0);
End;

procedure Finalizar(p_pausa:boolean);
Begin
  Apaga_Temps;
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclusão de operações de arquivos.
End;

{
procedure Seta_boolCipher(p_strRetorno : String);
var v_Aux : string;
Begin
  g_oCacic.setBoolCipher(false);

  //
  g_oCacic.setBoolCipher(false);

  v_Aux := g_oCacic.xmlGetValue('cs_cipher',p_strRetorno);
  if (p_strRetorno = '') or (v_Aux = '') then v_Aux := '3';

  if (v_Aux='1') then
    Begin
      g_oCacic.writeDebugLog('ATIVANDO Criptografia!');
      g_oCacic.setBoolCipher(true);
    End
  else if (v_Aux='2') then
    Begin
      g_oCacic.writeDailyLog('Setando criptografia para nível 2 e finalizando para rechamada.');
      g_oCacic.SetValueIniFile('Configs','CS_CIPHER', g_oCacic.enCrypt(v_Aux),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      Finalizar(true);
      Sair;
    End;
  g_oCacic.SetValueIniFile('Configs','CS_CIPHER', g_oCacic.enCrypt(v_Aux),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
End;

procedure Seta_l_cs_compress(p_strRetorno : String);
var v_Aux : string;
Begin
  l_cs_compress := false;

  v_Aux := g_oCacic.xmlGetValue('cs_compress',p_strRetorno);
  if v_Aux = '' then v_Aux := '3';

  if (v_Aux='1') then
    Begin
      g_oCacic.writeDebugLog('ATIVANDO Compressão!');
      l_cs_compress := true;
    End
  else
    g_oCacic.writeDebugLog('DESATIVANDO Compressão!');

  g_oCacic.SetValueIniFile('Configs','CS_COMPRESS', g_oCacic.enCrypt(v_Aux),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
End;
}

// Adaptação de código obtido em http://www.swissdelphicenter.ch/torry/showcode.php?id=1578
function GetUserLoggedInDomain(const ServerName: string) : String;
const
  MAX_NAME_STRING = 1024;
var
  userName, domainName: array[0..MAX_NAME_STRING] of Char;
  subKeyName: array[0..MAX_PATH] of Char;
//  NIL_HANDLE: Integer absolute 0;
//  Result: ATStrings;
  subKeyNameSize: DWORD;
  Index: DWORD;
  userNameSize: DWORD;
  domainNameSize: DWORD;
  lastWriteTime: FILETIME;
  usersKey: HKEY;
  sid: PSID;
  sidType: SID_NAME_USE;
  authority: SID_IDENTIFIER_AUTHORITY;
  subAuthorityCount: BYTE;
  authorityVal: DWORD;
  revision: DWORD;
  subAuthorityVal: array[0..7] of DWORD;

  function getvals(s: string): Integer;
  var
    i, j, k, l: integer;
    tmp: string;
  begin
    Delete(s, 1, 2);
    j   := Pos('-', s);
    tmp := Copy(s, 1, j - 1);
    val(tmp, revision, k);
    Delete(s, 1, j);
    j := Pos('-', s);
    tmp := Copy(s, 1, j - 1);
    val('$' + tmp, authorityVal, k);
    Delete(s, 1, j);
    i := 2;
    s := s + '-';
    for l := 0 to 7 do 
    begin
      j := Pos('-', s);
      if j > 0 then 
      begin
        tmp := Copy(s, 1, j - 1);
        val(tmp, subAuthorityVal[l], k);
        Delete(s, 1, j);
        Inc(i);
      end
      else
        break;
    end;
    Result := i;
  end;
begin
  setlength(Result, 0);
  revision     := 0;
  authorityVal := 0;

  FillChar(subAuthorityVal, SizeOf(subAuthorityVal), #0);
  FillChar(userName, SizeOf(userName), #0);
  FillChar(domainName, SizeOf(domainName), #0);
  FillChar(subKeyName, SizeOf(subKeyName), #0);

  if ServerName <> '' then
  begin
    usersKey := 0;
    if (RegConnectRegistry(PChar(ServerName), HKEY_USERS, usersKey) <> 0) then
      Exit;
  end
  else
  begin
    if (RegOpenKey(HKEY_USERS, nil, usersKey) <> ERROR_SUCCESS) then
      Exit;
  end;
  Index          := 0;
  subKeyNameSize := SizeOf(subKeyName);
  while (RegEnumKeyEx(usersKey, Index, subKeyName, subKeyNameSize,
    nil, nil, nil, @lastWriteTime) = ERROR_SUCCESS) do
  begin
    if (lstrcmpi(subKeyName, '.default') <> 0) and (Pos('Classes', string(subKeyName)) = 0) then
    begin
      subAuthorityCount := getvals(subKeyName);
      if (subAuthorityCount >= 3) then
      begin
        subAuthorityCount := subAuthorityCount - 2;
        if (subAuthorityCount < 2) then subAuthorityCount := 2;
        authority.Value[5] := PByte(@authorityVal)^;
        authority.Value[4] := PByte(DWORD(@authorityVal) + 1)^;
        authority.Value[3] := PByte(DWORD(@authorityVal) + 2)^;
        authority.Value[2] := PByte(DWORD(@authorityVal) + 3)^;
        authority.Value[1] := 0;
        authority.Value[0] := 0;
        sid := nil;
        userNameSize := MAX_NAME_STRING;
        domainNameSize := MAX_NAME_STRING;
        if AllocateAndInitializeSid(authority, subAuthorityCount,
          subAuthorityVal[0], subAuthorityVal[1], subAuthorityVal[2],
          subAuthorityVal[3], subAuthorityVal[4], subAuthorityVal[5],
          subAuthorityVal[6], subAuthorityVal[7], sid) then
        begin
          if LookupAccountSid(PChar(ServerName), sid, userName, userNameSize,
            domainName, domainNameSize, sidType) then
          begin
            // Hier kann das Ziel eingetragen werden
            Result := string(userName) + '@' + string(domainName);
          end;
        end;
        if Assigned(sid) then FreeSid(sid);
      end;
    end;
    subKeyNameSize := SizeOf(subKeyName);
    Inc(Index);
  end;
  RegCloseKey(usersKey);
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

function LastPos(SubStr, S: string): Integer;
var
  Found, Len, Pos: integer;
begin
  Pos := Length(S);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if Copy(S, Pos, Len) = SubStr then
      Found := Pos;
    Dec(Pos);
  end;
  LastPos := Found;
end;

function GetMACAddress: string;
var
  NCB: PNCB;
  Adapter: PAdapterStatus;

//  URetCode: PChar;
  RetCode: char;
  I: integer;
  Lenum: PlanaEnum;
  _SystemID: string;
//  TMPSTR: string;
begin
  Result    := '';
  _SystemID := '';
  Getmem(NCB, SizeOf(TNCB));
  Fillchar(NCB^, SizeOf(TNCB), 0);

  Getmem(Lenum, SizeOf(TLanaEnum));
  Fillchar(Lenum^, SizeOf(TLanaEnum), 0);

  Getmem(Adapter, SizeOf(TAdapterStatus));
  Fillchar(Adapter^, SizeOf(TAdapterStatus), 0);

  Lenum.Length    := chr(0);
  NCB.ncb_command := chr(NCBENUM);
  NCB.ncb_buffer  := Pointer(Lenum);
  NCB.ncb_length  := SizeOf(Lenum);
  RetCode         := Netbios(NCB);

  i := 0;
  repeat
    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBRESET);
    Ncb.ncb_lana_num := lenum.lana[I];
    RetCode          := Netbios(Ncb);

    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBASTAT);
    Ncb.ncb_lana_num := lenum.lana[I];
    // Must be 16
    Ncb.ncb_callname := '*               ';

    Ncb.ncb_buffer := Pointer(Adapter);

    Ncb.ncb_length := SizeOf(TAdapterStatus);
    RetCode        := Netbios(Ncb);
    //---- calc _systemId from mac-address[2-5] XOR mac-address[1]...
    if (RetCode = chr(0)) or (RetCode = chr(6)) then
    begin
      _SystemId := IntToHex(Ord(Adapter.adapter_address[0]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[1]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[2]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[3]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[4]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[5]), 2);
    end;
    Inc(i);
  until (I >= Ord(Lenum.Length)) or (_SystemID <> '00-00-00-00-00-00');
  FreeMem(NCB);
  FreeMem(Adapter);
  FreeMem(Lenum);
  GetMacAddress := _SystemID;
end;

Function GetWorkgroup : String;
//var listaAux_GWG : TStrings;
begin
   If Win32Platform = VER_PLATFORM_WIN32_WINDOWS Then { Windows 9x/ME }
       Result := g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VxD\VNETSUP\Workgroup')
   else if g_oCacic.isWindowsGEVista then
       Result := g_oCacic.getValueRegistryKey('HKEY_CURRENT_USER\Volatile Environment\USERDOMAIN')
   Else If Win32Platform = VER_PLATFORM_WIN32_NT Then
     Begin
       Try
          Result := g_oCacic.getValueRegistryKey('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Last Domain');
       Except
          Result := '';
       end;
     end;

   Try
     if Result='' then
        Result := g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultDomainName');
   Except
   End;
end;

function GetIPRede(IP_Computador : String ; MascaraRede : String) : String;
var L1_GIR, L2_GIR : TStrings;
    aux1, aux2, aux3, aux4, aux5 : string;
    j, i : short;

    function IntToBin(Value: LongInt;  Digits: Integer): String;
    var i: Integer;
    begin
       Result:='';
       for i:=Digits downto 0 do
          if Value and (1 shl i)<>0 then  Result:=Result + '1'
          else  Result:=Result + '0';
    end;

    function BinToInt(Value: String): LongInt;
    var i,Size: Integer;
        aux : Extended;
    begin
        aux := 0;
        Size := Length(Value);
        For i := Size - 1 downto 0 do
        Begin
           if Copy(Value, i+1, 1) = '1' Then aux := aux + IntPower(2, (Size - 1) - i);
        end;
       Result := Round(aux);
    end;
begin
  Try
   L1_GIR := g_oCacic.explode(IP_Computador, '.');
   L2_GIR := g_oCacic.explode(MascaraRede, '.');

   //Percorre cada um dos 4 octetos dos endereços
   for i := 0 to 3  do
   Begin
       aux1 := IntToBin(StrToInt(L1_GIR[i]), 7);
       aux2 := IntToBin(StrToInt(L2_GIR[i]), 7);
       aux4 := '';
       for j := 1 to Length(aux1) do
       Begin
           If ((aux1[j] = '0') or (aux2[j] = '0')) then aux3 := '0' else aux3 := '1';
           aux4 := aux4 + aux3;
       end;
       aux5 := aux5 + inttostr(BinToInt(aux4)) + '.';
   end;
   L1_GIR.Free;
   L2_GIR.Free;
   aux5 := Copy(aux5, 0, Length(aux5)-1);

     // Para os casos em que a rotina GetIPRede não funcionar!  (Ex.: Win95x em NoteBook)
     if (aux5 = '') or (aux5 = IP_Computador) or (aux5 = '0.0.0.0')then
        begin
        aux5 := '';
        i := 0;
        for j := 1 to Length(IP_Computador) do
          Begin
           If (IP_Computador[j] = '.') then i := i + 1;
           if (i < 3) then
              begin
                aux5 := aux5 + IP_Computador[j];
              end
           else
              begin
                if (i = 3) then //Consideraremos provisoriamente que a máscara seja 255.255.255.0
                    begin
                      aux5 := aux5 + '.0';
                      i := 30; // Para não entrar mais nessa condição!
                    end;
              end;
          end;
     end;
   Result := aux5;
  Except
   Result := '';
  End;
end;

// Função criada devido a divergências entre os valores retornados pelos métodos dos componentes MSI e seus Reports.
function Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
var intClasses, intSections, intDatas, v_achei_SectionName, v_array_SectionName_Count : integer;
    v_ClassName, v_DataName, v_string_consulta : string;
    v_array_SectionName : tstrings;
begin
    Result              := '';
    if (p_SectionName <> '') then
      Begin
        v_array_SectionName := g_oCacic.explode(p_SectionName,'/');
        v_array_SectionName_Count := v_array_SectionName.Count;
      End
    else v_array_SectionName_Count := 0;
    v_achei_SectionName := 0;
    v_ClassName         := 'classname="' + p_ClassName + '">';
    v_DataName          := '<data name="' + p_DataName + '"';

    intClasses          := 0;
    try
      While intClasses < p_Report.Count Do
        Begin
          if (pos(v_ClassName,p_Report[intClasses])>0) then
            Begin
              intSections := intClasses;
              While intSections < p_Report.Count Do
                Begin
                  if (p_SectionName<>'') then
                    Begin
                      v_string_consulta := '<section name="' + v_array_SectionName[v_achei_SectionName]+'">';
                      if (pos(v_string_consulta,p_Report[intSections])>0) then v_achei_SectionName := v_achei_SectionName+1;
                    End;

                  if (v_achei_SectionName = v_array_SectionName_Count) then
                    Begin

                      intDatas := intSections;
                      While intDatas < p_Report.Count Do
                        Begin

                          if (pos(v_DataName,p_Report[intDatas])>0) then
                            Begin
                              Result := Copy(p_Report[intDatas],pos('>',p_Report[intDatas])+1,length(p_Report[intDatas]));
                              Result := StringReplace(Result,'</data>','',[rfReplaceAll]);
                              intClasses  := p_Report.Count;
                              intSections := p_Report.Count;
                              intDatas    := p_Report.Count;
                            End;
                            intDatas := intDatas + 1;
                        End; //for intDatas...
                    End; // if pos(v_SectionName...
                    intSections := intSections + 1;
                End; // for intSections...
            End; // if pos(v_ClassName...
            intClasses := intClasses + 1;
        End; // for intClasses...
    except
        Begin
          g_oCacic.writeDailyLog('ERRO! Problema na rotina parse');
        End;
    end;
end;

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

function GetIP: string;
var ipwsa:TWSAData; p:PHostEnt; s:array[0..128] of char; c:pchar;
begin
  wsastartup(257,ipwsa);
  GetHostName(@s, 128);
  p := GetHostByName(@s);
  c := iNet_ntoa(PInAddr(p^.h_addr_list^)^);
  Result := String(c);
end;

Function ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
var Response_CS     : TStringStream;
    strEndereco,
    v_TeWebServicesFolder,
    strAux          : String;
    idHTTP1         : TIdHTTP;
    intAux          : integer;
    v_AuxRequest    : TStringList;
Begin
    v_AuxRequest := TStringList.Create;
    v_AuxRequest := Request;

    // A partir da versão 2.0.2.5+ envio um Classificador indicativo de dados criptografados...
    v_AuxRequest.Values['cs_cipher']   := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_CIPHER',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

    // A partir da versão 2.0.2.18+ envio um Classificador indicativo de dados compactados...
    v_AuxRequest.Values['cs_compress'] := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COMPRESS',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

    strAux := g_oCacic.deCrypt(g_oCacic.getValueFromFile('TcpIp','TE_IP', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    if (strAux = '') then
        strAux := 'A.B.C.D'; // Apenas para forçar que o Gerente extraia via _SERVER[REMOTE_ADDR]

    // Tratamentos de valores para tráfego POST:
    v_AuxRequest.Values['te_node_address']   := StringReplace(g_oCacic.getValueFromFile('TcpIp','TE_NODE_ADDRESS'   , g_oCacic.getLocalFolder + g_oCacic.getInfFileName),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_so']             := StringReplace(g_oCacic.EnCrypt(g_oCacic.getWindowsStrId()                                        ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_ip']             := StringReplace(g_oCacic.EnCrypt(strAux                                                            ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_ip_rede']        := StringReplace(g_oCacic.getValueFromFile('TcpIp','ID_IP_REDE'        , g_oCacic.getLocalFolder + g_oCacic.getInfFileName),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_workgroup']      := StringReplace(g_oCacic.getValueFromFile('TcpIp','TE_WORKGROUP'      , g_oCacic.getLocalFolder + g_oCacic.getInfFileName),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_nome_computador']:= StringReplace(g_oCacic.getValueFromFile('TcpIp','TE_NOME_COMPUTADOR', g_oCacic.getLocalFolder + g_oCacic.getInfFileName),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['id_ip_estacao']     := StringReplace(g_oCacic.EnCrypt(GetIP                                                             ),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_versao_cacic']   := StringReplace(g_oCacic.EnCrypt(g_oCacic.getVersionInfo(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName)),'+','<MAIS>',[rfReplaceAll]);
    v_AuxRequest.Values['te_versao_gercols'] := StringReplace(g_oCacic.EnCrypt(g_oCacic.getVersionInfo(ParamStr(0))                                       ),'+','<MAIS>',[rfReplaceAll]);

    v_TeWebServicesFolder := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','TeWebServicesFolder', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    v_TeWebManagerAddress := g_oCacic.getWebManagerAddress;

    g_oCacic.writeDebugLog('v_TeWebServicesFolder : "' + v_TeWebServicesFolder + '"');
    g_oCacic.writeDebugLog('v_TeWebManagerAddress : "' + v_TeWebManagerAddress + '"');

    if (trim(v_TeWebServicesFolder)='') then
      Begin
        v_TeWebServicesFolder := '/ws/';
        g_oCacic.setValueToFile('Configs','TeWebServicesFolder', g_oCacic.enCrypt(v_TeWebServicesFolder), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      End;

    if (trim(v_TeWebManagerAddress)='') then
        v_TeWebManagerAddress := Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getWinDir + 'chksis.ini')));

    strEndereco := 'http://' + v_TeWebManagerAddress + v_TeWebServicesFolder + URL;

    if (trim(MsgAcao)='') then
        MsgAcao := 'Enviando informações iniciais ao Gerente WEB.';

    if (trim(MsgAcao)<>'.') then
        g_oCacic.writeDailyLog(MsgAcao);

    Response_CS := TStringStream.Create('');

    g_oCacic.writeDebugLog('Iniciando comunicação com http://' + v_TeWebManagerAddress + v_TeWebServicesFolder + URL);

    Try
       idHTTP1 := TIdHTTP.Create(nil);
       idHTTP1.AllowCookies                     := true;
       idHTTP1.ASCIIFilter                      := false; // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.AuthRetries                      := 1;     // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.BoundPort                        := 0;
       idHTTP1.HandleRedirects                  := false;
       idHTTP1.ProxyParams.BasicAuthentication  := false;
       idHTTP1.ProxyParams.ProxyPort            := 0;
       idHTTP1.ReadTimeout                      := 0;
       idHTTP1.RedirectMaximum                  := 15;
       idHTTP1.Request.UserAgent                := StringReplace(g_oCacic.enCrypt('AGENTE_CACIC'),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Username                 := StringReplace(g_oCacic.enCrypt('USER_CACIC'),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Password                 := StringReplace(g_oCacic.enCrypt('PW_CACIC'),'+','<MAIS>',[rfReplaceAll]);
       idHTTP1.Request.Accept                   := 'text/html, */*';
       idHTTP1.Request.BasicAuthentication      := true;
       idHTTP1.Request.ContentLength            := -1;
       idHTTP1.Request.ContentRangeStart        := 0;
       idHTTP1.Request.ContentRangeEnd          := 0;
       idHTTP1.Request.ContentType              := 'text/html';
       idHTTP1.RecvBufferSize                   := 32768; // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.SendBufferSize                   := 32768; // ATENÇÃO: Esta propriedade deixa de existir na próxima versão do Indy (10.x)
       idHTTP1.Tag                              := 0;

       // ATENÇÃO: Substituo os sinais de "+" acima por <MAIS> devido a problemas encontrados no envio POST

       if g_oCacic.inDebugMode then
          Begin
            g_oCacic.writeDebugLog('te_so => '+g_oCacic.getWindowsStrId);
            g_oCacic.writeDebugLog('Valores de REQUEST para envio ao Gerente WEB:');
            for intAux := 0 to v_AuxRequest.count -1 do
                g_oCacic.writeDebugLog('#'+inttostr(intAux)+': '+v_AuxRequest[intAux]);
          End;

       IdHTTP1.Post(strEndereco, v_AuxRequest, Response_CS);
       idHTTP1.Disconnect;
       idHTTP1.Free;

       g_oCacic.writeDebugLog('Retorno: "'+Response_CS.DataString+'"');
    Except
       g_oCacic.writeDailyLog('ERRO! Comunicação impossível com o endereço ' + strEndereco + Response_CS.DataString);
       result := '0';
       Exit;
    end;

    Try
      strAux := 'N';
      if (UpperCase(g_oCacic.xmlGetValue('Status', Response_CS.DataString)) <> 'OK') Then
        Begin
           g_oCacic.writeDailyLog('PROBLEMAS DURANTE A COMUNICAÇÃO:');
           g_oCacic.writeDailyLog('Endereço: ' + strEndereco);
           g_oCacic.writeDailyLog('Mensagem: ' + Response_CS.DataString);
           result := '0';
        end
      Else
        Begin
           strAux := 'S';
           result := Response_CS.DataString;
        end;
      g_oCacic.setValueToFile('Configs','ConexaoOK',g_oCacic.enCrypt(strAux),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      Response_CS.Free;
    Except
      Begin
        g_oCacic.writeDailyLog('PROBLEMAS DURANTE A COMUNICAÇÃO:');
        g_oCacic.writeDailyLog('Endereço: ' + strEndereco);
        g_oCacic.writeDailyLog('Mensagem: ' + Response_CS.DataString);
        result := '0';
      End;
    End;
end;

// Baixada de http://www.geocities.com/SiliconValley/Bay/1058/fdelphi.html
Function Rat(OQue: String; Onde: String) : Integer;
//  Procura uma string dentro de outra, da direita para esquerda
//  Retorna a posição onde foi encontrada ou 0 caso não seja encontrada
var
Pos   : Integer;
Tam1  : Integer;
Tam2  : Integer;
Achou : Boolean;
begin
Tam1   := Length(OQue);
Tam2   := Length(Onde);
Pos    := Tam2-Tam1+1;
Achou  := False;
while (Pos >= 1) and not Achou do
      begin
      if Copy(Onde, Pos, Tam1) = OQue then
         begin
         Achou := True
         end
      else
         begin
         Pos := Pos - 1;
         end;
      end;
Result := Pos;
end;

Function PegaDadosIPConfig(p_array_campos: TStringList; p_array_valores: TStringList; p_tripa:String; p_excecao:String): String;
var tstrOR, tstrAND, tstrEXCECOES : TStrings;
var intAux1, intAux2, intAux3, intAux4, v_conta, v_conta_EXCECOES : integer;

Begin
   Result   := '';
   tstrOR   := g_oCacic.explode(p_tripa,';'); // OR

    for intAux1 := 0 to tstrOR.Count-1 Do
      Begin
        tstrAND  := g_oCacic.explode(tstrOR[intAux1],','); // AND
        for intAux2 := 0 to p_array_campos.Count-1 Do
          Begin
            v_conta := 0;
            for intAux3 := 0 to tstrAND.Count-1 Do
              Begin
                if (LastPos(tstrAND[intAux3],StrLower(PChar(p_array_campos[intAux2]))) > 0) then
                  Begin
                    v_conta := v_conta + 1;
                  End;
              End;
            if (v_conta = tstrAND.Count) then
              Begin
                v_conta_EXCECOES := 0;
                if (p_excecao <> '') then
                  Begin
                    tstrEXCECOES  := g_oCacic.explode(p_excecao,','); // Excecoes a serem tratadas
                    for intAux4 := 0 to tstrEXCECOES.Count-1 Do
                      Begin
                        if (rat(tstrEXCECOES[intAux4],p_array_valores[intAux2]) > 0) then
                          Begin
                            v_conta_EXCECOES := 1;
                            break;
                          End;
                      End;
                  End;
              if (v_conta_EXCECOES = 0) then
                Begin
                  Result := p_array_valores[intAux2];
                  break;
                End;
              End;
          End;
        if (v_conta = tstrAND.Count) then
          Begin
            break;
          End
        else
          Begin
            Result := '';
          End;
      End;
End;

Function FTP_Get(strHost, strUser, strPass, strArq, strDirOrigem, strDirDestino, strTipo : String; intPort : integer) : Boolean;
var IdFTP1 : TIdFTP;
begin
    g_oCacic.writeDebugLog('Instanciando FTP...');
    IdFTP1                := TIdFTP.Create(IdFTP1);
    g_oCacic.writeDebugLog('FTP Instanciado!');
    IdFTP1.Host           := strHost;
    IdFTP1.Username       := strUser;
    IdFTP1.Password       := strPass;
    IdFTP1.Port           := intPort;
    IdFTP1.Passive        := true;
    if (strTipo = 'ASC') then
      IdFTP1.TransferType := ftASCII
    else
      IdFTP1.TransferType := ftBinary;

    g_oCacic.writeDebugLog('Iniciando FTP de '+strArq +' para '+StringReplace(strDirDestino + '\' + strArq,'\\','\',[rfReplaceAll]));
    g_oCacic.writeDebugLog('Host........ ='+IdFTP1.Host);
    g_oCacic.writeDebugLog('UserName.... ='+IdFTP1.Username);
    g_oCacic.writeDebugLog('Port........ ='+inttostr(IdFTP1.Port));
    g_oCacic.writeDebugLog('Pasta Origem ='+strDirOrigem);

    Try
      if IdFTP1.Connected = true then
        begin
          IdFTP1.Disconnect;
        end;
      IdFTP1.Connect;
      IdFTP1.ChangeDir(strDirOrigem);
      Try
        // Substituo \\ por \ devido a algumas vezes em que o DirDestino assume o valor de DirTemp...
        g_oCacic.writeDebugLog('FTP - Size de "'+strArq+'" Antes => '+IntToSTR(IdFTP1.Size(strArq)));
        IdFTP1.Get(strArq, StringReplace(strDirDestino + '\' + strArq,'\\','\',[rfReplaceAll]), True);
        g_oCacic.writeDebugLog('FTP - Size de "'+strDirDestino + '\' + strArq +'" Após => '+Get_File_Size(strDirDestino + '\' + strArq,true));
      Finally
        result := true;
        g_oCacic.writeDebugLog('FTP - Size de "'+strDirDestino + '\' + strArq +'" Após em Finally => '+Get_File_Size(strDirDestino + '\' + strArq,true));
        idFTP1.Disconnect;
        IdFTP1.Free;
      End;
    Except
        g_oCacic.writeDebugLog('FTP - Erro - Size de "'+strDirDestino + '\' + strArq +'" Após em Except => '+Get_File_Size(strDirDestino + '\' + strArq,true));
        result := false;
    end;
end;

procedure CriaTXT(p_Dir, p_File : string);
var v_TXT : TextFile;
begin
  AssignFile(v_TXT,p_Dir + '\' + p_File + '.txt'); {Associa o arquivo a uma variável do tipo TextFile}
  Rewrite (v_TXT);
  Closefile(v_TXT);
end;

function Ver_UPD(p_File, p_Nome_Modulo, p_Dir_Inst, p_Dir_Temp : string; p_Medir_FTP:boolean) : integer;
var Baixar      : boolean;
    strAux,
    strAux1,
    v_versao_disponivel,
    v_Dir_Temp,
    v_versao_atual,
    strHashLocal,
    strHashRemoto : String;
Begin
   Result := 0;
   Try
       if (trim(p_Dir_Temp)='') then
         v_Dir_Temp := p_Dir_Inst
       else
         v_Dir_Temp := p_Dir_Temp;

       if p_Medir_FTP then
         g_oCacic.writeDebugLog('Verificando necessidade de FTP para "'+p_Nome_Modulo +'" ('+p_File+')');

       v_versao_disponivel := '';
       v_versao_atual      := '';
       if not (p_Medir_FTP) then
          Begin
            v_versao_disponivel := StringReplace(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs',UpperCase('DT_VERSAO_'+ p_File + '_DISPONIVEL'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),'.EXE','',[rfReplaceAll]);

            g_oCacic.writeDebugLog('Versão Disponível para "'+p_Nome_Modulo+'": '+v_versao_disponivel);
            if (trim(v_versao_disponivel)='') then v_versao_disponivel := '*';

            v_versao_atual := trim(StringReplace(g_oCacic.GetVersionInfo(p_Dir_Inst + p_File + '.exe'),'.','',[rfReplaceAll]));

            if (v_versao_atual = '0.0.0.0') then
              Begin
                g_oCacic.killFiles(p_Dir_Inst,p_File + '.exe');
                v_versao_atual := '';
              End;

            // Atenção: Foi acrescentada a string "0103", símbolo do dia/mês de primeira release, para simular versão maior no GER_COLS até 02/2005.
            // Solução provisória até total convergência das versões para 2.0.1.x
            if (v_versao_atual <> '') then v_versao_atual := v_versao_atual + '0103';
          End;

       v_Tamanho_Arquivo := Get_File_Size(p_Dir_Inst + p_File + '.exe',true);
       Baixar := false;

       g_oCacic.writeDebugLog('Verificando Existência de "'+p_Dir_Inst + p_File + '.exe');
       if not (FileExists(p_Dir_Inst + p_File + '.exe')) then
          Begin
            if (p_Medir_FTP) then
              Result := 1
            else
              Begin
                g_oCacic.writeDailyLog(p_Nome_Modulo + '('+p_Dir_Inst + p_File + '.exe) inexistente');
                g_oCacic.writeDailyLog('Efetuando FTP do ' + p_Nome_Modulo);
                Baixar := true;
                Result := 2;
              End
          End
       else
          Begin
            strHashLocal  := g_oCacic.getFileHash(p_Dir_Inst + p_File + '.exe');

            strHashRemoto := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','TE_HASH_'+UpperCase(p_File), g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

            g_oCacic.writeDebugLog('Ver_UPD => '+p_File+'  [strHashLocal]: '+strHashLocal+' [strHashRemoto]: '+strHashRemoto);
           if ((strHashRemoto <> '') and (strHashLocal <> strHashRemoto)) or (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') or (trim(g_oCacic.GetVersionInfo(p_Dir_Inst + p_File + '.exe'))='0.0.0.0') then
              Begin
                if (p_Medir_FTP) then
                  Result := 1
                else
                  Begin
                    g_oCacic.writeDailyLog('Efetuando FTP do ' + p_Nome_Modulo);
                    Baixar := true;
                    Result := 2;
                  End;
              End;
          End;

       if (Baixar) or ((v_versao_atual <> v_versao_disponivel) and (v_versao_disponivel <> '*')) Then
        Begin
           if (v_versao_atual <> v_versao_disponivel) and not Baixar then
                g_oCacic.writeDailyLog('Recebendo módulo ' + p_Nome_Modulo);

           Try
             g_oCacic.writeDebugLog('Baixando: '+ p_File + '.exe para '+v_Dir_Temp);
             if (FTP_Get(g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','TE_SERV_UPDATES', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),
                         g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','NM_USUARIO_LOGIN_SERV_UPDATES', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),
                         g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','TE_SENHA_LOGIN_SERV_UPDATES', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),
                         p_File + '.exe',
                         g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','TE_PATH_SERV_UPDATES', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),
                         v_Dir_Temp,
                         'BIN',
                         strtoint(g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','NU_PORTA_SERV_UPDATES', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)))) = False) Then
               Begin
                g_oCacic.writeDailyLog('ERRO!');
                strAux  := 'Não foi possível baixar o módulo "'+ p_Nome_Modulo + '".';
                strAux1 := 'Verifique se foi disponibilizado no Servidor de Updates pelo administrador do Gerente WEB.';
                g_oCacic.writeDailyLog(strAux);
                g_oCacic.writeDailyLog(strAux1);
                if (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','IN_EXIBE_ERROS_CRITICOS', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') Then
                  Begin
                    g_oCacic.setValueToFile('Mensagens','CsTipo', g_oCacic.enCrypt( 'mtError'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Mensagens','TeMensagem', g_oCacic.enCrypt( strAux + '. ' + strAux1), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                  End;
               end
             else g_oCacic.writeDailyLog('Versão Atual-> '+v_versao_atual+' / Versão Recebida-> '+v_versao_disponivel);
           Except
              g_oCacic.writeDailyLog('Não foi possível baixar o módulo '+ p_Nome_Modulo + '.');
           End;
        end;
   Except
        Begin
          CriaTXT(g_oCacic.getLocalFolder,'ger_erro');
          g_oCacic.setValueToFile('Mensagens','CsTipo'    ,g_oCacic.enCrypt( 'mtWarning'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
          g_oCacic.setValueToFile('Mensagens','TeMensagem',g_oCacic.enCrypt( 'PROBLEMAS COM ROTINA DE EXECUÇÃO DE UPDATES DE VERSÕES. Não foi possível baixar o módulo '+ p_Nome_Modulo + '.'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
          g_oCacic.writeDailyLog('PROBLEMAS COM ROTINA DE EXECUÇÃO DE UPDATES DE VERSÕES.');
        End;
   End;
End;

function ChecaAgente(agentFolder, agentName : String) : boolean;
Begin
  Result := true;

  g_oCacic.writeDebugLog('Verificando existência e tamanho de "'+agentFolder+'\'+agentName+'"');
  v_Tamanho_Arquivo := Get_File_Size(agentFolder+'\'+agentName,true);

  g_oCacic.writeDebugLog('Resultado: #'+v_Tamanho_Arquivo);

  if (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') then
    Begin
      Result := false;

      g_oCacic.killFiles(agentFolder+'\',agentName);

      Ver_UPD(StringReplace(LowerCase(agentName),'.exe','',[rfReplaceAll]),agentName,agentFolder+'\','Temp',false);

      sleep(15000); // 15 segundos de espera para download do agente
      v_Tamanho_Arquivo := Get_File_Size(agentFolder+'\'+agentName,true);
      if not(v_Tamanho_Arquivo = '0') and not(v_Tamanho_Arquivo = '-1') then
        Begin
          g_oCacic.writeDailyLog('Agente "'+agentFolder+'\'+agentName+'" RECUPERADO COM SUCESSO!');
          Result := True;
        End
      else
          g_oCacic.writeDailyLog('Agente "'+agentFolder+'\'+agentName+'" NÃO RECUPERADO!');
    End;
End;

{
procedure ChecaCipher;
begin
    // Os valores possíveis serão 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Será transformado em "1") 3-Ainda se comunicará com o Gerente WEB
    g_oCacic.setBoolCipher(true);
    v_Aux := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_CIPHER', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

    g_oCacic.setBoolCipher(false);
    if (v_Aux='1') or (v_Aux='2') then
        Begin
          g_oCacic.setBoolCipher(true);
          g_oCacic.setValueToFile('Configs','CS_CIPHER',g_oCacic.enCrypt('1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        End
    else
        g_oCacic.setValueToFile('Configs','CS_CIPHER',g_oCacic.enCrypt('3'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
end;

procedure ChecaCompress;
begin
    // Os valores possíveis serão 0-DESLIGADO 1-LIGADO 2-ESPERA PARA LIGAR (Será transformado em "1") 3-Ainda se comunicará com o Gerente WEB
    l_cs_compress  := false;
    v_Aux := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COMPRESS', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    if (v_Aux='1') or (v_Aux='2') then
        Begin
          l_cs_compress  := true;
          g_oCacic.setValueToFile('Configs','CS_COMPRESS',g_oCacic.enCrypt('1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        End
    else
        g_oCacic.setValueToFile('Configs','CS_COMPRESS',g_oCacic.enCrypt('3'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
end;
}
procedure BuscaConfigs(p_mensagem_log : boolean);
var
  Request_SVG,
  v_array_campos,
  v_array_valores,
  v_Report          : TStringList;

  intAux1,
  intAux2,
  intAux3,
  intAux4,
  v_conta_EXCECOES,
  v_index_ethernet  : integer;

  strRetorno,
  strTripa,
  strAux3,
  ValorChaveRegistro,
  ValorRetornado,
  v_mensagem_log,
  v_mascara,
  te_ip,
  te_mascara,
  te_gateway,
  te_serv_dhcp,
  te_dns_primario,
  te_dns_secundario,
  te_wins_primario,
  te_wins_secundario,
  te_nome_host,
  te_dominio_dns,
  te_dominio_windows,
  v_mac_address,
  v_metodo_obtencao,
  v_nome_arquivo,
  IpConfigLINHA,
  v_enderecos_mac_invalidos,
  v_win_dir,
  v_dir_command,
  v_dir_ipcfg,
  v_win_dir_command,
  v_win_dir_ipcfg,
  v_serv_cacic,
  strKeyWord     : string;

  tstrTripa1,
  tstrTripa2,
  tstrTripa3,
  tstrTripa4,
  tstrTripa5,
  tstrEXCECOES        : TStrings;

  IpConfigTXT,
  chksis_ini,
  textfileKeyWord     : TextFile;

  v_oMachine          : TMiTec_Machine;
  v_TCPIP             : TMiTeC_TCPIP;
  v_NETWORK           : TMiTeC_Network;
Begin
  Try
    {
    ChecaCipher;
    ChecaCompress;
    }

    v_acao_gercols := 'Instanciando TMiTeC_Machine...';
    v_oMachine := TMiTec_Machine.Create(nil);
    v_oMachine.RefreshData();

    v_acao_gercols := 'Instanciando TMiTeC_TcpIp...';
    v_TCPIP := TMiTeC_tcpip.Create(nil);
    v_tcpip.RefreshData;

    // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
    // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI MiTeC.
    if (g_oCacic.inDebugMode) then
      Begin
        g_oCacic.writeDebugLog('Montando ambiente para busca de configurações...');
        v_Report := TStringList.Create;
        MSI_XML_Reports.TCPIP_XML_Report(v_TCPIP,true,v_Report);
        for intAux1:=0 to v_Report.count-1 do
            Grava_Debugs(v_report[intAux1]);

        v_Report.Free;
      End;
    v_tcpip.RefreshData;

    v_index_ethernet := -1;

    for intAux1:=0 to v_tcpip.AdapterCount -1 do
        if (v_index_ethernet=-1) and (v_tcpip.Adapter[intAux1].Typ=atEthernet) and (v_tcpip.Adapter[intAux1].IPAddress[0]<>'0.0.0.0') then v_index_ethernet := intAux1;

    if (v_index_ethernet=-1) then
        v_index_ethernet := 0;

    Try v_mac_address      := v_tcpip.Adapter[v_index_ethernet].Address                    except v_mac_address       := ''; end;
    Try te_mascara         := v_tcpip.Adapter[v_index_ethernet].IPAddressMask[0]           except te_mascara          := ''; end;
    Try te_ip              := v_tcpip.Adapter[v_index_ethernet].IPAddress[0]               except te_ip               := ''; end;
    Try te_nome_host       := v_oMachine.MachineName                                       except te_nome_host        := ''; end;

    if (v_mac_address='') or (te_ip='') then
      Begin
        v_acao_gercols := 'Instanciando TMiTeC_Network...';
        v_NETWORK := TMiTeC_Network.Create(nil);
        v_NETWORK.RefreshData;

        // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
        // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI MiTeC.
        v_acao_gercols := 'Instanciando Report para TMiTeC_Network...';
        v_Report := TStringList.Create;
        if (g_oCacic.inDebugMode) then
          Begin
            v_acao_gercols := 'Gerando Report para TMiTeC_Network...';
            MSI_XML_Reports.Network_XML_Report(v_NETWORK,true,v_Report);

            for intAux1:=0 to v_Report.count-1 do
              Begin
                v_acao_gercols := 'Gravando Report para TMiTeC_Network...';
                Grava_Debugs(v_report[intAux1]);
              End;
          End;
        v_NETWORK.RefreshData;

        v_mac_address  := parse('TNetwork','MACAdresses','MACAddress[0]',v_Report);
        te_ip          := parse('TNetwork','IPAddresses','IPAddress[0]',v_Report);

        v_Report.Free;
      End;

    // Verifico comunicação com o Módulo Gerente WEB.
    Request_SVG := TStringList.Create;
    Request_SVG.Values['in_teste']          := StringReplace(g_oCacic.enCrypt('OK'),'+','<MAIS>',[rfReplaceAll]);

    v_acao_gercols := 'Preparando teste de comunicação com Módulo Gerente WEB.';

    g_oCacic.writeDebugLog('Teste de Comunicação.');

    Try
      v_TeWebManagerAddress := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','TeWebManagerAddress', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

      intAux2 := (v_tcpip.Adapter[v_index_ethernet].IPAddress.Count)-1;
      if intAux2 < 0 then intAux2 := 0;

      // Testando a comunicação com o Módulo Gerente WEB.
      for intAux1 := 0 to intAux2 do
        Begin
          v_acao_gercols := 'Setando Request.te_ip com ' + v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1];
          g_oCacic.setValueToFile('TcpIp','TE_IP',g_oCacic.enCrypt( v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1]), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
          Try
            strRetorno := ComunicaServidor('get_config.php', Request_SVG, 'Testando comunicação com o Módulo Gerente WEB.');
            {
            Seta_boolCipher(strRetorno);
            Seta_l_cs_compress(strRetorno);
            }

            v_Aux := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_WEB_MANAGER_ADDRESS', strRetorno));
            if (v_TeWebManagerAddress <> v_Aux) and (v_Aux <> '') then
               g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.enCrypt(Trim(v_Aux)), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

            if (strRetorno <> '0') and (g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_rede_ok', strRetorno))<>'N') Then
              Begin
                v_acao_gercols := 'IP/Máscara usados: ' + v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1]+'/'+v_tcpip.Adapter[v_index_ethernet].IPAddressMask[intAux1]+' validados pelo Módulo Gerente WEB.';
                te_ip      := v_tcpip.Adapter[v_index_ethernet].IPAddress[intAux1];
                te_mascara := v_tcpip.Adapter[v_index_ethernet].IPAddressMask[intAux1];
                g_oCacic.writeDailyLog(v_acao_gercols);
                break;
              End;
          except g_oCacic.writeDailyLog('Insucesso na comunicação com o Módulo Gerente WEB.');
          end
        End;
    Except
      Begin
        v_acao_gercols := 'Teste de comunicação com o Módulo Gerente WEB.';

        // Nova tentativa, preciso reinicializar o objeto devido aos restos da operação anterior... (Eu acho!)  :)
        Request_SVG.Free;
        Request_SVG := TStringList.Create;
        Request_SVG.Values['in_teste']          := StringReplace(g_oCacic.enCrypt('OK'),'+','<MAIS>',[rfReplaceAll]);
        Try
          strRetorno := ComunicaServidor('get_config.php', Request_SVG, 'Teste de comunicação com o Módulo Gerente WEB.');
          {
          Seta_boolCipher(strRetorno);
          Seta_l_cs_compress(strRetorno);
          }

          v_Aux := g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_WEB_MANAGER_ADDRESS', strRetorno));
          if (v_TeWebManagerAddress <> v_Aux) and (v_Aux <> '') then
             g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.enCrypt( Trim(v_Aux)), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

          if (strRetorno <> '0') and (g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_rede_ok', strRetorno))<>'N') Then
            Begin
              v_acao_gercols := 'IP validado pelo Módulo Gerente WEB.';
              g_oCacic.writeDailyLog(v_acao_gercols);
            End
          else g_oCacic.writeDailyLog('Insucesso na comunicação com o Módulo Gerente WEB.');
        except
          g_oCacic.writeDailyLog('Problemas no teste de comunicação com o Módulo Gerente WEB.');
        end;
      End;
    End;
    Request_SVG.Free;

    Try te_gateway         := v_tcpip.Adapter[v_index_ethernet].Gateway_IPAddress[0]       except te_gateway          := ''; end;
    Try te_serv_dhcp       := v_tcpip.Adapter[v_index_ethernet].DHCP_IPAddress[0]          except te_serv_dhcp        := ''; end;
    Try te_dns_primario    := v_tcpip.DNSServers[0]                                        except te_dns_primario     := ''; end;
    Try te_dns_secundario  := v_tcpip.DNSServers[1]                                        except te_dns_secundario   := ''; end;
    Try te_wins_primario   := v_tcpip.Adapter[v_index_ethernet].PrimaryWINS_IPAddress[0]   except te_wins_primario    := ''; end;
    Try te_wins_secundario := v_tcpip.Adapter[v_index_ethernet].SecondaryWINS_IPAddress[0] except te_wins_secundario  := ''; end;
    Try te_dominio_dns     := v_tcpip.DomainName                                           except te_dominio_dns      := ''; end;

    v_acao_gercols := 'Setando endereço WS para /ws/';
    // Setando /ws/ como caminho de pseudo-WebServices
    g_oCacic.setValueToFile('Configs','TeWebServicesFolder',g_oCacic.enCrypt( '/ws/' ), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

    v_acao_gercols := 'Setando TE_FILA_FTP=0';
    // Setando controle de FTP para 0 (0=tempo de espera para FTP   de algum componente do sistema)
    g_oCacic.setValueToFile('Configs','TE_FILA_FTP',g_oCacic.enCrypt('0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    CountUPD := 0;

    // Verifico e contabilizo as necessidades de FTP dos agentes (instalação ou atualização)
    // Para possível requisição de acesso ao grupo FTP... (Essa medida visa balancear o acesso aos servidores de atualização de versões, principalmente quando é um único S.A.V.)
    v_acao_gercols := 'Contabilizando necessidade de Updates...';

    // O valor "true" para o 5º parâmetro da função Ver_UPD informa para apenas verificar a necessidade de FTP do referido objeto.
    CountUPD := CountUPD + Ver_UPD(StringReplace(v_scripter,'.exe','',[rfReplaceAll]) ,'Interpretador VBS'                                ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('chksis'                                           ,'Verificador de Integridade do Sistema'            ,g_oCacic.getWinDir                  ,'',true);
    CountUPD := CountUPD + Ver_UPD('cacicservice'                                     ,'Serviço para Sustentação do Sistema'              ,g_oCacic.getWinDir                  ,g_oCacic.getWinDir + 'Temp',true);
    CountUPD := CountUPD + Ver_UPD(StringReplace(LowerCase(g_oCacic.getMainProgramName),'.exe','',[rfReplaceAll]),'Agente Principal'      ,g_oCacic.getLocalFolder             ,g_oCacic.getLocalFolder + 'Temp',true);
    CountUPD := CountUPD + Ver_UPD('srcacicsrv'                                       ,'Suporte Remoto Seguro'                            ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('ger_cols'                                         ,'Gerente de Coletas'                               ,g_oCacic.getLocalFolder + 'Modulos\',g_oCacic.getLocalFolder + 'Temp',true);
    CountUPD := CountUPD + Ver_UPD('col_anvi'                                         ,'Coletor de Informações de Anti-Vírus OfficeScan'  ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_comp'                                         ,'Coletor de Informações de Compartilhamentos'      ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_hard'                                         ,'Coletor de Informações de Hardware'               ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_moni'                                         ,'Coletor de Informações de Sistemas Monitorados'   ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_soft'                                         ,'Coletor de Informações de Softwares Básicos'      ,g_oCacic.getLocalFolder + 'Modulos\','',true);
    CountUPD := CountUPD + Ver_UPD('col_undi'                                         ,'Coletor de Informações de Unidades de Disco'      ,g_oCacic.getLocalFolder + 'Modulos\','',true);



    // Verifica existência dos dados de configurações principais e estado de CountUPD. Caso verdadeiro, simula uma instalação pelo chkCACIC...
    if  ((g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','TE_SERV_UPDATES'              , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
         (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','NM_USUARIO_LOGIN_SERV_UPDATES', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
         (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','TE_SENHA_LOGIN_SERV_UPDATES'  , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
         (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','TE_PATH_SERV_UPDATES'         , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
         (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','NU_PORTA_SERV_UPDATES'        , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
         (g_oCacic.deCrypt(g_oCacic.getValueFromFile('TcpIp','TE_ENDERECOS_MAC_INVALIDOS'     , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
         (CountUPD > 0)) and
         (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Configs','ID_FTP', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') then
        Begin
          g_oCacic.writeDebugLog('Preparando contato com módulo Gerente WEB para Downloads.');
          v_acao_gercols := 'Contactando o módulo Gerente WEB: get_config.php...';
          Request_SVG := TStringList.Create;
          Request_SVG.Values['in_chkcacic']   := StringReplace(g_oCacic.enCrypt('chkcacic'),'+','<MAIS>',[rfReplaceAll]);
          Request_SVG.Values['te_fila_ftp']   := StringReplace(g_oCacic.enCrypt('1'),'+','<MAIS>',[rfReplaceAll]); // Indicará que o agente quer entrar no grupo para FTP
          //Request_SVG.Values['id_ip_estacao'] := EnCrypt(GetIP,l_cs_compress); // Informará o IP para registro na tabela redes_grupos_FTP

          g_oCacic.writeDebugLog(v_acao_gercols + ' Parâmetros: in_chkcacic="'+Request_SVG.Values['in_chkcacic']+'", te_fila_ftp="'+Request_SVG.Values['te_fila_ftp']+'" e id_ip_estacao="'+Request_SVG.Values['id_ip_estacao']+'"');
          strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);
          {
          Seta_boolCipher(strRetorno);
          Seta_l_cs_compress(strRetorno);
          }

          Request_SVG.Free;
          if (strRetorno <> '0') Then
            Begin
              g_oCacic.setValueToFile('Configs','TE_SERV_UPDATES'              ,g_oCacic.xmlGetValue('te_serv_updates'                   , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','NM_USUARIO_LOGIN_SERV_UPDATES',g_oCacic.xmlGetValue('nm_usuario_login_serv_updates'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','TE_SENHA_LOGIN_SERV_UPDATES'  ,g_oCacic.xmlGetValue('te_senha_login_serv_updates'       , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','TE_PATH_SERV_UPDATES'         ,g_oCacic.xmlGetValue('te_path_serv_updates'              , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','NU_PORTA_SERV_UPDATES'        ,g_oCacic.xmlGetValue('nu_porta_serv_updates'             , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','TE_FILA_FTP'                  ,g_oCacic.xmlGetValue('te_fila_ftp'                       , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','ID_FTP'                       ,g_oCacic.xmlGetValue('id_ftp'                            , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('TcpIp'  ,'TE_ENDERECOS_MAC_INVALIDOS'   ,g_oCacic.xmlGetValue('te_enderecos_mac_invalidos'        , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
            End;
        End;

    v_Aux := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','TE_FILA_FTP', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

    v_acao_gercols := 'Verificando versões do scripter e chksis';
    g_oCacic.writeDebugLog(''+v_acao_gercols);

    Ver_UPD(StringReplace(v_scripter,'.exe','',[rfReplaceAll]) ,'Interpretador VBS'                    ,g_oCacic.getLocalFolder + 'Modulos\','',false);
    Ver_UPD('chksis'                                           ,'Verificador de Integridade do Sistema',g_oCacic.getWinDir                  ,'',false);

    g_oCacic.killFiles(g_oCacic.getWinDir + 'Temp','cacicservice.exe');
    if (Ver_UPD('cacicservice'                                 ,'Serviço para Sustentação do Sistema'  ,g_oCacic.getWinDir                  ,g_oCacic.getWinDir + 'Temp\',false) = 2) then
      g_oCacic.setValueToFile('Configs','TeServiceProgramHash' ,g_oCacic.enCrypt( g_oCacic.getFileHash( g_oCacic.getWinDir + 'Temp\CACICservice.exe')),g_oCacic.getWinDir + 'chksis.ini');

    // Caso seja necessário fazer algum FTP e o Módulo Gerente Web tenha devolvido um tempo para espera eu finalizo e espero o tempo para uma nova tentativa
    if (CountUPD > 0) and (v_Aux <> '') and (v_Aux <> '0') then
      Begin
        g_oCacic.writeDebugLog('Finalizando para nova tentativa de FTP em '+v_Aux+' minuto(s)');
        Finalizar(true);
        Sair;
      End;


    // O módulo de Suporte Remoto é opcional, através da opção Administração / Módulos
    {
    g_oCacic.writeDailyLog('Verificando nova versão para módulo Suporte Remoto Seguro.');
    // Caso encontre nova versão de srCACICsrv esta será gravada em Modulos.
    Ver_UPD('srcacicsrv','Suporte Remoto Seguro',g_oCacic.getLocalFolder + 'Modulos\','',false);
    }

    // Verifico existência do chksis.ini
    if not (FileExists(g_oCacic.getWinDir + 'chksis.ini')) then
      Begin
         Try
           v_acao_gercols := 'chksis.ini inexistente, recriando...';
           g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.getWebManagerAddress, g_oCacic.getWinDir + 'chksis.ini');
           g_oCacic.setValueToFile('Configs','TeLocalFolder'      ,g_oCacic.getLocalFolder      , g_oCacic.getWinDir + 'chksis.ini');
           g_oCacic.setValueToFile('Configs','TeMainProgramName'  ,g_oCacic.getMainProgramName  , g_oCacic.getWinDir + 'chksis.ini');
           g_oCacic.setValueToFile('Configs','TeMainProgramHash'  ,g_oCacic.getMainProgramHash  , g_oCacic.getWinDir + 'chksis.ini');
         Except
           g_oCacic.writeDailyLog('Erro na recuperação de chksis.');
         End;
      End;

    v_mensagem_log  := 'Obtendo configurações a partir do Gerente WEB.';

    if (not p_mensagem_log) then v_mensagem_log := '';

  // Caso a obtenção dos dados de TCP via MSI_NETWORK/TCP tenha falhado...
  if (v_mac_address='') or (te_mascara='')    or (te_ip='')           or (te_gateway='') or
     (te_nome_host='')  or (te_serv_dhcp='' ) or (te_dns_primario='') or (te_wins_primario='') or
     (te_wins_secundario='') then
    Begin
      v_nome_arquivo    := g_oCacic.getLocalFolder + 'Temp\ipconfig.txt';
      v_metodo_obtencao := 'WMI Object';
      v_acao_gercols    := 'Criando batch para obtenção de IPCONFIG via WMI...';
      Try
         Batchfile := TStringList.Create;
         Batchfile.Add('Dim FileSys,FileSysOk,IPConfigFile,IPConfigFileOK,strComputer,objWMIService,colItems,colUser,v_ok');
         Batchfile.Add('Set FileSys  = WScript.CreateObject("Scripting.FileSystemObject")');
         Batchfile.Add('Set IPConfigFile= FileSys.CreateTextFile("'+ v_nome_arquivo + '", True)');
         Batchfile.Add('On Error Resume Next');
         Batchfile.Add('strComputer = "."');
         Batchfile.Add('v_ok        = ""');
         Batchfile.Add('Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")');
         Batchfile.Add('Set colItems      = objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE")');
         Batchfile.Add('For Each objItem in colItems');
         Batchfile.Add('  ipconfigfile.WriteLine "Endereço físico.........: " & objItem.MACAddress');
         Batchfile.Add('  ipconfigfile.WriteLine "Endereço ip.............: " & objItem.IPAddress(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Máscara de Sub-rede.....: " & objItem.IPSubnet(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Gateway padrão..........: " & objItem.DefaultIPGateway(i)');
         Batchfile.Add('  ipconfigfile.WriteLine "Nome do host............: " & objItem.DNSHostName');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor DHCP...........: " & objItem.DHCPServer');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidores DNS..........: " & objItem.DNSDomain');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor WINS Primario..: " & objItem.WINSPrimaryServer');
         Batchfile.Add('  ipconfigfile.WriteLine "Servidor WINS Secundario: " & objItem.WINSSecondaryServer');
         Batchfile.Add('  v_ok = "OK"');
         Batchfile.Add('Next');
         Batchfile.Add('Set GetUser = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")');
         Batchfile.Add('Set colUser       = GetUser.ExecQuery("Select * from Win32_ComputerSystem")');
         Batchfile.Add('For Each objUser in colUser');
         Batchfile.Add('	ipconfigfile.WriteLine "Domínio/Usuário Logado..: " & objUser.UserName');
         Batchfile.Add('Next');
         Batchfile.Add('IPConfigFile.Close');
         Batchfile.Add('if v_ok = "OK" then');
         Batchfile.Add('  Set FileSysOK      = WScript.CreateObject("Scripting.FileSystemObject")');
         Batchfile.Add('  Set IPConfigFileOK = FileSysOK.CreateTextFile("'+g_oCacic.getLocalFolder + 'Temp\ipconfi1.txt", True)');
         Batchfile.Add('  IPConfigFileOK.Close');
         Batchfile.Add('end if');
         Batchfile.Add('WScript.Quit');
         Batchfile.SaveToFile(g_oCacic.getLocalFolder + 'Temp\ipconfig.vbs');
         BatchFile.Free;
         v_acao_gercols := 'Invocando execução de VBS para obtenção de IPCONFIG...';
         g_oCacic.writeDebugLog('Executando "'+g_oCacic.getLocalFolder + 'Modulos\' + v_scripter + ' //b ' + g_oCacic.getLocalFolder + 'temp\ipconfig.vbs"');

         if ChecaAgente(g_oCacic.getLocalFolder + 'Modulos', v_scripter) then
	         g_oCacic.createOneProcess(g_oCacic.getLocalFolder + 'Modulos\' + v_scripter + ' //b ' + g_oCacic.getLocalFolder + 'temp\ipconfig.vbs', false);
      Except
        Begin
          g_oCacic.writeDailyLog('Erro na geração do ipconfig.txt pelo ' + v_metodo_obtencao+'.');
        End;
      End;

      // Para aguardar o processamento acima, caso aconteça
      sleep(5000);

      v_Tamanho_Arquivo := Get_File_Size(g_oCacic.getLocalFolder + 'Temp\ipconfig.txt',true);
      if not (FileExists(g_oCacic.getLocalFolder + 'Temp\ipconfi1.txt')) or (v_Tamanho_Arquivo='0')  then // O arquivo ipconfig.txt foi gerado vazio, tentarei IPConfig ou WinIPcfg!
        Begin
          Try
             v_win_dir          := g_oCacic.getWinDir;
             v_win_dir_command  := g_oCacic.getWinDir;
             v_win_dir_ipcfg    := g_oCacic.getWinDir;
             v_dir_command      := '';
             v_dir_ipcfg        := '';

             // Definição do comando para obtenção de informações de TCP (Ipconfig ou WinIpCFG)
             if g_oCacic.isWindowsNTPlataform then
                Begin
                  v_metodo_obtencao := 'Execução de IPConfig';
                  if      (fileexists(v_win_dir_command + '\system32\cmd.exe'))          then v_dir_command := '\system32'
                  else if (fileexists(v_win_dir_command + '\system32\dllcache\cmd.exe')) then v_dir_command := '\system32\dllcache'
                  else if (fileexists(v_win_dir_command + '\system\cmd.exe'))            then v_dir_command := '\system'
                  else if (fileexists(LeftStr(v_win_dir_command,2) + '\cmd.exe')) then
                    Begin
                      v_win_dir_command := LeftStr(v_win_dir_command,2);
                      v_dir_command     := '\';
                    End;

                  if      (fileexists(v_win_dir + '\system32\ipconfig.exe'))     then v_dir_ipcfg := '\system32'
                  else if (fileexists(v_win_dir + '\ipconfig.exe'))              then v_dir_ipcfg := '\'
                  else if (fileexists(v_win_dir + '\system\ipconfig.exe'))       then v_dir_ipcfg := '\system'
                  else if (fileexists(LeftStr(v_win_dir,2) + '\ipconfig.exe')) then
                    Begin
                      v_win_dir_ipcfg := LeftStr(v_win_dir_command,2);
                      v_dir_ipcfg     := '\';
                    End;

                  g_oCacic.createOneProcess(v_win_dir + v_dir_command + '\cmd.exe /c ' + v_win_dir + v_dir_ipcfg + '\ipconfig.exe /all > ' + v_nome_arquivo, false);
                End
             else
                Begin
                  v_metodo_obtencao := 'Execução de WinIPCfg';
                  if      (fileexists(v_win_dir_command + '\system32\command.com'))          then v_dir_command := '\system32'
                  else if (fileexists(v_win_dir_command + '\system32\dllcache\command.com')) then v_dir_command := '\system32\dllcache'
                  else if (fileexists(v_win_dir_command + '\system\command.com'))            then v_dir_command := '\system'
                  else if (fileexists(LeftStr(v_win_dir_command,2) + '\command.com')) then
                    Begin
                      v_win_dir_command := LeftStr(v_win_dir_command,2);
                      v_dir_command     := '\';
                    End;

                  if      (fileexists(v_win_dir + '\system32\winipcfg.exe'))     then v_dir_ipcfg := '\system32'
                  else if (fileexists(v_win_dir + '\winipcfg.exe'))              then v_dir_ipcfg := '\'
                  else if (fileexists(v_win_dir + '\system\winipcfg.exe'))       then v_dir_ipcfg := '\system'
                  else if (fileexists(LeftStr(v_win_dir,2) + '\winipcfg.exe')) then
                    Begin
                      v_win_dir_ipcfg := LeftStr(v_win_dir_command,2);
                      v_dir_ipcfg     := '\';
                    End;
                  g_oCacic.createOneProcess(v_win_dir + v_dir_command + '\command.com /c ' + v_win_dir + v_dir_ipcfg + '\winipcfg.exe /all /batch ' + v_nome_arquivo, false);
                End;
          Except g_oCacic.writeDailyLog('Erro na geração do ipconfig.txt pelo ' + v_metodo_obtencao+'.');
          End;
        End;

      sleep(3000); // 3 Segundos para finalização do ipconfig...

      // Seto a forma de obtenção das informações de TCP...
      g_oCacic.setValueToFile('TcpIp','TE_ORIGEM_MAC',g_oCacic.enCrypt( v_metodo_obtencao), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      v_mac_address := '';
      v_acao_gercols := 'Criando StringLists para campos e valores de temp/ipconfig.txt...';
      v_array_campos  := TStringList.Create;
      v_array_valores := TStringList.Create;
      Try
        v_acao_gercols := 'Acessando o arquivo ' + v_nome_arquivo;
        AssignFile(IpConfigTXT, v_nome_arquivo);
        v_acao_gercols := 'Abrindo o arquivo ' + v_nome_arquivo;
        Reset(IpConfigTXT);
        while not Eof(IpConfigTXT) do
         begin
           v_acao_gercols := 'Lendo linha ' + IpConfigLINHA + ' de ' + v_nome_arquivo;
           ReadLn(IpConfigTXT, IpConfigLINHA);
           IpConfigLINHA := trim (IpConfigLINHA);
           intAux1 := LastPos(': ',PChar(IpConfigLINHA));
           if (intAux1 > 0) then
             Begin
               v_acao_gercols := 'Adicionando ' + copy(IpConfigLINHA,1,intAux1) + ' à matriz campos';
               v_array_campos.Add(copy(IpConfigLINHA,1,intAux1));
               v_acao_gercols := 'Adicionando ' + copy(IpConfigLINHA,intAux1 + 2, length(IpConfigLINHA)) + ' à matriz valores';
               v_array_valores.Add(copy(IpConfigLINHA,intAux1 + 2, length(IpConfigLINHA)));
             End;
         end;
      Except g_oCacic.writeDailyLog('Erro na extração de informações do ipconfig.txt.');
      End; // fim do Try

      v_acao_gercols := 'Fechando ' + v_nome_arquivo;

      // Pausa para total unlock do arquivo
      sleep(2000);

      // Fecho o arquivo
      CloseFile(IpConfigTXT);
      v_acao_gercols := 'Arquivo ' + v_nome_arquivo + ' fechado com sucesso!';
      sleep(1000);

      if (v_array_campos.Count > 0) then
        Begin
           v_acao_gercols := 'Definindo pseudo MAC´s...';
           // Vamos desviar dos famosos pseudo-MAC´s...
           v_enderecos_mac_invalidos := g_oCacic.deCrypt( g_oCacic.getValueFromFile('TcpIp','TE_ENDERECOS_MAC_INVALIDOS', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
           if (v_enderecos_mac_invalidos <> '') then v_enderecos_mac_invalidos := v_enderecos_mac_invalidos + ',';
           v_enderecos_mac_invalidos := v_enderecos_mac_invalidos + '00:00:00:00:00:00';

           v_acao_gercols := 'Extraindo informações TCP via PegaDadosIPConfig...';
           // Os parâmetros para a chamada à função PegaDadosIPConfig devem estar estar em minúsculo.
           if (v_mac_address='')      then Try v_mac_address      := PegaDadosIPConfig(v_array_campos,v_array_valores,'endere,sico;physical,address;direcci,adaptador',v_enderecos_mac_invalidos) Except v_mac_address      := ''; end;
           if (te_mascara='')         then Try te_mascara         := PegaDadosIPConfig(v_array_campos,v_array_valores,'scara,sub,rede;sub,net,mask;scara,subred','255.255.255.255;')         Except te_mascara         := ''; end;
           if (te_ip='')              then Try te_ip              := PegaDadosIPConfig(v_array_campos,v_array_valores,'endere,ip;ip,address;direcci,ip','0.0.0.0')                         Except te_ip              := ''; end;
           if (te_gateway='')         then Try te_gateway         := PegaDadosIPConfig(v_array_campos,v_array_valores,'gateway,padr;gateway,definido;default,gateway;puerta,enlace,predeterminada','')       Except te_gateway         := ''; end;
           if (te_nome_host='')       then Try te_nome_host       := PegaDadosIPConfig(v_array_campos,v_array_valores,'nome,host;host,name;nombre,del,host','')                                 Except te_nome_host       := ''; end;
           if (te_serv_dhcp='')       then Try te_serv_dhcp       := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,dhcp;dhcp,server','')                           Except te_serv_dhcp       := ''; end;
           if (te_dns_primario='')    then Try te_dns_primario    := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidores,dns;dns,servers','')                          Except te_dns_primario    := ''; end;
           if (te_wins_primario='')   then Try te_wins_primario   := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,wins,prim;wins,server,primary','')              Except te_wins_primario   := ''; end;
           if (te_wins_secundario='') then Try te_wins_secundario := PegaDadosIPConfig(v_array_campos,v_array_valores,'servidor,wins,secund;wins,server,secondary','')          Except te_wins_secundario := ''; end;

           Try
              te_dominio_windows :=  GetUserLoggedInDomain(te_nome_host);
           Except
              te_dominio_windows := 'Não Identificado';
           End;
        End // fim do Begin
      Else
        Begin
          Try
             if (v_mac_address = '') then
                Begin
                  v_mac_address := GetMACAddress;
                  g_oCacic.setValueToFile('TcpIp','TE_ORIGEM_MAC',g_oCacic.enCrypt( 'utils_GetMACaddress'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                End;
             if (v_mac_address = '') then
                Begin
                  v_mac_address := Trim(v_tcpip.Adapter[v_index_ethernet].Address);
                  g_oCacic.setValueToFile('TcpIp','TE_ORIGEM_MAC',g_oCacic.enCrypt( 'MSI_TCP.Adapter['+IntToStr(v_index_ethernet)+'].Address'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                End;

             if (v_mac_address <> '') then
                Begin
                  v_enderecos_mac_invalidos := g_oCacic.deCrypt( g_oCacic.getValueFromFile('TcpIp','TE_ENDERECOS_MAC_INVALIDOS', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
                  v_conta_EXCECOES := 0;
                  if (v_enderecos_mac_invalidos <> '') then
                    Begin
                      tstrEXCECOES  := g_oCacic.explode(v_enderecos_mac_invalidos,','); // Excecoes a serem tratadas
                      for intAux4 := 0 to tstrEXCECOES.Count-1 Do
                        Begin
                          if (rat(tstrEXCECOES[intAux4],v_mac_address) > 0) then
                            Begin
                              v_conta_EXCECOES := 1;
                              break;
                            End;
                        End;

                      if (v_conta_EXCECOES > 0) then
                        Begin
                          v_mac_address := '';
                        End;
                    End;
                End;
              Except g_oCacic.writeDailyLog('Erro na obtenção de informações de rede! (GetMACAddress).');
              End;
        End;

      // Deleto os arquivos usados na obtenção via VBScript e CMD/Command
      v_acao_gercols := 'Excluindo arquivo '+v_nome_arquivo+', usado na obtenção de IPCONFIG...';
      g_oCacic.writeDebugLog('Excluindo: "'+v_nome_arquivo+'"');
      DeleteFile(v_nome_arquivo);

      v_acao_gercols := 'Excluindo arquivo '+g_oCacic.getLocalFolder + 'Temp\ipconfi1.txt, usado na obtenção de IPCONFIG...';
      g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','ipconfi1.txt');

      v_acao_gercols := 'Excluindo arquivo '+g_oCacic.getLocalFolder + 'Temp\ipconfig.vbs, usado na obtenção de IPCONFIG...';
      g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','ipconfig.vbs');
    End;

    v_mascara := te_mascara;
    // Em 12/08/2005, extinção da obrigatoriedade de obtenção de Máscara de Rede na estação.
    // O cálculo para obtenção deste parâmetro poderá ser feito pelo módulo Gerente Web através do script get_config.php
    // if (trim(v_mascara)='') then v_mascara := '255.255.255.0';

    try
      if (trim(GetIPRede(te_ip, te_mascara))<>'') then
      g_oCacic.setValueToFile('TcpIp','ID_IP_REDE',g_oCacic.enCrypt( GetIPRede(te_ip, te_mascara)), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    except
       g_oCacic.writeDailyLog('Erro setando IP_REDE.');
    end;

    try
      g_oCacic.setValueToFile('TcpIp','TE_NODE_ADDRESS',g_oCacic.enCrypt( StringReplace(v_mac_address,':','-',[rfReplaceAll])), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    except
       g_oCacic.writeDailyLog('Erro setando NODE_ADDRESS.');
    end;

    Try
      g_oCacic.setValueToFile('TcpIp','TE_NOME_HOST',g_oCacic.enCrypt( TE_NOME_HOST), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    Except
      g_oCacic.writeDailyLog('Erro setando NOME_HOST.');
    End;

    try
       g_oCacic.setValueToFile('TcpIp','TE_NOME_COMPUTADOR' ,g_oCacic.enCrypt( TE_NOME_HOST), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    except
       g_oCacic.writeDailyLog('Erro setando NOME_COMPUTADOR.');
    end;

    Try
      g_oCacic.setValueToFile('TcpIp','TE_WORKGROUP',g_oCacic.enCrypt( GetWorkgroup), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    except
      g_oCacic.writeDailyLog('Erro setando TE_WORKGROUP.');
    end;

    if (Trim(g_oCacic.getWebManagerAddress) <> '') then
        begin
            // Passei a enviar sempre a versão do CACIC...
            // Solicito do servidor a configuração que foi definida pelo administrador do CACIC.
            Request_SVG := TStringList.Create;

            //Tratamento de Sistemas Monitorados
            intAux4 := 1;
            strAux3 := '';
            ValorChaveRegistro := '*';
            while ValorChaveRegistro <> '' do
              begin
                strAux3 := 'SIS' + trim(inttostr(intAux4));
                ValorChaveRegistro  := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas',strAux3, g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

                if (ValorChaveRegistro <> '') then
                  Begin
                     tstrTripa1  := g_oCacic.explode(ValorChaveRegistro,'#');
                     for intAux1 := 0 to tstrTripa1.Count-1 Do
                       Begin
                         tstrTripa2  := g_oCacic.explode(tstrTripa1[intAux1],',');
                         //Apenas os dois primeiros itens, id_aplicativo e dt_atualizacao
                         strTripa := strTripa + tstrTripa2[0] + ',' + tstrTripa2[1]+'#';
                       end;
                  End; //If
                intAux4 := intAux4 + 1;
              end; //While

             // Proposital, para forçar a chegada dos perfis, solução temporária...
             Request_SVG.Values['te_tripa_perfis']       := StringReplace(g_oCacic.enCrypt(''),'+','<MAIS>',[rfReplaceAll]);

             // Gero e armazeno uma palavra-chave e a envio ao Gerente WEB para atualização no BD.
             // Essa palavra-chave será usada para o acesso ao Agente Principal
             strAux := GeraPalavraChave;
             g_oCacic.setValueToFile('Configs','te_palavra_chave',g_oCacic.enCrypt( strAux), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

             // Renova a palavra chave para o Servidor de Suporte Remoto Seguro
             strKeyWord := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','te_palavra_chave',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));

             strKeyWord := StringReplace(g_oCacic.enCrypt(strKeyWord)      ,'+' ,'<MAIS>'    ,[rfReplaceAll]);
             strKeyWord := StringReplace(strKeyWord                        ,' ' ,'<ESPACE>'  ,[rfReplaceAll]);
             strKeyWord := StringReplace(strKeyWord                        ,'"' ,'<AD>'      ,[rfReplaceAll]);
             strKeyWord := StringReplace(strKeyWord                        ,'''','<AS>'      ,[rfReplaceAll]);
             strKeyWord := StringReplace(strKeyWord                        ,'\' ,'<BarrInv>' ,[rfReplaceAll]);

             g_oCacic.writeDebugLog('Criando cookie para srCACICsrv com nova palavra-chave "'+ strAux + '" => "'+strKeyWord+'"');

             AssignFile(textfileKeyWord,g_oCacic.getLocalFolder + 'cacic_keyword.txt');
             Rewrite(textfileKeyWord);
             Append(textfileKeyWord);
             Writeln(textfileKeyWord,strKeyWord);
             CloseFile(textfileKeyWord);
             //

             Request_SVG.Values['te_palavra_chave']       := g_oCacic.enCrypt(strAux);
             v_TeWebManagerAddress := g_oCacic.getWebManagerAddress;

             strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);

             {
             // A versão com criptografia do Módulo Gerente WEB retornará o valor cs_cipher=1(Quando receber "1") ou cs_cipher=2(Quando receber "3")
             Seta_boolCipher(strRetorno);

             // A versão com compressão do Módulo Gerente WEB retornará o valor cs_compress=1(Quando receber "1") ou cs_compress=2(Quando receber "3")
             Seta_l_cs_compress(strRetorno);
             }

             v_TeWebManagerAddress := trim(g_oCacic.deCrypt(g_oCacic.xmlGetValue('TE_WEB_MANAGER_ADDRESS',strRetorno)));

             if (strRetorno <> '0') and
                (v_TeWebManagerAddress <> '') and
                (v_TeWebManagerAddress <> g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','TeWebManagerAddress', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) then
                Begin
                  v_mensagem_log := 'Novo endereço para Gerente WEB: '+v_TeWebManagerAddress;
                  g_oCacic.setWebManagerAddress(v_TeWebManagerAddress);
                  g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.enCrypt(v_TeWebManagerAddress), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                  g_oCacic.writeDebugLog('Setando Criptografia para 3. (Primeiro contato)');
                  {
                  Seta_boolCipher('');
                  }
                  g_oCacic.writeDebugLog('Refazendo comunicação');

                  // Passei a enviar sempre a versão do CACIC...
                  // Solicito do servidor a configuração que foi definida pelo administrador do CACIC.
                  Request_SVG.Free;
                  Request_SVG := TStringList.Create;
                  Request_SVG.Values['te_tripa_perfis']    := StringReplace(g_oCacic.enCrypt(''),'+','<MAIS>',[rfReplaceAll]);
                  strRetorno := ComunicaServidor('get_config.php', Request_SVG, v_mensagem_log);
                  {
                  Seta_boolCipher(strRetorno);
                  Seta_l_cs_compress(strRetorno);
                  }
                End;

             Request_SVG.Free;

             if (strRetorno <> '0') Then
              Begin
                ValorRetornado := g_oCacic.deCrypt(g_oCacic.xmlGetValue('SISTEMAS_MONITORADOS_PERFIS', strRetorno));
                g_oCacic.writeDebugLog('Valor Retornado para Sistemas Monitorados: "'+ValorRetornado+'"');
                IF (ValorRetornado <> '') then
                Begin
                     intAux4 := 1;
                     strAux3 := '*';
                     while strAux3 <> '' do
                      begin
                        strAux3 := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','SIS' + trim(inttostr(intAux4)), g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
                        if (trim(strAux3)<>'') then
                          Begin
                            strAux3 := 'SIS' + trim(inttostr(intAux4));
                            g_oCacic.setValueToFile('Coletas',strAux3,g_oCacic.enCrypt( ''), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                          End;
                        intAux4 := intAux4 + 1;
                      end;

                   intAux4 := 0;
                   tstrTripa3  := g_oCacic.explode(ValorRetornado,'#');
                   for intAux3 := 0 to tstrTripa3.Count-1 Do
                   Begin
                     strAux3 := 'SIS' + trim(inttostr(intAux4));
                     tstrTripa4  := g_oCacic.explode(tstrTripa3[intAux3],',');
                     while strAux3 <> '' do
                      begin
                        intAux4 := intAux4 + 1;
                        strAux3 := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','SIS' + trim(inttostr(intAux4)), g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
                        if (trim(strAux3)<>'') then
                          Begin
                            tstrTripa5 := g_oCacic.explode(strAux3,',');
                            if (tstrTripa5[0] = tstrTripa4[0]) then strAux3 := '';
                          End;
                      end;
                     strAux3 := 'SIS' + trim(inttostr(intAux4));
                     g_oCacic.setValueToFile('Coletas',strAux3,g_oCacic.enCrypt( tstrTripa3[intAux3]), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                   end;
                end;

                g_oCacic.writeDebugLog('Armazenando valores obtidos no DAT Memória.');
                v_acao_gercols := 'Armazenando valores obtidos no DAT Memória.';

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //Gravação no DatFileName dos valores de REDE, COMPUTADOR e EXECUÇÃO obtidos, para consulta pelos outros módulos...
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                g_oCacic.setValueToFile('Configs','CS_AUTO_UPDATE'                 ,g_oCacic.xmlGetValue('cs_auto_update'          , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_COLETA_HARDWARE'             ,g_oCacic.xmlGetValue('cs_coleta_hardware'      , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_COLETA_SOFTWARE'             ,g_oCacic.xmlGetValue('cs_coleta_software'      , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_COLETA_MONITORADO'           ,g_oCacic.xmlGetValue('cs_coleta_monitorado'    , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_COLETA_OFFICESCAN'           ,g_oCacic.xmlGetValue('cs_coleta_officescan'    , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_COLETA_COMPARTILHAMENTOS'    ,g_oCacic.xmlGetValue('cs_coleta_compart'       , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_COLETA_UNID_DISC'            ,g_oCacic.xmlGetValue('cs_coleta_unid_disc'        , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_SUPORTE_REMOTO'              ,g_oCacic.xmlGetValue('cs_suporte_remoto'          , strRetorno), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_' + StringReplace(UpperCase(g_oCacic.getMainProgramName),'.EXE','',[rfReplaceAll])+'_DISPONIVEL',g_oCacic.xmlGetValue('dt_versao_'+StringReplace(UpperCase( g_oCacic.getMainProgramName),'.EXE','',[rfReplaceAll])+'_disponivel' , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_'   + StringReplace(UpperCase(g_oCacic.getMainProgramName),'.EXE','',[rfReplaceAll])              ,g_oCacic.xmlGetValue('te_hash_'+StringReplace(UpperCase( g_oCacic.getMainProgramName),'.EXE','',[rfReplaceAll])                 , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_GER_COLS_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_ger_cols_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);                                                                                                                        g_oCacic.setValueToFile('Configs','TE_HASH_GER_COLS'               ,g_oCacic.xmlGetValue('te_hash_ger_cols'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_CHKSIS_DISPONIVEL'    ,g_oCacic.xmlGetValue('dt_versao_chksis_disponivel'       , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_CHKSIS'                 ,g_oCacic.xmlGetValue('te_hash_chksis'                    , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_COL_ANVI_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_col_anvi_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_COL_ANVI'               ,g_oCacic.xmlGetValue('te_hash_col_anvi'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_COL_COMP_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_col_comp_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_COL_COMP'               ,g_oCacic.xmlGetValue('te_hash_col_comp'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_COL_HARD_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_col_hard_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_COL_HARD'               ,g_oCacic.xmlGetValue('te_hash_col_hard'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_COL_MONI_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_col_moni_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_COL_MONI'               ,g_oCacic.xmlGetValue('te_hash_col_moni'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_COL_SOFT_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_col_soft_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_COL_SOFT'               ,g_oCacic.xmlGetValue('te_hash_col_soft'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_COL_UNDI_DISPONIVEL'  ,g_oCacic.xmlGetValue('dt_versao_col_undi_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_COL_UNDI'               ,g_oCacic.xmlGetValue('te_hash_col_undi'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_SRCACICSRV'             ,g_oCacic.xmlGetValue('te_hash_srcacicsrv'                , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_VERSAO_SRCACICSRV_DISPONIVEL',g_oCacic.xmlGetValue('dt_versao_srcacicsrv_disponivel'   , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_CACICSERVICE'           ,g_oCacic.xmlGetValue('te_hash_cacicservice'              , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TeServiceProgramHash'           ,g_oCacic.xmlGetValue('te_hash_cacicservice'              , strRetorno) , g_oCacic.getWinDir      + 'chksis.ini');
                g_oCacic.setValueToFile('Configs','DT_VERSAO_CACICSERVICE_DISPONIVEL' ,g_oCacic.xmlGetValue('dt_versao_cacicservice_disponivel'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_HASH_'+StringReplace(v_scripter,'.exe','',[rfReplaceAll]),g_oCacic.xmlGetValue('te_hash_'+StringReplace(v_scripter,'.exe','',[rfReplaceAll]),strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_SERV_UPDATES'                ,g_oCacic.xmlGetValue('te_serv_updates'                   , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','NU_PORTA_SERV_UPDATES'          ,g_oCacic.xmlGetValue('nu_porta_serv_updates'             , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_PATH_SERV_UPDATES'           ,g_oCacic.xmlGetValue('te_path_serv_updates'              , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','NM_USUARIO_LOGIN_SERV_UPDATES'  ,g_oCacic.xmlGetValue('nm_usuario_login_serv_updates'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_SENHA_LOGIN_SERV_UPDATES'    ,g_oCacic.xmlGetValue('te_senha_login_serv_updates'       , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','IN_EXIBE_ERROS_CRITICOS'        ,g_oCacic.xmlGetValue('in_exibe_erros_criticos'           , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_SENHA_ADM_AGENTE'            ,g_oCacic.xmlGetValue('te_senha_adm_agente'               , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','NU_INTERVALO_EXEC'              ,g_oCacic.xmlGetValue('nu_intervalo_exec'                 , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','NU_EXEC_APOS'                   ,g_oCacic.xmlGetValue('nu_exec_apos'                      , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','IN_EXIBE_BANDEJA'               ,g_oCacic.xmlGetValue('in_exibe_bandeja'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','TE_JANELAS_EXCECAO'             ,g_oCacic.xmlGetValue('te_janelas_excecao'                , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','NU_PORTA_SRCACIC'               ,g_oCacic.xmlGetValue('nu_porta_srcacic'                  , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','ID_LOCAL'                       ,g_oCacic.xmlGetValue('id_local'                          , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','NU_TIMEOUT_SRCACIC'             ,g_oCacic.xmlGetValue('nu_timeout_srcacic'                , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','CS_PERMITIR_DESATIVAR_SRCACIC'  ,g_oCacic.xmlGetValue('cs_permitir_desativar_srcacic'     , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA'           ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada'              , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA_ANVI'      ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada_anvi'         , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA_COMP'      ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada_comp'         , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA_HARD'      ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada_hard'         , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA_MONI'      ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada_moni'         , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA_SOFT'      ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada_soft'         , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('Configs','DT_HR_COLETA_FORCADA_UNDI'      ,g_oCacic.xmlGetValue('dt_hr_coleta_forcada_undi'         , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp'  ,'TE_ENDERECOS_MAC_INVALIDOS'     ,g_oCacic.xmlGetValue('te_enderecos_mac_invalidos'        , strRetorno) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                //g_oCacic.cipherClose(g_oCacic.getLocalFolder + g_oCacic.getDatFileName, g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                //sleep(2000);
                //v_tstrCipherOpened := g_oCacic.cipherOpen(g_oCacic.getLocalFolder + g_oCacic.getDatFileName);
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
              end;


            // Envio de Dados de TCP_IP
            if (te_dominio_windows = '') then
              Begin
                Try
                  te_dominio_windows :=  GetUserLoggedInDomain(te_nome_host);
                Except
                  te_dominio_windows := 'Não Identificado';
                End;
              End;

            Request_SVG := TStringList.Create;
            Request_SVG.Values['te_mascara']         := StringReplace(g_oCacic.enCrypt(te_mascara),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_gateway']         := StringReplace(g_oCacic.enCrypt(te_gateway),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_serv_dhcp']       := StringReplace(g_oCacic.enCrypt(te_serv_dhcp),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dns_primario']    := StringReplace(g_oCacic.enCrypt(te_dns_primario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dns_secundario']  := StringReplace(g_oCacic.enCrypt(te_dns_secundario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_wins_primario']   := StringReplace(g_oCacic.enCrypt(te_wins_primario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_wins_secundario'] := StringReplace(g_oCacic.enCrypt(te_wins_secundario),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_nome_host']       := StringReplace(g_oCacic.enCrypt(te_nome_host),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dominio_dns']     := StringReplace(g_oCacic.enCrypt(te_dominio_dns),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_origem_mac']      := StringReplace(g_oCacic.getValueFromFile('TcpIp','TE_ORIGEM_MAC', g_oCacic.getLocalFolder + g_oCacic.getInfFileName),'+','<MAIS>',[rfReplaceAll]);
            Request_SVG.Values['te_dominio_windows'] := StringReplace(g_oCacic.enCrypt(te_dominio_windows),'+','<MAIS>',[rfReplaceAll]);

            v_acao_gercols := 'Contactando módulo Gerente WEB: set_tcp_ip.php';

            strRetorno := ComunicaServidor('set_tcp_ip.php', Request_SVG, 'Enviando configurações de TCP/IP ao Gerente WEB.');
            if (strRetorno <> '0') Then
              Begin
                g_oCacic.setValueToFile('TcpIp','te_mascara'        , g_oCacic.enCrypt(te_mascara)        , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_gateway'        , g_oCacic.enCrypt(te_gateway)        , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_serv_dhcp'      , g_oCacic.enCrypt(te_serv_dhcp)      , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_dns_primario'   , g_oCacic.enCrypt(te_dns_primario)   , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_dns_secundario' , g_oCacic.enCrypt(te_dns_secundario) , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_wins_primario'  , g_oCacic.enCrypt(te_wins_primario)  , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_wins_secundario', g_oCacic.enCrypt(te_wins_secundario), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_nome_host'      , g_oCacic.enCrypt(te_nome_host)      , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                g_oCacic.setValueToFile('TcpIp','te_dominio_dns'    , g_oCacic.enCrypt(te_dominio_dns)    , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              End;

            Request_SVG.Free;
        end;
  v_tcpip.Free;
  except g_oCacic.writeDailyLog('PROBLEMAS EM BUSCACONFIGS - ' + v_acao_gercols+'.');
  End;
end;

procedure CriaCookie(strFileName : String);
Begin
  // A existência e bloqueio do arquivo abaixo evitará que o Agente Principal chame o Ger_Cols quando este estiver em funcionamento
  AssignFile(v_Aguarde,g_oCacic.getLocalFolder + 'temp\' + strFileName); {Associa o arquivo a uma variável do tipo TextFile}
  {$IOChecks off}
  Reset(v_Aguarde); {Abre o arquivo texto}
  {$IOChecks on}
  if (IOResult <> 0) then // Arquivo não existe, será recriado.
   Rewrite (v_Aguarde);

  Append(v_Aguarde);
  Writeln(v_Aguarde,'Apenas um pseudo-cookie para o Agente Principal esperar o término de Ger_Cols');
  Append(v_Aguarde);
End;

procedure Executa_Ger_Cols;
var strRetorno,
    strDtHrColetaForcada,
    strDtHrUltimaColeta : String;
Begin
  Try
          // Parâmetros possíveis (aceitos)
          //   /coletas       =>  Chamada para ativação das coletas
          //   /recuperaSR    =>  Chamada para tentativa de recuperação do módulo srCACIC
          // USBinfo          =>  Informação sobre dispositivo USB inserido/removido
          // UpdatePrincipal  =>  Atualização do Agente Principal

          // Chamada efetuada pelo Agente Principal quando da existência de temp\<AgentePrincipal>.exe para AutoUpdate
          If FindCmdLineSwitch('UpdatePrincipal', True) Then
            Begin
               CriaCookie(g_oCacic.getLocalFolder + 'Temp\aguarde_UPDATE.txt');
               g_oCacic.writeDebugLog('Opção /UpdatePrincipal recebida...');
               // 15 segundos de tempo total até a execução do novo Agente Principal
               sleep(7000);
               v_acao_gercols := 'Atualização do Agente Principal - Excluindo '+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName;
               g_oCacic.killFiles(g_oCacic.getLocalFolder,g_oCacic.getMainProgramName);
               sleep(2000);

               v_acao_gercols := 'Atualização do Agente Principal - Copiando '+g_oCacic.getLocalFolder + 'temp\'+g_oCacic.getMainProgramName+' para '+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName;
               g_oCacic.writeDebugLog('Movendo '+g_oCacic.getLocalFolder + 'temp\'+g_oCacic.getMainProgramName+' para '+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName);
               MoveFile(pChar(g_oCacic.getLocalFolder + 'temp\'+ g_oCacic.getMainProgramName),pChar(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName));
               sleep(2000);

               g_oCacic.setValueToFile('Configs','NU_EXEC_APOS',g_oCacic.enCrypt( '12345'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName); // Para que o Agente Principal comande a coleta logo após 1 minuto...
               sleep(2000);

               g_oCacic.writeDebugLog('Invocando atualização do Agente Principal...');

               v_acao_gercols := 'Atualização do Agente Principal - Invocando '+g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /atualizacao';
               Finalizar(false);

               if ChecaAgente(g_oCacic.getLocalFolder,g_oCacic.getMainProgramName) then
                  g_oCacic.createOneProcess(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' /atualizacao', false);

               Sair;
              end;

          // Chamada efetuada pelo Agente Principal quando o usuário clica no menu "Ativar Suporte Remoto" e o módulo srCACICsrv.exe não
          // tem seu HashCode validado
          If FindCmdLineSwitch('recuperaSR', True) Then
            Begin
              g_oCacic.writeDebugLog('Opção /recuperaSR recebida...');
              v_acao_gercols := 'Verificando/Recuperando srCACIC.';
              g_oCacic.writeDebugLog('Chamando Verificador/Atualizador...');
              Ver_UPD('srcacicsrv','Suporte Remoto Seguro',g_oCacic.getLocalFolder + 'Modulos\','',false);
              Finalizar(false);
              CriaTXT(g_oCacic.getLocalFolder+'temp','recuperaSR');
              Sair;
            End;

          strUSBinfo := '';

          // Chamada com informação de dispositivo USB inserido/removido
          For intAux := 1 to ParamCount do
            If LowerCase(Copy(ParamStr(intAux),1,9)) = '/usbinfo=' then
              strUSBinfo := Trim(Copy(ParamStr(intAux),10,Length((ParamStr(intAux)))));

          // Envio da informação sobre o dispositivo USB ao Gerente WEB
          if (strUSBinfo <> '') then
            begin
              g_oCacic.writeDebugLog('Parâmetro USBinfo recebido: "'+strUSBinfo+'"');
              v_acao_gercols := 'Informando ao Gerente WEB sobre dispositivo USB inserido/removido.';

              {
              ChecaCipher;
              ChecaCompress;
              }

              Request_Ger_Cols := TStringList.Create;
              g_oCacic.writeDebugLog('Preparando para criptografar "'+strUSBinfo+'"');
              Request_Ger_Cols.Values['te_usb_info'] := StringReplace(g_oCacic.enCrypt(strUSBinfo),'+','<MAIS>',[rfReplaceAll]);
              g_oCacic.writeDebugLog('Preparando para empacotar "'+Request_Ger_Cols.Values['te_usb_info']+'"');
              strRetorno := ComunicaServidor('set_usbinfo.php', Request_Ger_Cols, 'Enviando informações sobre ' + IfThen(Copy(strUSBinfo,1,1)='I','Inserção','Remoção')+ ' de dispositivo USB ao Gerente WEB!');
              if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('nm_device', strRetorno)) <> '') then
                g_oCacic.writeDailyLog('Dispositivo USB ' + IfThen(Copy(strUSBinfo,1,1)='I','Inserido','Removido')+': "' + g_oCacic.deCrypt(g_oCacic.xmlGetValue('nm_device', strRetorno)+'"')+'"');
              Request_Ger_Cols.Free;

              Finalizar(true);
            end;

          If FindCmdLineSwitch('BuscaConfigsPrimeira', True) Then
            begin
              g_oCacic.writeDebugLog('Opção /BuscaConfigsPrimeira recebida...');
              BuscaConfigs(false);
              Batchfile := TStringList.Create;
              Batchfile.Add('*** Simulação de cookie para o Agente Principal recarregar os valores de configurações ***');
              // A existência deste arquivo forçará o Agente Principal a recarregar valores das configurações obtidas e gravadas no DatFileName
              Batchfile.SaveToFile(g_oCacic.getLocalFolder + 'Temp\reset.txt');
              BatchFile.Free;
              g_oCacic.writeDebugLog('Configurações apanhadas no módulo Gerente WEB. Retornando ao Agente Principal...');
              Finalizar(false);
              Sair;
            end;

          // Chamada temporizada efetuada pelo Agente Principal
        If FindCmdLineSwitch('coletas', True) Then
            begin
              g_oCacic.writeDebugLog('Parâmetro(opção) /coletas recebido...');
              v_acao_gercols := 'Ger_Cols invocado para coletas...';

              // Verificando o registro de coletas do dia e eliminando datas diferentes...
              strAux := g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
              if (strAux = '') or
                 (copy(strAux,0,8) <> FormatDateTime('yyyymmdd', Date)) then
                 g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( FormatDateTime('yyyymmdd', Date)),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

              BuscaConfigs(true);

              // Abaixo eu testo se existe um endereço configurado para não disparar os procedimentos de coleta em vão.
              if (g_oCacic.getWebManagerAddress <> '') then
                  begin
                      v_CS_AUTO_UPDATE := (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_AUTO_UPDATE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S');
                      if (v_CS_AUTO_UPDATE) then
                          Begin
                            g_oCacic.writeDebugLog('Indicador CS_AUTO_UPDATE=S encontrado.');
                            g_oCacic.writeDailyLog('Verificando Agente Principal, Gerente de Coletas e Suporte Remoto.');

                            // Caso encontre nova versão do Agente Principal esta será gravada em temp e ocorrerá o autoupdate em sua próxima tentativa de chamada ao Ger_Cols.
                            v_acao_gercols := 'Verificando versão do Agente Principal';
                            g_oCacic.writeDailyLog('Verificando nova versão para módulo Principal.');
                            Ver_UPD(StringReplace(LowerCase(g_oCacic.getMainProgramName),'.exe','',[rfReplaceAll]),'Agente Principal',g_oCacic.getLocalFolder,g_oCacic.getLocalFolder + 'Temp',false);

                            g_oCacic.writeDailyLog('Verificando nova versão para módulo Gerente de Coletas.');
                            // Caso encontre nova versão de Ger_Cols esta será gravada em temp e ocorrerá o autoupdate.
                            Ver_UPD('ger_cols','Gerente de Coletas',g_oCacic.getLocalFolder + 'Modulos\',g_oCacic.getLocalFolder + 'Temp',false);

                            // O módulo de Suporte Remoto é opcional...
                            if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_SUPORTE_REMOTO'         , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                              Begin
                                g_oCacic.writeDailyLog('Verificando nova versão para módulo Suporte Remoto Seguro.');
                                // Caso encontre nova versão de srCACICsrv esta será gravada em Modulos.
                                Ver_UPD('srcacicsrv','Suporte Remoto Seguro',g_oCacic.getLocalFolder + 'Modulos\','',false);
                              End;

                            if (FileExists(g_oCacic.getLocalFolder + 'Temp\ger_cols.exe')) or
                               (FileExists(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName))  then
                                Begin
                                  g_oCacic.setValueToFile('Configs','TeMainProgramHash',g_oCacic.enCrypt( g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName)),g_oCacic.getWinDir + 'chksis.ini');
                                  g_oCacic.writeDailyLog('Finalizando... (Update em ± 1 minuto).');
                                  Finalizar(false);
                                  Sair;
                                End;
                          End
                      else
                          g_oCacic.writeDailyLog('Indicador CS_AUTO_UPDATE="N". O recomendado é que esteja em "S" no Gerente WEB!');

                      if ((g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_HARDWARE'         , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') or
                          (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_SOFTWARE'         , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') or
                          (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_MONITORADO'       , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') or
                          (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_OFFICESCAN'       , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') or
                          (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_COMPARTILHAMENTOS', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') or
                          (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_UNID_DISC'        , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S')) and
                          not FileExists(g_oCacic.getLocalFolder + 'Temp\ger_cols.exe')  then
                          begin
                             v_acao_gercols := 'Montando script de coletas';
                             // Monto o batch de coletas de acordo com as configurações
                             g_oCacic.writeDailyLog('Verificando novas versões para Coletores de Informações.');

                             v_ModulosOpcoes := '';
                             strDtHrUltimaColeta := '0';
                             Try
                               strDtHrUltimaColeta := Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_ULTIMA_COLETA', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)));
                             Except
                             End;

                             if (strDtHrUltimaColeta = '') then
                                strDtHrUltimaColeta := '0';

                             if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_OFFICESCAN'       , g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                                begin

                                  strDtHrColetaForcada := StringReplace(StringReplace(StringReplace(Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_COLETA_FORCADA_ANVI', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]);
                                  strDtHrColetaForcada := IfThen(strDtHrColetaForcada <> '',strDtHrColetaForcada,'0');
                                  g_oCacic.writeDebugLog('Data/Hora Coleta Forçada ANVI: '+strDtHrColetaForcada);
                                  g_oCacic.writeDebugLog('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_ANVI',g_oCacic.enCrypt('S'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                  else
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_ANVI',g_oCacic.enCrypt('N'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_anvi','Coletor de Informações de Anti-Vírus OfficeScan',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                   if (FileExists(g_oCacic.getLocalFolder + 'Modulos\col_anvi.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_anvi,nowait,system';
                                      End
                                   Else g_oCacic.writeDailyLog('Executável Col_Anvi Inexistente!');

                                end;

                             if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_COMPARTILHAMENTOS', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                                begin
                                  strDtHrColetaForcada := StringReplace(StringReplace(StringReplace(Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_COLETA_FORCADA_COMP', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]);
                                  strDtHrColetaForcada := IfThen(strDtHrColetaForcada <> '',strDtHrColetaForcada,'0');

                                  g_oCacic.writeDebugLog('Data/Hora Coleta Forçada COMP: '+strDtHrColetaForcada);
                                  g_oCacic.writeDebugLog('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);
                                  if not(strDtHrColetaForcada = '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_COMP',g_oCacic.enCrypt( 'S'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                  else
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_COMP',g_oCacic.enCrypt( 'N'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_comp','Coletor de Informações de Compartilhamentos',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                   if (FileExists(g_oCacic.getLocalFolder + 'Modulos\col_comp.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_comp,nowait,system';
                                      End
                                   Else
                                      g_oCacic.writeDailyLog('Executável Col_Comp Inexistente!');
                                end;

                             if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_HARDWARE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                                begin
                                  strDtHrColetaForcada := StringReplace(StringReplace(StringReplace(Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_COLETA_FORCADA_HARD', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]);
                                  strDtHrColetaForcada := IfThen(strDtHrColetaForcada <> '',strDtHrColetaForcada,'0');

                                  g_oCacic.writeDebugLog('Data/Hora Coleta Forçada HARD: '+strDtHrColetaForcada);
                                  g_oCacic.writeDebugLog('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_HARD',g_oCacic.enCrypt('S'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                  else
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_HARD',g_oCacic.enCrypt('N'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_hard','Coletor de Informações de Hardware',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                   if (FileExists(g_oCacic.getLocalFolder + 'Modulos\col_hard.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_hard,nowait,system';
                                      End
                                   Else
                                      g_oCacic.writeDailyLog('Executável Col_Hard Inexistente!');
                                end;


                             if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_MONITORADO', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                                begin
                                  strDtHrColetaForcada := StringReplace(StringReplace(StringReplace(Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_COLETA_FORCADA_MONI', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]);
                                  strDtHrColetaForcada := IfThen(strDtHrColetaForcada <> '',strDtHrColetaForcada,'0');

                                  g_oCacic.writeDebugLog('Data/Hora Coleta Forçada MONI: '+strDtHrColetaForcada);
                                  g_oCacic.writeDebugLog('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_MONI',g_oCacic.enCrypt('S'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                  else
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_MONI',g_oCacic.enCrypt('N'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_moni','Coletor de Informações de Sistemas Monitorados',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                   if (FileExists(g_oCacic.getLocalFolder + 'Modulos\col_moni.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_moni,wait,system';
                                      End
                                   Else
                                      g_oCacic.writeDailyLog('Executável Col_Moni Inexistente!');
                                end;

                             if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_SOFTWARE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                                begin
                                  strDtHrColetaForcada := StringReplace(StringReplace(StringReplace(Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_COLETA_FORCADA_SOFT', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]);
                                  strDtHrColetaForcada := IfThen(strDtHrColetaForcada <> '',strDtHrColetaForcada,'0');

                                  g_oCacic.writeDebugLog('Data/Hora Coleta Forçada SOFT: '+strDtHrColetaForcada);
                                  g_oCacic.writeDebugLog('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_SOFT',g_oCacic.enCrypt('S'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                  else
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_SOFT',g_oCacic.enCrypt('N'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_soft','Coletor de Informações de Softwares Básicos',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                   if (FileExists(g_oCacic.getLocalFolder + 'Modulos\col_soft.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_soft,nowait,system';
                                      End
                                   Else
                                      g_oCacic.writeDailyLog('Executável Col_Soft Inexistente!');
                                end;

                             if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','CS_COLETA_UNID_DISC', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = 'S') then
                                begin
                                  strDtHrColetaForcada := StringReplace(StringReplace(StringReplace(Trim(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','DT_HR_COLETA_FORCADA_UNDI', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))),'-','',[rfReplaceAll]),' ','',[rfReplaceAll]),':','',[rfReplaceAll]);
                                  strDtHrColetaForcada := IfThen(strDtHrColetaForcada <> '',strDtHrColetaForcada,'0');

                                  g_oCacic.writeDebugLog('Data/Hora Coleta Forçada UNDI: '+strDtHrColetaForcada);
                                  g_oCacic.writeDebugLog('Data/Hora Última Coleta GERAL: '+strDtHrUltimaColeta);

                                  if (strDtHrColetaForcada <> '') and (StrToInt64(strDtHrColetaForcada) > StrToInt64(strDtHrUltimaColeta)) then
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_UNDI',g_oCacic.enCrypt('S'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                  else
                                     g_oCacic.setValueToFile('Configs','IN_COLETA_FORCADA_UNDI',g_oCacic.enCrypt('N'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                                   if (v_CS_AUTO_UPDATE) then Ver_UPD('col_undi','Coletor de Informações de Unidades de Disco',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                   if (FileExists(g_oCacic.getLocalFolder + 'Modulos\col_undi.exe'))  then
                                      Begin
                                         intMontaBatch := 1;
                                         if (v_ModulosOpcoes<>'') then v_ModulosOpcoes := v_ModulosOpcoes + '#';
                                         v_ModulosOpcoes := v_ModulosOpcoes + 'col_undi,nowait,system';
                                      End
                                   Else
                                      g_oCacic.writeDailyLog('Executável Col_Undi Inexistente!');
                                end;
                             if (countUPD > 0) or
                                (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Configs','ID_FTP',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))<>'') then
                                Begin
                                  Request_Ger_Cols := TStringList.Create;
                                  Request_Ger_Cols.Values['in_chkcacic']   := StringReplace(g_oCacic.enCrypt('chkcacic'),'+','<MAIS>',[rfReplaceAll]);
                                  Request_Ger_Cols.Values['te_fila_ftp']   := StringReplace(g_oCacic.enCrypt('2'),'+','<MAIS>',[rfReplaceAll]); // Indicará sucesso na operação de FTP e liberará lugar para o próximo
                                  Request_Ger_Cols.Values['id_ftp']        := StringReplace(g_oCacic.getValueFromFile('Configs','ID_FTP',g_oCacic.getLocalFolder + g_oCacic.getInfFileName),'+','<MAIS>',[rfReplaceAll]); // Indicará sucesso na operação de FTP e liberará lugar para o próximo
                                  ComunicaServidor('get_config.php', Request_Ger_Cols, 'Liberando Grupo FTP!...');
                                  Request_Ger_Cols.Free;
                                  g_oCacic.setValueToFile('Configs','ID_FTP',g_oCacic.enCrypt(''), g_oCacic.getLocalFolder + g_oCacic.getInfFileName)
                                End;
                             if (intMontaBatch > 0) then
                                Begin
                                  {
                                  Ver_UPD('ini_cols','Inicializador de Coletas',g_oCacic.getLocalFolder + 'Modulos\','',false);
                                  g_oCacic.writeDebugLog('Invocando Inicializador de Coletas: "'+g_oCacic.getLocalFolder + 'Modulos\ini_cols.exe /LocalFolder='+g_oCacic.getLocalFolder+' /p_ModulosOpcoes=' + v_ModulosOpcoes+'"');
                                  g_oCacic.createOneProcess( g_oCacic.getLocalFolder + 'Modulos\ini_cols.exe /LocalFolder='+g_oCacic.getLocalFolder+' /p_ModulosOpcoes=' + v_ModulosOpcoes, CACIC_PROCESS_WAIT );
                                  }
                                  tstrModulosOpcoes := g_oCacic.explode(v_ModulosOpcoes,'#');

                                  g_oCacic.writeDailyLog('Início de Coletas do Intervalo');
                                  For intAux := 0 to (tstrModulosOpcoes.Count -1) do
                                    Begin
                                      tstrModuloOpcao := g_oCacic.explode(tstrModulosOpcoes[intAux],',');
                                      g_oCacic.writeDailyLog('Ativando Coletor "' + tstrModuloOpcao[0]+'"');

                                      strAux := tstrModuloOpcao[0]+'.exe /LocalFolder='+g_oCacic.getLocalFolder+' /p_Option='+tstrModuloOpcao[2];

                                      // TO-DO: Tratar o valor [1] que informa wait / nowait fazendo a execução do processo esperar ou não o fim da execução da coleta
                                      g_oCacic.writeDebugLog('Chamando "' + tstrModuloOpcao[0]+'.exe " /p_Option='+tstrModuloOpcao[2]);
                                      g_oCacic.createOneProcess( g_oCacic.getLocalFolder + '\modulos\' + strAux, CACIC_PROCESS_WAIT );
                                      Sleep(1000); // 1 segundo para a total saída do agente da memória.
                                    End;

                                  g_oCacic.writeDailyLog('Fim de Coletas do Intervalo');

                                End;
                          end
                       else
                          begin
                             if not FileExists(g_oCacic.getLocalFolder + 'Temp\ger_cols.exe') and
                                not FileExists(g_oCacic.getLocalFolder + 'Modulos\ger_cols.exe')  then
                                  g_oCacic.writeDailyLog('Módulo Gerente de Coletas inexistente.')
                             else
                                  g_oCacic.writeDailyLog('Nenhuma coleta configurada para essa subrede / estação / S.O.');
                          end;
                  End;
            end;

        // Caso não existam os arquivos abaixo, será finalizado.
        if FileExists(g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf') or
           FileExists(g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf') or
           FileExists(g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf') or
           FileExists(g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf') or
           FileExists(g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf') or
           FileExists(g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf') then
            begin
              g_oCacic.writeDebugLog('Realizando leituras de coletas...');

              // Envio das informações coletadas com exclusão dos arquivos batchs e inis utilizados...
              Request_Ger_Cols:=TStringList.Create;
              intAux := 0;

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf')) then
                  Begin
                    g_oCacic.writeDebugLog('Indicador '+g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Anti-Vírus.';

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt(g_oCacic.deCrypt(g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+'#Informações sobre Anti-Vírus OfficeScan'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    // Armazeno as horas de início e fim das coletas
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt(g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+','+g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Anvi','Inicio',g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt(g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+','+g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Anvi','Fim',g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    if (g_oCacic.deCrypt(g_oCacic.getValueFromFile('Col_Anvi','nada', g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'))='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['nu_versao_engine' ] := StringReplace(g_oCacic.getValueFromFile('Col_Anvi','nu_versao_engine' ,g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['nu_versao_pattern'] := StringReplace(g_oCacic.getValueFromFile('Col_Anvi','nu_versao_pattern',g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['dt_hr_instalacao' ] := StringReplace(g_oCacic.getValueFromFile('Col_Anvi','dt_hr_instalacao' ,g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_servidor'      ] := StringReplace(g_oCacic.getValueFromFile('Col_Anvi','te_servidor'      ,g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['in_ativo'         ] := StringReplace(g_oCacic.getValueFromFile('Col_Anvi','in_ativo'         ,g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'),'+','<MAIS>',[rfReplaceAll]);

                        if g_oCacic.inDebugMode then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                g_oCacic.writeDebugLog('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Anvi: ' + Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_officescan.php', Request_Ger_Cols, 'Enviando informações de Antivírus OfficeScan para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            // Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            g_oCacic.setValueToFile('Coletas','OfficeScan',g_oCacic.getValueFromFile('Col_Anvi','UVC', g_oCacic.getLocalFolder + 'Temp\COL_ANVI.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName) ;
                            intAux := 1;
                          End
                        else
                            // Armazeno o Status Negativo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',-1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                      End
                    Else
                      // Armazeno o Status Nulo de Envio
                      g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    Request_Ger_Cols.Clear;
                    g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','COL_ANVI.inf');
                  End;

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf')) then
                  Begin
                    g_oCacic.writeDebugLog('Indicador '+g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Compartilhamentos.';

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+'#Informações sobre Compartilhamentos'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    // Armazeno as horas de início e fim das coletas
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Comp','Inicio',g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Comp','Fim',g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Comp','nada',g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf'))='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['CompartilhamentosLocais'] := StringReplace(g_oCacic.enCrypt( StringReplace(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Comp','UVC',g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf')),'\','<BarrInv>',[rfReplaceAll])),'+','<MAIS>',[rfReplaceAll]);
                        if g_oCacic.inDebugMode then
                          Begin
                            g_oCacic.writeDebugLog('Col_Comp.UVC => '+g_oCacic.getValueFromFile('Col_Comp','UVC',g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf'));
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                g_oCacic.writeDebugLog('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Comp: '+Request_Ger_Cols.ValueFromIndex[intLoop]);
                          End;

                        if (ComunicaServidor('set_compart.php', Request_Ger_Cols, 'Enviando informações de Compartilhamentos para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            g_oCacic.setValueToFile('Coletas','Compartilhamentos', g_oCacic.getValueFromFile('Col_Comp','UVC',g_oCacic.getLocalFolder + 'Temp\COL_COMP.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                            intAux := 1;
                          End
                        Else
                          // Armazeno o Status Negativo de Envio
                          g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',-1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    Request_Ger_Cols.Clear;
                    g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','COL_COMP.inf');
                  End;

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf')) then
                  Begin
                    g_oCacic.writeDebugLog('Indicador '+g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Hardware.';

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    g_oCacic.setValueToFile('Coletas','HOJE', g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+'#Informações sobre Hardware'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    // Armazeno as horas de início e fim das coletas
                    g_oCacic.setValueToFile('Coletas','HOJE', g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Hard','Inicio',g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Coletas','HOJE', g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Hard','Fim'   ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Hard','nada',g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf')) = '') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['te_Tripa_TCPIP'          ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_Tripa_TCPIP'          ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_Tripa_CPU'            ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_Tripa_CPU'            ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_Tripa_CDROM'          ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_Tripa_CDROM'          ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_mae_fabricante' ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_placa_mae_fabricante' ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_mae_desc'       ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_placa_mae_desc'       ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_mem_ram'              ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','qt_mem_ram'              ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_mem_ram_desc'         ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_mem_ram_desc'         ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_desc'            ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_bios_desc'            ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_data'            ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_bios_data'            ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_bios_fabricante'      ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_bios_fabricante'      ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_placa_video_cores'    ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','qt_placa_video_cores'    ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_video_desc'     ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_placa_video_desc'     ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['qt_placa_video_mem'      ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','qt_placa_video_mem'      ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_video_resolucao'] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_placa_video_resolucao',g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_placa_som_desc'       ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_placa_som_desc'       ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_teclado_desc'         ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_teclado_desc'         ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_mouse_desc'           ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_mouse_desc'           ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_modem_desc'           ] := StringReplace(g_oCacic.getValueFromFile('Col_Hard','te_modem_desc'           ,g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'),'+','<MAIS>',[rfReplaceAll]);

                        if g_oCacic.inDebugMode then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                g_oCacic.writeDebugLog('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Hard: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_hardware.php', Request_Ger_Cols, 'Enviando informações de Hardware para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            g_oCacic.setValueToFile('Coletas','Hardware', g_oCacic.getValueFromFile('Col_Hard','UVC',g_oCacic.getLocalFolder + 'Temp\COL_HARD.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',-1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    Request_Ger_Cols.Clear;
                    g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','col_hard.inf');
                  End;

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf')) then
                  Begin
                    g_oCacic.writeDebugLog('Indicador '+g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Sistemas Monitorados.';

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+'#Informações sobre Sistemas Monitorados'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    // Armazeno as horas de início e fim das coletas
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+','+ g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Moni','Inicio',g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+','+ g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Moni','Fim'   ,g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    if ( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Moni','nada',g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf'))='') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['te_tripa_monitorados'] := StringReplace(g_oCacic.getValueFromFile('Col_Moni','UVC',g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf'),'+','<MAIS>',[rfReplaceAll]);

                        if g_oCacic.inDebugMode then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                g_oCacic.writeDebugLog('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Moni: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_monitorado.php', Request_Ger_Cols, 'Enviando informações de Sistemas Monitorados para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            g_oCacic.setValueToFile('Coletas','Sistemas_Monitorados', g_oCacic.getValueFromFile('Col_Moni','UVC',g_oCacic.getLocalFolder + 'Temp\COL_MONI.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',-1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    Request_Ger_Cols.Clear;
                    g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','COL_MONI.inf');
                  End;

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf')) then
                  Begin
                    g_oCacic.writeDebugLog('Indicador '+g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Softwares.';

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+'#Informações sobre Softwares'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    // Armazeno as horas de início e fim de execução das coletas
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Soft','Inicio',g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Soft','Fim'   ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Soft','nada',g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf')) = '') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['te_versao_bde'           ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_bde'           ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_dao'           ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_dao'           ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_ado'           ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_ado'           ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_odbc'          ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_odbc'          ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_directx'       ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_directx'       ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_acrobat_reader'] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_acrobat_reader',g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_ie'            ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_ie'            ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_mozilla'       ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_mozilla'       ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_versao_jre'           ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_versao_jre'           ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_inventario_softwares' ] := StringReplace(g_oCacic.getValueFromFile('Col_Soft','te_inventario_softwares' ,g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'),'+','<MAIS>',[rfReplaceAll]);
                        Request_Ger_Cols.Values['te_variaveis_ambiente'   ] := StringReplace(g_oCacic.enCrypt( StringReplace(g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Soft','te_variaveis_ambiente',g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf')),'\','<BarrInv>',[rfReplaceAll])),'+','<MAIS>',[rfReplaceAll]);

                        if g_oCacic.inDebugMode then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                g_oCacic.writeDebugLog('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Soft: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_software.php', Request_Ger_Cols, 'Enviando informações de Softwares Básicos para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            // Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            g_oCacic.setValueToFile('Coletas','Software', g_oCacic.getValueFromFile('Col_Soft','UVC',g_oCacic.getLocalFolder + 'Temp\COL_SOFT.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',-1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    Request_Ger_Cols.Clear;
                    g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','COL_SOFT.inf');
                  End;

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf')) then
                  Begin
                    g_oCacic.writeDebugLog('Indicador '+g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf encontrado.');
                    v_acao_gercols := '* Preparando envio de informações de Unidades de Disco.';

                    // Armazeno dados para informações de coletas na data, via menu popup do Systray
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+'#Informações sobre Unidades de Disco'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    // Armazeno as horas de início e fim das coletas
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Undi','Inicio',g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                    g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ',' + g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Undi','Fim'   ,g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf'))), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    if (g_oCacic.deCrypt( g_oCacic.getValueFromFile('Col_Undi','nada',g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf')) = '') then
                      Begin
                        // Preparação para envio...
                        Request_Ger_Cols.Values['UnidadesDiscos'] := StringReplace(g_oCacic.getValueFromFile('Col_Undi','UVC',g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf'),'+','<MAIS>',[rfReplaceAll]);

                        if g_oCacic.inDebugMode then
                            For intLoop := 0 to Request_Ger_Cols.Count-1 do
                                g_oCacic.writeDebugLog('Item "'+Request_Ger_Cols.Names[intLoop]+'" de Col_Undi: '+Request_Ger_Cols.ValueFromIndex[intLoop]);

                        if (ComunicaServidor('set_unid_discos.php', Request_Ger_Cols, 'Enviando informações de Unidades de Disco para o Gerente WEB.') <> '0') Then
                          Begin
                            // Armazeno o Status Positivo de Envio
                            g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                            // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
                            //Sobreponho a informação no registro para posterior comparação, na próxima execução.
                            g_oCacic.setValueToFile('Coletas','UnidadesDisco', g_oCacic.getValueFromFile('Col_Undi','UVC',g_oCacic.getLocalFolder + 'Temp\COL_UNDI.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                            intAux := 1;
                          End
                        else
                          // Armazeno o Status Negativo de Envio
                          g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',-1'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                      End
                    else
                      // Armazeno o Status Nulo de Envio
                      g_oCacic.setValueToFile('Coletas','HOJE',g_oCacic.enCrypt( g_oCacic.deCrypt( g_oCacic.getValueFromFile('Coletas','HOJE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))+',0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

                    Request_Ger_Cols.Clear;
                    g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','COL_UNDI.inf');
                  End;
              Request_Ger_Cols.Free;

              // Reinicializo o indicador de Fila de Espera para FTP
              g_oCacic.setValueToFile('Configs','TE_FILA_FTP',g_oCacic.enCrypt('0'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

              if (intAux = 0) then
                  g_oCacic.writeDailyLog('Sem informações para envio ao Gerente WEB.')
              else begin
                  // Atualiza a data de última coleta
                  g_oCacic.setValueToFile('Configs','DT_HR_ULTIMA_COLETA',g_oCacic.enCrypt( FormatDateTime('YYYYmmddHHnnss', Now)), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                  g_oCacic.writeDailyLog('Os dados coletados - e não redundantes - foram enviados ao Gerente WEB.');
              end;
            end;
  Except
    Begin
     g_oCacic.writeDailyLog('PROBLEMAS EM EXECUTA_GER_COLS! Ação: ' + v_acao_gercols+'.');
     CriaTXT(g_oCacic.getLocalFolder,'ger_erro');
     g_oCacic.setValueToFile('Mensagens','CsTipo'    , g_oCacic.enCrypt( 'mtError')     , g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
     g_oCacic.setValueToFile('Mensagens','TeMensagem', g_oCacic.enCrypt( v_acao_gercols), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
     Finalizar(false);
     Sair;
    End;
  End;
//  g_oCacic.Free;
End;

begin
   g_oCacic := TCACIC.Create();
   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    Begin
      if ParamCount > 0 then
        Begin
          g_oCacic.setLocalFolder(g_oCacic.GetParam('LocalFolder'));
          g_oCacic.setWebManagerAddress(g_oCacic.GetParam('WebManagerAddress'));
          g_oCacic.setMainProgramName(g_oCacic.GetParam('MainProgramName'));
          g_oCacic.setMainProgramHash(g_oCacic.GetParam('MainProgramHash'));

          Try
             g_oCacic.checkDebugMode;
             if g_oCacic.inDebugMode then
               g_oCacic.writeDailyLog('As informações para DEBUG de coletas internas serão gravadas em "' + g_oCacic.getLocalFolder + 'Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt');

             // De acordo com a versão do OS, determina-se o ShellCommand para chamadas externas.
             p_Shell_Command := 'cmd.exe /c '; //NT/2K/XP
             if(g_oCacic.isWindows9xME()) then
                p_Shell_Command := 'command.com /c ';

             if not DirectoryExists(g_oCacic.getLocalFolder + 'Temp') then
               ForceDirectories(g_oCacic.getLocalFolder + 'Temp');

             g_oCacic.setBoolCipher(true);

             // Não tirar desta posição
             g_oCacic.setValueToFile('Configs','TE_SO',g_oCacic.enCrypt( g_oCacic.getWindowsStrId()), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

             g_oCacic.setValueToFile('Configs','CS_CIPHER'  , g_oCacic.enCrypt('1'),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
             g_oCacic.setValueToFile('Configs','CS_COMPRESS', g_oCacic.enCrypt('0'),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

             g_oCacic.writeDebugLog('Te_So obtido: "' + g_oCacic.getWindowsStrId() +'"');

             v_scripter := 'wscript.exe';

             CriaCookie('aguarde_GER.txt');

             Executa_Ger_Cols;

             Finalizar(true);
          Except
             Begin
              g_oCacic.writeDailyLog('PROBLEMAS EM EXECUTA_GER_COLS! Ação : ' + v_acao_gercols+'.');
              CriaTXT(g_oCacic.getLocalFolder,'ger_erro');
              g_oCacic.setValueToFile('Mensagens','CsTipo'    , g_oCacic.enCrypt( 'mtError'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Mensagens','TeMensagem', g_oCacic.enCrypt( v_acao_gercols), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              Finalizar(false);
             End;
          End;
        End;
    End;
end.
