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

program col_hard;
{$R *.res}
{$APPTYPE CONSOLE}

uses
  Windows,
  Registry,
  SysUtils,
  Classes,
  IniFiles,
  MSI_SMBIOS,
  MSI_Devices,
  MSI_CPU,
  MSI_DISPLAY,
  MSI_MEDIA,
  MSI_NETWORK,
  MSI_XML_Reports,
  DCPcrypt2,
  DCPrijndael,
  DCPbase64,
  PJVersionInfo,
  CACIC_Library in '..\CACIC_Library.pas';

var  p_path_cacic, v_mensagem : string;
     v_debugs : boolean;
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

// Dica baixada de http://www.marcosdellantonio.net/2007/06/14/operador-if-ternario-em-delphi-e-c/
// Fiz isso para não ter que acrescentar o componente Math ao USES!
function iif(condicao : boolean; resTrue, resFalse : Variant) : Variant;
  Begin
    if condicao then
      Result := resTrue
    else
      Result := resFalse;
  End;
  
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
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage(p_path_cacic + 'cacic2.log')));
       DateTimeToString(strDataAtual   , 'yyyymmdd', Date);
       if (strDataAtual <> strDataArqLocal) then // Se o arquivo INI não é da data atual...
          begin
            Rewrite (HistoricoLog); //Cria/Recria o arquivo
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log <=======================');
          end;
       Append(HistoricoLog);
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor HARD] '+strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
//       FileSetAttr (ExtractFilePath(Application.Exename) + '\cacic2.log',6); // Muda o atributo para arquivo de SISTEMA e OCULTO

   except
     log_diario('Erro na gravação do log!');
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
       v_strCipherClosed := EnCrypt(v_strCipherOpenImploded);
       //v_strCipherClosed := v_Cipher.EncryptString(v_strCipherOpenImploded);
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

procedure log_DEBUG(p_msg:string);
Begin
  if v_Debugs then log_diario('(v.'+getVersionInfo(ParamStr(0))+') DEBUG - '+p_msg);
End;

// Função criada devido a divergências entre os valores retornados pelos métodos dos componentes MSI e seus Reports.
function Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
var intClasses, intSections, intDatas, v_achei_SectionName, v_array_SectionName_Count : integer;
    v_ClassName, v_DataName, v_string_consulta : string;
    v_array_SectionName : tstrings;
begin
    Log_DEBUG('p_ClassName => "'+p_ClassName+'" p_SectionName => "'+p_SectionName+'" p_DataName => "'+p_DataName+'"');
    Result              := '';
    if (p_SectionName <> '') then
      Begin
        v_array_SectionName := explode(p_SectionName,'/');
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
          log_diario('ERRO! Problema na rotina parse');
        End;
    end;
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

procedure Grava_Debugs(strMsg : String);
var
    DebugsFile : TextFile;
    strDataArqLocal, strDataAtual, v_file_debugs : string;
begin
   try
       v_file_debugs := p_path_cacic + '\Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt';
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

Function TrataExcecoesMacAddress(p_mac:String; p_excecao:String): String;
var tstrEXCECOES : TStrings;
var intAux1, v_conta_EXCECOES : integer;

Begin
   Result   := '';
   v_conta_EXCECOES := 0;
   if (p_excecao <> '') then
      Begin
        tstrEXCECOES  := Explode(p_excecao,','); // Excecoes a serem tratadas
        for intAux1 := 0 to tstrEXCECOES.Count-1 Do
          Begin
            if (rat(tstrEXCECOES[intAux1],p_mac) > 0) then
              Begin
                v_conta_EXCECOES := 1;
                break;
              End;
          End;
      End;
   if (v_conta_EXCECOES = 0) then
      Begin
        Result := p_mac;
      End;
End;

procedure Executa_Col_Hard;
var v_te_cpu_fabricante,
    v_te_cpu_desc,
    v_te_cpu_serial,
    v_te_cpu_frequencia,
    v_te_placa_rede_desc,
    v_te_placa_som_desc,
    v_te_cdrom_desc,
    v_te_teclado_desc,
    v_te_modem_desc,
    v_te_mouse_desc,
    v_te_mem_ram_desc,
    v_te_mem_ram_tipo,
    v_qt_placa_video_mem,
    v_te_placa_video_resolucao,
    v_te_placa_video_desc,
    v_qt_placa_video_cores,
    v_te_bios_fabricante,
    v_te_bios_data,
    v_te_bios_desc,
    v_te_placa_mae_fabricante,
    v_te_placa_mae_desc,
    UVC,
    ValorChaveRegistro,
    v_DataName,
    v_SectionName,
    v_Macs_Invalidos,
    v_Mac_Address,
    v_Tripa_CDROM,
    v_Tripa_TCPIP,
    v_Tripa_CPU,
    strAux,
    v_PhysicalAddress,
    v_IPAddress,
    v_IPMask,
    v_Gateway_IPAddress,
    v_DHCP_IPAddress,
    v_PrimaryWINS_IPAddress,
    v_SecondaryWINS_IPAddress                        : String;
    i, j, count                   : Integer;
    v_qt_mem_ram                  : WORD;
    v_CPU                         : TMiTeC_CPU;
    v_DISPLAY                     : TMiTeC_Display;
    v_MEDIA                       : TMiTeC_Media;
    v_DEVICES                     : TMiTeC_Devices;
    v_TCP                         : TMiTeC_TCPIP;
    v_SMBIOS                      : TMiTeC_SMBIOS;
    v_MemoriaRAM                  : TMemoryStatus;
    v_Report,
    v_tstrCPU,
    v_tstrCDROM,
    v_tstrTCPIP                   : TStringList;

    v_cpu_freq                    : TStrings;
    v_registry                    : TRegistry;

    oCacic : TCACIC;

begin
  oCacic := TCACIC.Create();
  Try
     SetValorDatMemoria('Col_Hard.Inicio', FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
     v_Report := TStringList.Create;
     log_diario('Coletando informações de Hardware.');

     v_cpu_freq  := TStringList.Create;
     v_tstrCPU   := TStringList.Create;
     v_tstrCDROM := TStringList.Create;
     v_tstrTCPIP := TStringList.Create;

     Try
        Begin
            Log_Debug('Instanciando SMBIOS para obter frequencia de CPU...');
            v_SMBIOS := TMiTeC_SMBIOS.Create(nil);
            v_SMBIOS.RefreshData;
            v_te_cpu_frequencia := 'ND';
            if(v_SMBIOS.Processor[0].Frequency > 0) then
              v_te_cpu_frequencia := inttostr(v_SMBIOS.Processor[0].Frequency) + 'Mhz'   // Frequancia de CPU via BIOS
            else begin
               v_registry := TRegistry.Create;
               try
                 v_registry.RootKey := HKEY_LOCAL_MACHINE;
                 try
                   if(v_registry.Openkey('HARDWARE\DESCRIPTION\System\CentralProcessor\0\', False)) then begin
                     v_te_cpu_frequencia := inttostr(v_registry.ReadInteger('~MHz'))+'Mhz'; // Frequencia de CPU via Regitry
                     v_registry.CloseKey;
                   end;
                 except
                   log_diario('CPU - informação de frequência ['+v_te_cpu_frequencia+'] não disponível (by SMBIOS/Registry): ');
                 end;
               finally
                 v_registry.Free;
               end;
            end;
            v_SMBIOS.Free;

            Log_Debug('CPU - frequência estática (by SMBIOS/Registry): '+v_te_cpu_frequencia);

            Log_Debug('Instanciando v_CPU...');
            v_CPU := TMiTeC_CPU.Create(nil);
            Log_Debug('Atualização de dados de CPU...');
            v_CPU.RefreshData;
            Log_Debug('Dados de CPU atualizados - OK!');

            // Obtem dados de CPU
            Try
               for i:=0 to v_CPU.CPUCount-1 do begin
                  v_te_cpu_serial := v_CPU.SerialNumber;
                  v_te_cpu_desc   := v_CPU.CPUName;
                  if(v_te_cpu_desc = '') then
                     v_te_cpu_desc := v_CPU.MarketingName;

                  v_te_cpu_fabricante  := cVendorNames[v_CPU.Vendor].Prefix;

                  Log_Debug('CPU - frequência dinâmica (by CPU): '+inttostr(v_CPU.Frequency) + 'Mhz');

                  // Se pegou ao menos a descrição, adiciona-se à tripa...
                  if (v_te_cpu_desc <> '') then
                    Begin
                      v_tstrCPU.Add('te_cpu_desc###'       + v_te_cpu_desc        + '#FIELD#' +
                                    'te_cpu_fabricante###' + v_te_cpu_fabricante  + '#FIELD#' +
                                    'te_cpu_serial###'     + v_te_cpu_serial      + '#FIELD#' +
                                    'te_cpu_frequencia###' + v_te_cpu_frequencia);
                      Log_Debug('Adicionando a tstrCPU: "'+v_tstrCPU[v_tstrCPU.count-1]);
                      Log_DEBUG('Tamanho de v_tstrCPU 0: '+intToStr(v_tstrCPU.Count));
                    End;
               end;
            Except
              log_diario('Problemas ao coletar dados de CPU!');
            end;
            v_CPU.Free;
            Log_DEBUG('Tamanho de v_tstrCPU 1: '+intToStr(v_tstrCPU.Count));

            // Media informations
            Try
              v_MEDIA := TMiTeC_Media.Create(nil);
              v_MEDIA.RefreshData;
              if v_Media.SoundCardIndex>-1 then begin
                 //n:=Tree.Items.AddChild(r,Media.Devices[Media.SoundCardIndex]);
                 v_te_placa_som_desc := v_Media.Devices[v_Media.SoundCardIndex];
              end;
            except log_diario('Problemas ao coletar dados de Aúdio');
            end;

            Log_Debug('Dados de aúdio coletados - OK!');

            // Devices informations
            Try
              Log_Debug('Instanciando v_DEVICES...');
              v_DEVICES := TMiTeC_Devices.Create(nil);
              Log_Debug('RefreshingData...');
              v_DEVICES.RefreshData;
              if v_Debugs then MSI_XML_Reports.Devices_XML_Report(v_DEVICES,TRUE,v_Report);
              Log_Debug('v_DEVICES.DeviceCount = '+intToStr(v_DEVICES.DeviceCount));
              i := 0;
              While i < v_DEVICES.DeviceCount do
                Begin
                  v_mensagem := 'Obtendo Descrição de CDROM';
                  Log_Debug('Percorrendo v_DEVICES.Devices['+intToStr(i)+']...');

                  if v_DEVICES.Devices[i].DeviceClass=dcCDROM then
                    Begin
                      // Vamos tentar de tudo!  :))))
                      v_te_cdrom_desc := Trim(v_DEVICES.Devices[i].Name);
                      if Trim(v_te_cdrom_desc)='' then
                        v_te_cdrom_desc := v_DEVICES.Devices[i].FriendlyName;
                      if Trim(v_te_cdrom_desc)='' then
                        v_te_cdrom_desc := v_DEVICES.Devices[i].Description;

                      if (v_te_cdrom_desc <> '') then
                        Begin
                          v_tstrCDROM.Add('te_cdrom_desc###'+v_te_cdrom_desc);
                          Log_Debug('Adicionando a tstrCDROM: "'+v_tstrCDROM[v_tstrCDROM.count-1]+'"');
                          Log_Debug('CDROM Informations - OK!');
                        End;
                    End;


                  v_mensagem := 'Obtendo Descrição de Modem';
                  if v_DEVICES.Devices[i].DeviceClass=dcModem then
                    Begin
                      if Trim(v_DEVICES.Devices[i].FriendlyName)='' then
                        v_te_modem_desc := Trim(v_DEVICES.Devices[i].Description)
                      else
                        v_te_modem_desc := Trim(v_DEVICES.Devices[i].FriendlyName);

                      Log_Debug('MODEM Informations - OK!');
                    End;

                  v_mensagem := 'Obtendo Descrição de Mouse';
                  if v_DEVICES.Devices[i].DeviceClass=dcMouse then
                    Begin
                      if Trim(v_DEVICES.Devices[i].FriendlyName)='' then
                        v_te_mouse_desc := Trim(v_DEVICES.Devices[i].Description)
                      else
                        v_te_mouse_desc := Trim(v_DEVICES.Devices[i].FriendlyName);

                      Log_Debug('MOUSE Informations - OK!');
                    End;

                  v_mensagem := 'Obtendo Descrição de Teclado';
                  if v_DEVICES.Devices[i].DeviceClass=dcKeyboard then
                    Begin
                      if Trim(v_DEVICES.Devices[i].FriendlyName)='' then
                        v_te_teclado_desc := Trim(v_DEVICES.Devices[i].Description)
                      else
                        v_te_teclado_desc := Trim(v_DEVICES.Devices[i].FriendlyName);

                      Log_Debug('KEYBOARD Informations - OK!');
                    End;

                  v_mensagem := 'Obtendo Descrição de Vídeo';
                  if v_DEVICES.Devices[i].DeviceClass=dcDisplay then
                    Begin
                      if Trim(v_DEVICES.Devices[i].FriendlyName)='' then
                        v_te_placa_video_desc := Trim(v_DEVICES.Devices[i].Description)
                      else
                        v_te_placa_video_desc := Trim(v_DEVICES.Devices[i].FriendlyName);

                      Log_Debug('DISPLAY Informations - OK!');
                    End;

                  i := i+1;
                End;
            except log_diario('Problema em DEVICES Details!');
            end;
            v_DEVICES.Free;


            // Memory informations
            Try
              Begin
                  v_MemoriaRAM.dwLength := SizeOf(v_MemoriaRAM);
                  GlobalMemoryStatus(v_MemoriaRAM);
                  v_qt_mem_ram := v_MemoriaRAM.dwTotalPhys div 1024000;
                  Log_Debug('MEMORY Informations - OK!');
              End;
            except log_diario('Problema em MEMORY Details!');
            end;

            Try
              Begin
                v_SMBIOS := TMiTeC_SMBIOS.Create(nil);
                v_SMBIOS.RefreshData;
                if v_SMBIOS.MemoryModuleCount > -1 then
                  Begin
                    for i:=0 to v_SMBIOS.MemoryModuleCount-1 do begin
                      if (v_SMBIOS.MemoryModule[i].Size <> 0) then begin
                         v_te_mem_ram_tipo := v_SMBIOS.GetMemoryTypeStr(v_SMBIOS.MemoryModule[i].Types);
                         if (v_te_mem_ram_desc <> '') then
                            v_te_mem_ram_desc := v_te_mem_ram_desc + ' - ';
                         v_te_mem_ram_desc := v_te_mem_ram_desc + 'Slot '+ inttostr(i) + ': '
                                                                + v_SMBIOS.MemoryDevice[i].Manufacturer + ' '
                                                                + inttostr(v_SMBIOS.MemoryModule[i].Size) + 'Mb '
                                                                + '(' + v_te_mem_ram_tipo +')';
                      end;
                    end;
                  end;

                if (trim(v_te_placa_mae_fabricante)='') then begin
                   v_te_placa_mae_fabricante := v_SMBIOS.MainBoardManufacturer;
                   if (trim(v_te_placa_mae_fabricante)='') then
                      v_te_placa_mae_fabricante := v_SMBIOS.SystemManufacturer;
                end;

                if (trim(v_te_placa_mae_desc)='') then begin
                   v_te_placa_mae_desc := v_SMBIOS.MainBoardModel;
                   if (trim(v_te_placa_mae_desc)='')       then
                      v_te_placa_mae_desc := v_SMBIOS.SystemModel;
                end;


                v_te_bios_data            := v_SMBIOS.BIOSDate;
                v_te_bios_fabricante      := v_SMBIOS.BIOSVendor;
                v_te_bios_desc            := v_SMBIOS.BIOSVersion;

                v_SMBIOS.Free;
                Log_Debug('SMBIOS Informations - OK!');
              End;
            Except log_diario('Problema em SMBIOS Details!');
            End;

            // Display informations
            Try
              Begin
                v_DISPLAY := TMiTeC_Display.Create(nil);
                v_DISPLAY.RefreshData;

                if (trim(v_te_placa_video_desc)='') then v_te_placa_video_desc := v_DISPLAY.Adapter;
                v_qt_placa_video_cores     := IntToStr(v_DISPLAY.ColorDepth);
                v_qt_placa_video_mem       := IntToStr(v_DISPLAY.Memory div 1048576 ) + 'Mb';
                v_te_placa_video_resolucao := IntToStr(v_DISPLAY.HorzRes) + 'x' + IntToStr(v_DISPLAY.VertRes);

                v_DISPLAY.Free;
                Log_Debug('VIDEO Informations - OK!');
              End;
            Except log_diario('Problema em VIDEO Details!');
            End;

            // Network informations
            Try
              Begin
                v_TCP := TMiTeC_TCPIP.Create(nil);
                v_TCP.RefreshData;

                v_mensagem := 'Ativando TCP Getinfo...';

                i := 0;
                v_Macs_Invalidos := trim(GetValorDatMemoria('TCPIP.TE_ENDERECOS_MAC_INVALIDOS',v_tstrCipherOpened));

                // Avalia quantidade de placas de rede e obtem respectivos dados
                if v_TCP.AdapterCount>0 then
                  for i:=0 to v_TCP.AdapterCount-1 do begin
                    v_te_placa_rede_desc      := v_TCP.Adapter[i].Name;
                    v_PhysicalAddress         := v_TCP.Adapter[i].Address;
                    v_IPAddress               := v_TCP.Adapter[i].IPAddress[0];
                    v_IPMask                  := v_TCP.Adapter[i].IPAddressMask[0];
                    v_Gateway_IPAddress       := v_TCP.Adapter[i].Gateway_IPAddress[0];
                    v_DHCP_IPAddress          := v_TCP.Adapter[i].DHCP_IPAddress[0];
                    v_PrimaryWINS_IPAddress   := v_TCP.Adapter[i].PrimaryWINS_IPAddress[0];
                    v_SecondaryWINS_IPAddress := v_TCP.Adapter[i].SecondaryWINS_IPAddress[0];

                    if (trim( v_te_placa_rede_desc    +
                              v_PhysicalAddress       +
                              v_IPAddress             +
                              v_IPMask                +
                              v_Gateway_IPAddress     +
                              v_DHCP_IPAddress        +
                              v_PrimaryWINS_IPAddress +
                              v_SecondaryWINS_IPAddress)<>'') then
                      Begin
                        v_tstrTCPIP.Add('te_placa_rede_desc###' + v_te_placa_rede_desc     +'#FIELD#'+
                                        'te_node_address###'    + v_PhysicalAddress        +'#FIELD#'+
                                        'te_ip###'              + v_IPAddress              +'#FIELD#'+
                                        'te_mascara###'         + v_IPMask                 +'#FIELD#'+
                                        'te_gateway###'         + v_Gateway_IPAddress      +'#FIELD#'+
                                        'te_serv_dhcp###'       + v_DHCP_IPAddress         +'#FIELD#'+
                                        'te_wins_primario###'   + v_PrimaryWINS_IPAddress  +'#FIELD#'+
                                        'te_wins_secundario###' + v_SecondaryWINS_IPAddress);
                        Log_Debug('Adicionando a tstrTCPIP: "'+v_tstrTCPIP[v_tstrTCPIP.count-1]+'"');
                      End
                  End;
                v_TCP.Free;
                Log_Debug('TCPIP Informations - OK!');
              End;
            Except log_diario('Problema em TCP Details!');
            End;

            // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
            // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
            if v_Debugs then
              Begin
                i := 0;
                while i < v_Report.count-1 do
                  Begin
                    Grava_Debugs(v_report[i]);
                    i := i + 1;
                  End;
                v_report.Free;
              End;
        End;
     Except
     End;

     // Crio as Tripas dos múltiplos ítens...
     v_Tripa_CPU := '';
     v_tstrCPU.Sort;
     Log_DEBUG('Tamanho de v_tstrCPU 2: '+intToStr(v_tstrCPU.Count));
     i := 0;
     while (i < v_tstrCPU.Count) do
        Begin
          v_Tripa_CPU := v_Tripa_CPU + iif(v_Tripa_CPU = '','','#CPU#');
          v_Tripa_CPU := v_Tripa_CPU + v_tstrCPU[i];
          i := i + 1;
        End;

     v_Tripa_CDROM := '';
     v_tstrCDROM.Sort;
     Log_DEBUG('Tamanho de v_tstrCDROM: '+intToStr(v_tstrCDROM.Count));
     i := 0;
     while (i < v_tstrCDROM.Count) do
        Begin
          v_Tripa_CDROM := v_Tripa_CDROM + iif(v_Tripa_CDROM = '','','#CDROM#');
          v_Tripa_CDROM := v_Tripa_CDROM + v_tstrCDROM[i];
          i := i + 1;
        End;

     v_Tripa_TCPIP := '';
     v_tstrTCPIP.Sort;
     Log_DEBUG('Tamanho de v_tstrTCPIP: '+intToStr(v_tstrTCPIP.Count));
     i := 0;
     while (i < v_tstrTCPIP.Count) do
        Begin
          v_Tripa_TCPIP := v_Tripa_TCPIP + iif(v_Tripa_TCPIP = '','','#TCPIP#');
          v_Tripa_TCPIP := v_Tripa_TCPIP + v_tstrTCPIP[i];
          i := i + 1;
        End;

     Try
     // Monto a string que será comparada com o valor armazenado no registro.
      v_mensagem := 'Montando pacote para comparações...';
     UVC := oCacic.trimEspacosExcedentes(v_Tripa_TCPIP     + ';' +
                                v_Tripa_CPU                + ';' +
                                v_Tripa_CDROM              + ';' +
                                v_te_mem_ram_desc          + ';' +
                                IntToStr(v_qt_mem_ram)     + ';' +
                                v_te_bios_desc             + ';' +
                                v_te_bios_data             + ';' +
                                v_te_bios_fabricante       + ';' +
                                v_te_placa_mae_fabricante  + ';' +
                                v_te_placa_mae_desc        + ';' +
                                v_te_placa_video_desc      + ';' +
                                v_te_placa_video_resolucao + ';' +
                                v_qt_placa_video_cores     + ';' +
                                v_qt_placa_video_mem       + ';' +
                                v_te_placa_som_desc        + ';' +
                                v_te_teclado_desc          + ';' +
                                v_te_modem_desc            + ';' +
                                v_te_mouse_desc);
     Except log_diario('Problema em comparação de envio!');
     End;

     // Obtenho do registro o valor que foi previamente armazenado
     ValorChaveRegistro := Trim(GetValorDatMemoria('Coletas.Hardware',v_tstrCipherOpened));

     SetValorDatMemoria('Col_Hard.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

     // Se essas informações forem diferentes significa que houve alguma alteração
     // na configuração de hardware. Nesse caso, gravo as informações no BD Central
     // e, se não houver problemas durante esse procedimento, atualizo as
     // informações no registro.
     If (GetValorDatMemoria('Configs.IN_COLETA_FORCADA_HARD',v_tstrCipherOpened)='S') or
         (oCacic.trimEspacosExcedentes(UVC) <> oCacic.trimEspacosExcedentes(ValorChaveRegistro)) Then
      Begin
        Try
        //Envio via rede para ao Agente Gerente, para gravação no BD.
        SetValorDatMemoria('Col_Hard.te_Tripa_TCPIP'          , oCacic.trimEspacosExcedentes( v_Tripa_TCPIP              ), v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_Tripa_CPU'            , oCacic.trimEspacosExcedentes( v_Tripa_CPU                ), v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_Tripa_CDROM'          , oCacic.trimEspacosExcedentes( v_Tripa_CDROM              ), v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_placa_mae_fabricante' , oCacic.trimEspacosExcedentes( v_te_placa_mae_fabricante  ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_placa_mae_desc'       , oCacic.trimEspacosExcedentes( v_te_placa_mae_desc        ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.qt_mem_ram'              , oCacic.trimEspacosExcedentes( IntToStr(v_qt_mem_ram)     ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_mem_ram_desc'         , oCacic.trimEspacosExcedentes( v_te_mem_ram_desc          ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_bios_desc'            , oCacic.trimEspacosExcedentes( v_te_bios_desc             ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_bios_data'            , oCacic.trimEspacosExcedentes( v_te_bios_data             ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_bios_fabricante'      , oCacic.trimEspacosExcedentes( v_te_bios_fabricante       ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.qt_placa_video_cores'    , oCacic.trimEspacosExcedentes( v_qt_placa_video_cores     ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_placa_video_desc'     , oCacic.trimEspacosExcedentes( v_te_placa_video_desc      ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.qt_placa_video_mem'      , oCacic.trimEspacosExcedentes( v_qt_placa_video_mem       ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_placa_video_resolucao', oCacic.trimEspacosExcedentes( v_te_placa_video_resolucao ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_placa_som_desc'       , oCacic.trimEspacosExcedentes( v_te_placa_som_desc        ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_teclado_desc'         , oCacic.trimEspacosExcedentes( v_te_teclado_desc          ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_mouse_desc'           , oCacic.trimEspacosExcedentes( v_te_mouse_desc            ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.te_modem_desc'           , oCacic.trimEspacosExcedentes( v_te_modem_desc            ) , v_tstrCipherOpened1);
        SetValorDatMemoria('Col_Hard.UVC'                     , oCacic.trimEspacosExcedentes( UVC                        ) , v_tstrCipherOpened1);
        CipherClose(p_path_cacic + 'temp\col_hard.dat', v_tstrCipherOpened1);
        Except log_diario('Problema em gravação de dados no DAT!');
        End;
      end
   else
    Begin
      SetValorDatMemoria('Col_Hard.nada','nada', v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Hard.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);
      CipherClose(p_path_cacic + 'temp\col_hard.dat', v_tstrCipherOpened1);
    End;
  Except
    Begin
      SetValorDatMemoria('Col_Hard.nada','nada', v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Hard.Fim'               , '99999999', v_tstrCipherOpened1);
      CipherClose(p_path_cacic + 'temp\col_hard.dat', v_tstrCipherOpened1);
      log_diario('Problema na execução => ' + v_mensagem);
    End;
  End;
  oCacic.Free();
end;

const
  CACIC_APP_NAME = 'col_hard';

var tstrTripa1 : TStrings;
    intAux     : integer;
    oCacic : TCACIC;

begin
   oCacic := TCACIC.Create();

   if( not oCacic.isAppRunning( CACIC_APP_NAME ) )  then
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
             intAux :=0;
             While intAux < tstrTripa1.Count -1 do
               begin
                 p_path_cacic := p_path_cacic + tstrTripa1[intAux] + '\';
                 intAux := intAux + 1
               end;

             // A chave AES foi obtida no parâmetro p_CipherKey. Recomenda-se que cada empresa altere a sua chave.
             v_IV                := 'abcdefghijklmnop';
             v_DatFileName       := p_path_cacic + 'cacic2.dat';
             v_tstrCipherOpened  := TStrings.Create;
             v_tstrCipherOpened  := CipherOpen(v_DatFileName);

             v_tstrCipherOpened1 := TStrings.Create;
             v_tstrCipherOpened1 := CipherOpen(p_path_cacic + 'temp\col_hard.dat');

             Try
                v_Debugs      := false;
                if DirectoryExists(p_path_cacic + 'Temp\Debugs') then
                  Begin
                    if (FormatDateTime('ddmmyyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs')) = FormatDateTime('ddmmyyyy', date)) then
                      Begin
                        v_Debugs := true;
                        log_diario('Pasta "' + p_path_cacic + 'Temp\Debugs" com data '+FormatDateTime('dd-mm-yyyy', GetFolderDate(p_path_cacic + 'Temp\Debugs'))+' encontrada. DEBUG ativado.');
                      End;
                  End;
                Executa_Col_Hard;
             Except
                SetValorDatMemoria('Col_Hard.nada', 'nada', v_tstrCipherOpened1);
                CipherClose(p_path_cacic + 'temp\col_hard.dat', v_tstrCipherOpened1);
             End;
          End;
    End;

   oCacic.Free();

end.
