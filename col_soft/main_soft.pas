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

unit main_soft;

interface

uses Windows, IniFiles, Forms, Classes, SysUtils, Registry, MSI_GUI;
var  p_path_cacic, p_path_cacic_ini : string;

type
  Tfrm_col_soft = class(TForm)
    MSystemInfo1: TMSystemInfo;
    procedure FormCreate(Sender: TObject);
  private
    procedure Executa_Col_Soft;
    procedure Log_Historico(strMsg : String);
    function  GetAllEnvVars():String;
    function  SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
    Function  Crip(PNome: String): String;
    Function  DesCrip(PNome: String): String;
    function  GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    function  GetValorChaveRegEdit(Chave: String): Variant;
    Function  Explode(Texto, Separador : String) : TStrings;
    Function  GetRootKey(strRootKey: String): HKEY;
    Function  RemoveCaracteresEspeciais(Texto : String) : String;
    function  GetVersaoIE: string;
    function  GetVersaoAcrobatReader: String;
    function  GetVersaoJRE: String;
    function  GetVersaoMozilla: String;
  public
    { Public declarations }
  end;

var
  frm_col_soft: Tfrm_col_soft;

implementation

uses StrUtils;

{$R *.dfm}

function Tfrm_col_soft.GetAllEnvVars():String;
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


//Para gravar no Arquivo INI...
function Tfrm_col_soft.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
//    Reg_Ini.WriteString(frm_col_soft.Crip(p_Secao), frm_col_soft.Crip(p_Chave), frm_col_soft.Crip(p_Valor));
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function Tfrm_col_soft.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
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


Function Tfrm_col_soft.Explode(Texto, Separador : String) : TStrings;
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

function Tfrm_col_soft.GetRootKey(strRootKey: String): HKEY;
begin
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function Tfrm_col_soft.RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;



function Tfrm_col_soft.GetVersaoIE: string;
var strVersao: string;
begin
    // Detalhes das versões em http://support.microsoft.com/default.aspx?scid=KB;EN-US;Q164539&
    strVersao := '';
    strVersao := Trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Version'));
    Result := strVersao;
end;

// Função adaptada de http://www.latiumsoftware.com/en/delphi/00004.php
//Para buscar do RegEdit...
function Tfrm_col_soft.GetValorChaveRegEdit(Chave: String): Variant;
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


function Tfrm_col_soft.GetVersaoAcrobatReader: String;
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

function Tfrm_col_soft.GetVersaoJRE: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\JavaSoft\Java Runtime Environment\CurrentVersion'));
    Result := strVersao;
end;

function Tfrm_col_soft.GetVersaoMozilla: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(GetValorChaveRegEdit('HKEY_LOCAL_MACHINE\Software\mozilla.org\Mozilla\CurrentVersion'));
    Result := strVersao;
end;

procedure Tfrm_col_soft.Executa_Col_Soft;
var te_versao_mozilla, te_versao_ie, te_versao_jre, te_versao_acrobat_reader,
    ValorChaveColetado,ValorChaveRegistro, te_inventario_softwares, te_variaveis_ambiente : String;
    InfoSoft : TStringList;
    i : integer;
begin
 Try
   Log_Historico('* Coletando informações de Softwares Básicos.');

   Try MSystemInfo1.Engines.GetInfo;  except end;
   te_versao_mozilla        := GetVersaoMozilla;
   te_versao_ie             := GetVersaoIE;
   te_versao_jre            := GetVersaoJRE;
   te_versao_acrobat_reader := GetVersaoAcrobatReader;

   Try MSystemInfo1.Software.GetInfo;          except end;
   InfoSoft := TStringList.Create;
   Try MSystemInfo1.Software.Report(InfoSoft,false); except end;

   for i := 0 to InfoSoft.Count - 1 do
      begin
          if (trim(MidStr(InfoSoft[i],13,Pos('type=',InfoSoft[i])-15))<>'') then
              Begin
                if (te_inventario_softwares <> '') then te_inventario_softwares := te_inventario_softwares + '#';
                te_inventario_softwares := te_inventario_softwares + MidStr(InfoSoft[i],13,Pos('type=',InfoSoft[i])-15);
              End;
      end;
   InfoSoft.Free;

   // Pego todas as variáveis de ambiente.
   te_variaveis_ambiente := GetAllEnvVars();

   // Monto a string que será comparada com o valor armazenado no registro.
   ValorChaveColetado := MSystemInfo1.Engines.ODBC  + ';' +
                         MSystemInfo1.Engines.BDE  + ';' +
                         MSystemInfo1.Engines.DAO  + ';' +
                         MSystemInfo1.Engines.ADO  + ';' +
                         MSystemInfo1.Engines.DirectX.Version  + ';' +
                         te_versao_mozilla + ';' +
                         te_versao_ie + ';' +
                         te_versao_acrobat_reader + ';' +
                         te_versao_jre + ';' +
                         te_inventario_softwares +
                         te_variaveis_ambiente;

   // Obtenho do registro o valor que foi previamente armazenado
   ValorChaveRegistro := Trim(GetValorChaveRegIni('Coleta','Software',p_path_cacic_ini));


   // Se essas informações forem diferentes significa que houve alguma alteração
   // na configuração. Nesse caso, gravo as informações no BD Central
   // e, se não houver problemas durante esse procedimento, atualizo as
   // informações no registro.
   If (GetValorChaveRegIni('Configs','IN_COLETA_FORCADA_SOFT',p_path_cacic_ini)='S') or
      (ValorChaveColetado <> ValorChaveRegistro) Then
    Begin
      //Envio via rede para ao Agente Gerente, para gravação no BD.
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_bde'           , frm_col_soft.MSystemInfo1.Engines.BDE            , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_dao'           , frm_col_soft.MSystemInfo1.Engines.DAO            , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_ado'           , frm_col_soft.MSystemInfo1.Engines.ADO            , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_odbc'          , frm_col_soft.MSystemInfo1.Engines.ODBC           , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_directx'       , frm_col_soft.MSystemInfo1.Engines.DirectX.Version, frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_acrobat_reader', te_versao_acrobat_reader                         , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_ie'            , te_versao_ie                                     , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_mozilla'       , te_versao_mozilla                                , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_versao_jre'           , te_versao_jre                                    , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_inventario_softwares' , te_inventario_softwares                          , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','te_variaveis_ambiente'   , te_variaveis_ambiente                            , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
      frm_col_soft.SetValorChaveRegIni('Col_Soft','ValorChaveColetado'      , ValorChaveColetado                               , frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
    end
   else
     frm_col_soft.SetValorChaveRegIni('Col_Soft','nada', 'nada', frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
   Application.Terminate;
 Except
   frm_col_soft.SetValorChaveRegIni('Col_Soft','nada', 'nada', frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
   Application.Terminate;
 End;
end;


procedure Tfrm_col_soft.Log_Historico(strMsg : String);
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
// Simples rotinas de Criptografação e Descriptografação
// Baixadas de http://www.costaweb.com.br/forum/delphi/474.shtml
Function Tfrm_col_soft.Crip(PNome: String): String;
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

Function Tfrm_col_soft.DesCrip(PNome: String): String;
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


procedure Tfrm_col_soft.FormCreate(Sender: TObject);
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
    Executa_Col_Soft;
  Except
    frm_col_soft.SetValorChaveRegIni('Col_Soft','nada', 'nada', frm_col_soft.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_soft.ini');
    Application.Terminate;
  End;
end;
end.

