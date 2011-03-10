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
  SysUtils,
  Classes,
  Registry, // Utilizado em Executa_Col_Hard
  MSI_SMBIOS,
  MSI_Devices,
  MSI_CPU,
  MSI_DISPLAY,
  MSI_MEDIA,
  MSI_NETWORK,
  MSI_XML_Reports,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_mensagem            : String;
  g_oCacic              : TCACIC;


// Dica baixada de http://www.marcosdellantonio.net/2007/06/14/operador-if-ternario-em-delphi-e-c/
// Fiz isso para não ter que acrescentar o componente Math ao USES!
function iif(condicao : boolean; resTrue, resFalse : Variant) : Variant;
  Begin
    if condicao then
      Result := resTrue
    else
      Result := resFalse;
  End;

// Função criada devido a divergências entre os valores retornados pelos métodos dos componentes MSI e seus Reports.
function Parse(p_ClassName, p_SectionName, p_DataName:string; p_Report : TStringList) : String;
var intClasses, intSections, intDatas, v_achei_SectionName, v_array_SectionName_Count : integer;
    v_ClassName, v_DataName, v_string_consulta : string;
    v_array_SectionName : tstrings;
begin
    g_oCacic.writeDebugLog('p_ClassName => "'+p_ClassName+'" p_SectionName => "'+p_SectionName+'" p_DataName => "'+p_DataName+'"');
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



// Converte caracteres básicos da tabela Ansi para Ascii
// Solução temporária.  :)
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
        tstrEXCECOES  := g_oCacic.explode(p_excecao,','); // Excecoes a serem tratadas
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
    v_Macs_Invalidos,
    v_Tripa_CDROM,
    v_Tripa_TCPIP,
    v_Tripa_CPU,
    v_PhysicalAddress,
    v_IPAddress,
    v_IPMask,
    v_Gateway_IPAddress,
    v_DHCP_IPAddress,
    v_PrimaryWINS_IPAddress,
    v_SecondaryWINS_IPAddress                        : String;
    intLoop                       : Integer;
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

begin

   if g_oCacic.inDebugMode then
     g_oCacic.writeDailyLog('As informações para DEBUG serão gravadas em "' + g_oCacic.getLocalFolder + 'Temp\Debugs\debug_'+StringReplace(ExtractFileName(StrUpper(PChar(ParamStr(0)))),'.EXE','',[rfReplaceAll])+'.txt');

  Try
     g_oCacic.setValueToFile('Col_Hard','Inicio', g_oCacic.enCrypt(FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
     v_Report := TStringList.Create;
     g_oCacic.writeDailyLog('Coletando informações de Hardware.');

     v_cpu_freq  := TStringList.Create;
     v_tstrCPU   := TStringList.Create;
     v_tstrCDROM := TStringList.Create;
     v_tstrTCPIP := TStringList.Create;

     Try
        Begin
            g_oCacic.writeDebugLog('Instanciando SMBIOS para obter frequencia de CPU...');
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
                   g_oCacic.writeDailyLog('CPU - informação de frequência ['+v_te_cpu_frequencia+'] não disponível (by SMBIOS/Registry): ');
                 end;
               finally
                 v_registry.Free;
               end;
            end;
            v_SMBIOS.Free;

            g_oCacic.writeDebugLog('CPU - frequência estática (by SMBIOS/Registry): '+v_te_cpu_frequencia);

            g_oCacic.writeDebugLog('Instanciando v_CPU...');
            v_CPU := TMiTeC_CPU.Create(nil);
            g_oCacic.writeDebugLog('Atualização de dados de CPU...');
            v_CPU.RefreshData;
            g_oCacic.writeDebugLog('Dados de CPU atualizados - OK!');

            // Obtem dados de CPU
            Try
               for intLoop := 0 to v_CPU.CPUCount-1 do begin
                  v_te_cpu_serial := v_CPU.SerialNumber;
                  v_te_cpu_desc   := v_CPU.CPUName;
                  if(v_te_cpu_desc = '') then
                     v_te_cpu_desc := v_CPU.MarketingName;

                  v_te_cpu_fabricante  := cVendorNames[v_CPU.Vendor].Prefix;

                  g_oCacic.writeDebugLog('CPU - frequência dinâmica (by CPU): '+inttostr(v_CPU.Frequency) + 'Mhz');

                  // Se pegou ao menos a descrição, adiciona-se à tripa...
                  if (v_te_cpu_desc <> '') then
                    Begin
                      v_tstrCPU.Add('te_cpu_desc###'       + v_te_cpu_desc        + '#FIELD#' +
                                    'te_cpu_fabricante###' + v_te_cpu_fabricante  + '#FIELD#' +
                                    'te_cpu_serial###'     + v_te_cpu_serial      + '#FIELD#' +
                                    'te_cpu_frequencia###' + v_te_cpu_frequencia);
                      g_oCacic.writeDebugLog('Adicionando a tstrCPU: "'+v_tstrCPU[v_tstrCPU.count-1]);
                      g_oCacic.writeDebugLog('Tamanho de v_tstrCPU 0: '+intToStr(v_tstrCPU.Count));
                    End;
               end;
            Except
              g_oCacic.writeDailyLog('Problemas ao coletar dados de CPU!');
            end;
            v_CPU.Free;
            g_oCacic.writeDebugLog('Tamanho de v_tstrCPU 1: '+intToStr(v_tstrCPU.Count));

            // Media informations
            Try
              v_MEDIA := TMiTeC_Media.Create(nil);
              v_MEDIA.RefreshData;
              if v_Media.SoundCardIndex>-1 then begin
                 //n:=Tree.Items.AddChild(r,Media.Devices[Media.SoundCardIndex]);
                 v_te_placa_som_desc := v_Media.Devices[v_Media.SoundCardIndex];
              end;
            except g_oCacic.writeDailyLog('Problemas ao coletar dados de Aúdio');
            end;

            g_oCacic.writeDebugLog('Dados de aúdio coletados - OK!');

            // Devices informations
            Try
              g_oCacic.writeDebugLog('Instanciando v_DEVICES...');
              v_DEVICES := TMiTeC_Devices.Create(nil);
              g_oCacic.writeDebugLog('RefreshingData...');
              v_DEVICES.RefreshData;
              if g_oCacic.inDebugMode then MSI_XML_Reports.Devices_XML_Report(v_DEVICES,TRUE,v_Report);
              g_oCacic.writeDebugLog('v_DEVICES.DeviceCount = '+intToStr(v_DEVICES.DeviceCount));
              intLoop := 0;
              While intLoop < v_DEVICES.DeviceCount do
                Begin
                  v_mensagem := 'Obtendo Descrição de CDROM';
                  g_oCacic.writeDebugLog('Percorrendo v_DEVICES.Devices['+intToStr(intLoop)+']...');

                  if v_DEVICES.Devices[intLoop].DeviceClass=dcCDROM then
                    Begin
                      // Vamos tentar de tudo!  :))))
                      v_te_cdrom_desc := Trim(v_DEVICES.Devices[intLoop].Name);
                      if Trim(v_te_cdrom_desc)='' then
                        v_te_cdrom_desc := v_DEVICES.Devices[intLoop].FriendlyName;
                      if Trim(v_te_cdrom_desc)='' then
                        v_te_cdrom_desc := v_DEVICES.Devices[intLoop].Description;

                      if (v_te_cdrom_desc <> '') then
                        Begin
                          v_tstrCDROM.Add('te_cdrom_desc###'+v_te_cdrom_desc);
                          g_oCacic.writeDebugLog('Adicionando a tstrCDROM: "'+v_tstrCDROM[v_tstrCDROM.count-1]+'"');
                          g_oCacic.writeDebugLog('CDROM Informations - OK!');
                        End;
                    End;


                  v_mensagem := 'Obtendo Descrição de Modem';
                  if v_DEVICES.Devices[intLoop].DeviceClass=dcModem then
                    Begin
                      if Trim(v_DEVICES.Devices[intLoop].FriendlyName)='' then
                        v_te_modem_desc := Trim(v_DEVICES.Devices[intLoop].Description)
                      else
                        v_te_modem_desc := Trim(v_DEVICES.Devices[intLoop].FriendlyName);

                      g_oCacic.writeDebugLog('MODEM Informations - OK!');
                    End;

                  v_mensagem := 'Obtendo Descrição de Mouse';
                  if v_DEVICES.Devices[intLoop].DeviceClass=dcMouse then
                    Begin
                      if Trim(v_DEVICES.Devices[intLoop].FriendlyName)='' then
                        v_te_mouse_desc := Trim(v_DEVICES.Devices[intLoop].Description)
                      else
                        v_te_mouse_desc := Trim(v_DEVICES.Devices[intLoop].FriendlyName);

                      g_oCacic.writeDebugLog('MOUSE Informations - OK!');
                    End;

                  v_mensagem := 'Obtendo Descrição de Teclado';
                  if v_DEVICES.Devices[intLoop].DeviceClass=dcKeyboard then
                    Begin
                      if Trim(v_DEVICES.Devices[intLoop].FriendlyName)='' then
                        v_te_teclado_desc := Trim(v_DEVICES.Devices[intLoop].Description)
                      else
                        v_te_teclado_desc := Trim(v_DEVICES.Devices[intLoop].FriendlyName);

                      g_oCacic.writeDebugLog('KEYBOARD Informations - OK!');
                    End;

                  v_mensagem := 'Obtendo Descrição de Vídeo';
                  if v_DEVICES.Devices[intLoop].DeviceClass=dcDisplay then
                    Begin
                      if Trim(v_DEVICES.Devices[intLoop].FriendlyName)='' then
                        v_te_placa_video_desc := Trim(v_DEVICES.Devices[intLoop].Description)
                      else
                        v_te_placa_video_desc := Trim(v_DEVICES.Devices[intLoop].FriendlyName);

                      g_oCacic.writeDebugLog('DISPLAY Informations - OK!');
                    End;

                  inc(intLoop);
                End;
            except g_oCacic.writeDailyLog('Problema em DEVICES Details!');
            end;
            v_DEVICES.Free;


            // Memory informations
            Try
              Begin
                  v_MemoriaRAM.dwLength := SizeOf(v_MemoriaRAM);
                  GlobalMemoryStatus(v_MemoriaRAM);
                  v_qt_mem_ram := v_MemoriaRAM.dwTotalPhys div 1024000;
                  g_oCacic.writeDebugLog('MEMORY Informations - OK!');
              End;
            except g_oCacic.writeDailyLog('Problema em MEMORY Details!');
            end;

            Try
              Begin
                v_SMBIOS := TMiTeC_SMBIOS.Create(nil);
                v_SMBIOS.RefreshData;
                with v_SMBIOS do begin
                   if v_SMBIOS.MemoryDeviceCount>0 then begin
                     for intLoop := 0 to v_SMBIOS.MemoryDeviceCount-1 do
                       if (v_SMBIOS.MemoryDevice[intLoop].Size>0) then begin
                         if v_SMBIOS.MemoryDevice[intLoop].Device>smmdUnknown then
                            v_te_mem_ram_tipo:=MemoryDeviceTypes[v_SMBIOS.MemoryDevice[intLoop].Device]
                         else
                           v_te_mem_ram_tipo:=MemoryFormFactors[v_SMBIOS.MemoryDevice[intLoop].FormFactor];

                         if (v_te_mem_ram_desc <> '') then
                            v_te_mem_ram_desc := v_te_mem_ram_desc + ' - ';

                         v_te_mem_ram_desc := v_te_mem_ram_desc + 'Slot '+ inttostr(intLoop) + ': '
                                                                + v_SMBIOS.MemoryDevice[intLoop].Manufacturer + ' '
                                                                + inttostr(v_SMBIOS.MemoryDevice[intLoop].Size) + 'MB '
                                                                + '(' + v_te_mem_ram_tipo +')';
                       end;
                   end
                   else if v_SMBIOS.MemoryModuleCount > -1 then
                     Begin
                       for intLoop := 0 to v_SMBIOS.MemoryModuleCount-1 do begin
                         if (v_SMBIOS.MemoryModule[intLoop].Size <> 0) then begin
                            v_te_mem_ram_tipo := v_SMBIOS.GetMemoryTypeStr(v_SMBIOS.MemoryModule[intLoop].Types);
                            if (v_te_mem_ram_desc <> '') then
                               v_te_mem_ram_desc := v_te_mem_ram_desc + ' - ';
                            v_te_mem_ram_desc := v_te_mem_ram_desc + 'Slot '+ inttostr(intLoop) + ': '
                                                                   + v_SMBIOS.MemoryDevice[intLoop].Manufacturer + ' '
                                                                   + inttostr(v_SMBIOS.MemoryModule[intLoop].Size) + 'MB '
                                                                   + '(' + v_te_mem_ram_tipo +')';
                         end;
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
                g_oCacic.writeDebugLog('SMBIOS Informations - OK!');
              End;
            Except g_oCacic.writeDailyLog('Problema em SMBIOS Details!');
            End;

            // Display informations
            Try
              Begin
                v_DISPLAY := TMiTeC_Display.Create(nil);
                v_DISPLAY.RefreshData;

                if (trim(v_te_placa_video_desc)='') then v_te_placa_video_desc := v_DISPLAY.Adapter;
                v_qt_placa_video_cores     := IntToStr(v_DISPLAY.ColorDepth);
                v_qt_placa_video_mem       := IntToStr(v_DISPLAY.Memory div 1048576 ) + 'MB';
                v_te_placa_video_resolucao := IntToStr(v_DISPLAY.HorzRes) + 'x' + IntToStr(v_DISPLAY.VertRes);

                v_DISPLAY.Free;
                g_oCacic.writeDebugLog('VIDEO Informations - OK!');
              End;
            Except g_oCacic.writeDailyLog('Problema em VIDEO Details!');
            End;

            // Network informations
            Try
              Begin
                v_TCP := TMiTeC_TCPIP.Create(nil);
                v_TCP.RefreshData;

                v_mensagem := 'Ativando TCP Getinfo...';

                intLoop := 0;
                v_Macs_Invalidos := trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TCPIP','TE_ENDERECOS_MAC_INVALIDOS',g_oCacic.getLocalFolder + 'GER_COLS.inf')));

                // Avalia quantidade de placas de rede e obtem respectivos dados
                if v_TCP.AdapterCount>0 then
                  for intLoop := 0 to v_TCP.AdapterCount-1 do begin
                    v_te_placa_rede_desc      := v_TCP.Adapter[intLoop].Name;
                    v_PhysicalAddress         := v_TCP.Adapter[intLoop].Address;
                    v_IPAddress               := v_TCP.Adapter[intLoop].IPAddress[0];
                    v_IPMask                  := v_TCP.Adapter[intLoop].IPAddressMask[0];
                    v_Gateway_IPAddress       := v_TCP.Adapter[intLoop].Gateway_IPAddress[0];
                    v_DHCP_IPAddress          := v_TCP.Adapter[intLoop].DHCP_IPAddress[0];
                    v_PrimaryWINS_IPAddress   := v_TCP.Adapter[intLoop].PrimaryWINS_IPAddress[0];
                    v_SecondaryWINS_IPAddress := v_TCP.Adapter[intLoop].SecondaryWINS_IPAddress[0];

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
                        g_oCacic.writeDebugLog('Adicionando a tstrTCPIP: "'+v_tstrTCPIP[v_tstrTCPIP.count-1]+'"');
                      End
                  End;
                v_TCP.Free;
                g_oCacic.writeDebugLog('TCPIP Informations - OK!');
              End;
            Except g_oCacic.writeDailyLog('Problema em TCP Details!');
            End;

            // Caso exista a pasta ..temp/debugs, será criado o arquivo diário debug_<coletor>.txt
            // Usar esse recurso apenas para debug de coletas mal-sucedidas através do componente MSI-Mitec.
            if g_oCacic.inDebugMode then
              Begin
                intLoop := 0;
                while intLoop < v_Report.count-1 do
                  Begin
                    Grava_Debugs(v_report[intLoop]);
                    inc(intLoop);
                  End;
                v_report.Free;
              End;
        End;
     Except
     End;

     // Crio as Tripas dos múltiplos ítens...
     v_Tripa_CPU := '';
     v_tstrCPU.Sort;
     g_oCacic.writeDebugLog('Tamanho de v_tstrCPU 2: '+intToStr(v_tstrCPU.Count));
     intLoop := 0;
     while (intLoop < v_tstrCPU.Count) do
        Begin
          v_Tripa_CPU := v_Tripa_CPU + iif(v_Tripa_CPU = '','','#CPU#');
          v_Tripa_CPU := v_Tripa_CPU + v_tstrCPU[intLoop];
          inc(intLoop);
        End;

     v_Tripa_CDROM := '';
     v_tstrCDROM.Sort;
     g_oCacic.writeDebugLog('Tamanho de v_tstrCDROM: '+intToStr(v_tstrCDROM.Count));
     intLoop := 0;
     while (intLoop < v_tstrCDROM.Count) do
        Begin
          v_Tripa_CDROM := v_Tripa_CDROM + iif(v_Tripa_CDROM = '','','#CDROM#');
          v_Tripa_CDROM := v_Tripa_CDROM + v_tstrCDROM[intLoop];
          inc(intLoop);
        End;

     v_Tripa_TCPIP := '';
     v_tstrTCPIP.Sort;
     g_oCacic.writeDebugLog('Tamanho de v_tstrTCPIP: '+intToStr(v_tstrTCPIP.Count));
     intLoop := 0;
     while (intLoop < v_tstrTCPIP.Count) do
        Begin
          v_Tripa_TCPIP := v_Tripa_TCPIP + iif(v_Tripa_TCPIP = '','','#TCPIP#');
          v_Tripa_TCPIP := v_Tripa_TCPIP + v_tstrTCPIP[intLoop];
          inc(intLoop);
        End;

     Try
     // Monto a string que será comparada com o valor armazenado no registro.
      v_mensagem := 'Montando pacote para comparações...';
     UVC := g_oCacic.trimEspacosExcedentes(v_Tripa_TCPIP     + ';' +
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
     Except g_oCacic.writeDailyLog('Problema em comparação de envio!');
     End;

     // Obtenho do registro o valor que foi previamente armazenado
     ValorChaveRegistro := Trim(g_oCacic.GetValueFromFile('Coletas','Hardware',g_oCacic.getLocalFolder + 'GER_COLS.inf'));

     g_oCacic.setValueToFile('Col_Hard','Fim', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

     // Se essas informações forem diferentes significa que houve alguma alteração
     // na configuração de hardware. Nesse caso, gravo as informações no BD Central
     // e, se não houver problemas durante esse procedimento, atualizo o registro local.
     If (g_oCacic.GetValueFromFile('Configs','IN_COLETA_FORCADA_HARD',g_oCacic.getLocalFolder + 'GER_COLS.inf')='S') or
         (g_oCacic.trimEspacosExcedentes(UVC) <> g_oCacic.trimEspacosExcedentes(ValorChaveRegistro)) Then
      Begin
        Try
        //Envio via rede para ao Agente Gerente, para gravação no BD.
        g_oCacic.setValueToFile('Col_Hard','te_Tripa_TCPIP'          , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_Tripa_TCPIP              )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_Tripa_CPU'            , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_Tripa_CPU                )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_Tripa_CDROM'          , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_Tripa_CDROM              )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_placa_mae_fabricante' , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_placa_mae_fabricante  )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_placa_mae_desc'       , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_placa_mae_desc        )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','qt_mem_ram'              , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( IntToStr(v_qt_mem_ram)     )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_mem_ram_desc'         , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_mem_ram_desc          )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_bios_desc'            , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_bios_desc             )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_bios_data'            , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_bios_data             )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_bios_fabricante'      , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_bios_fabricante       )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','qt_placa_video_cores'    , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_qt_placa_video_cores     )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_placa_video_desc'     , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_placa_video_desc      )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','qt_placa_video_mem'      , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_qt_placa_video_mem       )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_placa_video_resolucao', g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_placa_video_resolucao )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_placa_som_desc'       , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_placa_som_desc        )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_teclado_desc'         , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_teclado_desc          )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_mouse_desc'           , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_mouse_desc            )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','te_modem_desc'           , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( v_te_modem_desc            )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Col_Hard','UVC'                     , g_oCacic.enCrypt(g_oCacic.trimEspacosExcedentes( UVC                        )) , g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        Except
          g_oCacic.writeDailyLog('Problema em gravação de dados no DAT!');
        End;
      end
   else
    Begin
      g_oCacic.setValueToFile('Col_Hard','nada',g_oCacic.enCrypt('nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Hard','Fim' ,g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    End;
  Except
    Begin
      g_oCacic.setValueToFile('Col_Hard','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Hard','Fim' ,g_oCacic.enCrypt( '99999999'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.writeDailyLog('Problema na execução => ' + v_mensagem);
    End;
  End;
  g_oCacic.Free();
end;

// ATENÇÃO: Caso haja falha na execução deste agente pela estação de trabalho,
//          a provável causa será a falta da Runtime Library RTL70.BPL, que
//          costuma ser "confundida" com vírus e apagada por alguns anti-vírus
//          como o Avasti.
//          SOLUÇÃO: Baixar a partir do endereço http://nwvault.ign.com/View.php?view=Other.Detail&id=119 o pacote
//                   D70_Installer.zip, descompactar e executar na estação de trabalho.
const CACIC_APP_NAME = 'col_hard';
begin
   g_oCacic := TCACIC.Create();
   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) )  then
      if (ParamCount>0) then
          Begin
            g_oCacic.setLocalFolder( g_oCacic.GetParam('LocalFolder') );

            if (g_oCacic.getLocalFolder <> '') then
              Begin
                 g_oCacic.checkDebugMode;

                 Try
                    Executa_Col_Hard;
                 Except
                    g_oCacic.setValueToFile('Col_Hard','nada', g_oCacic.enCrypt('nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
                 End;
                 Halt(0);
              End;
          End;
end.
