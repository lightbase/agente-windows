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

uses
  Windows,
  SysUtils,
  Classes,
  Registry,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_strCipherClosed         : String;

var
  v_tstrCipherOpened,
  v_tstrCipherOpened1        : TStrings;

var
  g_oCacic : TCACIC;

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
       Writeln(HistoricoLog,FormatDateTime('dd/mm hh:nn:ss : ', Now)+ '[Coletor COMP] '+strMsg); {Grava a string Texto no arquivo texto}
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
      Result := g_oCacic.explode('Configs.ID_SO'+g_oCacic.getSeparatorKey+g_oCacic.getWindowsStrId() +g_oCacic.getSeparatorKey+'Configs.Endereco_WS'+g_oCacic.getSeparatorKey+'/cacic2/ws/',g_oCacic.getSeparatorKey);


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

Function GetValorDatMemoria(p_Chave : String) : String;
begin
    if (v_tstrCipherOpened.IndexOf(p_Chave)<>-1) then
      Result := v_tstrCipherOpened[v_tstrCipherOpened.IndexOf(p_Chave)+1]
    else
      Result := '';
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
    in_senha_escrita,	in_senha_leitura, te_comentario, strTripaDados, strAux,
    cs_tipo_permissao, cs_tipo_compart  : String;
    I, intAux: Integer;
    Lista_RCC : TStringList;
Begin
  Try
    Begin
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
      strTripaDados := '';

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
             if (strTripaDados <> '') then
                strTripaDados := strTripaDados + '<REG>'; // Delimitador de REGISTRO

             strTripaDados := strTripaDados + nm_compartilhamento + '<FIELD>' +
                                              nm_dir_compart      + '<FIELD>' +
                                              cs_tipo_compart     + '<FIELD>' +
                                              te_comentario;
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
             {
             strXML := strXML + '<compart>' +
                          '<nm_compartilhamento>' + nm_compartilhamento + '</nm_compartilhamento>' +
                          '<nm_dir_compart>' + nm_dir_compart + '</nm_dir_compart>' +
                          '<cs_tipo_compart>' + cs_tipo_compart + '</cs_tipo_compart>' +
                          '<cs_tipo_permissao>' + cs_tipo_permissao + '</cs_tipo_permissao>' +
                          '<in_senha_leitura>' + in_senha_leitura + '</in_senha_leitura>' +
                          '<in_senha_escrita>' + in_senha_escrita + '</in_senha_escrita>' +
                          '<te_comentario>' + te_comentario + '</te_comentario>' +
                       '</compart>';
             }
             if (strTripaDados <> '') then
                strTripaDados := strTripaDados + '<REG>'; // Delimitador de REGISTRO

             strTripaDados := strTripaDados + nm_compartilhamento + '<FIELD>' +
                                              nm_dir_compart      + '<FIELD>' +
                                              cs_tipo_compart     + '<FIELD>' +
                                              te_comentario       + '<FIELD>' +
                                              in_senha_leitura    + '<FIELD>' +
                                              in_senha_escrita    + '<FIELD>' +
                                              cs_tipo_permissao;
          end;
      end;

      Reg_RCC.Free;
      Lista_RCC.Free;


      // Obtenho do registro o valor que foi previamente armazenado
      ValorChaveRegistro := Trim(GetValorDatMemoria('Coletas.Compartilhamentos'));

      SetValorDatMemoria('Col_Comp.Fim'               , FormatDateTime('hh:nn:ss', Now), v_tstrCipherOpened1);

      // Se essas informações forem diferentes significa que houve alguma alteração
      // na configuração. Nesse caso, gravo as informações no BD Central e, se não houver
      // problemas durante esse procedimento, atualizo as informações no registro.
      If ((GetValorDatMemoria('Configs.IN_COLETA_FORCADA_COMP')='S') or (strTripaDados <> ValorChaveRegistro)) and
         (strTripaDados <> '') Then
        Begin
          SetValorDatMemoria('Col_Comp.UVC', strTripaDados, v_tstrCipherOpened1);
          CipherClose(g_oCacic.getCacicPath + 'temp\col_comp.dat', v_tstrCipherOpened1);
        End
      else
        SetValorDatMemoria('Col_Comp.nada', 'nada', v_tstrCipherOpened1);

      CipherClose(g_oCacic.getCacicPath + 'temp\col_comp.dat', v_tstrCipherOpened1);
    End;
  Except
    Begin
      SetValorDatMemoria('Col_Comp.nada', 'nada', v_tstrCipherOpened1);
      SetValorDatMemoria('Col_Comp.Fim', '99999999', v_tstrCipherOpened1);
      CipherClose(g_oCacic.getCacicPath + 'temp\col_comp.dat', v_tstrCipherOpened1);
    End;
  End;
end;

var tstrTripa1 : TStrings;
    intAux     : integer;
    strAux     : String;

const
  CACIC_APP_NAME = 'col_comp';

begin
  g_oCacic := TCACIC.Create();

  g_oCacic.setBoolCipher(true);

  if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          strAux := '';
          For intAux := 1 to ParamCount do
            Begin
              if LowerCase(Copy(ParamStr(intAux),1,11)) = '/cacicpath=' then
                begin
                  strAux := Trim(Copy(ParamStr(intAux),12,Length((ParamStr(intAux)))));
                end;
            end;

          if (strAux <> '') then
            Begin
               g_oCacic.setCacicPath(strAux);

               v_tstrCipherOpened  := TStrings.Create;
               v_tstrCipherOpened  := CipherOpen(g_oCacic.getCacicPath + g_oCacic.getDatFileName);

               v_tstrCipherOpened1 := TStrings.Create;
               v_tstrCipherOpened1 := CipherOpen(g_oCacic.getCacicPath + 'temp\col_comp.dat');

               Try
                  Executa_Col_comp;
               Except
                  SetValorDatMemoria('Col_Comp.nada', 'nada', v_tstrCipherOpened1);
                  CipherClose(g_oCacic.getCacicPath + 'temp\col_comp.dat', v_tstrCipherOpened1);
               End;
               Halt(0);
            End;
        End;
   g_oCacic.Free();
end.
