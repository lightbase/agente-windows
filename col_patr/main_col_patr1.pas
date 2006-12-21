unit main_col_patr1;

interface

uses
  Windows, Forms, IniFiles, SysUtils, Classes, Registry;

type
  Tfrm_col_patr = class(TForm)
    procedure Executa_Col_comp;
    procedure Log_Historico(strMsg : String);
    Function Crip(PNome: String): String;
    Function DesCrip(PNome: String): String;
    function SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
    function GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
    function GetValorChaveRegEdit(Chave: String): Variant;
    function GetRootKey(strRootKey: String): HKEY;
    Function Explode(Texto, Separador : String) : TStrings;
    Function RemoveCaracteresEspeciais(Texto : String) : String;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_col_patr: Tfrm_col_patr;

uses frmPatrimonio;

implementation

{$R *.dfm}

//Para gravar no Arquivo INI...
function Tfrm_col_patr.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
    Reg_Ini.WriteString(frm_col_patr.Crip(p_Secao), frm_col_patr.Crip(p_Chave), frm_col_patr.Crip(p_Valor));
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
function Tfrm_col_patr.GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
var Reg_Ini: TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
    Result  := frm_col_patr.DesCrip(Reg_Ini.ReadString(frm_col_patr.Crip(p_Secao), frm_col_patr.Crip(p_Chave), ''));
    Reg_Ini.Free;
end;

Function Tfrm_col_patr.Explode(Texto, Separador : String) : TStrings;
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
//Não estava sendo liberado
//    ListaAuxUTILS.Free;
//Ao ativar esta liberação tomei uma baita surra!!!!  11/05/2004 - 20:30h - Uma noite muito escura!  :)  Anderson Peterle
end;

function Tfrm_col_patr.GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function Tfrm_col_patr.RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;

function Tfrm_col_patr.GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := frm_col_patr.Explode(Chave, '\');

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
               Result := frm_col_patr.RemoveCaracteresEspeciais(s);
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
Function Tfrm_col_patr.Crip(PNome: String): String;
Var
  TamI, TamF: Integer;
  SenA, SenM, SenD: String;
Begin
    SenA := Trim(PNome);
    SenM := '';
    SenD := '';
    TamF := Length(SenA);
    For TamI := TamF Downto 1 do
        Begin
            SenM := SenM + Copy(SenA,TamI,1);
        End;
    SenD := Chr(TamF+95)+Copy(SenM,1,1)+Copy(SenA,1,1)+Copy(SenM,2,TamF-2)+Chr(75+TamF);
    Result := SenD;
End;

Function Tfrm_col_patr.DesCrip(PNome: String): String;
Var
  TamI, TamF: Integer;
  SenA, SenM, SenD: String;
Begin
    SenA := Trim(PNome);
    SenM := '';
    SenD := '';
    TamF := Length(SenA) - 2;
    SenA := Copy(SenA,2,TamF);
    SenM := Copy(SenA,1,1)+Copy(SenA,3,TamF)+Copy(SenA,2,1);
    For TamI := TamF Downto 1 do
        Begin
            SenD := SenD + Copy(SenM,TamI,1);
        End;
    Result := SenD;
End;

procedure Tfrm_col_patr.Log_Historico(strMsg : String);
var
    HistoricoLog : TextFile;
    strDataArqLocal, strDataAtual : string;
begin
   try
       FileSetAttr ('..\cacic2.log',0); // Retira os atributos do arquivo para evitar o erro FILE ACCESS DENIED em máquinas 2000
       AssignFile(HistoricoLog,'..\cacic2.log'); {Associa o arquivo a uma variável do tipo TextFile}
       {$IOChecks off}
       Reset(HistoricoLog); {Abre o arquivo texto}
       {$IOChecks on}
       if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (HistoricoLog);
            Append(HistoricoLog);
            Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Iniciando o Log do CACIC <=======================');
          end;
       DateTimeToString(strDataArqLocal, 'yyyymmdd', FileDateToDateTime(Fileage('..\cacic2.log')));
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
//       FileSetAttr (ExtractFilePath(Application.Exename) + '\cacic2.log',6); // Muda o atributo para arquivo de SISTEMA e OCULTO

   except
     Log_Historico('Erro na gravação do log!');
   end;
end;
end.


