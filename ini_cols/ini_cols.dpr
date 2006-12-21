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
  DCPcrypt2,
  DCPrijndael,
  DCPbase64;


var p_path_cacic,
    v_te_senha_login_serv_updates,
    v_versao                  : string;
    v_array_path_cacic        : TStrings;
    intAux,
    v_ContaTempo,
    v_Tolerancia              : integer;
    v_CipherKey,
    v_IV,
    v_SeparatorKey,
    v_DatFileName,
    v_ModulosOpcoes,
    v_Aux                     : String;
    v_Debugs                  : Boolean;
    v_Aguarde                 : TextFile;

var v_tstrCipherOpened,
    v_tstrModulosOpcoes,
    v_tstrModuloOpcao         : TStrings;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits

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
       if (trim(strMsg) <> '') then
          begin
             DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
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

Function GetValorDatMemoria(p_Chave : String) : String;
begin
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
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
  End;
end;

Function CipherOpen(p_DatFileName : string) : TStrings;
var v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
//    intLoop           : integer;
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
      log_DEBUG('Rotina de Abertura do cacic2.dat RESTAURANDO estado da criptografia.');
    end;
    if (trim(v_strCipherOpened)<>'') then
      Result := explode(v_strCipherOpened,v_SeparatorKey)
    else
      Result := explode('Configs.ID_SO'+v_SeparatorKey+inttostr(GetWinVer)+v_SeparatorKey+'Configs.Endereco_WS'+v_SeparatorKey+'/cacic2/ws/',v_SeparatorKey);


    if Result.Count mod 2 <> 0 then
      Begin
        log_DEBUG('Vetor MemoryDAT com tamanho IMPAR... Ajustando.');
        Result.Add('');
      End;

    {
    log_DEBUG(v_DatFileName+' aberto com sucesso!');
    if v_Debugs then
      for intLoop := 0 to (Result.Count-1) do
        log_DEBUG('Posição ['+inttostr(intLoop)+'] do MemoryDAT: '+Result[intLoop]);
    }

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


begin
  if (ParamCount>0) then // A passagem da chave EAS é mandatória...
    Begin
       For intAux := 1 to ParamCount do
          Begin
            if LowerCase(Copy(ParamStr(intAux),1,13)) = '/p_cipherkey=' then
              v_CipherKey := Trim(Copy(ParamStr(intAux),14,Length((ParamStr(intAux)))));
          End;

       if (trim(v_CipherKey)<>'') then
          Begin
             //Pegarei o nível anterior do diretório, que deve ser, por exemplo \Cacic, para leitura do cacic2.dat
             v_array_path_cacic := explode(ExtractFilePath(ParamStr(0)),'\');
             p_path_cacic := '';
             For intAux := 0 to v_array_path_cacic.Count -2 do
               begin
                 p_path_cacic := p_path_cacic + v_array_path_cacic[intAux] + '\';
               end;

             v_Debugs := false;
             if DirectoryExists(p_path_cacic + 'Temp\Debugs') then
                Begin
                 if (FormatDateTime('ddmmyyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                   Begin
                     v_Debugs := true;
                     log_DEBUG('Pasta "' + p_path_cacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                   End;
                End;

             // A existência e bloqueio do arquivo abaixo evitará que Cacic2.exe chame o Ger_Cols quando a coleta ainda estiver sendo efetuada
             AssignFile(v_Aguarde,p_path_cacic + 'temp\aguarde_INI.txt'); {Associa o arquivo a uma variável do tipo TextFile}
             {$IOChecks off}
             Reset(v_Aguarde); {Abre o arquivo texto}
             {$IOChecks on}
             if (IOResult <> 0) then // Arquivo não existe, será recriado.
                  Rewrite (v_Aguarde);

             Append(v_Aguarde);
             Writeln(v_Aguarde,'Apenas um pseudo-cookie para o Cacic2 esperar o término de Ini_Cols');
             Append(v_Aguarde);

             // A chave AES foi obtida no parâmetro p_CipherKey. Recomenda-se que cada empresa altere a sua chave.
             v_IV           := 'abcdefghijklmnop';
             v_DatFileName  := p_path_cacic + 'cacic2.dat';
             v_SeparatorKey := '=CacicIsFree=';

             Try
                  // Caso exista o Gerente de Coletas será verificada a versão...
                  // Devido a problemas na rotina de FTP na versão 2.0.1.2,
                  // que impossibilitava atualização de versões de todos os componentes, exceto INI_COLS
                  If (FileExists(p_path_cacic + 'modulos\ger_cols.exe')) Then
                      Begin
                        v_versao := trim(GetVersionInfo(p_path_cacic +  'modulos\ger_cols.exe'));
                        if (v_versao = '0.0.0.0') then // Provavelmente arquivo corrompido ou versão muito antiga
                          Begin
                            Matar(p_path_cacic+'modulos\','ger_cols.exe');
                            Sleep(5000); // Pausa 5 segundos para total exclusão de GER_COLS
                            CipherOpen(v_DatFileName);
                            v_te_senha_login_serv_updates := GetValorDatMemoria('Configs.te_senha_login_serv_updates');

                            FTP(GetValorDatMemoria('Configs.te_serv_updates'),
                                GetValorDatMemoria('Configs.nu_porta_serv_updates'),
                                GetValorDatMemoria('Configs.nm_usuario_login_serv_updates'),
                                v_te_senha_login_serv_updates,
                                GetValorDatMemoria('Configs.te_path_serv_updates'),
                                'ger_cols.exe',
                                p_path_cacic + 'modulos');

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
                  v_tstrModulosOpcoes := explode(v_ModulosOpcoes,'#');

                  // Tempo de tolerância para as coletas
                  v_Tolerancia := 5; // (minutos)

                  For intAux := 0 to v_tstrModulosOpcoes.Count -1 do
                    Begin
                      v_tstrModuloOpcao := explode(v_tstrModulosOpcoes[intAux],',');
                      v_Aux := v_tstrModuloOpcao[0]+'.exe /p_CipherKey='+v_CipherKey+ ' /p_Option='+v_tstrModuloOpcao[2];
                      log_DEBUG('Chamando "' + v_tstrModuloOpcao[0]+'.exe /p_CipherKey=*****" /p_Option='+v_tstrModuloOpcao[2]);

                      WinExec(PChar(v_Aux), SW_HIDE);

                      if (v_tstrModuloOpcao[1]='wait') then
                          while not FileExists(p_path_cacic + 'temp\'+v_tstrModuloOpcao[0]+'.dat') do
                              Sleep(2000)
                      else
                        Begin
                          v_ContaTempo := 0;
                          while not FileExists(p_path_cacic + 'temp\'+v_tstrModuloOpcao[0]+'.dat') and
                                    ((v_ContaTempo/60)< v_Tolerancia) do // Tolerância para a coleta
                            Begin
                              Sleep(2000);
                              v_ContaTempo := v_ContaTempo + 2;
                            End;
                        End;
                    End;

                  For intAux := 0 to v_tstrModulosOpcoes.Count -1 do
                    Begin
                      v_tstrModuloOpcao := explode(v_tstrModulosOpcoes[intAux],',');
                      v_Aux := p_path_cacic + 'temp\'+v_tstrModuloOpcao[0]+'.dat';
                      if (FileExists(v_Aux)) then
                        Begin
                          log_DEBUG('Chamando "'+'ger_cols.exe /p_CipherKey=*****');
                          WinExec(PChar('ger_cols.exe /p_CipherKey='+v_CipherKey), SW_HIDE);
                          // Fecha o arquivo temp\aguarde_INI.txt
                          CloseFile(v_Aguarde);
                          Matar(p_path_cacic+'temp\','aguarde_INI');
                          break;
                        End;
                    End;
             except
             end;
          End;
    End;
end.
