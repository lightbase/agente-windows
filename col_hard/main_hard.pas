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
unit main_hard;

interface

uses Windows, Messages, SysUtils, Classes, Forms, IniFiles, ExtCtrls, Controls, MSI_GUI, MSI_Devices, MSI_CPU;
var  p_path_cacic, p_path_cacic_ini : string;
type
  Tfrm_col_hard = class(TForm)
    MSystemInfo1: TMSystemInfo;
    procedure FormCreate(Sender: TObject);
  private
    procedure Executa_Col_Hard;
    procedure Log_Historico(strMsg : String);
    function  SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
    Function  Crip(PNome: String): String;
    Function  DesCrip(PNome: String): String;
//    Function  GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
    function  GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    Function  Explode(Texto, Separador : String) : TStrings;
    Function  GetRootKey(strRootKey: String): HKEY;
    Function  RemoveCaracteresEspeciais(Texto : String) : String;
  public
  end;

var
  frm_col_hard: Tfrm_col_hard;

implementation

{$R *.dfm}

//uses MSI_CPU, MSI_Devices, MiTeC_WinIOCTL, NB30;
//MSI_Devices, MSI_CPU, MSI_GUI,

//Para gravar no Arquivo INI...
function Tfrm_col_hard.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
begin
    FileSetAttr (p_Path,0);
    Reg_Ini := TIniFile.Create(p_Path);
//    Reg_Ini.WriteString(frm_col_hard.Crip(p_Secao), frm_col_hard.Crip(p_Chave), frm_col_hard.Crip(p_Valor));
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
//function Tfrm_col_hard.GetValorChaveRegIni(p_Secao: String; p_Chave : String; p_Path : String): String;
//var Reg_Ini: TIniFile;
//begin
//    FileSetAttr (p_Path,0);
//    Reg_Ini := TIniFile.Create(p_Path);
////    Result  := frm_col_hard.DesCrip(Reg_Ini.ReadString(frm_col_hard.Crip(p_Secao), frm_col_hard.Crip(p_Chave), ''));
//    Result  := Reg_Ini.ReadString(p_Secao, p_Chave, '');
//    Reg_Ini.Free;
//end;
//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function Tfrm_col_hard.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
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

Function Tfrm_col_hard.Explode(Texto, Separador : String) : TStrings;
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

function Tfrm_col_hard.GetRootKey(strRootKey: String): HKEY;
begin
    /// Encontrar uma maneira mais elegante de fazer esses testes.
    if      Trim(strRootKey) = 'HKEY_LOCAL_MACHINE'   Then Result := HKEY_LOCAL_MACHINE
    else if Trim(strRootKey) = 'HKEY_CLASSES_ROOT'    Then Result := HKEY_CLASSES_ROOT
    else if Trim(strRootKey) = 'HKEY_CURRENT_USER'    Then Result := HKEY_CURRENT_USER
    else if Trim(strRootKey) = 'HKEY_USERS'           Then Result := HKEY_USERS
    else if Trim(strRootKey) = 'HKEY_CURRENT_CONFIG'  Then Result := HKEY_CURRENT_CONFIG
    else if Trim(strRootKey) = 'HKEY_DYN_DATA'        Then Result := HKEY_DYN_DATA;
end;

Function Tfrm_col_hard.RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;


procedure Tfrm_col_hard.Executa_Col_Hard;
var InfoSoft : TStringList;
    v_te_cpu_freq, v_te_cpu_fabricante, v_te_cpu_desc, v_te_cpu_serial, v_te_placa_rede_desc, v_te_placa_som_desc, v_te_cdrom_desc, v_te_teclado_desc,
    v_te_modem_desc, v_te_mouse_desc, v_qt_mem_ram, v_te_mem_ram_desc, v_qt_placa_video_mem, v_te_placa_video_resolucao, v_te_placa_video_desc,
    v_qt_placa_video_cores, v_te_bios_fabricante, v_te_bios_data, v_te_bios_desc,
    v_te_placa_mae_fabricante, v_te_placa_mae_desc,
    ValorChaveColetado, ValorChaveRegistro : String;
    i : Integer;
begin
  Try
     frm_col_hard.Log_Historico('* Coletando informações de Hardware.');

     Try frm_col_hard.MSysteminfo1.CPU.GetInfo(False, False); except end;
     Try frm_col_hard.MSysteminfo1.Machine.GetInfo(0); except end;
     Try frm_col_hard.MSysteminfo1.Machine.SMBIOS.GetInfo(1);except end;
     Try frm_col_hard.MSysteminfo1.Display.GetInfo; except end;
     Try frm_col_hard.MSysteminfo1.Media.GetInfo; except end;
     Try frm_col_hard.MSysteminfo1.Devices.GetInfo; except end;
     Try frm_col_hard.MSysteminfo1.Memory.GetInfo; except end;
     Try frm_col_hard.MSysteminfo1.OS.GetInfo; except end;
//       frm_col_hard.MSysteminfo1.Software.GetInfo;
//       frm_col_hard.MSysteminfo1.Software.Report(InfoSoft);


     //Try frm_col_hard.MSysteminfo1.Storage.GetInfo; except end;


     if (frm_col_hard.MSysteminfo1.Network.CardAdapterIndex > -1) then v_te_placa_rede_desc := frm_col_hard.MSysteminfo1.Network.Adapters[frm_col_hard.MSysteminfo1.Network.CardAdapterIndex]
     else v_te_placa_rede_desc := frm_col_hard.MSysteminfo1.Network.Adapters[0];
     v_te_placa_rede_desc := Trim(v_te_placa_rede_desc);


     if (frm_col_hard.MSysteminfo1.Media.Devices.Count > 0) then
        if (frm_col_hard.MSysteminfo1.Media.SoundCardIndex > -1) then v_te_placa_som_desc := frm_col_hard.MSysteminfo1.Media.Devices[frm_col_hard.MSysteminfo1.Media.SoundCardIndex]
        else v_te_placa_som_desc := frm_col_hard.MSysteminfo1.Media.Devices[0];

     v_te_placa_som_desc := Trim(v_te_placa_som_desc);


     for i:=0 to frm_col_hard.MSysteminfo1.Devices.DeviceCount-1 do
     Begin
        if frm_col_hard.MSysteminfo1.Devices.Devices[i].DeviceClass=dcCDROM then
            if Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName)='' then  v_te_cdrom_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].Description)
            else v_te_cdrom_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName);
        if frm_col_hard.MSysteminfo1.Devices.Devices[i].DeviceClass=dcModem then
            if Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName)='' then v_te_modem_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].Description)
            else v_te_modem_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName);
        if frm_col_hard.MSysteminfo1.Devices.Devices[i].DeviceClass=dcMouse then
            if Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName)='' then v_te_mouse_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].Description)
            else v_te_mouse_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName);
        if frm_col_hard.MSysteminfo1.Devices.Devices[i].DeviceClass=dcKeyboard then
            if Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName)='' then v_te_teclado_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].Description)
            else v_te_teclado_desc := Trim(frm_col_hard.MSysteminfo1.Devices.Devices[i].FriendlyName);
     end;


     v_te_mem_ram_desc := '';
     Try
//        for i:=0 to frm_col_hard.MSysteminfo1.Machine.SMBIOS.MemoryModuleCount-1 do
        for i:=0 to frm_col_hard.MSysteminfo1.Machine.SMBIOS.MemorySlotCount-1 do
//        if (frm_col_hard.MSysteminfo1.Machine.SMBIOS.MemoryModule[i].Size > 0) then
        if (frm_col_hard.MSysteminfo1.Machine.SMBIOS.MemoryBank[i].Size > 0) then
        begin
            v_te_mem_ram_desc := v_te_mem_ram_desc + IntToStr(frm_col_hard.MSysteminfo1.Machine.SMBIOS.MemoryBank[i].Size) + ' ' +
                           frm_col_hard.MSysteminfo1.Machine.SMBIOS.GetMemoryTypeStr(frm_col_hard.MSysteminfo1.Machine.SMBIOS.MemoryBank[i].Types) + ' ';
        end;
     Except
     end;

     v_te_mem_ram_desc := Trim(v_te_mem_ram_desc);
     v_qt_mem_ram := IntToStr((frm_col_hard.MSysteminfo1.Memory.PhysicalTotal div 1048576) + 1);

     Try
       v_te_placa_mae_fabricante := Trim(frm_col_hard.MSysteminfo1.Machine.SMBIOS.MainboardManufacturer);
       v_te_placa_mae_desc       := Trim(frm_col_hard.MSysteminfo1.Machine.SMBIOS.MainboardModel);
     Except
     end;

     Try
       v_te_cpu_serial     := Trim(frm_col_hard.MSystemInfo1.CPU.SerialNumber);
       v_te_cpu_desc       := Trim(frm_col_hard.MSystemInfo1.CPU.FriendlyName + ' ' + frm_col_hard.MSystemInfo1.CPU.CPUIDNameString);
       v_te_cpu_fabricante := CPUVendors[frm_col_hard.MSystemInfo1.CPU.vendorType];
       v_te_cpu_freq       := IntToStr(frm_col_hard.MSystemInfo1.CPU.Frequency);
     Except
     end;

     Try
         v_te_bios_desc       := Trim(frm_col_hard.MSysteminfo1.Machine.BIOS.Name);
         v_te_bios_data       := Trim(frm_col_hard.MSysteminfo1.Machine.BIOS.Date);
         v_te_bios_fabricante := Trim(frm_col_hard.MSysteminfo1.Machine.BIOS.Copyright);
     Except
     End;

     Try
         v_qt_placa_video_cores     := IntToStr(frm_col_hard.MSysteminfo1.Display.ColorDepth);
         v_te_placa_video_desc      := Trim(frm_col_hard.MSysteminfo1.Display.Adapter);
         v_qt_placa_video_mem       := IntToStr((frm_col_hard.MSysteminfo1.Display.Memory) div 1048576 );
         v_te_placa_video_resolucao := IntToStr(frm_col_hard.MSysteminfo1.Display.HorzRes) + 'x' + IntToStr(frm_col_hard.MSysteminfo1.Display.VertRes);
     Except
     End;
     {
     for i:=0 to frm_col_hard.MSysteminfo1.Storage.DeviceCount-1 do
     if (frm_col_hard.MSysteminfo1.Storage.Devices[i].Geometry.MediaType = Fixedmedia) Then
     Begin
       DescHDs := frm_col_hard.MSysteminfo1.Storage.Devices[i].Model + IntToStr((frm_col_hard.MSysteminfo1.Storage.Devices[i].Capacity div 1024) div 1024);
     end;
      }



     // Monto a string que será comparada com o valor armazenado no registro.
     ValorChaveColetado := Trim(v_te_placa_rede_desc + ';' +
         v_te_cpu_fabricante  + ';' +
         v_te_cpu_desc  + ';' +
         // Como a frequência não é constante, ela não vai entrar na verificação da mudança de hardware.
         // IntToStr(frm_col_hard.MSysteminfo1.CPU.Frequency)  + ';' +
         v_te_cpu_serial  + ';' +
         v_te_mem_ram_desc  + ';' +
         v_qt_mem_ram  + ';' +
         v_te_bios_desc  + ';' +
         v_te_bios_data  + ';' +
         v_te_bios_fabricante + ';' +
         v_te_placa_mae_fabricante + ';' +
         v_te_placa_mae_desc + ';' +
         v_te_placa_video_desc + ';' +
         v_te_placa_video_resolucao + ';' +
         v_qt_placa_video_cores  + ';' +
         v_qt_placa_video_mem + ';' +
         v_te_placa_som_desc + ';' +
         v_te_cdrom_desc + ';' +
         v_te_teclado_desc + ';' +
         v_te_modem_desc + ';' +
         v_te_mouse_desc);


     // Obtenho do registro o valor que foi previamente armazenado
     ValorChaveRegistro := Trim(GetValorChaveRegIni('Coleta','Hardware',p_path_cacic_ini));

     // Se essas informações forem diferentes significa que houve alguma alteração
     // na configuração de hardware. Nesse caso, gravo as informações no BD Central
     // e, se não houver problemas durante esse procedimento, atualizo as
     // informações no registro.

     If (GetValorChaveRegIni('Configs','IN_COLETA_FORCADA_HARD',p_path_cacic_ini)='S') or (ValorChaveColetado <> ValorChaveRegistro) Then
      Begin
        //Envio via rede para ao Agente Gerente, para gravação no BD.
        SetValorChaveRegIni('Col_Hard','te_placa_rede_desc'      , v_te_placa_rede_desc      , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_placa_mae_fabricante' , v_te_placa_mae_fabricante , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_placa_mae_desc'       , v_te_placa_mae_desc       , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_cpu_serial'           , v_te_cpu_serial           , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_cpu_desc'             , v_te_cpu_desc             , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_cpu_fabricante'       , v_te_cpu_fabricante       , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_cpu_freq'             , v_te_cpu_freq             , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','qt_mem_ram'              , v_qt_mem_ram              , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_mem_ram_desc'         , v_te_mem_ram_desc         , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_bios_desc'            , v_te_bios_desc            , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_bios_data'            , v_te_bios_data            , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_bios_fabricante'      , v_te_bios_fabricante      , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','qt_placa_video_cores'    , v_qt_placa_video_cores    , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_placa_video_desc'     , v_te_placa_video_desc     , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','qt_placa_video_mem'      , v_qt_placa_video_mem      , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_placa_video_resolucao', v_te_placa_video_resolucao, frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_placa_som_desc'       , v_te_placa_som_desc       , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_cdrom_desc'           , v_te_cdrom_desc           , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_teclado_desc'         , v_te_teclado_desc         , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_mouse_desc'           , v_te_mouse_desc           , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','te_modem_desc'           , v_te_modem_desc           , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        SetValorChaveRegIni('Col_Hard','ValorChaveColetado'      , ValorChaveColetado      , frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');

      end
   else SetValorChaveRegIni('Col_Hard','nada', 'nada', frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
   Application.terminate
  Except
    SetValorChaveRegIni('Col_Hard','nada', 'nada', frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
    Application.terminate;
  End;
end;


procedure Tfrm_col_hard.Log_Historico(strMsg : String);
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
Function Tfrm_col_hard.Crip(PNome: String): String;
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

Function Tfrm_col_hard.DesCrip(PNome: String): String;
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

procedure Tfrm_col_hard.FormCreate(Sender: TObject);
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

     Try
        Executa_Col_Hard;
     Except
        SetValorChaveRegIni('Col_Hard','nada', 'nada', frm_col_hard.GetValorChaveRegIni('Configs','P_PATH_COLETAS_INI',p_path_cacic + 'cacic2.ini')+'col_hard.ini');
        Application.terminate;
     End;
end;

end.
