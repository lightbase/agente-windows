unit coleta_unidades_disco;

interface

Uses Registry, Classes, SysUtils, Windows, dialogs;

procedure RealizarColetaUnidadesDisco;

implementation

Uses main, comunicacao, registro;


procedure RealizarColetaUnidadesDisco;
var ValorChaveRegistro, strXML,  strAux, id_tipo_unid_disco: String;
    I: Integer;
    Request_RCUD: TStringList;
Begin

   if (CS_COLETA_UNID_DISC) Then
   Begin
        main.frmMain.Log_Historico('* Coletando informações de unidades de disco.');

        strXML := '<?xml version="1.0" encoding="ISO-8859-1"?>' +
                  '<unidades>' +
                  '<te_node_address>' + TE_NODE_ADDRESS + '</te_node_address>' +
                  '<te_nome_computador>' + TE_NOME_COMPUTADOR + '</te_nome_computador>' +
                  '<te_workgroup>' + te_workgroup + '</te_workgroup>' +
                  '<id_so>' + ID_SO + '</id_so>';

        main.frmMain.MSystemInfo.Disk.GetInfo;
        with main.frmMain.MSystemInfo.Disk do
        begin
          for i:=1 to length(AvailableDisks) do
          begin
             strAux := UpperCase(Copy(AvailableDisks,i,1) + ':\');
             Drive := copy(strAux,1,2);

             id_tipo_unid_disco := GetMediaTypeStr(MediaType);
             { if (UpperCase(id_tipo_unid_disco) = 'REMOVABLE') then id_tipo_unid_disco := '1'
             else if (UpperCase(id_tipo_unid_disco) = 'CDROM') then id_tipo_unid_disco := '3'
             else if (UpperCase(id_tipo_unid_disco) = 'REMOTE') then id_tipo_unid_disco := '4'
             else id_tipo_unid_disco := '';  }
             // Decidi que só me interessa unidades de HD.
             if (UpperCase(id_tipo_unid_disco) = 'FIXED') then
             Begin
                 id_tipo_unid_disco := '2';
                 strXML := strXML + '<unidade>' +
                                       '<te_letra>' + Drive + '</te_letra>';
                 if ((id_tipo_unid_disco = '2') or (id_tipo_unid_disco = '4')) then strXML := strXML +
                                       '<cs_sist_arq>' + FileSystem + '</cs_sist_arq>' +
                                       '<nu_serial>' + SerialNumber + '</nu_serial>' +
                                       '<nu_capacidade>' + IntToStr(Capacity  div 10485760) + '0</nu_capacidade>' +  // Em MB  - Coleta apenas de 10 em 10 MB
                                       '<nu_espaco_livre>' + IntToStr(FreeSpace div 10485760 ) + '0</nu_espaco_livre>'; // Em MB  - Coleta apenas de 10 em 10 MB
                 if (id_tipo_unid_disco = '4') then strXML := strXML +
                                       '<te_unc>' + ExpandUNCFilename(Drive) + '</te_unc>';
                 strXML := strXML +    '<id_tipo_unid_disco>' + id_tipo_unid_disco +  '</id_tipo_unid_disco>' +
                                  '</unidade>';
             end;
          end;
        end;

        strXML := strXML + '</unidades>';

        // Obtenho do registro o valor que foi previamente armazenado
        ValorChaveRegistro := Trim(Registro.GetValorChaveRegIni('Coleta','UnidadesDisco',p_path_cacic_ini));

        // Se essas informações forem diferentes significa que houve alguma alteração
        // na configuração. Nesse caso, gravo as informações no BD Central e, se não houver
        // problemas durante esse procedimento, atualizo as informações no registro.
        If (IN_COLETA_FORCADA or (strXML <> ValorChaveRegistro)) Then
        Begin
           //Envio via rede para ao Agente Gerente, para gravação no BD.
           Request_RCUD:=TStringList.Create;
           Request_RCUD.Values['unidades'] := strXML;

           // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
           //Sobreponho a informação no registro para posterior comparação, na próxima execução.
           if (comunicacao.ComunicaServidor('set_unid_discos.php', Request_RCUD, '>> Enviando informações de Unidades de Disco para o servidor.') <> '0') Then
              Registro.SetValorChaveRegIni('Coleta','UnidadesDisco', strXML,p_path_cacic_ini);
           Request_RCUD.Free;
        end;
   end;
end;



end.
