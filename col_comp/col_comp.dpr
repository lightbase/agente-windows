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

program col_comp;
{$R *.res}

uses  Windows,
      SysUtils,
      Classes,
      Registry,
      DCPcrypt2,
      DCPrijndael,
      DCPbase64;

var  p_path_cacic : string;
     v_CipherKey,
     v_IV,
     v_strCipherClosed,
     v_DatFileName             : String;

var v_tstrCipherOpened,
    v_tstrCipherOpened1        : TStrings;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

function HomeDrive : string;
var
WinDir : array [0..144] of char;
begin
GetWindowsDirectory (WinDir, 144);
Result := StrPas (WinDir);
end;

Function Implode(p_Array : TStrings ; p_Separador : String) : String;
var intAux : integer;
    strAux : string;
Begin
    strAux := '';
    For intAux := 0 To p_Array.Count -1 do
      Begin
        if (strAux<>'') then strAux := strAux + p_Separador;
        strAux := strAux + p_Array[intAux];
      End;
    Implode := strAux;
end;

procedure log_diario(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr (p_path_cacic + 'cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,p_path_cacic + 'cacic2.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor COMP] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
//       FileSetAttr (ExtractFilePath(Application.Exename) + '\cacic2.log',6); // Muda o atributo para arquivo de SISTEMA e OCULTO

   except
     log_diario('Erro na gravação do log!');
   end;
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


// Encrypt a string and return the Base64 encoded result
function EnCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    // Pad Key, IV and Data with zeros as appropriate
    l_Key   := PadWithZeros(v_CipherKey,KeySize);
    l_IV    := PadWithZeros(v_IV,BlockSize);
    l_Data  := PadWithZeros(p_Data,BlockSize);

    // Create the cipher and initialise according to the key length
    l_Cipher := TDCP_rijndael.Create(nil);
    if Length(v_CipherKey) <= 16 then
      l_Cipher.Init(l_Key[1],128,@l_IV[1])
    else if Length(v_CipherKey) <= 24 then
      l_Cipher.Init(l_Key[1],192,@l_IV[1])
    else
      l_Cipher.Init(l_Key[1],256,@l_IV[1]);

    // Encrypt the data
    l_Cipher.EncryptCBC(l_Data[1],l_Data[1],Length(l_Data));

    // Free the cipher and clear sensitive information
    l_Cipher.Free;
    FillChar(l_Key[1],Length(l_Key),0);

    // Return the Base64 encoded result
    Result := Base64EncodeStr(l_Data);
  Except
    log_diario('Erro no Processo de Criptografia');
  End;
end;

function DeCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    // Pad Key and IV with zeros as appropriate
    l_Key := PadWithZeros(v_CipherKey,KeySize);
    l_IV := PadWithZeros(v_IV,BlockSize);

    // Decode the Base64 encoded string
    l_Data := Base64DecodeStr(p_Data);

    // Create the cipher and initialise according to the key length
    l_Cipher := TDCP_rijndael.Create(nil);
    if Length(v_CipherKey) <= 16 then
      l_Cipher.Init(l_Key[1],128,@l_IV[1])
    else if Length(v_CipherKey) <= 24 then
      l_Cipher.Init(l_Key[1],192,@l_IV[1])
    else
      l_Cipher.Init(l_Key[1],256,@l_IV[1]);

    // Decrypt the data
    l_Cipher.DecryptCBC(l_Data[1],l_Data[1],Length(l_Data));

    // Free the cipher and clear sensitive information
    l_Cipher.Free;
    FillChar(l_Key[1],Length(l_Key),0);

    // Return the result
    Result := l_Data;
  Except
    log_diario('Erro no Processo de Decriptografia');
  End;
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

       //v_Cipher  := TDCP_rijndael.Create(nil);
       //v_Cipher.InitStr(v_CipherKey,TDCP_md5);
       v_strCipherOpenImploded := Implode(p_tstrCipherOpened,'=CacicIsFree=');
       //v_strCipherClosed := v_Cipher.EncryptString(v_strCipherOpenImploded);
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);
       //v_Cipher.Burn;
       //v_Cipher.Free;
       Writeln(v_DatFile,v_strCipherClosed); {Grava a string Texto no arquivo texto}
       CloseFile(v_DatFile);
   except
   end;
end;

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
        If (Copy(Texto,I,TamanhoSeparador) = Separador) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + Texto[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
            strItem := strItem + Texto[I];

        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
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
      v_strCipherOpened:= DeCrypt(v_strCipherClosed);
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := explode(v_strCipherOpened,'=CacicIsFree=')
    else
      Result := explode('Configs.ID_SO=CacicIsFree='+inttostr(GetWinVer)+'=CacicIsFree=Configs.Endereco_WS=CacicIsFree=/cacic2/ws/','=CacicIsFree=');


    if Result.Count mod 2 <> 0 then
        Result.Add('');
end;

Procedure SetValorDatMemoria(p_Chave : string; p_Valor : String; p_tstrCipherOpened : TStrings);
begin
//log_diario('Gravando: '+p_Chave+' Valor: '+p_Valor);
    // Exemplo: p_Chave => Configs.nu_ip_servidor  :  p_Valor => 10.71.0.120
    if (p_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
        p_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1] := p_Valor
    else
      Begin
        p_tstrCipherOpened.Add(p_Chave);
        p_tstrCipherOpened.Add(p_Valor);
      End;

end;

Function GetValorDatMemoria(p_Chave : String) : String;
begin
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
//log_diario('Buscando: '+p_Chave+' Resultado: '+Result);
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
    ListaAuxGet := Explode(Chave, '\');

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




procedure Executa_Col_comp;
function RetornaValorShareNT(ValorReg : String; LimiteEsq : String; LimiteDir : String) : String;
var intAux, intAux2 : Integer;
Begin
    intAux := Pos(LimiteEsq, ValorReg) + Length(LimiteEsq);
    if (LimiteDir = 'Fim') Then intAux2 := Length(ValorReg) - 1
    Else intAux2 := Pos(LimiteDir, ValorReg) - intAux - 1;
    result := Trim(Copy(ValorReg, intAux, intAux2));
end;
var Reg_RCC : TRegistry;
    ChaveRegistro, ValorChaveRegistro, nm_compartilhamento, nm_dir_compart,
    in_senha_escrita,	in_senha_leitura, te_comentario, strXML, strAux,
    cs_tipo_permissao, cs_tipo_compart  : String;
    I, intAux: Integer;
    Lista_RCC : TStringList;
Begin
  Try
    SetValorDatMemoria('Col_Comp.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
    nm_compartilhamento := '';
    nm_dir_compart := '';
    cs_tipo_compart := ' ';
    cs_tipo_permissao := ' ';
    in_senha_leitura := '';
    in_senha_escrita := '';
    log_diario('Coletando informações de Compartilhamentos.');
    Reg_RCC := TRegistry.Create;
    Reg_RCC.LazyWrite := False;
    Lista_RCC := TStringList.Create;
    Reg_RCC.Rootkey := HKEY_LOCAL_MACHINE;
    {
    strXML := '<?xml version="1.0" encoding="ISO-8859-1"?>' +
              '<comparts>'           +
              '<te_node_address>'    + GetValorChaveRegIni('TcpIp'  ,'TE_NODE_ADDRESS'   ,p_path_cacic_ini) + '</te_node_address>'    +
              '<te_nome_computador>' + GetValorChaveRegIni('TcpIp'  ,'TE_NOME_COMPUTADOR',p_path_cacic_ini) + '</te_nome_computador>' +
              '<te_workgroup>'       + GetValorChaveRegIni('TcpIp'  ,'TE_WORKGROUP'      ,p_path_cacic_ini) + '</te_workgroup>'       +
              '<id_so>'              + GetValorChaveRegIni('Configs','ID_SO'             ,p_path_cacic_ini) + '</id_so>';
    }

    strXML := '<?xml version="1.0" encoding="ISO-8859-1"?><comparts>';

    if Win32Platform = VER_PLATFORM_WIN32_NT then
    Begin  // 2k, xp, nt.
        ChaveRegistro := '\System\ControlSet001\Services\lanmanserver\Shares\';
        Reg_RCC.OpenKeyReadOnly(ChaveRegistro);
        Reg_RCC.GetValueNames(Lista_RCC);
        Reg_RCC.CloseKey;
        For I := 0 To Lista_RCC.Count - 1 Do
        Begin
           nm_compartilhamento := Lista_RCC.Strings[i];
           strAux := GetValorChaveRegEdit('HKEY_LOCAL_MACHINE' + ChaveRegistro + nm_compartilhamento);
           nm_dir_compart := RetornaValorShareNT(strAux, 'Path=', 'Permissions=');
           te_comentario := RetornaValorShareNT(strAux, 'Remark=', 'Type=');
           cs_tipo_compart := RetornaValorShareNT(strAux, 'Type=', 'Fim');
           if (cs_tipo_compart = '0') Then cs_tipo_compart := 'D' Else cs_tipo_compart := 'I';
           strXML := strXML + '<compart>' +
                     '<nm_compartilhamento>' + nm_compartilhamento + '</nm_compartilhamento>' +
                     '<nm_dir_compart>' + nm_dir_compart + '</nm_dir_compart>' +
                     '<cs_tipo_compart>' + cs_tipo_compart + '</cs_tipo_compart>' +
                     '<te_comentario>' + te_comentario + '</te_comentario>' +
                     '</compart>';
        end;
    end
    Else
    Begin
        ChaveRegistro := '\Software\Microsoft\Windows\CurrentVersion\Network\LanMan\';
        Reg_RCC.OpenKeyReadOnly(ChaveRegistro);
        Reg_RCC.GetKeyNames(Lista_RCC);
        Reg_RCC.CloseKey;
        For I := 0 To Lista_RCC.Count - 1 Do
        Begin
           nm_compartilhamento := Lista_RCC.Strings[i];
           Reg_RCC.OpenKey(ChaveRegistro + nm_compartilhamento, True);
           nm_dir_compart := Reg_RCC.ReadString('Path');
           te_comentario := Reg_RCC.ReadString('Remark');
           if (Reg_RCC.GetDataSize('Parm1enc') = 0) Then in_senha_escrita := '0' Else in_senha_escrita := '1';
           if (Reg_RCC.GetDataSize('Parm2enc') = 0) Then in_senha_leitura := '0' Else in_senha_leitura := '1';
           if (Reg_RCC.ReadInteger('Type') = 0) Then cs_tipo_compart := 'D' Else cs_tipo_compart := 'I';
           intAux := Reg_RCC.ReadInteger('Flags');
           Case intAux of    //http://www.la2600.org/talks/chronology/enigma/19971107.html
             401 : cs_tipo_permissao := 'S'; // Somente Leitura.
             258 : cs_tipo_permissao := 'C'; // Completo.
             259 : cs_tipo_permissao := 'D'; // Depende de senha.
           end;
           Reg_RCC.CloseKey;
           strXML := strXML + '<compart>' +
                        '<nm_compartilhamento>' + nm_compartilhamento + '</nm_compartilhamento>' +
                        '<nm_dir_compart>' + nm_dir_compart + '</nm_dir_compart>' +
                        '<cs_tipo_compart>' + cs_tipo_compart + '</cs_tipo_compart>' +
                        '<cs_tipo_permissao>' + cs_tipo_permissao + '</cs_tipo_permissao>' +
                        '<in_senha_leitura>' + in_senha_leitura + '</in_senha_leitura>' +
                        '<in_senha_escrita>' + in_senha_escrita + '</in_senha_escrita>' +
                        '<te_comentario>' + te_comentario + '</te_comentario>' +
                     '</compart>';
        end;
    end;

    if (Lista_RCC.Count = 0) then strXML := strXML + '<compart>' +
                     '<nm_compartilhamento></nm_compartilhamento>' +
                     '<nm_dir_compart></nm_dir_compart>' +
                     '<cs_tipo_compart></cs_tipo_compart>' +
                     '<te_comentario></te_comentario>' +
                     '</compart>';

    Reg_RCC.Free;
    Lista_RCC.Free;
    strXML := strXML + '</comparts>';

    // Obtenho do registro o valor que foi previamente armazenado
    ValorChaveRegistro := Trim(GetValorDatMemoria('Coletas.Compartilhamentos'));

    SetValorDatMemoria('Col_Comp.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

    // Se essas informações forem diferentes significa que houve alguma alteração
    // na configuração. Nesse caso, gravo as informações no BD Central e, se não houver
    // problemas durante esse procedimento, atualizo as informações no registro.
    If (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_COMP')='S') or (strXML <> ValorChaveRegistro) Then
       Begin
         SetValorDatMemoria('Col_Comp.UVC', strXML, v_tstrCipherOpened1);
//log_diario('Vou chamar o CLOSE...');
         CipherClose(p_path_cacic + 'temp\col_comp.dat', v_tstrCipherOpened1);
//log_diario('Após chamada ao CLOSE...');
       End
    else
      Begin
        SetValorDatMemoria('Col_Comp.nada', 'nada', v_tstrCipherOpened1);
        CipherClose(p_path_cacic + 'temp\col_comp.dat', v_tstrCipherOpened1);
      End;
  Except
    Begin
      SetValorDatMemoria('Col_Comp.nada', 'nada', v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Comp.Fim', '99999999', v_tstrCipherOpened1);      
      CipherClose(p_path_cacic + 'temp\col_comp.dat', v_tstrCipherOpened1);
    End;
  End;
end;

var tstrTripa1 : TStrings;
    intAux     : integer;
begin
  if (ParamCount>0) then
    Begin
      For intAux := 1 to ParamCount do
        Begin
          if LowerCase(Copy(ParamStr(intAux),1,13)) = '/p_cipherkey=' then
            v_CipherKey := Trim(Copy(ParamStr(intAux),14,Length((ParamStr(intAux)))));
        End;

       if (trim(v_CipherKey)<>'') then
          Begin
             //Pegarei o nível anterior do diretório, que deve ser, por exemplo \Cacic, para leitura do cacic2.ini
             tstrTripa1 := explode(ExtractFilePath(ParamStr(0)),'\');
             p_path_cacic := '';
             For intAux := 0 to tstrTripa1.Count -2 do
               begin
                 p_path_cacic := p_path_cacic + tstrTripa1[intAux] + '\';
               end;

             // A chave AES foi obtida no parâmetro p_CipherKey. Recomenda-se que cada empresa altere a sua chave.
             v_IV                := 'abcdefghijklmnop';             
             v_DatFileName       := p_path_cacic + 'cacic2.dat';
             v_tstrCipherOpened  := TStrings.Create;
             v_tstrCipherOpened  := CipherOpen(v_DatFileName);

             v_tstrCipherOpened1 := TStrings.Create;
             v_tstrCipherOpened1 := CipherOpen(p_path_cacic + 'temp\col_comp.dat');

             Try
                Executa_Col_comp;
             Except
                SetValorDatMemoria('Col_Comp.nada', 'nada', v_tstrCipherOpened1);
                CipherClose(p_path_cacic + 'temp\col_comp.dat', v_tstrCipherOpened1);
             End;
             Halt(0);
          End;
    End;
end.
