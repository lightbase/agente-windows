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

unit main_comp;

interface

uses Windows, Forms, IniFiles, SysUtils, Classes, Registry;
var  p_path_cacic, p_path_cacic_ini : string;
type
  Tfrmcol_comp = class(TForm)
    procedure Executa_Col_comp;
    procedure Log_Historico(strMsg : String);
    Function Crip(PNome: String): String;
    Function DesCrip(PNome: String): String;
    function SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
//    function GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
    function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    function GetValorChaveRegEdit(Chave: String): Variant;
    function GetRootKey(strRootKey: String): HKEY;
    Function Explode(Texto, Separador : String) : TStrings;
    Function RemoveCaracteresEspeciais(Texto : String) : String;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmcol_comp: Tfrmcol_comp;

implementation

{$R *.dfm}

//Para gravar no Arquivo INI...
function Tfrmcol_comp.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
//    Reg_Ini.WriteString(frmcol_comp.Crip(p_Secao), frmcol_comp.Crip(p_Chave), frmcol_comp.Crip(p_Valor));
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
//function Tfrmcol_comp.GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
//var Reg_Ini: TIniFile;
//begin
//    FileSetAttr (p_Path,0);
//    Reg_Ini := TIniFile.Create(p_Path);
////    Result  := frmcol_comp.DesCrip(Reg_Ini.ReadString(frmcol_comp.Crip(p_Secao), frmcol_comp.Crip(p_Chave), ''));
//    Result  := Reg_Ini.ReadString(p_Secao, p_Chave, '');
//    Reg_Ini.Free;
//end;
//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function Tfrmcol_comp.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
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


Function Tfrmcol_comp.Explode(Texto, Separador : String) : TStrings;
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

function Tfrmcol_comp.GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function Tfrmcol_comp.RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;

function Tfrmcol_comp.GetValorChaveRegEdit(Chave: String): Variant;
var RegEditGet: TRegistry;
    RegDataType: TRegDataType;
    strRootKey, strKey, strValue, s: String;
    ListaAuxGet : TStrings;
    DataSize, Len, I : Integer;
begin
    try
    Result := '';
    ListaAuxGet := frmcol_comp.Explode(Chave, '\');

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
               Result := frmcol_comp.RemoveCaracteresEspeciais(s);
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
Function Tfrmcol_comp.Crip(PNome: String): String;
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

Function Tfrmcol_comp.DesCrip(PNome: String): String;
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

procedure Tfrmcol_comp.Log_Historico(strMsg : String);
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
//       FileSetAttr (ExtractFilePath(Application.Exename) + '\cacic2.log',6); // Muda o atributo para arquivo de SISTEMA e OCULTO

   except
     Log_Historico('Erro na gravação do log!');
   end;
end;



procedure Tfrmcol_comp.Executa_Col_comp;
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
    nm_compartilhamento := '';
    nm_dir_compart := '';
    cs_tipo_compart := ' ';
    cs_tipo_permissao := ' ';
    in_senha_leitura := '';
    in_senha_escrita := '';
    Log_Historico('* Coletando informações de Compartilhamentos.');
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
    ValorChaveRegistro := Trim(GetValorChaveRegIni('Coleta','Compartilhamentos',p_path_cacic_ini));
    // Se essas informações forem diferentes significa que houve alguma alteração
    // na configuração. Nesse caso, gravo as informações no BD Central e, se não houver
    // problemas durante esse procedimento, atualizo as informações no registro.
    If (GetValorChaveRegIni('Configs','IN_COLETA_FORCADA_COMP',p_path_cacic_ini)='S') or (strXML <> ValorChaveRegistro) Then
       Begin
         frmcol_comp.SetValorChaveRegIni('Col_Comp','Compartilhamentos', strXML, frmcol_comp.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_comp.ini');
       End
    else frmcol_comp.SetValorChaveRegIni('Col_Comp','nada', 'nada', frmcol_comp.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_comp.ini');
    application.Terminate;
  Except
    frmcol_comp.SetValorChaveRegIni('Col_Comp','nada', 'nada', frmcol_comp.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_comp.ini');
    application.Terminate;
  End;
end;

procedure Tfrmcol_comp.FormCreate(Sender: TObject);
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
    Executa_Col_comp;
  Except
    frmcol_comp.SetValorChaveRegIni('Col_Comp','nada', 'nada', frmcol_comp.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_comp.ini');
    application.Terminate;
  End;
end;

end.

