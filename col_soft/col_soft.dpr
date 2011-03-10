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
  Registry, // Utilizado em algumas functions
  MSI_SOFTWARE,
  MSI_ENGINES,
  MSI_OS,
  MSI_XML_Reports,
  CACIC_Library in '..\CACIC_Library.pas';

var
  g_oCacic                    : TCACIC;

const
  CACIC_APP_NAME              = 'col_soft';


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
      if g_oCacic.inDebugMode then
        Begin
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
        End
   except
     g_oCacic.writeDailyLog('Erro na gravação do Debug!');
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
    strVersao := Trim(g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\Version'));
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
    strVersao := Trim(g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\JavaSoft\Java Runtime Environment\CurrentVersion'));
    Result := strVersao;
end;

function GetVersaoMozilla: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(g_oCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\mozilla.org\Mozilla\CurrentVersion'));
    Result := strVersao;
end;

procedure Executa_Col_Soft;
var te_versao_mozilla, te_versao_ie, te_versao_jre, te_versao_acrobat_reader,
    UVC,ValorChaveRegistro, te_inventario_softwares, te_variaveis_ambiente,
    strDisplayName,
    strKeyName : String;
    InfoSoft, v_Report : TStringList;
    i : integer;
    v_SOFTWARE      : TMiTeC_Software;
    v_ENGINES       : TMiTeC_Engines;
    v_OS            : TMiTeC_OperatingSystem;
    registrySoftwares : TRegistry;
begin
 Try
   g_oCacic.setValueToFile('Col_Soft','Inicio', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
   g_oCacic.writeDailyLog('Coletando informações de Softwares Básicos: Versão de Engine Mozilla');
   te_versao_mozilla        := GetVersaoMozilla;
   g_oCacic.writeDailyLog('Coletando informações de Softwares Básicos: Versão de Navegador I.E.');
   te_versao_ie             := GetVersaoIE;
   g_oCacic.writeDailyLog('Coletando informações de Softwares Básicos: Versão de Java Runtime Environment');
   te_versao_jre            := GetVersaoJRE;
   g_oCacic.writeDailyLog('Coletando informações de Softwares Básicos: Versão de Adobe Acrobat Reader');
   te_versao_acrobat_reader := GetVersaoAcrobatReader;

   te_inventario_softwares  := '';

   v_Report := TStringList.Create;

   InfoSoft                 := TStringList.Create;

   if not g_oCacic.isWindowsGEVista then
    Begin
       Try
          v_SOFTWARE := TMiTeC_Software.Create(nil);
          v_SOFTWARE.RefreshData;
          MSI_XML_Reports.Software_XML_Report(v_SOFTWARE,true,InfoSoft);

          // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
          // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
          if g_oCacic.inDebugMode then
            Begin
              MSI_XML_Reports.Software_XML_Report(v_SOFTWARE,true,v_Report);
              v_SOFTWARE.Free;

              v_OS := TMiTeC_OperatingSystem.Create(nil);
              v_OS.RefreshData;

              MSI_XML_Reports.OperatingSystem_XML_Report(v_OS,true,v_Report);
              v_OS.Free;
            End

       except
          g_oCacic.writeDailyLog('Problema em Software Report!');
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
    end
   else
    Begin
        // Chave para 64Bits
        strKeyName := 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall';

        registrySoftwares := TRegistry.Create;
        with registrySoftwares do
        begin
          RootKey:=HKEY_LOCAL_MACHINE;
          if OpenKey(strKeyName,False)=True then
              GetKeyNames(InfoSoft);

          CloseKey;

          for i:=0 to InfoSoft.Count-1 do
          begin
            RootKey:=HKEY_LOCAL_MACHINE;
            OpenKey(strKeyName + '\'+InfoSoft[i],False);
            strDisplayName := ReadString('DisplayName');

            if (strDisplayName <> '') then
              Begin
                if (Copy(strDisplayName,1,1)='{') then
                  begin
                    OpenKey(strKeyName + '\'+InfoSoft[i]+'\'+strDisplayName,False);
                    strDisplayName := ReadString('DisplayName');
                  end;

                if (te_inventario_softwares <> '') then
                  te_inventario_softwares := te_inventario_softwares + '#';
                te_inventario_softwares := te_inventario_softwares + strDisplayName;
              end;
            CloseKey;
          end;
        end;

        // Caso a consulta acima tenha retornado vazio, tentarei a chave para 32Bits
        strKeyName := 'Software\Microsoft\Windows\CurrentVersion\Uninstall';

        with registrySoftwares do
        begin
          RootKey:=HKEY_LOCAL_MACHINE;
          if OpenKey(strKeyName,False)=True then
              GetKeyNames(InfoSoft);

          CloseKey;

          for i:=0 to InfoSoft.Count-1 do
          begin
            RootKey:=HKEY_LOCAL_MACHINE;
            OpenKey(strKeyName + '\'+InfoSoft[i],False);
            strDisplayName := ReadString('DisplayName');
            if (strDisplayName <> '') then
              Begin
                if (Copy(strDisplayName,1,1)='{') then
                  begin
                    OpenKey(strKeyName + '\'+InfoSoft[i]+'\'+strDisplayName,False);
                    strDisplayName := ReadString('DisplayName');
                  end;

                if (te_inventario_softwares <> '') then
                  te_inventario_softwares := te_inventario_softwares + '#';
                te_inventario_softwares := te_inventario_softwares + strDisplayName;
              end;
            CloseKey;
          end;
        end;

        //
    end;

   try
      te_inventario_softwares := AnsiToAscii(te_inventario_softwares);
   except
      g_oCacic.writeDailyLog('Falha após a Conversão ANSIxASCII.');
   end;

   InfoSoft.Free;

   // Pego todas as variáveis de ambiente.
   g_oCacic.writeDailyLog('Coletando informações sobre Variáveis de Ambiente...');
   te_variaveis_ambiente := GetAllEnvVars();

   v_ENGINES := TMiTeC_Engines.Create(nil);
   v_ENGINES.RefreshData;

   // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
   // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
   if g_oCacic.inDebugMode then
       MSI_XML_Reports.Engines_XML_Report(v_ENGINES,false,v_Report);

   // Monto a string que será comparada com o valor armazenado no registro local.
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
   ValorChaveRegistro := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','Software',g_oCacic.getLocalFolder + 'GER_COLS.inf')));

   g_oCacic.setValueToFile('Col_Soft','Fim',g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

   // Se essas informações forem diferentes significa que houve alguma alteração
   // na configuração. Nesse caso, gravo as informações no BD Central
   // e, se não houver problemas durante esse procedimento, atualizo as
   // informações no registro.
   If (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_COLETA_FORCADA_SOFT',g_oCacic.getLocalFolder + 'GER_COLS.inf'))='S') or
      (UVC <> ValorChaveRegistro) Then
    Begin
      //Envio via rede para ao Agente Gerente, para gravação no BD.
      g_oCacic.setValueToFile('Col_Soft','te_versao_bde'           ,g_oCacic.enCrypt( v_ENGINES.BDE)            , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_dao'           ,g_oCacic.enCrypt( v_ENGINES.DAO)            , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_ado'           ,g_oCacic.enCrypt( v_ENGINES.ADO)            , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_odbc'          ,g_oCacic.enCrypt( v_ENGINES.ODBC)           , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_directx'       ,g_oCacic.enCrypt( v_ENGINES.DirectX.Version), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_acrobat_reader',g_oCacic.enCrypt( te_versao_acrobat_reader) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_ie'            ,g_oCacic.enCrypt( te_versao_ie)             , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_mozilla'       ,g_oCacic.enCrypt( te_versao_mozilla)        , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_versao_jre'           ,g_oCacic.enCrypt( te_versao_jre)            , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_inventario_softwares' ,g_oCacic.enCrypt( te_inventario_softwares)  , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','te_variaveis_ambiente'   ,g_oCacic.enCrypt( te_variaveis_ambiente)    , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Soft','UVC'                     ,g_oCacic.enCrypt( UVC)                      , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    end
   else
     g_oCacic.setValueToFile('Col_Soft','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

   v_ENGINES.Free;

   // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
   // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
   if g_oCacic.inDebugMode then
      Begin
        for i:=0 to v_Report.count-1 do
          Grava_Debugs(v_report[i]);

        v_report.Free;
      End;
 Except
  Begin
   g_oCacic.setValueToFile('Col_Soft','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
   g_oCacic.setValueToFile('Col_Soft','Fim' ,g_oCacic.enCrypt( '99999999'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
  End;
 End;
end;

begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          g_oCacic.setLocalFolder( g_oCacic.GetParam('LocalFolder') );

          if (g_oCacic.getLocalFolder <> '') then
            Begin
               g_oCacic.checkDebugMode;

               Try
                  if g_oCacic.inDebugMode then
                    g_oCacic.writeDailyLog('As informações para DEBUG de coletas internas serão gravadas em "' + g_oCacic.getLocalFolder + '\Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt');

                  Executa_Col_Soft;
               Except
                  g_oCacic.setValueToFile('Col_Soft','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
               End;
            End;
        End;

   g_oCacic.Free();

end.
