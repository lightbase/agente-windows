unit coleta_monitorado;

interface

uses Windows, Registry, SysUtils, Classes, dialogs;

procedure RealizarColetaMonitorado;

implementation


Uses main, comunicacao, utils, registro, Math;

procedure RealizarColetaMonitorado;
var Request_RCH : TStringlist;
    tstrTripa2, tstrTripa3, v_array1, v_array2, v_array3, v_array4 : TStrings;
    strAux, strAux1, strAux3, strAux4, strTripa, ValorChavePerfis, ValorChaveColetado : String;
    intAux4, v1, v3, v_achei : Integer;
begin
   // Verifica se deverá ser realizada a coleta de informações de aplicativos monitorados neste
   // computador, perguntando ao agente gerente.
   if (CS_COLETA_MONITORADO) Then
   Begin
       main.frmMain.Log_Historico('* Coletando informações de aplicativos monitorados.');
       intAux4 := 1;
       strAux3 := '';
       ValorChavePerfis := '*';
       while ValorChavePerfis <> '' do
            begin
              strAux3 := 'APL' + trim(inttostr(intAux4));

             strTripa := ''; // Conterá as informações a serem enviadas ao Gerente.
             // Obtenho do registro o valor que foi previamente armazenado
             ValorChavePerfis := Trim(Registro.GetValorChaveRegIni('Coleta',strAux3, p_path_cacic_ini));
             if (ValorChavePerfis <> '') then
               Begin
               //Atenção, OS ELEMENTOS DEVEM ESTAR DE ACORDO COM A ORDEM QUE SÃO TRATADOS NO MÓDULO GERENTE.
                   tstrTripa2  := Utils.Explode(ValorChavePerfis,',');
                   if (strAux <> '') then strAux := strAux + '#';
                   strAux := strAux + trim(tstrTripa2[0]) + ',';


                   //Coleta de Informação de Licença
                   if (trim(tstrTripa2[2])='0') then //Vazio
                     Begin
                        strAux := strAux + ',';
                     End;
                   if (trim(tstrTripa2[2])='1') then //Caminho\Chave\Valor em Registry
                     Begin
                        strAux4 := Trim(Registro.GetValorChaveRegEdit(trim(tstrTripa2[3])));
                        if (strAux4 = '') then strAux4 := '?';
                        strAux  := strAux + strAux4 + ',';
                     End;
                   if (trim(tstrTripa2[2])='2') then //Nome\Seção\Chave de Arquivo INI
                     Begin
                        Try
                          if (LastPos('/',trim(tstrTripa2[3]))>0) then
                            Begin
                              tstrTripa3  := Utils.Explode(trim(tstrTripa2[3]),'\');
                              strAux4 := Trim(Registro.GetValorChaveRegIni(tstrTripa3[1],tstrTripa3[2],tstrTripa3[0]));
                              if (strAux4 = '') then strAux4 := '?';
                              strAux := strAux + strAux4 + ',';
                            End;
                          if (LastPos('\',trim(tstrTripa2[3]))=0) then
                            Begin
                              strAux := strAux + 'Parâm.Lic.Incorreto,';
                            End
                        Except
                            strAux := strAux + 'Parâm.Lic.Incorreto,';
                        End;
                     End;


                   //Coleta de Informação de Instalação
                   if (trim(tstrTripa2[4])='0') then //Vazio
                     Begin
                        strAux := strAux + ',';
                     End;

                   if (trim(tstrTripa2[4])='1') or (trim(tstrTripa2[4]) = '2') then //Nome de Executável OU Nome de Arquivo de Configuração (CADPF!!!)
                     Begin
                      strAux1 := trim(utils.FileSearch('\',trim(tstrTripa2[5])));
                      if (strAux1 <> '') then strAux := strAux + 'S,';
                      if (strAux1 = '') then strAux := strAux + 'N,';
                     End;

                   if (trim(tstrTripa2[4])='3') then //Caminho\Chave\Valor em Registry
                     Begin
                      strAux1 := Trim(Registro.GetValorChaveRegEdit(trim(tstrTripa2[5])));
                      if (strAux1 <> '') then strAux := strAux + 'S,';
                      if (strAux1 = '') then strAux := strAux + 'N,';
                     End;


                   //Coleta de Informação de Versão
                   if (trim(tstrTripa2[6])='0') then //Vazio
                     Begin
                        strAux := strAux + ',';
                     End;

                   if (trim(tstrTripa2[6])='1') then //Data de Arquivo
                     Begin
                      strAux1 := trim(utils.FileSearch('\',trim(tstrTripa2[7])));
                      if (strAux1 <> '') then
                        Begin
                          strAux := strAux + DateToStr(FileDateToDateTime(FileAge(strAux1)))+',';
                        End;
                      if (strAux1 = '') then strAux := strAux + '?,';
                     End;

                   if (trim(tstrTripa2[6])='2') then //Caminho\Chave\Valor em Registry
                     Begin
                      strAux1 := Trim(Registro.GetValorChaveRegEdit(trim(tstrTripa2[7])));
                      if (strAux1 <> '') then strAux := strAux + strAux1 + ',';
                      if (strAux1 = '') then strAux := strAux + '?,';
                     End;

                   if (trim(tstrTripa2[6])='3') then //Nome\Seção\Chave de Arquivo INI
                     Begin
                        Try
                          if (LastPos('\',trim(tstrTripa2[7]))>0) then
                            Begin
                              tstrTripa3  := Utils.Explode(trim(tstrTripa2[7]),'\');
                              strAux4 := Trim(Registro.GetValorChaveRegIni(tstrTripa3[1],tstrTripa3[2],tstrTripa3[0]));
                              if (strAux4 = '') then strAux4 := '?';
                              strAux := strAux + strAux4 + ',';

                            End;
                          if (LastPos('\',trim(tstrTripa2[7]))=0) then
                            Begin
                              strAux := strAux + 'Parâm.Versao Incorreto,';
                            End
                        Except
                            strAux := strAux + 'Parâm.Versao Incorreto,';
                        End;
                     End;

                   //Coleta de Informação de Engine
                   if (trim(tstrTripa2[8])='.') then //Vazio
                     Begin
                        strAux := strAux + ',';
                     End;
                   //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
                   if (trim(tstrTripa2[8])<>'.') then //Arquivo para Versão de Engine
                     Begin
                      strAux1 := trim(utils.FileSearch('\',trim(tstrTripa2[8])));
                      if (strAux1 <> '') then
                        Begin
                          tstrTripa3 := utils.Explode(utils.getVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                          strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                        End;
                      if (strAux1 = '') then strAux := strAux + '?,';
                     End;

                   //Coleta de Informação de Pattern
                   //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
                   if (trim(tstrTripa2[9])<>'.') then //Arquivo para Versão de Pattern
                     Begin
                      strAux1 := trim(utils.FileSearch('\',trim(tstrTripa2[9])));
                      if (strAux1 <> '') then
                        Begin
                          tstrTripa3 := utils.Explode(utils.getVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                          strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                        End;
                      if (strAux1 = '') then strAux := strAux + '?,';
                     End;
               End;
              intAux4 := intAux4 + 1;
         End;

       ValorChaveColetado := Trim(Registro.GetValorChaveRegIni('Coleta','APLICATIVOS_MONITORADOS_COLETADOS', p_path_cacic_ini));
If ((trim(strAux) <> trim(ValorChaveColetado)) and (trim(ValorChaveColetado) <> '')) Then
  begin
      v_array1  :=  utils.Explode(strAux, '#');
      strAux    :=  '';
      v_array3  :=  utils.Explode(ValorChaveColetado, '#');
      for v1 := 0 to (v_array1.count)-1 do
        Begin
          v_array2  :=  utils.Explode(v_array1[v1], ',');
          v_achei   :=  0;
          for v3 := 0 to (v_array3.count)-1 do
            Begin
              v_array4  :=  utils.Explode(v_array3[v3], ',');
              if (v_array4=v_array2) then v_achei := 1;
            End;
          if (v_achei = 0) then
            Begin
              if (strAUX <> '') then strAUX :=  strAUX + '#';
              strAUX  :=  strAUX + v_array1[v1];
            End;
        End;
  end;


       // Se essas informações forem diferentes significa que houve alguma alteração
       // na configuração de hardware. Nesse caso, gravo as informações no BD Central
       // e, se não houver problemas durante esse procedimento, atualizo as
       // informações no registro.
       If (IN_COLETA_FORCADA or (trim(strAux) <> trim(ValorChaveColetado))) Then
       Begin
          //Envio via rede para ao Agente Gerente, para gravação no BD.
          Request_RCH:=TStringList.Create;
          Request_RCH.Values['te_node_address']         := TE_NODE_ADDRESS;
          Request_RCH.Values['id_so']                   := ID_SO;
          Request_RCH.Values['te_nome_computador']      := TE_NOME_COMPUTADOR;
          Request_RCH.Values['id_ip_rede']              := ID_IP_REDE;
          Request_RCH.Values['te_ip']                   := TE_IP;
          Request_RCH.Values['te_workgroup']            := TE_WORKGROUP;
          Request_RCH.Values['te_tripa_monitorados']    := strAux;


          // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
          //Sobreponho a informação no registro para posterior comparação, na próxima execução.
          if (comunicacao.ComunicaServidor('set_monitorado.php', Request_RCH, '>> Enviando informações de aplicativos monitorados para o servidor.') <> '0') Then
          Begin
            Registro.SetValorChaveRegIni('Coleta','APLICATIVOS_MONITORADOS_COLETADOS',strAux, p_path_cacic_ini);
          end;
          Request_RCH.Free;
       end
   else main.frmMain.Log_Historico('Coleta de informações de aplicativos monitorados não configurada.');
   end;
end;


end.

