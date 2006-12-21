unit frmPatrimonio;

interface

uses
  Windows, StdCtrls, Controls, Classes, Forms;

type
  TFormPatrimonio = class(TForm)
    GroupBox1: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    GroupBox2: TGroupBox;
    Etiqueta1: TLabel;
    Etiqueta2: TLabel;
    Etiqueta3: TLabel;
    id_unid_organizacional_nivel1: TComboBox;
    id_unid_organizacional_nivel2: TComboBox;
    te_localizacao_complementar: TEdit;
    Button2: TButton;
    Etiqueta4: TLabel;
    Etiqueta5: TLabel;
    Etiqueta6: TLabel;
    Etiqueta7: TLabel;
    Etiqueta8: TLabel;
    Etiqueta9: TLabel;
    te_info_patrimonio3: TEdit;
    te_info_patrimonio1: TEdit;
    te_info_patrimonio2: TEdit;
    te_info_patrimonio6: TEdit;
    te_info_patrimonio4: TEdit;
    te_info_patrimonio5: TEdit;

    procedure FormCreate(Sender: TObject);
    procedure MontaCombos;
    procedure MontaInterface;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure id_unid_organizacional_nivel1Change(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure RecuperaValoresAnteriores;
  private
    var_id_unid_organizacional_nivel1, var_id_unid_organizacional_nivel2, var_te_localizacao_complementar,
    var_te_info_patrimonio1, var_te_info_patrimonio2, var_te_info_patrimonio3, var_te_info_patrimonio4,
    var_te_info_patrimonio5, var_te_info_patrimonio6,
    var_dt_hr_alteracao_patrim_interface, var_dt_hr_alteracao_patrim_uon1, var_dt_hr_alteracao_patrim_uon2 : String;

  public
    { Public declarations }
  end;

var
  FormPatrimonio: TFormPatrimonio;

implementation

{$R *.dfm}


// Estruturas de dados para armazenar os itens da uon1 e uon2
type
  TRegistroUON1 = record
    id1 : String;
    valor : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON2 = record
    id1 : String;
    id2 : String;
    valor : String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1 : TVetorUON1;
    VetorUON2 : TVetorUON2;

    // Esse array é usado apenas para saber a uon2, após a filtragem pelo uon1
    VetorUON2Filtrado : array of String;


Function RetornaValorVetorUON1(id1Procurado1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].id1 = id1Procurado1) Then Result := VetorUON1[I].valor;
end;


Function RetornaValorVetorUON2(id1Procurado : string; id2Procurado : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].id1 = id1Procurado) and (VetorUON2[I].id2 = id2Procurado) Then Result := VetorUON2[I].valor;
end;



procedure TFormPatrimonio.FormCreate(Sender: TObject);
var Request_PAT: TStringList ; strRetorno: string;
Begin
        //Recuperar valores abaixo do INI...
       {
       Request_PAT := TStringList.Create;
       Request_PAT.Values['te_node_address']    := TE_NODE_ADDRESS;
       Request_PAT.Values['id_so']              := ID_SO;
       Request_PAT.Values['id_ip_rede']         := ID_IP_REDE;
       Request_PAT.Values['te_nome_computador'] := TE_NOME_COMPUTADOR;
       Request_PAT.Values['te_ip']              := TE_IP;
       Request_PAT.Values['te_workgroup']       := TE_WORKGROUP;



//   strRetorno := comunicacao.ComunicaServidor('get_patrimonio.php?tipo=dua', Nil, '<< Obtendo as datas de alteração das configurações de patrimônio.');
   strRetorno := comunicacao.ComunicaServidor('get_patrimonio.php?tipo=dua', Request_PAT, '<< Obtendo as datas de alteração das configurações de patrimônio.');

   // Antes não liberava...
   Request_PAT.Free;
    }
 strRetorno := '0';
   if (strRetorno <> '0') Then
   begin
       //Vejo as datas de alteração da interface e da uon1 e uon2.
       {
       Pegar do INI
       var_dt_hr_alteracao_patrim_interface := XML.XML_RetornaValor('dt_hr_alteracao_patrim_interface', strRetorno);
       var_dt_hr_alteracao_patrim_uon1 := XML.XML_RetornaValor('dt_hr_alteracao_patrim_uon1', strRetorno);
       var_dt_hr_alteracao_patrim_uon2 := XML.XML_RetornaValor('dt_hr_alteracao_patrim_uon2', strRetorno);
       }

       MontaInterface;
       MontaCombos;
       RecuperaValoresAnteriores;
   end;

end;




procedure TFormPatrimonio.RecuperaValoresAnteriores;
begin
    var_id_unid_organizacional_nivel1 := GetValorChaveRegIni('Patrimonio','id_unid_organizacional_nivel1', p_path_cacic_ini);
    var_id_unid_organizacional_nivel2 := registro.GetValorChaveRegIni('Patrimonio','id_unid_organizacional_nivel2', p_path_cacic_ini);
    var_te_localizacao_complementar   := registro.GetValorChaveRegIni('Patrimonio','te_localizacao_complementar', p_path_cacic_ini);
    var_te_info_patrimonio1           := registro.GetValorChaveRegIni('Patrimonio','te_info_patrimonio1', p_path_cacic_ini);
    var_te_info_patrimonio2           := registro.GetValorChaveRegIni('Patrimonio','te_info_patrimonio2', p_path_cacic_ini);
    var_te_info_patrimonio3           := registro.GetValorChaveRegIni('Patrimonio','te_info_patrimonio3', p_path_cacic_ini);
    var_te_info_patrimonio4           := registro.GetValorChaveRegIni('Patrimonio','te_info_patrimonio4', p_path_cacic_ini);
    var_te_info_patrimonio5           := registro.GetValorChaveRegIni('Patrimonio','te_info_patrimonio5', p_path_cacic_ini);
    var_te_info_patrimonio6           := registro.GetValorChaveRegIni('Patrimonio','te_info_patrimonio6', p_path_cacic_ini);

    Try
      id_unid_organizacional_nivel1.ItemIndex := id_unid_organizacional_nivel1.Items.IndexOf(RetornaValorVetorUON1(var_id_unid_organizacional_nivel1));
      id_unid_organizacional_nivel1Change(Nil); // Para filtrar os valores do combo2 de acordo com o valor selecionado no combo1
      id_unid_organizacional_nivel2.ItemIndex := id_unid_organizacional_nivel2.Items.IndexOf(RetornaValorVetorUON2(var_id_unid_organizacional_nivel1, var_id_unid_organizacional_nivel2));
    Except
    end;
    te_localizacao_complementar.Text  := var_te_localizacao_complementar;
    te_info_patrimonio1.Text          := var_te_info_patrimonio1;
    te_info_patrimonio2.Text          := var_te_info_patrimonio2;
    te_info_patrimonio3.Text          := var_te_info_patrimonio3;
    te_info_patrimonio4.Text          := var_te_info_patrimonio4;
    te_info_patrimonio5.Text          := var_te_info_patrimonio5;
    te_info_patrimonio6.Text          := var_te_info_patrimonio6;
end;



procedure TFormPatrimonio.MontaCombos;
var strRetorno, strAux, strItensUON1Registro, strItensUON2Registro : String;
    Parser : TXmlParser;
    i : integer;
begin
      // Código para montar o combo 1
      // Se houve alteração na configuração da uon1, atualizo os dados no registro e depois monto a interface.
      // Caso, contrário, pego direto do registro.
      strItensUON1Registro := Registro.GetValorChaveRegIni('Patrimonio','itens_uon1', p_path_cacic_ini);
      strAux := registro.GetValorChaveRegIni('Patrimonio','dt_hr_alteracao_patrim_uon1', p_path_cacic_ini);
      If (Trim(strItensUON1Registro) = '') or (Trim(var_dt_hr_alteracao_patrim_uon1) = '') or (Trim(strAux) = '') or (var_dt_hr_alteracao_patrim_uon1 <> strAux) Then
      Begin
         strRetorno := comunicacao.ComunicaServidor('get_patrimonio.php?tipo=itens_uon1', Nil, '<< Obtendo os itens da Tabela de Unidade Organizacional Nível 1 a partir do servidor.');
         if (strRetorno <> '0') Then
         begin
             // Gravo no registro a dt_hr_alteracao_patrim_uon1, obtida a partir do bd, para posterior comparação.
             Registro.SetValorChaveRegIni('Patrimonio','dt_hr_alteracao_patrim_uon1', var_dt_hr_alteracao_patrim_uon1, p_path_cacic_ini);
             Registro.SetValorChaveRegIni('Patrimonio','itens_uon1', strRetorno, p_path_cacic_ini);
         end;
      end
      Else strRetorno := strItensUON1Registro;

      Parser := TXmlParser.Create;
      Parser.Normalize := True;
      Parser.LoadFromBuffer(PAnsiChar(strRetorno));
      Parser.StartScan;
      i := -1;
      While Parser.Scan DO
      Begin
         if ((Parser.CurPartType = ptStartTag) and (UpperCase(Parser.CurName) = UpperCase('ITEM'))) Then
         Begin
           i := i + 1;
           SetLength(VetorUON1, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
         end
         else if (Parser.CurPartType in [ptContent, ptCData]) Then
         begin
            if (UpperCase(Parser.CurName) = UpperCase('ID1')) then  VetorUON1[i].id1 := Parser.CurContent
            else if (UpperCase(Parser.CurName) = UpperCase('VALOR')) then VetorUON1[i].valor := Parser.CurContent
         end
      end;


      // Código para montar o combo 2
      // Se houve alteração na configuração da uon2, atualizo os dados no registro e depois monto a interface.
      // Caso, contrário, pego direto do registro.
      strItensUON2Registro := registro.GetValorChaveRegIni('Patrimonio','itens_uon2', p_path_cacic_ini);
      strAux := registro.GetValorChaveRegIni('Patrimonio','dt_hr_alteracao_patrim_uon2', p_path_cacic_ini);
      If (Trim(strItensUON2Registro) = '') or (Trim(var_dt_hr_alteracao_patrim_uon2) = '') or (Trim(strAux) = '') or (var_dt_hr_alteracao_patrim_uon2 <> strAux) Then
      Begin
         strRetorno := comunicacao.ComunicaServidor('get_patrimonio.php?tipo=itens_uon2', Nil, '<< Obtendo os itens da Tabela de Unidade Organizacional Nível 2 a partir do servidor.');
         if (strRetorno <> '0') Then
         begin
             // Gravo no registro a dt_hr_alteracao_patrim_uon2, obtida a partir do bd, para posterior comparação.
             Registro.SetValorChaveRegIni('Patrimonio','dt_hr_alteracao_patrim_uon2', var_dt_hr_alteracao_patrim_uon2, p_path_cacic_ini);
             Registro.SetValorChaveRegIni('Patrimonio','itens_uon2', strRetorno, p_path_cacic_ini);
         end;
      end
      Else strRetorno := strItensUON2Registro;

      Parser.LoadFromBuffer(PAnsiChar(strRetorno));
      Parser.StartScan;

      i := -1;
      While Parser.Scan DO
      Begin
         if ((Parser.CurPartType = ptStartTag) and (UpperCase(Parser.CurName) = UpperCase('ITEM'))) Then
         Begin
           i := i + 1;
           SetLength(VetorUON2, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
         end
         else if (Parser.CurPartType in [ptContent, ptCData]) Then
         begin
            if (UpperCase(Parser.CurName) = UpperCase('ID1')) then  VetorUON2[i].id1 := Parser.CurContent
            else if (UpperCase(Parser.CurName) = UpperCase('ID2')) then VetorUON2[i].id2 := Parser.CurContent
            else if (UpperCase(Parser.CurName) = UpperCase('VALOR')) then VetorUON2[i].valor := Parser.CurContent
         end
      end;

      Parser.Free;

      // Como os itens do combo1 nunca mudam durante a execução do programa (ao contrario do combo2), posso colocar o seu preenchimento aqui mesmo.
      id_unid_organizacional_nivel1.Items.Clear;
      For i := 0 to Length(VetorUON1) - 1 Do
         id_unid_organizacional_nivel1.Items.Add(VetorUON1[i].valor);

end;



procedure TFormPatrimonio.id_unid_organizacional_nivel1Change(Sender: TObject);
var i, j: Word;
    strAux : String;
begin
  // Filtro os itens do combo2, de acordo com o item selecionado no combo1
  strAux := VetorUON1[id_unid_organizacional_nivel1.ItemIndex].id1;
  id_unid_organizacional_nivel2.Items.Clear;
  SetLength(VetorUON2Filtrado, 0);
  For i := 0 to Length(VetorUON2) - 1 Do
  Begin
     if VetorUON2[i].id1 = strAux then
     Begin
        id_unid_organizacional_nivel2.Items.Add(VetorUON2[i].valor);
        j := Length(VetorUON2Filtrado);
        SetLength(VetorUON2Filtrado, j + 1);
        VetorUON2Filtrado[j] := VetorUON2[i].id2;
     end;
  end;
end;


procedure TFormPatrimonio.AtualizaPatrimonio(Sender: TObject);
var Request_ATPAT: TStringList;
    strAux1, strAux2 : String;
begin
      //Verifico se houve qualquer alteração nas informações.
      // Só vou enviar as novas informações para o bd ou gravar no registro se houve alterações.
     Try
        strAux1 := VetorUON1[id_unid_organizacional_nivel1.ItemIndex].id1;
        strAux2 := VetorUON2Filtrado[id_unid_organizacional_nivel2.ItemIndex];
     Except
     end;
     if (strAux1 <> var_id_unid_organizacional_nivel1) or
        (strAux2 <> var_id_unid_organizacional_nivel2) or
         (te_localizacao_complementar.Text <> var_te_localizacao_complementar) or
         (te_info_patrimonio1.Text <> var_te_info_patrimonio1) or
         (te_info_patrimonio2.Text <> var_te_info_patrimonio2) or
         (te_info_patrimonio3.Text <> var_te_info_patrimonio3) or
         (te_info_patrimonio4.Text <> var_te_info_patrimonio4) or
         (te_info_patrimonio5.Text <> var_te_info_patrimonio5) or
         (te_info_patrimonio6.Text <> var_te_info_patrimonio6) then
      begin
           //Envio via rede para ao Agente Gerente, para gravação no BD.
           Request_ATPAT:=TStringList.Create;
           Request_ATPAT.Values['te_node_address']                := TE_NODE_ADDRESS;
           Request_ATPAT.Values['id_so']                          := ID_SO;
           Request_ATPAT.Values['te_nome_computador']             := TE_NOME_COMPUTADOR;
           Request_ATPAT.Values['te_nome_host']                   := TE_NOME_HOST;
           Request_ATPAT.Values['id_ip_rede']                     := ID_IP_REDE;
           Request_ATPAT.Values['te_ip']                          := TE_IP;
           Request_ATPAT.Values['te_workgroup']                   := TE_WORKGROUP;
           Request_ATPAT.Values['id_unid_organizacional_nivel1'] := strAux1;
           Request_ATPAT.Values['id_unid_organizacional_nivel2'] := strAux2;
           Request_ATPAT.Values['te_localizacao_complementar']   := te_localizacao_complementar.Text;
           Request_ATPAT.Values['te_info_patrimonio1']           := te_info_patrimonio1.Text;
           Request_ATPAT.Values['te_info_patrimonio2']           := te_info_patrimonio2.Text;
           Request_ATPAT.Values['te_info_patrimonio3']           := te_info_patrimonio3.Text;
           Request_ATPAT.Values['te_info_patrimonio4']           := te_info_patrimonio4.Text;
           Request_ATPAT.Values['te_info_patrimonio5']           := te_info_patrimonio5.Text;
           Request_ATPAT.Values['te_info_patrimonio6']           := te_info_patrimonio6.Text;

           // Somente atualizo o registro caso não tenha havido nenhum erro durante o envio das informações para o BD
           //Sobreponho a informação no registro para posterior comparação, na próxima execução.
           if (comunicacao.ComunicaServidor('set_patrimonio.php', Request_ATPAT, '>> Enviando informações de patrimônio para o servidor.') <> '0') Then
           Begin
               Registro.SetValorChaveRegIni('Patrimonio','id_unid_organizacional_nivel1', strAux1, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','id_unid_organizacional_nivel2', strAux2, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_localizacao_complementar', te_localizacao_complementar.Text, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_info_patrimonio1', te_info_patrimonio1.Text, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_info_patrimonio2', te_info_patrimonio2.Text, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_info_patrimonio3', te_info_patrimonio3.Text, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_info_patrimonio4', te_info_patrimonio4.Text, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_info_patrimonio5', te_info_patrimonio5.Text, p_path_cacic_ini);
               Registro.SetValorChaveRegIni('Patrimonio','te_info_patrimonio6', te_info_patrimonio6.Text, p_path_cacic_ini);
           end;

           Request_ATPAT.Free;
      end;

      registro.SetValorChaveRegIni('Patrimonio','ultima_rede_obtida', ID_IP_REDE, p_path_cacic_ini);
      registro.SetValorChaveRegIni('Patrimonio','dt_ultima_renovacao_patrim', FormatDateTime('yyyymmdd', Date), p_path_cacic_ini);

      Close;
end;

procedure TFormPatrimonio.MontaInterface;
var strAux, strRetorno: string;
Begin
   // Se houve alteração na configuração da interface, atualizo os dados no registro e depois monto a interface.
   // Caso, contrário, pego direto do registro.
   strAux := registro.GetValorChaveRegIni('Patrimonio','dt_hr_alteracao_patrim_interface', p_path_cacic_ini);

   If ((var_dt_hr_alteracao_patrim_interface) = '') or (Trim(strAux) = '') or (var_dt_hr_alteracao_patrim_interface <> strAux) Then
   Begin
       strRetorno := comunicacao.ComunicaServidor('get_patrimonio.php?tipo=config', Nil, '<< Obtendo as configurações da tela de patrimônio a partir do servidor.');

       if (strRetorno <> '0') Then
       begin
          // Gravo no registro a dt_hr_alteracao_patrim_interface, obtida a partir do bd, para posterior comparação.
          Registro.SetValorChaveRegIni('Patrimonio','config_interface', strRetorno, p_path_cacic_ini);
          Registro.SetValorChaveRegIni('Patrimonio','dt_hr_alteracao_patrim_interface', var_dt_hr_alteracao_patrim_interface, p_path_cacic_ini);
       end;
   end
   Else strRetorno := Registro.GetValorChaveRegIni('Patrimonio','config_interface', p_path_cacic_ini);

   Etiqueta1.Caption := XML.XML_RetornaValor('te_etiqueta1', strRetorno);
   id_unid_organizacional_nivel1.Hint := XML.XML_RetornaValor('te_help_etiqueta1', strRetorno);

   Etiqueta2.Caption := XML.XML_RetornaValor('te_etiqueta2', strRetorno);
   id_unid_organizacional_nivel2.Hint := XML.XML_RetornaValor('te_help_etiqueta2', strRetorno);

   Etiqueta3.Caption := XML.XML_RetornaValor('te_etiqueta3', strRetorno);
   te_localizacao_complementar.Hint := XML.XML_RetornaValor('te_help_etiqueta3', strRetorno);

   if (XML.XML_RetornaValor('in_exibir_etiqueta4', strRetorno) = 'S') then
   begin
      Etiqueta4.Caption := XML.XML_RetornaValor('te_etiqueta4', strRetorno);
      te_info_patrimonio1.Hint := XML.XML_RetornaValor('te_help_etiqueta4', strRetorno);
      te_info_patrimonio1.visible := True;
   end
   else begin
      Etiqueta4.Visible := False;
      te_info_patrimonio1.visible := False;

   end;

   if (XML.XML_RetornaValor('in_exibir_etiqueta5', strRetorno) = 'S') then
   begin
      Etiqueta5.Caption := XML.XML_RetornaValor('te_etiqueta5', strRetorno);
      te_info_patrimonio2.Hint := XML.XML_RetornaValor('te_help_etiqueta5', strRetorno);
      te_info_patrimonio2.visible := True;
   end
   else begin
      Etiqueta5.Visible := False;
      te_info_patrimonio2.visible := False;
   end;

   if (XML.XML_RetornaValor('in_exibir_etiqueta6', strRetorno) = 'S') then
   begin
      Etiqueta6.Caption := XML.XML_RetornaValor('te_etiqueta6', strRetorno);
      te_info_patrimonio3.Hint := XML.XML_RetornaValor('te_help_etiqueta6', strRetorno);
      te_info_patrimonio3.visible := True;
   end
   else begin
      Etiqueta6.Visible := False;
      te_info_patrimonio3.visible := False;
   end;

   if (XML.XML_RetornaValor('in_exibir_etiqueta7', strRetorno) = 'S') then
   begin
      Etiqueta7.Caption := XML.XML_RetornaValor('te_etiqueta7', strRetorno);
      te_info_patrimonio4.Hint := XML.XML_RetornaValor('te_help_etiqueta7', strRetorno);
      te_info_patrimonio4.visible := True;
   end  else
   begin
      Etiqueta7.Visible := False;
      te_info_patrimonio4.visible := False;
   end;

   if (XML.XML_RetornaValor('in_exibir_etiqueta8', strRetorno) = 'S') then
   begin
      Etiqueta8.Caption := XML.XML_RetornaValor('te_etiqueta8', strRetorno);
      te_info_patrimonio5.Hint := XML.XML_RetornaValor('te_help_etiqueta8', strRetorno);
      te_info_patrimonio5.visible := True;
   end else
   begin
      Etiqueta8.Visible := False;
      te_info_patrimonio5.visible := False;
  end;

   if (XML.XML_RetornaValor('in_exibir_etiqueta9', strRetorno) = 'S') then
  begin
     Etiqueta9.Caption := XML.XML_RetornaValor('te_etiqueta9', strRetorno);
     te_info_patrimonio6.Hint := XML.XML_RetornaValor('te_help_etiqueta9', strRetorno);
     te_info_patrimonio6.visible := True;
  end
  else begin
     Etiqueta9.Visible := False;
     te_info_patrimonio6.visible := False;
  end;
end;







procedure TFormPatrimonio.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   //Teste Anderson
//   FormPatrimonio := nil;
   Action := cafree;
end;






end.
