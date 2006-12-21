unit coleta_hardware;

interface

uses Windows, Registry, SysUtils, Classes, dialogs;

procedure RealizarColetaHardware;
function GetMACAdress: string;

implementation


Uses main, comunicacao, utils, registro, MSI_CPU, MSI_Devices, MiTeC_WinIOCTL, NB30 ;



function GetMACAdress: string;
var
  NCB: PNCB;
  Adapter: PAdapterStatus;

  URetCode: PChar;
  RetCode: char;
  I: integer;
  Lenum: PlanaEnum;
  _SystemID: string;
  TMPSTR: string;
begin
  Result    := ''; 
  _SystemID := '';
  Getmem(NCB, SizeOf(TNCB)); 
  Fillchar(NCB^, SizeOf(TNCB), 0); 

  Getmem(Lenum, SizeOf(TLanaEnum)); 
  Fillchar(Lenum^, SizeOf(TLanaEnum), 0); 

  Getmem(Adapter, SizeOf(TAdapterStatus));
  Fillchar(Adapter^, SizeOf(TAdapterStatus), 0); 

  Lenum.Length    := chr(0); 
  NCB.ncb_command := chr(NCBENUM); 
  NCB.ncb_buffer  := Pointer(Lenum); 
  NCB.ncb_length  := SizeOf(Lenum); 
  RetCode         := Netbios(NCB); 

  i := 0; 
  repeat 
    Fillchar(NCB^, SizeOf(TNCB), 0);
    Ncb.ncb_command  := chr(NCBRESET);
    Ncb.ncb_lana_num := lenum.lana[I]; 
    RetCode          := Netbios(Ncb);

    Fillchar(NCB^, SizeOf(TNCB), 0); 
    Ncb.ncb_command  := chr(NCBASTAT); 
    Ncb.ncb_lana_num := lenum.lana[I];
    // Must be 16 
    Ncb.ncb_callname := '*               '; 

    Ncb.ncb_buffer := Pointer(Adapter); 

    Ncb.ncb_length := SizeOf(TAdapterStatus); 
    RetCode        := Netbios(Ncb); 
    //---- calc _systemId from mac-address[2-5] XOR mac-address[1]...
    if (RetCode = chr(0)) or (RetCode = chr(6)) then
    begin
      _SystemId := IntToHex(Ord(Adapter.adapter_address[0]), 2) + '-' +
        IntToHex(Ord(Adapter.adapter_address[1]), 2) + '-' + 
        IntToHex(Ord(Adapter.adapter_address[2]), 2) + '-' + 
        IntToHex(Ord(Adapter.adapter_address[3]), 2) + '-' + 
        IntToHex(Ord(Adapter.adapter_address[4]), 2) + '-' + 
        IntToHex(Ord(Adapter.adapter_address[5]), 2); 
    end;
    Inc(i);
  until (I >= Ord(Lenum.Length)) or (_SystemID <> '00-00-00-00-00-00');
  FreeMem(NCB); 
  FreeMem(Adapter);
  FreeMem(Lenum);
  GetMacAdress := _SystemID;
end;





procedure RealizarColetaHardware;
var Request_RCH, InfoSoft : TStringList;
    DescPlacaRede, DescPlacaSom, DescCDROM, DescTeclado, DescModem, DescMouse, QtdMemoria, DescMemoria,
    DescHDs, te_placa_mae_fabricante, te_placa_mae_desc,
    ValorChaveColetado, ValorChaveRegistro, s : String;
    i, c : Integer;
begin
   // Verifica se deverá ser realizada a coleta de informações de hardware neste
   // computador, perguntando ao agente gerente.
   if (CS_COLETA_HARDWARE) Then
   Begin
       main.frmMain.Log_Historico('* Coletando informações de hardware.');

       Try main.frmMain.MSystemInfo.CPU.GetInfo(False, False); except end;
       Try main.frmMain.MSystemInfo.Machine.GetInfo(0); except end;
       Try main.frmMain.MSystemInfo.Machine.SMBIOS.GetInfo(1);except end;
       Try main.frmMain.MSystemInfo.Display.GetInfo; except end;
       Try main.frmMain.MSystemInfo.Media.GetInfo; except end;
       Try main.frmMain.MSystemInfo.Devices.GetInfo; except end;
       Try main.frmMain.MSystemInfo.Memory.GetInfo; except end;
       Try main.frmMain.MSystemInfo.OS.GetInfo; except end;
//       main.frmMain.MSystemInfo.Software.GetInfo;
//       main.frmMain.MSystemInfo.Software.Report(InfoSoft);


       //Try main.frmMain.MSystemInfo.Storage.GetInfo; except end;


       if (main.frmMain.MSystemInfo.Network.CardAdapterIndex > -1) then DescPlacaRede := main.frmMain.MSystemInfo.Network.Adapters[main.frmMain.MSystemInfo.Network.CardAdapterIndex]
       else DescPlacaRede := main.frmMain.MSystemInfo.Network.Adapters[0];
       DescPlacaRede := Trim(DescPlacaRede);


       if (main.frmMain.MSystemInfo.Media.Devices.Count > 0) then
          if (main.frmMain.MSystemInfo.Media.SoundCardIndex > -1) then DescPlacaSom := main.frmMain.MSystemInfo.Media.Devices[main.frmMain.MSystemInfo.Media.SoundCardIndex]
          else DescPlacaSom := main.frmMain.MSystemInfo.Media.Devices[0];

       DescPlacaSom := Trim(DescPlacaSom);


       for i:=0 to main.frmMain.MSystemInfo.Devices.DeviceCount-1 do
       Begin
          if main.frmMain.MSystemInfo.Devices.Devices[i].DeviceClass=dcCDROM then
              if Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName)='' then  DescCDROM := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].Description)
              else DescCDROM := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName);
          if main.frmMain.MSystemInfo.Devices.Devices[i].DeviceClass=dcModem then
              if Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName)='' then DescModem := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].Description)
              else DescModem := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName);
          if main.frmMain.MSystemInfo.Devices.Devices[i].DeviceClass=dcMouse then
              if Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName)='' then DescMouse := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].Description)
              else DescMouse := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName);
          if main.frmMain.MSystemInfo.Devices.Devices[i].DeviceClass=dcKeyboard then
              if Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName)='' then DescTeclado := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].Description)
              else DescTeclado := Trim(main.frmMain.MSystemInfo.Devices.Devices[i].FriendlyName);
       end;


       DescMemoria := '';
       Try
          for i:=0 to main.frmMain.MSystemInfo.Machine.SMBIOS.MemoryModuleCount-1 do
          if (main.frmMain.MSystemInfo.Machine.SMBIOS.MemoryModule[i].Size > 0) then
          begin
              DescMemoria := DescMemoria + IntToStr(main.frmMain.MSystemInfo.Machine.SMBIOS.MemoryModule[i].Size) + ' ' +
                             main.frmMain.MSystemInfo.Machine.SMBIOS.GetMemoryTypeStr(main.frmMain.MSystemInfo.Machine.SMBIOS.MemoryModule[i].Types) + ' ';
          end;
       Except
       end;

       DescMemoria := Trim(DescMemoria);
       QtdMemoria := IntToStr((main.frmMain.MSystemInfo.Memory.PhysicalTotal div 1048576) + 1);

       Try
         te_placa_mae_fabricante := Trim(main.frmMain.MSystemInfo.Machine.SMBIOS.MainboardManufacturer);
         te_placa_mae_desc       := Trim(main.frmMain.MSystemInfo.Machine.SMBIOS.MainboardModel);
       Except
       end;


       {
       for i:=0 to main.frmMain.MSystemInfo.Storage.DeviceCount-1 do
       if (main.frmMain.MSystemInfo.Storage.Devices[i].Geometry.MediaType = Fixedmedia) Then
       Begin
         DescHDs := main.frmMain.MSystemInfo.Storage.Devices[i].Model + IntToStr((main.frmMain.MSystemInfo.Storage.Devices[i].Capacity div 1024) div 1024);
       end;
        }


       // Monto a string que será comparada com o valor armazenado no registro.
       ValorChaveColetado := Trim(DescPlacaRede + ';' +
           CPUVendors[main.frmMain.MSystemInfo.CPU.vendorType]  + ';' +
           main.frmMain.MSystemInfo.CPU.FriendlyName + '  ' + main.frmMain.MSystemInfo.CPU.CPUIDNameString  + ';' +
           // Como a frequência não é constante, ela não vai entrar na verificação da mudança de hardware.
           // IntToStr(main.frmMain.MSystemInfo.CPU.Frequency)  + ';' +
           main.frmMain.MSystemInfo.CPU.SerialNumber  + ';' +
           DescMemoria  + ';' +
           QtdMemoria  + ';' +
           main.frmMain.MSystemInfo.Machine.BIOS.Name  + ';' +
           main.frmMain.MSystemInfo.Machine.BIOS.Date  + ';' +
           main.frmMain.MSystemInfo.Machine.BIOS.Copyright + ';' +
           te_placa_mae_fabricante + ';' +
           te_placa_mae_desc + ';' +
           main.frmMain.MSystemInfo.Display.Adapter + ';' +
           IntToStr(main.frmMain.MSystemInfo.Display.HorzRes) + 'x' + IntToStr(main.frmMain.MSystemInfo.Display.VertRes) + ';' +
           IntToStr(main.frmMain.MSystemInfo.Display.ColorDepth)  + ';' +
           IntToStr((main.frmMain.MSystemInfo.Display.Memory) div 1048576 )  + ';' +
           DescPlacaSom + ';' +
           DescCDROM + ';' +
           DescTeclado + ';' +
           DescModem + ';' +
           DescMouse);

       // Obtenho do registro o valor que foi previamente armazenado
       ValorChaveRegistro := Trim(Registro.GetValorChaveRegIni('Coleta','Hardware',p_path_cacic_ini));

       // Se essas informações forem diferentes significa que houve alguma alteração
       // na configuração de hardware. Nesse caso, gravo as informações no BD Central
       // e, se não houver problemas durante esse procedimento, atualizo as
       // informações no registro.
       If (IN_COLETA_FORCADA or (ValorChaveColetado <> ValorChaveRegistro)) Then
       Begin
          //Envio via rede para ao Agente Gerente, para gravação no BD.
          Request_RCH:=TStringList.Create;
          Request_RCH.Values['te_node_address']         := TE_NODE_ADDRESS;
          Request_RCH.Values['id_so']                   := ID_SO;
          Request_RCH.Values['te_nome_computador']      := TE_NOME_COMPUTADOR;
          Request_RCH.Values['id_ip_rede']              := ID_IP_REDE;
          Request_RCH.Values['te_ip']                   := TE_IP;
          Request_RCH.Values['te_workgroup']            := TE_WORKGROUP;
          Request_RCH.Values['te_placa_rede_desc']      := DescPlacaRede;
          Request_RCH.Values['te_placa_mae_fabricante'] := te_placa_mae_fabricante;
          Request_RCH.Values['te_placa_mae_desc']       := te_placa_mae_desc;
          Request_RCH.Values['te_cpu_serial']           := Trim(main.frmMain.MSystemInfo.CPU.SerialNumber);
          Request_RCH.Values['te_cpu_desc']             := Trim(main.frmMain.MSystemInfo.CPU.FriendlyName + ' ' + main.frmMain.MSystemInfo.CPU.CPUIDNameString);
          Request_RCH.Values['te_cpu_fabricante']       := CPUVendors[main.frmMain.MSystemInfo.CPU.vendorType];
          Request_RCH.Values['te_cpu_freq']             := IntToStr(main.frmMain.MSystemInfo.CPU.Frequency);
          Request_RCH.Values['qt_mem_ram']              := QtdMemoria;
          Request_RCH.Values['te_mem_ram_desc']         := DescMemoria;
          Request_RCH.Values['te_bios_desc']            := Trim(main.frmMain.MSystemInfo.Machine.BIOS.Name);
          Request_RCH.Values['te_bios_data']            := Trim(main.frmMain.MSystemInfo.Machine.BIOS.Date);
          Request_RCH.Values['te_bios_fabricante']      := Trim(main.frmMain.MSystemInfo.Machine.BIOS.Copyright);
          Request_RCH.Values['qt_placa_video_cores']    := IntToStr(main.frmMain.MSystemInfo.Display.ColorDepth);
          Request_RCH.Values['te_placa_video_desc']     := Trim(main.frmMain.MSystemInfo.Display.Adapter);
          Request_RCH.Values['qt_placa_video_mem']      := IntToStr((main.frmMain.MSystemInfo.Display.Memory) div 1048576);
          Request_RCH.Values['te_placa_video_resolucao']:= IntToStr(main.frmMain.MSystemInfo.Display.HorzRes) + 'x' + IntToStr(main.frmMain.MSystemInfo.Display.VertRes);
          Request_RCH.Values['te_placa_som_desc']       := DescPlacaSom;
          Request_RCH.Values['te_cdrom_desc']           := DescCDROM;
          Request_RCH.Values['te_teclado_desc']         := DescTeclado;
          Request_RCH.Values['te_mouse_desc']           := DescMouse;
          Request_RCH.Values['te_modem_desc']           := DescModem;

          // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
          //Sobreponho a informação no registro para posterior comparação, na próxima execução.
          if (comunicacao.ComunicaServidor('set_hardware.php', Request_RCH, '>> Enviando informações de hardware para o servidor.') <> '0') Then
          Begin
             Registro.SetValorChaveRegIni('Coleta','Hardware', ValorChaveColetado,p_path_cacic_ini);
          end;
          Request_RCH.Free;
       end;
   end
   else main.frmMain.Log_Historico('Coleta de informações de hardware não configurada.');

end;


end.

