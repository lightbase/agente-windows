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

unit main_moni;

interface

uses Windows, Forms, sysutils, inifiles, Registry, Classes, PJVersionInfo;

var  p_path_cacic, p_path_cacic_ini, v_Res_Search, v_Drive, v_File : string;

type
  Tfrm_col_moni = class(TForm)
    PJVersionInfo1: TPJVersionInfo;
    procedure Executa_Col_moni;
    procedure Log_Historico(strMsg : String);
    Function Crip(PNome: String): String;
    Function DesCrip(PNome: String): String;
    function SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
    function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    function GetValorChaveRegEdit(Chave: String): Variant;
    function GetRootKey(strRootKey: String): HKEY;
    Function Explode(Texto, Separador : String) : TStrings;
    Function RemoveCaracteresEspeciais(Texto : String) : String;
    function GetVersionInfo(p_File: string):string;
    function VerFmt(const MS, LS: DWORD): string;
    function LetrasDrives : string;
    function LastPos(SubStr, S: string): Integer;
    function SearchFile(p_Drive,p_File:string) : boolean;
    procedure GetSubDirs(Folder:string; sList:TStringList);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_col_moni: Tfrm_col_moni;

implementation

{$R *.dfm}
function Tfrm_col_moni.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

{ TMainForm }

function Tfrm_col_moni.GetVersionInfo(p_File: string):string;
begin
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
end;

// Baixada de http://www.infoeng.hpg.ig.com.br/borland_delphi_dicas_2.htm
function Tfrm_col_moni.LetrasDrives: string;
var
Drives: DWord;
I, Tipo: byte;
v_Unidade : string;
begin
Result := '';
Drives := GetLogicalDrives;
if Drives <> 0 then
for I := 65 to 90 do
  if ((Drives shl (31 - (I - 65))) shr 31) = 1 then
    Begin
      v_Unidade := Char(I) + ':\';
      Tipo := GetDriveType(PChar(v_Unidade));
      case Tipo of
        DRIVE_FIXED: Result := Result + Char(I);
      end;
    End;
end;

// By Muad Dib 2003
// at http://www.planet-source-code.com.
// Excelente!!!
function Tfrm_col_moni.SearchFile(p_Drive,p_File:string) : boolean;
var sr:TSearchRec;
    sDirList:TStringList;
    i:integer;
begin
   Result := false;
   v_Res_Search := '';
   if FindFirst(p_Drive+p_File,faAnyFile,sr) = 0 then
    Begin
      v_Res_Search := p_Drive+p_File;
      Result := true;
    End
   else
    Begin
     repeat
     until FindNext(sr)<>0;
        FindClose(sr);
        sDirList:= TStringList.Create;
        try
         GetSubDirs(p_Drive,sDirList);
         for i:=0 to sDirList.Count-1 do
            if (sDirList[i]<>'.') and (sDirList[i]<>'..') then
             begin
              Application.ProcessMessages;
              if (SearchFile(IncludeTrailingPathDelimiter(p_Drive+sDirList[i]),p_File)) then
                Begin
                  Result := true;
                  Break;
                End;
             end;
         finally
         sDirList.Free;
    End;
   end;
end;

procedure Tfrm_col_moni.GetSubDirs(Folder:string; sList:TStringList);
 var
  sr:TSearchRec;
begin
  if FindFirst(Folder+'*.*',faDirectory,sr)=0 then
   try
    repeat
      if(sr.Attr and faDirectory)=faDirectory then
       sList.Add(sr.Name);
    until FindNext(sr)<>0;
   finally
    FindClose(sr);
   end;
end;


//Para gravar no Arquivo INI...
function Tfrm_col_moni.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
//    Reg_Ini.WriteString(frm_col_moni.Crip(p_Secao), frm_col_moni.Crip(p_Chave), frm_col_moni.Crip(p_Valor));
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function Tfrm_col_moni.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
    v_SectionName := '[' + p_SectionName + ']';
    v_Size_Section := strLen(PChar(v_SectionName));
    v_KeyName := p_KeyName + '=';
    v_Size_Key     := strLen(PChar(v_KeyName));
    FileText := TStringList.Create;
    try
      FileText.LoadFromFile(p_IniFileName);
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

Function Tfrm_col_moni.Explode(Texto, Separador : String) : TStrings;
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

function Tfrm_col_moni.GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function Tfrm_col_moni.RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;

function Tfrm_col_moni.GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := frm_col_moni.Explode(Chave, '\');

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
               Result := frm_col_moni.RemoveCaracteresEspeciais(s);
             end
        end;
    finally
    RegEditGet.CloseKey;
    RegEditGet.Free;
    ListaAuxGet.Free;

    end;
end;


// Simples rotinas de Criptografação e Descriptografação
// Baixadas de http://www.costaweb.com.br/forum/delphi/474.shtml
Function Tfrm_col_moni.Crip(PNome: String): String;
Var
  TamI, TamF: Integer;
  SenA, SenM, SenD: String;
Begin
    SenA := Trim(PNome);
    TamF := Length(SenA);
    if (TamF > 1) then
      begin
        SenM := '';
        SenD := '';
        For TamI := TamF Downto 1 do
            Begin
                SenM := SenM + Copy(SenA,TamI,1);
            End;
        SenD := Chr(TamF+95)+Copy(SenM,1,1)+Copy(SenA,1,1)+Copy(SenM,2,TamF-2)+Chr(75+TamF);
      end
    else SenD := SenA;
    Result := SenD;
End;

Function Tfrm_col_moni.DesCrip(PNome: String): String;
Var
  TamI, TamF: Integer;
  SenA, SenM, SenD: String;
Begin
    SenA := Trim(PNome);
    TamF := Length(SenA) - 2;
    if (TamF > 1) then
      begin
        SenM := '';
        SenD := '';
        SenA := Copy(SenA,2,TamF);
        SenM := Copy(SenA,1,1)+Copy(SenA,3,TamF)+Copy(SenA,2,1);
        For TamI := TamF Downto 1 do
            Begin
                SenD := SenD + Copy(SenM,TamI,1);
            End;
      end
    else SenD := SenA;
    Result := SenD;
End;

procedure Tfrm_col_moni.Log_Historico(strMsg : String);
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
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + strMsg); {Grava a string Texto no arquivo texto}
       CloseFile(HistoricoLog); {Fecha o arquivo texto}
   except
     Log_Historico('Erro na gravação do log!');
   end;
end;

function Tfrm_col_moni.LastPos(SubStr, S: string): Integer;
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


procedure Tfrm_col_moni.Executa_Col_moni;
var tstrTripa2, tstrTripa3, v_array1, v_array2, v_array3, v_array4 : TStrings;
    strAux, strAux1, strAux3, strAux4, strTripa, ValorChavePerfis, ValorChaveColetado, v_LetrasDrives, v_Data : String;
    intAux4, v1, v3, v_achei : Integer;

begin
  Try
   // Verifica se deverá ser realizada a coleta de informações de sistemas monitorados neste
   // computador, perguntando ao agente gerente.
   Log_Historico('* Coletando informações de Sistemas Monitorados.');
   ShortDateFormat := 'dd/mm/yyyy';
   intAux4          := 1;
   strAux3          := '';
   ValorChavePerfis := '*';
   v_LetrasDrives   := LetrasDrives;

   while ValorChavePerfis <> '' do
      begin
         strAux3 := 'SIS' + trim(inttostr(intAux4));
         strTripa := ''; // Conterá as informações a serem enviadas ao Gerente.
         // Obtenho do registro o valor que foi previamente armazenado
         ValorChavePerfis := Trim(GetValorChaveRegIni('Coleta',strAux3, p_path_cacic + 'cacic2.ini'));

         if (ValorChavePerfis <> '') then
           Begin
               //Atenção, OS ELEMENTOS DEVEM ESTAR DE ACORDO COM A ORDEM QUE SÃO TRATADOS NO MÓDULO GERENTE.
               tstrTripa2  := Explode(ValorChavePerfis,',');
               if (strAux <> '') then strAux := strAux + '#';
               strAux := strAux + trim(tstrTripa2[0]) + ',';

               //Coleta de Informação de Licença
               if (trim(tstrTripa2[2])='0') then //Vazio
                 Begin
                    strAux := strAux + ',';
                 End;

               if (trim(tstrTripa2[2])='1') then //Caminho\Chave\Valor em Registry
                 Begin
                    strAux4 := '';
                    Try
                      strAux4 := Trim(GetValorChaveRegEdit(trim(tstrTripa2[3])));
                    Except
                    End;
                    if (strAux4 = '') then strAux4 := '?';
                    strAux  := strAux + strAux4 + ',';
                 End;

               if (trim(tstrTripa2[2])='2') then //Nome/Seção/Chave de Arquivo INI
                 Begin
                    Try
                      if (LastPos('/',trim(tstrTripa2[3]))>0) then
                        Begin
                          tstrTripa3  := Explode(trim(tstrTripa2[3]),'/');
                          //
                          for v1:=1 to length(v_LetrasDrives) do
                            Begin
                              v_File := trim(tstrTripa3[0]);
                              if (LastPos(':\',v_File)>0) then
                                Begin
                                  v_Drive := Copy(v_File,1,3);
                                  v_File  := Copy(v_File,4,Length(v_File));
                                End
                              else
                                Begin
                                  v_Drive := v_LetrasDrives[v1] + ':';
                                  if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                                  v_File  := Copy(v_File,1,Length(v_File));
                                End;

                              strAux1 := ExtractShortPathName(v_Drive + v_File);
                              if (strAux1 = '') then
                                begin
                                  if (SearchFile(v_Drive,v_File)) then
                                    Begin
                                      strAux1 := v_Res_Search;
                                      break;
                                    End;
                                end
                              else break;
                            End;


                          //
                          strAux4 := Trim(GetValorChaveRegIni(tstrTripa3[1],tstrTripa3[2],strAux1));
                          if (strAux4 = '') then strAux4 := '?';
                          strAux := strAux + strAux4 + ',';
                        End;

                      if (LastPos('/',trim(tstrTripa2[3]))=0) then
                        Begin
                          strAux := strAux + 'Parâm.Lic.Incorreto,';
                        End
                    Except
                        strAux := strAux + 'Parâm.Lic.Incorreto,';
                    End;
                 End;

               //Coleta de Informação de Instalação
               if (trim(tstrTripa2[5])='0') then //Vazio
                 Begin
                    strAux := strAux + ',';
                 End;

               if (trim(tstrTripa2[5])='1') or (trim(tstrTripa2[5]) = '2') then //Nome de Executável OU Nome de Arquivo de Configuração (CADPF!!!)
                 Begin
                  strAux1 := '';
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                    v_File := trim(tstrTripa2[6]);
                    if (LastPos(':\',v_File)>0) then
                      Begin
                        v_Drive := Copy(v_File,1,3);
                        v_File  := Copy(v_File,4,Length(v_File));
                      End
                    else
                      Begin
                        v_Drive := v_LetrasDrives[v1] + ':';
                        if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                        v_File  := Copy(v_File,1,Length(v_File));
                      End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;

                    End;

                  if (strAux1 <> '') then strAux := strAux + 'S,';
                  if (strAux1 = '')  then strAux := strAux + 'N,';
                  strAux1 := '';
                 End;

               if (trim(tstrTripa2[5])='3') then //Caminho\Chave\Valor em Registry
                 Begin
                  strAux1 := '';
                  Try
                    strAux1 := Trim(GetValorChaveRegEdit(trim(tstrTripa2[5])));
                  Except
                  End;
                  if (strAux1 <> '') then strAux  := strAux + 'S,';
                  if (strAux1 = '') then strAux := strAux + 'N,';
                  strAux1 := '';
                 End;

               //Coleta de Informação de Versão
               if (trim(tstrTripa2[7])='0') then //Vazio
                 Begin
                    strAux := strAux + ',';
                 End;

               if (trim(tstrTripa2[7])='1') then //Data de Arquivo
                 Begin
                  strAux1 := '';
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                    v_File := trim(tstrTripa2[8]);
                    if (LastPos(':\',v_File)>0) then
                      Begin
                        v_Drive := Copy(v_File,1,3);
                        v_File  := Copy(v_File,4,Length(v_File));
                      End
                    else
                      Begin
                        v_Drive := v_LetrasDrives[v1] + ':';
                        if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                        v_File  := Copy(v_File,1,Length(v_File));
                      End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;
                    End;
                  if (strAux1 <> '') then
                    Begin
                      v_Data := StringReplace(DateToStr(FileDateToDateTime(FileAge(strAux1))),'.','/',[rfReplaceAll]);
                      v_Data := StringReplace(v_Data,'-','/',[rfReplaceAll]);
                      strAux := strAux + v_Data + ',';
                      v_Data := '';
                    End;
                  if (strAux1 = '') then strAux := strAux + '?,';
                  strAux1 := '';
                 End;

               if (trim(tstrTripa2[7])='2') then //Caminho\Chave\Valor em Registry
                 Begin
                  strAux1 := '';
                  Try
                    strAux1 := Trim(GetValorChaveRegEdit(trim(tstrTripa2[8])));
                  Except
                  End;
                  if (strAux1 <> '') then strAux := strAux + strAux1 + ',';
                  if (strAux1 = '') then strAux := strAux + '?,';
                  strAux1 := '';
                 End;

               if (trim(tstrTripa2[7])='3') then //Nome/Seção/Chave de Arquivo INI
                 Begin
                    Try
                      if (LastPos('/',trim(tstrTripa2[8]))>0) then
                        Begin
                          tstrTripa3  := Explode(trim(tstrTripa2[8]),'/');
                          //
                          for v1:=1 to length(v_LetrasDrives) do
                            Begin
                              v_File := trim(tstrTripa3[0]);
                              if (LastPos(':\',v_File)>0) then
                                Begin
                                  v_Drive := Copy(v_File,1,3);
                                  v_File  := Copy(v_File,4,Length(v_File));
                                End
                              else
                                Begin
                                  v_Drive := v_LetrasDrives[v1] + ':';
                                  if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                                  v_File  := Copy(v_File,1,Length(v_File));
                                End;


                              strAux1 := ExtractShortPathName(v_Drive + v_File);
                              if (strAux1 = '') then
                                begin
                                  if (SearchFile(v_Drive,v_File)) then
                                    Begin
                                      strAux1 := v_Res_Search;
                                      break;
                                    End;
                                end
                              else break;
                            End;

                          //
                          strAux4 := Trim(GetValorChaveRegIni(tstrTripa3[1],tstrTripa3[2],strAux1));
                          if (strAux4 = '') then strAux4 := '?';
                          strAux := strAux + strAux4 + ',';
                        End
                      else
                        Begin
                          strAux := strAux + 'Parâm.Versao Incorreto,';
                        End;
                    Except
                    End;
                 End;

               //Coleta de Informação de Engine
               if (trim(tstrTripa2[9])='.') then //Vazio
                 Begin
                    strAux := strAux + ',';
                 End;
               //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
               if (trim(tstrTripa2[9])<>'.') then //Arquivo para Versão de Engine
                 Begin
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                      v_File := trim(tstrTripa2[9]);
                      if (LastPos(':\',v_File)>0) then
                        Begin
                          v_Drive := Copy(v_File,1,3);
                          v_File  := Copy(v_File,4,Length(v_File));
                        End
                      else
                        Begin
                          v_Drive := v_LetrasDrives[v1] + ':';
                          if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                          v_File  := Copy(v_File,1,Length(v_File));
                        End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;
                    End;
                  if (strAux1 <> '') then
                    Begin
                      tstrTripa3 := Explode(getVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                      strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                    End;
                 End;

               //Coleta de Informação de Pattern
               //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
               strAux1 := '';
               if (trim(tstrTripa2[10])<>'.') then //Arquivo para Versão de Pattern
                 Begin
                    for v1:=1 to length(v_LetrasDrives) do
                      Begin
                      v_File := trim(tstrTripa2[10]);
                      if (LastPos(':\',v_File)>0) then
                        Begin
                          v_Drive := Copy(v_File,1,3);
                          v_File  := Copy(v_File,4,Length(v_File));
                        End
                      else
                        Begin
                          v_Drive := v_LetrasDrives[v1] + ':';
                          if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                          v_File  := Copy(v_File,1,Length(v_File));
                        End;

                        strAux1 := ExtractShortPathName(v_Drive + v_File);
                        if (strAux1 = '') then
                          begin
                          if (SearchFile(v_Drive, v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;

                      End;
                 End;
                 if (strAux1 <> '') then
                    Begin
                      tstrTripa3 := Explode(getVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                      strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                    End;
                 if (strAux1 = '') then strAux := strAux + ',';
                 strAux1 := '';
           End;
           intAux4 := intAux4 + 1;
      End;
      ValorChaveColetado := Trim(GetValorChaveRegIni('Coleta','Sistemas_Monitorados', p_path_cacic + 'cacic2.ini'));
      If (GetValorChaveRegIni('Configs','IN_COLETA_FORCADA_MONI',p_path_cacic_ini)='S') or (trim(strAux) <> trim(ValorChaveColetado)) Then
        Begin
          if (trim(ValorChaveColetado) <> '') then
            begin
              v_array1  :=  Explode(strAux, '#');
              strAux    :=  '';
              v_array3  :=  Explode(ValorChaveColetado, '#');
              for v1 := 0 to (v_array1.count)-1 do
                Begin
                  v_array2  :=  Explode(v_array1[v1], ',');
                  v_achei   :=  0;
                  for v3 := 0 to (v_array3.count)-1 do
                    Begin
                      v_array4  :=  Explode(v_array3[v3], ',');
                      if (v_array4=v_array2) then v_achei := 1;
                    End;
                  if (v_achei = 0) then
                    Begin
                      if (strAUX <> '') then strAUX :=  strAUX + '#';
                      strAUX  :=  strAUX + v_array1[v1];
                    End;
                End;
              end;
          frm_col_moni.SetValorChaveRegIni('Col_Moni','Sistemas_Monitorados', strAux,frm_col_moni.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_moni.ini');
        end
      else frm_col_moni.SetValorChaveRegIni('Col_Moni','nada', 'nada',frm_col_moni.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_moni.ini');
      application.Terminate;
  Except
    Begin
      frm_col_moni.SetValorChaveRegIni('Col_Moni','nada', 'nada',frm_col_moni.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_moni.ini');
      application.Terminate;
    End;
  End;
END;

procedure Tfrm_col_moni.FormCreate(Sender: TObject);
var tstrTripa1 : TStrings;
    intAux     : integer;
begin

     //Pegarei o nível anterior do diretório, que deve ser, por exemplo \Cacic, para leitura do cacic2.ini
     tstrTripa1 := explode(ExtractFilePath(Application.Exename),'\');
     p_path_cacic := '';
     For intAux := 0 to tstrTripa1.Count -2 do
       begin
         p_path_cacic := p_path_cacic + tstrTripa1[intAux] + '\';
       end;
     p_path_cacic_ini := p_path_cacic + 'cacic2.ini';
     Application.ShowMainForm := false;

     Try
       Executa_Col_moni;
     Except
       frm_col_moni.SetValorChaveRegIni('Col_Moni','nada', 'nada',frm_col_moni.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_moni.ini');
       application.Terminate;
     End;
end;
end.

