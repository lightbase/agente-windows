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

unit uMainMapa;

interface

uses
  Windows,
  SysUtils,    // Deve ser colocado após o Windows acima, nunca antes
  StrUtils,
  StdCtrls,
  Controls,
  Classes,
  Forms,
  ExtCtrls,
  Graphics,
  Dialogs,
  CACIC_Library,
  CACIC_Comm,
  ComCtrls,
  ShellAPI,
  uAcessoMapa,
  Math;

function IsUserAnAdmin() : boolean; external shell32;

var strCollectsPatrimonioLast,
    strConfigsPatrimonioCombos,
    strFieldsAndValuesToRequest,
    strIdUON1,
    strFrmAtual,
    strShowOrHide               : string;
    textFileAguarde             : TextFile;
    boolFinalizando             : boolean;
    objCacic                    : TCACIC;
type
  TfrmMapaCacic = class(TForm)
    gbLeiaComAtencao: TGroupBox;
    lbLeiaComAtencao: TLabel;
    gbInformacoesSobreComputador: TGroupBox;
    lbEtiqueta1: TLabel;
    lbEtiqueta2: TLabel;
    lbEtiqueta3: TLabel;
    cbIdUnidOrganizacionalNivel1: TComboBox;
    cbIdUnidOrganizacionalNivel2: TComboBox;
    edTeLocalizacaoComplementar: TEdit;
    btGravarInformacoes: TButton;
    lbEtiqueta4: TLabel;
    lbEtiqueta5: TLabel;
    lbEtiqueta6: TLabel;
    lbEtiqueta7: TLabel;
    lbEtiqueta8: TLabel;
    lbEtiqueta9: TLabel;
    edTeInfoPatrimonio1: TEdit;
    edTeInfoPatrimonio2: TEdit;
    edTeInfoPatrimonio3: TEdit;
    edTeInfoPatrimonio4: TEdit;
    edTeInfoPatrimonio5: TEdit;
    edTeInfoPatrimonio6: TEdit;
    lbEtiqueta1a: TLabel;
    cbIdUnidOrganizacionalNivel1a: TComboBox;
    pnDivisoria01: TPanel;
    lbWebManagerAddress: TLabel;
    edWebManagerAddress: TLabel;
    pnVersao: TPanel;
    btCombosUpdate: TButton;
    timerMessageShowTime: TTimer;
    timerMessageBoxShowOrHide: TTimer;
    pnMessageBox: TPanel;
    lbMensagens: TLabel;

    procedure AtualizaPatrimonio(Sender: TObject);
    procedure mapa;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cbIdUnidOrganizacionalNivel1Change(Sender: TObject);
    procedure cbIdUnidOrganizacionalNivel1aChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbIdUnidOrganizacionalNivel1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure cbIdUnidOrganizacionalNivel1DrawItem(Control: TWinControl;
      Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure btCombosUpdateClick(Sender: TObject);
    procedure timerMessageShowTimeTimer(Sender: TObject);
    procedure cbIdUnidOrganizacionalNivel1aDrawItem(Control: TWinControl;
      Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure cbIdUnidOrganizacionalNivel2DrawItem(Control: TWinControl;
      Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure timerMessageBoxShowOrHideTimer(Sender: TObject);
  private
    strIdUnidOrganizacionalNivel1,
    strIdUnidOrganizacionalNivel1a,
    strIdUnidOrganizacionalNivel2,
    strIdLocal,
    strTeLocalizacaoComplementar,
    strTeInfoPatrimonio1,
    strTeInfoPatrimonio2,
    strTeInfoPatrimonio3,
    strTeInfoPatrimonio4,
    strTeInfoPatrimonio5,
    strTeInfoPatrimonio6     : String;

    function  getConfigs                                             : String;
    function  RetornaValorVetorUON1(pStrIdUON1 : string)   : String;
    function  RetornaValorVetorUON1a(pStrIdUON1a : string) : String;
    function  RetornaValorVetorUON2(pStrIdUON2,pStrIdLocal : string) : String;

    procedure CriaFormSenha(Sender: TObject);
    procedure MontaCombos;
    procedure MontaInterface;
    procedure RecuperaValoresAnteriores;
    procedure Sair;
  public
    boolAcessoOK                : boolean;
    strId_usuario,
    strChkSisInfFileName,
    strGerColsInfFileName       : String;
    procedure Finalizar(p_pausa:boolean);
    procedure Mensagem(p_strMsg : String; p_boolAlerta : boolean = false; p_intPausaSegundos : integer = 0);
  end;

var frmMapaCacic: TfrmMapaCacic;

implementation

{$R *.dfm}

// Estruturas de dados para armazenar os itens das Unidades Organizacionais de Níveis 1, 1a e 2
type
  TRegistroUON1 = record // Nível 1 => Entidade
    idUON1 : String;
    nmUON1 : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON1a = record // Nível 1a => Linha de Negócio
    idUON1     : String;
    idUON1a    : String;
    nmUON1a    : String;
  end;
  TVetorUON1a = array of TRegistroUON1a;

  TRegistroUON2 = record // Nível 2 => Órgão
    idUON1a    : String;
    idUON2     : String;
    nmUON2     : String;
    idLocal    : String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1  : TVetorUON1;
    VetorUON1a : TVetorUON1a;
    VetorUON2  : TVetorUON2;

    // Esse array é usado apenas para saber a uon1a, após a filtragem pelo uon1
    VetorUON1aFiltrado : array of String;

    // Esse array é usado apenas para saber a uon2, após a filtragem pelo uon1a
    VetorUON2Filtrado : array of String;

procedure TfrmMapaCacic.Mensagem(p_strMsg : String; p_boolAlerta : boolean = false; p_intPausaSegundos : integer = 0);
Begin
  strShowOrHide := 'Show';

  objCacic.writeDebugLog('Mensagem: ' + p_strMsg);

  if p_boolAlerta then
    lbMensagens.Font.Color := clRed
  else
    lbMensagens.Font.Color := clBlack;

  lbMensagens.Caption := p_strMsg;

  objCacic.writeDailyLog(lbMensagens.Caption);
  Application.ProcessMessages;

  if (p_intPausaSegundos > 0) then
    timerMessageShowTime.Interval := p_intPausaSegundos * 1000;

  timerMessageBoxShowOrHide.Enabled := true;

  Application.ProcessMessages;
End;

procedure showMessageBox;
Begin

End;

procedure TfrmMapaCacic.Sair;
Begin
    Application.Terminate;
End;

procedure TfrmMapaCacic.Finalizar(p_pausa:boolean);
Begin
  gbLeiaComAtencao.Visible              := false;
  gbInformacoesSobreComputador.Visible  := false;
  btGravarInformacoes.Visible           := false;

  Mensagem('Finalizando o MapaCacic...');

  Application.ProcessMessages;
  
  Sleep(1000);

  Sair;
End;
//

Function TfrmMapaCacic.RetornaValorVetorUON1(pStrIdUON1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].idUON1 = pStrIdUON1) Then Result := VetorUON1[I].nmUON1;
end;

Function TfrmMapaCacic.RetornaValorVetorUON1a(pStrIdUON1a : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1a)-1)  Do
       If (VetorUON1a[I].idUON1a = pStrIdUON1a) Then Result := VetorUON1a[I].nmUON1a;
end;

Function TfrmMapaCacic.RetornaValorVetorUON2(pStrIdUON2, pStrIdLocal: string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].idUON2  = pStrIdUON2) and
          (VetorUON2[I].idLocal = pStrIdLocal) Then Result := VetorUON2[I].nmUON2;
end;

procedure TfrmMapaCacic.RecuperaValoresAnteriores;
var strCollectsPatrimonioLast,
    strConfigsPatrimonioInterface : String;
begin
  btCombosUpdate.Enabled := false;

  Mensagem('Recuperando Valores Anteriores...',false,1);

  strCollectsPatrimonioLast := objCacic.deCrypt( objCacic.GetValueFromFile('Collects','Patrimonio_Last',strGerColsInfFileName));

  if (strCollectsPatrimonioLast <> '') then
    Begin
      strIdUnidOrganizacionalNivel1 := objCacic.GetValueFromFile('Patrimonio','IdUnidOrganizacionalNivel1',strGerColsInfFileName);
      if (strIdUnidOrganizacionalNivel1='') then
        strIdUnidOrganizacionalNivel1 := objCacic.deCrypt(objCacic.getValueFromTags('ID_UON1', strCollectsPatrimonioLast));

      strIdUnidOrganizacionalNivel1a := objCacic.GetValueFromFile('Patrimonio','IdUnidOrganizacionalNivel1a',strGerColsInfFileName);
      if (strIdUnidOrganizacionalNivel1a='') then
        strIdUnidOrganizacionalNivel1a := objCacic.deCrypt(objCacic.getValueFromTags('ID_UON1a', strCollectsPatrimonioLast));

      strIdUnidOrganizacionalNivel2 := objCacic.GetValueFromFile('Patrimonio','IdUnidOrganizacionalNivel2',strGerColsInfFileName);
      if (strIdUnidOrganizacionalNivel2='') then
        strIdUnidOrganizacionalNivel2 := objCacic.deCrypt(objCacic.getValueFromTags('ID_UON2', strCollectsPatrimonioLast));

      strIdLocal := objCacic.getValueFromTags('IdLocal',strCollectsPatrimonioLast);

      Try
        cbIdUnidOrganizacionalNivel1.ItemIndex := cbIdUnidOrganizacionalNivel1.Items.IndexOf(RetornaValorVetorUON1(strIdUnidOrganizacionalNivel1));
        cbIdUnidOrganizacionalNivel1Change(Nil); // Para filtrar os valores do combo2 de acordo com o valor selecionado no combo1
        cbIdUnidOrganizacionalNivel1a.ItemIndex := cbIdUnidOrganizacionalNivel1a.Items.IndexOf(RetornaValorVetorUON1(strIdUnidOrganizacionalNivel1));
      Except
        on E:Exception do
           Begin
             objCacic.writeExceptionLog(E.Message,e.ClassName,'Setando "cbIdUnidOrganizacionalNivel1a.ItemIndex" para "' + IntToStr(cbIdUnidOrganizacionalNivel1a.Items.IndexOf(RetornaValorVetorUON1(strIdUnidOrganizacionalNivel1))) + '"');
             objCacic.writeDebugLog('RecuperaValoresAnteriores: Problema ao setar "cbIdUnidOrganizacionalNivel1a.ItemIndex" para "' + IntToStr(cbIdUnidOrganizacionalNivel1a.Items.IndexOf(RetornaValorVetorUON1(strIdUnidOrganizacionalNivel1))) + '"');
           End;
      end;

      Try
        cbIdUnidOrganizacionalNivel1a.ItemIndex := cbIdUnidOrganizacionalNivel1a.Items.IndexOf(RetornaValorVetorUON1a(strIdUnidOrganizacionalNivel1a));
        cbIdUnidOrganizacionalNivel1aChange(Nil); // Para filtrar os valores do combo3 de acordo com o valor selecionado no combo2
        cbIdUnidOrganizacionalNivel2.ItemIndex := cbIdUnidOrganizacionalNivel2.Items.IndexOf(RetornaValorVetorUON2(strIdUnidOrganizacionalNivel2,strIdLocal));
      Except
        on E:Exception do
           Begin
             objCacic.writeExceptionLog(E.Message,e.ClassName,'Setando "cbIdUnidOrganizacionalNivel2.ItemIndex" para "' + IntToStr(cbIdUnidOrganizacionalNivel2.Items.IndexOf(RetornaValorVetorUON2(strIdUnidOrganizacionalNivel2,strIdLocal))) + '"');
             objCacic.writeDebugLog('RecuperaValoresAnteriores: Problema ao setar "cbIdUnidOrganizacionalNivel2.ItemIndex" para "' + IntToStr(cbIdUnidOrganizacionalNivel2.Items.IndexOf(RetornaValorVetorUON2(strIdUnidOrganizacionalNivel2,strIdLocal))) + '"');
           End;
      end;

      strConfigsPatrimonioInterface := objCacic.deCrypt( objCacic.GetValueFromFile('Configs','Patrimonio_Interface',strGerColsInfFileName));

      lbEtiqueta1.Caption := objCacic.getValueFromTags('te_etiqueta1', strConfigsPatrimonioInterface);
      lbEtiqueta1a.Caption := objCacic.deCrypt(objCacic.getValueFromTags('te_etiqueta1a', strConfigsPatrimonioInterface));

      strTeLocalizacaoComplementar   := objCacic.getValueFromTags('TeLocalizacaoComplementar',strCollectsPatrimonioLast);

      // Tentarei buscar informação gravada no Registry
      strTeInfoPatrimonio1           := objCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1');
      strTeInfoPatrimonio2           := objCacic.getValueFromTags('TeInfoPatrimonio2',strCollectsPatrimonioLast);
      strTeInfoPatrimonio3           := objCacic.getValueFromTags('TeInfoPatrimonio3',strCollectsPatrimonioLast);
      strTeInfoPatrimonio4           := objCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4');
      strTeInfoPatrimonio5           := objCacic.getValueFromTags('TeInfoPatrimonio5',strCollectsPatrimonioLast);
      strTeInfoPatrimonio6           := objCacic.getValueFromTags('TeInfoPatrimonio6',strCollectsPatrimonioLast);

      if (strTeInfoPatrimonio1='') then strTeInfoPatrimonio1 := objCacic.getValueFromTags('TE_INFO1', strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio2='') then strTeInfoPatrimonio2 := objCacic.getValueFromTags('TE_INFO2', strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio3='') then strTeInfoPatrimonio3 := objCacic.getValueFromTags('TE_INFO3', strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio4='') then strTeInfoPatrimonio4 := objCacic.getValueFromTags('TE_INFO4', strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio5='') then strTeInfoPatrimonio5 := objCacic.getValueFromTags('TE_INFO5', strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio6='') then strTeInfoPatrimonio6 := objCacic.getValueFromTags('TE_INFO6', strCollectsPatrimonioLast);
    End;
  btCombosUpdate.Enabled := true;
  Application.ProcessMessages;
end;

procedure TfrmMapaCacic.MontaCombos;
var intTagCount,
    intLoopUOS    : integer;
    strTagName,
    strTagValue   : String;
    tstrTagsNames : TStrings;
begin
  btCombosUpdate.Enabled                := false;
  cbIdUnidOrganizacionalNivel1.Enabled  := false;
  cbIdUnidOrganizacionalNivel1a.Enabled := false;
  cbIdUnidOrganizacionalNivel2.Enabled  := false;

  Mensagem('Montando Listas para Seleção de Unidades Organizacionais...',false,1);

  strConfigsPatrimonioCombos := objCacic.deCrypt(objCacic.GetValueFromFile('Configs' ,'Patrimonio_Combos',strGerColsInfFileName));
  strCollectsPatrimonioLast  := objCacic.deCrypt(objCacic.GetValueFromFile('Collects','Patrimonio_Last'  ,strGerColsInfFileName));

  strIdUON1 := objCacic.getValueFromTags('IdUON1',strCollectsPatrimonioLast);

  SetLength(VetorUON1 ,0);
  SetLength(VetorUON1a,0);
  SetLength(VetorUON2 ,0);

  cbIdUnidOrganizacionalNivel1.Items.Clear;
  cbIdUnidOrganizacionalNivel1a.Items.Clear;
  cbIdUnidOrganizacionalNivel2.Items.Clear;

  tstrTagsNames := objCacic.explode('UO1,UO1a,UO2',',');

  for intLoopUOS := 0 to tstrTagsNames.Count -1 do
    Begin
      intTagCount := 1;
      strTagValue := '*';
      while (strTagValue <> '') do
        Begin
          strTagName  := tstrTagsNames[intLoopUOS] + '#' + intToStr(intTagCount);
          strTagValue := objCacic.getValueFromTags(strTagName,strConfigsPatrimonioCombos);
          if (strTagValue <> '') then
            Begin
              if (tstrTagsNames[intLoopUOS] = 'UO1') then
                Begin
                  SetLength(VetorUON1 ,length(VetorUON1)+1);
                  VetorUON1[length(VetorUON1)-1].idUON1 := objCacic.getValueFromTags('UO1_ID',strTagValue);
                  VetorUON1[length(VetorUON1)-1].nmUON1 := objCacic.getValueFromTags('UO1_NM',strTagValue);
                  cbIdUnidOrganizacionalNivel1.Items.Add(VetorUON1[length(VetorUON1)-1].nmUON1);
                  if (strIdUON1 = VetorUON1[length(VetorUON1)-1].idUON1) then
                    cbIdUnidOrganizacionalNivel1.ItemIndex := cbIdUnidOrganizacionalNivel1.Items.Count-1;
                End
              else if (tstrTagsNames[intLoopUOS] = 'UO1a') then
                Begin
                  SetLength(VetorUON1a ,length(VetorUON1a)+1);
                  VetorUON1a[length(VetorUON1a)-1].idUON1  := objCacic.getValueFromTags('UO1a_IdUO1',strTagValue);
                  VetorUON1a[length(VetorUON1a)-1].idUON1a := objCacic.getValueFromTags('UO1a_ID'   ,strTagValue);
                  VetorUON1a[length(VetorUON1a)-1].nmUON1a := objCacic.getValueFromTags('UO1a_NM'   ,strTagValue);
                End
              else if (tstrTagsNames[intLoopUOS] = 'UO2') then
                Begin
                  SetLength(VetorUON2 ,length(VetorUON2)+1);
                  VetorUON2[length(VetorUON2)-1].idUON1a  := objCacic.getValueFromTags('UO2_IdUO1a' ,strTagValue);
                  VetorUON2[length(VetorUON2)-1].idUON2   := objCacic.getValueFromTags('UO2_ID'     ,strTagValue);
                  VetorUON2[length(VetorUON2)-1].nmUON2   := objCacic.getValueFromTags('UO2_NM'     ,strTagValue);
                  VetorUON2[length(VetorUON2)-1].idLocal  := objCacic.getValueFromTags('UO2_IdLocal',strTagValue);
                End;
            End;
          inc(intTagCount);
        End;
    End;

  // Ao fim...
  if (cbIdUnidOrganizacionalNivel1.ItemIndex = -1) then
    cbIdUnidOrganizacionalNivel1.ItemIndex := 0;

  cbIdUnidOrganizacionalNivel1Change(nil);

  btCombosUpdate.Enabled                := true;
  cbIdUnidOrganizacionalNivel1.Enabled  := true;
  cbIdUnidOrganizacionalNivel1a.Enabled := true;
  cbIdUnidOrganizacionalNivel2.Enabled  := true;

  Application.ProcessMessages;
end;

procedure TfrmMapaCacic.cbIdUnidOrganizacionalNivel1Change(Sender: TObject);
var intLoopVetorUON1a : integer;
begin
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: Nível 1 CHANGE');

  // Filtro os itens do combo2, de acordo com o item selecionado no combo1
  strIdUON1 := VetorUON1[cbIdUnidOrganizacionalNivel1.ItemIndex].idUON1;

  cbIdUnidOrganizacionalNivel1a.Items.Clear;
  cbIdUnidOrganizacionalNivel2.Items.Clear;
  cbIdUnidOrganizacionalNivel1a.Enabled := false;
  cbIdUnidOrganizacionalNivel2.Enabled  := false;
  SetLength(VetorUON1aFiltrado, 0);

  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: Tamanho de VetorUON1..: '+IntToStr(Length(VetorUON1)));
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: ItemIndex de cb_nivel1: '+IntToStr(cbIdUnidOrganizacionalNivel1.ItemIndex));
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: Tamanho de VetorUON1a.: '+IntToStr(Length(VetorUON1a)));

  For intLoopVetorUON1a := 0 to Length(VetorUON1a) - 1 Do
  Begin
      Try
        if VetorUON1a[intLoopVetorUON1a].idUON1 = strIdUON1 then
          Begin
            objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: Add em cb_nivel1a: '+VetorUON1a[intLoopVetorUON1a].nmUON1a);
            cbIdUnidOrganizacionalNivel1a.Items.Add(VetorUON1a[intLoopVetorUON1a].nmUON1a);

            SetLength(VetorUON1aFiltrado, Length(VetorUON1aFiltrado) + 1);
            VetorUON1aFiltrado[Length(VetorUON1aFiltrado)-1] := VetorUON1a[intLoopVetorUON1a].idUON1a;
            objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: VetorUON1aFiltrado['+IntToStr(Length(VetorUON1aFiltrado)-1)+']= '+VetorUON1aFiltrado[Length(VetorUON1aFiltrado)-1]);
          end;
      Except
        on E:Exception do
           Begin
             objCacic.writeExceptionLog(E.Message,e.ClassName);
           End;
      End;
  end;
  if (cbIdUnidOrganizacionalNivel1a.Items.Count > 0) then
    Begin
      cbIdUnidOrganizacionalNivel1a.Enabled   := true;
      cbIdUnidOrganizacionalNivel1a.ItemIndex := 0;
      objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Change: Provocando CHANGE em nivel1a');
      cbIdUnidOrganizacionalNivel1aChange(nil);
    End;
end;

procedure TfrmMapaCacic.cbIdUnidOrganizacionalNivel1aChange(
  Sender: TObject);
var intLoopVetorUON2 : integer;
begin
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: Nível 1a CHANGE');
  // Filtro os itens do combo2, de acordo com o item selecionado no combo1
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: cbIdUnidOrganizacionalNivel1a.ItemIndex = '+intToStr(cbIdUnidOrganizacionalNivel1a.ItemIndex));
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: VetorUON1aFiltrado['+intToStr(cbIdUnidOrganizacionalNivel1a.ItemIndex)+'] => '+VetorUON1aFiltrado[cbIdUnidOrganizacionalNivel1a.ItemIndex]);
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: strIdLocal = '+strIdLocal);

  cbIdUnidOrganizacionalNivel2.Items.Clear;
  cbIdUnidOrganizacionalNivel2.Enabled  := false;
  SetLength(VetorUON2Filtrado, 0);

  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: Tamanho de VetorUON1a..: '+IntToStr(Length(VetorUON1a)));
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: ItemIndex de cb_nivel1a: '+IntToStr(cbIdUnidOrganizacionalNivel1a.ItemIndex));
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: Tamanho de VetorUON2...: '+IntToStr(Length(VetorUON2)));

  For intLoopVetorUON2 := 0 to Length(VetorUON2) - 1 Do
  Begin
      Try
        if (VetorUON2[intLoopVetorUON2].idUON1a = VetorUON1aFiltrado[cbIdUnidOrganizacionalNivel1a.ItemIndex]) then
          Begin
            objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: Add em cb_nivel2: '+VetorUON2[intLoopVetorUON2].nmUON2);
            cbIdUnidOrganizacionalNivel2.Items.Add(VetorUON2[intLoopVetorUON2].nmUON2);

            SetLength(VetorUON2Filtrado, Length(VetorUON2Filtrado) + 1);
            VetorUON2Filtrado[Length(VetorUON2Filtrado)-1] := VetorUON2[intLoopVetorUON2].idUON2 + '#' + VetorUON2[intLoopVetorUON2].idLocal;
            objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1aChange: VetorUON2Filtrado['+IntToStr(Length(VetorUON2Filtrado)-1)+']= '+VetorUON2Filtrado[Length(VetorUON2Filtrado)-1]);
          end;
      Except
        on E:Exception do
           Begin
             objCacic.writeExceptionLog(E.Message,e.ClassName);
           End;
      End;
  end;
  if (cbIdUnidOrganizacionalNivel2.Items.Count > 0) then
    Begin
      cbIdUnidOrganizacionalNivel2.Enabled := true;
      cbIdUnidOrganizacionalNivel2.ItemIndex := 0;
    End;
end;


procedure TfrmMapaCacic.AtualizaPatrimonio(Sender: TObject);
var strColetaAtual,
    strIdUON1,
    strIdUON1a,
    strIdUON2,
    strIdLocal,
    strRetorno : String;
    tstrAuxAP    : TStrings;
begin
  tstrAuxAP := TStrings.Create;
  tstrAuxAP := objCacic.explode(VetorUON2Filtrado[cbIdUnidOrganizacionalNivel2.ItemIndex],'#');
  Try
    strIdUON1  := VetorUON1[cbIdUnidOrganizacionalNivel1.ItemIndex].idUON1;
    strIdUON2  := tstrAuxAP[0];
    strIdLocal := tstrAuxAP[1];
  Except
    on E:Exception do
       Begin
         objCacic.writeExceptionLog(E.Message,e.ClassName);
       End;
  end;

  tstrAuxAP := objCacic.explode(VetorUON1aFiltrado[cbIdUnidOrganizacionalNivel1a.ItemIndex],'#');
  Try
    strIdUON1a  := tstrAuxAP[0];
  Except
    on E:Exception do
       Begin
         objCacic.writeExceptionLog(E.Message,e.ClassName);
       End;
  end;

  tstrAuxAP.Free;
  Mensagem('Enviando Informações Coletadas ao Banco de Dados...',false,1);

  strFieldsAndValuesToRequest := 'CollectType=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt('col_patr')) ;

  strColetaAtual := StringReplace('[IdUsuario]'                   + frmMapaCacic.strId_usuario        + '[/IdUsuario]'                  +
                                  '[IdLocal]'                     + strIdLocal                        + '[/IdLocal]'                    +
                                  '[IdUnidOrganizacionalNivel1]'  + strIdUON1                         + '[/IdUnidOrganizacionalNivel1]' +
                                  '[IdUnidOrganizacionalNivel1a]' + strIdUON1A                        + '[/IdUnidOrganizacionalNivel1a]'+
                                  '[IdUnidOrganizacionalNivel2]'  + strIdUON2                         + '[/IdUnidOrganizacionalNivel2]' +
                                  '[TeLocalizacaoComplementar]'   + edTeLocalizacaoComplementar.Text  + '[/TeLocalizacaoComplementar]'  +
                                  '[TeInfoPatrimonio1]'           + edTeInfoPatrimonio1.Text          + '[/TeInfoPatrimonio1]'          +
                                  '[TeInfoPatrimonio2]'           + edTeInfoPatrimonio2.Text          + '[/TeInfoPatrimonio2]'          +
                                  '[TeInfoPatrimonio3]'           + edTeInfoPatrimonio3.Text          + '[/TeInfoPatrimonio3]'          +
                                  '[TeInfoPatrimonio4]'           + edTeInfoPatrimonio4.Text          + '[/TeInfoPatrimonio4]'          +
                                  '[TeInfoPatrimonio5]'           + edTeInfoPatrimonio5.Text          + '[/TeInfoPatrimonio5]'          +
                                  '[TeInfoPatrimonio6]'           + edTeInfoPatrimonio6.Text          + '[/TeInfoPatrimonio6]',',','[[COMMA]]',[rfReplaceAll]);

  strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',col_patr='  + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));

  strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName +'gercols/set/collects', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);
  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  if (strRetorno = '0') then
      Mensagem('ATENÇÃO: PROBLEMAS NO ENVIO DAS INFORMAÇÕES COLETADAS AO BANCO DE DADOS...',true,1)
  else
    Begin
      Mensagem('Salvando Informações Coletadas em Base Local...',false,1);
      objCacic.setValueToFile('Collects','Patrimonio_Last' , objCacic.enCrypt(strColetaAtual), strGerColsInfFileName);

      objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1', edTeInfoPatrimonio1.Text);
      objCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4', edTeInfoPatrimonio4.Text);
    End;
  objCacic.writeDebugLog('AtualizaPatrimonio: Dados Enviados ao Servidor!');
  Application.ProcessMessages;

  Finalizar(true);
end;

procedure TfrmMapaCacic.MontaInterface;
var strConfigsPatrimonioInterface : String;
Begin
   btCombosUpdate.Enabled := false;

   Mensagem('Montando Interface para Coleta de Informações...',false,1);

   strConfigsPatrimonioInterface := objCacic.deCrypt( objCacic.getValueFromFile('Configs','Patrimonio_Interface',strGerColsInfFileName));

   lbEtiqueta1.Caption                    := objCacic.getValueFromTags('te_etiqueta1', strConfigsPatrimonioInterface);
   lbEtiqueta1.Visible                    := true;
   cbIdUnidOrganizacionalNivel1.Hint      := objCacic.getValueFromTags('te_help_etiqueta1', strConfigsPatrimonioInterface);

   lbEtiqueta1a.Caption                   := objCacic.getValueFromTags('te_etiqueta1a', strConfigsPatrimonioInterface);
   lbEtiqueta1a.Visible                   := true;
   cbIdUnidOrganizacionalNivel1a.Hint     := objCacic.getValueFromTags('te_help_etiqueta1a', strConfigsPatrimonioInterface);

   lbEtiqueta2.Caption                    := objCacic.getValueFromTags('te_etiqueta2', strConfigsPatrimonioInterface);
   lbEtiqueta2.Visible                    := true;
   cbIdUnidOrganizacionalNivel2.Hint      := objCacic.getValueFromTags('te_help_etiqueta2', strConfigsPatrimonioInterface);

   lbEtiqueta3.Caption                    := objCacic.getValueFromTags('te_etiqueta3', strConfigsPatrimonioInterface);
   lbEtiqueta3.Visible                    := true;
   edTeLocalizacaoComplementar.Text       := strTeLocalizacaoComplementar;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta4 -> "'+objCacic.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonioInterface)+'"');
   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta4.Caption         := objCacic.getValueFromTags('te_etiqueta4', strConfigsPatrimonioInterface);
      lbEtiqueta4.Visible         := true;
      edTeInfoPatrimonio1.Hint    := objCacic.getValueFromTags('te_help_etiqueta4', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio1.Text    := strTeInfoPatrimonio1;
      edTeInfoPatrimonio1.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta5 -> "'+objCacic.getValueFromTags('in_exibir_etiqueta5', strConfigsPatrimonioInterface)+'"');
   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta5', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta5.Caption         := objCacic.getValueFromTags('te_etiqueta5', strConfigsPatrimonioInterface);
      lbEtiqueta5.Visible         := true;
      edTeInfoPatrimonio2.Hint    := objCacic.getValueFromTags('te_help_etiqueta5', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio2.Text    := strTeInfoPatrimonio2;
      edTeInfoPatrimonio2.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta6 -> "'+objCacic.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonioInterface)+'"');
   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta6.Caption         := objCacic.getValueFromTags('te_etiqueta6', strConfigsPatrimonioInterface);
      lbEtiqueta6.Visible         := true;
      edTeInfoPatrimonio3.Hint    := objCacic.getValueFromTags('te_help_etiqueta6', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio3.Text    := strTeInfoPatrimonio3;
      edTeInfoPatrimonio3.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta7 -> "'+objCacic.getValueFromTags('in_exibir_etiqueta7', strConfigsPatrimonioInterface)+'"');
   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta7', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta7.Caption         := objCacic.getValueFromTags('te_etiqueta7', strConfigsPatrimonioInterface);
      lbEtiqueta7.Visible         := true;
      edTeInfoPatrimonio4.Hint    := objCacic.getValueFromTags('te_help_etiqueta7', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio4.Text    := strTeInfoPatrimonio4;
      edTeInfoPatrimonio4.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta8 -> "'+objCacic.getValueFromTags('in_exibir_etiqueta8', strConfigsPatrimonioInterface)+'"');
   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta8', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta8.Caption         := objCacic.getValueFromTags('te_etiqueta8', strConfigsPatrimonioInterface);
      lbEtiqueta8.Visible         := true;
      edTeInfoPatrimonio5.Hint    := objCacic.getValueFromTags('te_help_etiqueta8', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio5.Text    := strTeInfoPatrimonio5;
      edTeInfoPatrimonio5.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta9 -> "'+objCacic.getValueFromTags('in_exibir_etiqueta9', strConfigsPatrimonioInterface)+'"');
   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta9', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta9.Caption         := objCacic.getValueFromTags('te_etiqueta9', strConfigsPatrimonioInterface);
      lbEtiqueta9.Visible         := true;
      edTeInfoPatrimonio6.Hint    := objCacic.getValueFromTags('te_help_etiqueta9', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio6.Text    := strTeInfoPatrimonio6;
      edTeInfoPatrimonio6.visible := True;
   end;

  Mensagem('',false,1);
  btGravarInformacoes.Visible := true;
  btCombosUpdate.Enabled      := true;

  cbIdUnidOrganizacionalNivel1.Enabled := true;
  cbIdUnidOrganizacionalNivel1.SetFocus;

  Application.ProcessMessages;
end;

procedure TfrmMapaCacic.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
  objCacic.writeDebugLog('FormClose: ' + Sender.ClassName);
  Finalizar(true);
end;

procedure TfrmMapaCacic.CriaFormSenha(Sender: TObject);
begin
    Application.CreateForm(TfrmAcesso, frmAcesso);
end;

procedure TfrmMapaCacic.mapa;
begin
  Try
    MontaInterface;
    MontaCombos;
    RecuperaValoresAnteriores;
  Except
    on E:Exception do
       Begin
         objCacic.writeExceptionLog(E.Message,e.ClassName);
       End;
  End;
End;
function TfrmMapaCacic.getConfigs : String;
Begin
  btCombosUpdate.Enabled := false;

  Result := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest,objCacic.getLocalFolderName);
  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  objCacic.writeDebugLog('FormActivate: Retorno de getConfigs: "'+Result+'"');

  if (Result <> '0') then
    Begin
      Mensagem('Comunicação Efetuada com Sucesso! Salvando as Configurações Obtidas...',false,1);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Combos'    , objCacic.getValueFromTags('Configs_Patrimonio_Combos'   , Result), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Interface' , objCacic.getValueFromTags('Configs_Patrimonio_Interface', Result), strGerColsInfFileName);
      objCacic.setValueToFile('Collects','Patrimonio_Last'      , objCacic.getValueFromTags('Collects_Patrimonio_Last'    , Result), strGerColsInfFileName);
    End;
  btCombosUpdate.Enabled := true;
End;

procedure TfrmMapaCacic.FormCreate(Sender: TObject);
begin
  Try
    strFrmAtual  := 'Principal';
    objCacic     := TCACIC.Create();

    objCacic.setBoolCipher(true);
    objCacic.setLocalFolderName('Cacic');
    objCacic.setWebServicesFolderName('ws/');

    if IsUserAnAdmin then
      Begin
        strChkSisInfFileName := objCacic.getWinDir + 'chksis.inf';

        Mensagem('Caminho local para a aplicação CACIC: "'+objCacic.GetValueFromFile('Configs','LocalFolderName',strChkSisInfFileName)+'"');
        if not (objCacic.GetValueFromFile('Configs','LocalFolderName',strChkSisInfFileName) = '') then
          Begin

            objCacic.setLocalFolderName(objCacic.GetValueFromFile('Configs','LocalFolderName',strChkSisInfFileName));
            objCacic.setWebServicesFolderName(objCacic.GetValueFromFile('Configs','WebServicesFolderName', strChkSisInfFileName));
            objCacic.setWebManagerAddress(objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName));

            strGerColsInfFileName := objCacic.getLocalFolderName + 'GerCols.inf';

            // A existência e bloqueio do arquivo abaixo evitará que o Agente Principal entre em ação
            AssignFile(textFileAguarde,objCacic.getLocalFolderName + '\temp\aguarde_MAPACACIC.txt'); {Associa o arquivo a uma variável do tipo TextFile}
            {$IOChecks off}
            Reset(textFileAguarde); {Abre o arquivo texto}
            {$IOChecks on}
            if (IOResult <> 0) then // Arquivo não existe, será recriado.
              Rewrite (textFileAguarde);

            Append(textFileAguarde);
            Writeln(textFileAguarde,'Apenas um pseudo-cookie para o Agente Principal esperar o término de MapaCACIC');
            Append(textFileAguarde);

            frmMapaCacic.edWebManagerAddress.Caption := objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName);

            frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autenticação no Módulo Gerente WEB Cacic';
            objCacic.writeDebugLog('FormActivate: Versão do MapaCacic...: ' + pnVersao.Caption);
            objCacic.writeDebugLog('FormActivate: Hash-Code do MapaCacic: ' + objCacic.getFileHash(ParamStr(0)));

            // Acessar...
            CriaFormSenha(nil);
            frmAcesso.ShowModal;

            Application.ProcessMessages;
            if boolAcessoOK then
              Begin
                Visible     := true;
                Height      := 575;
                Width       := 800;
                WindowState := wsNormal;
                Position    := poScreenCenter;

                pnMessageBox.Visible := true;
                Mensagem('Efetuando Comunicação com o Módulo Gerente WEB em "'+objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName)+'"...',false,1);
                frmAcesso.Free;

                // Povoamento com dados de configurações da interface patrimonial
                // Solicita ao servidor as configurações para a Coleta de Informações de Patrimônio
                strFieldsAndValuesToRequest := 'id_usuario=' + objCacic.replaceInvalidHTTPChars( objCacic.enCrypt(frmMapaCacic.strId_usuario));

                objCacic.writeDebugLog('FormActivate: Requisitando informações de patrimônio da estação...');

                if (getConfigs <> '0') then
                  mapa
                else
                  Sair;
              End;
          End
        else
          Begin
            frmMapaCacic.boolAcessoOK := false;
            MessageDLG(#13#10+'Atenção! É necessário reinstalar o CACIC nesta estação.' + #13#10     + #13#10 +
                              'A estrutura encontra-se corrompida.'   + #13#10,mtError,[mbOK],0);
            Application.ProcessMessages;
            frmMapaCacic.Finalizar(false);
          End;
      End
    else
      Begin // Se NT/2000/XP/...
        MessageDLG(#13#10+'ATENÇÃO! Essa aplicação requer execução com nível administrativo.',mtError,[mbOK],0);
        objCacic.writeDailyLog('SEM PRIVILÉGIOS: Necessário ser administrador "local" ou de Domínio!');
        Sair;
      End;
  Finally
  End;
end;

procedure TfrmMapaCacic.cbIdUnidOrganizacionalNivel1Click(
  Sender: TObject);
begin
  objCacic.writeDebugLog('cbIdUnidOrganizacionalNivel1Click: Click');
end;

procedure TfrmMapaCacic.FormActivate(Sender: TObject);
begin
  pnVersao.Caption := 'Versão: ' + objCacic.getVersionInfo(ParamStr(0));
  strFrmAtual := 'Principal';
end;

procedure TfrmMapaCacic.btCombosUpdateClick(Sender: TObject);
begin
  cbIdUnidOrganizacionalNivel1.Enabled  := false;
  cbIdUnidOrganizacionalNivel1a.Enabled := false;
  cbIdUnidOrganizacionalNivel2.Enabled  := false;

  getConfigs;
  MontaInterface;
  MontaCombos;
  RecuperaValoresAnteriores;
end;

procedure TfrmMapaCacic.timerMessageShowTimeTimer(Sender: TObject);
begin
  timerMessageShowTime.Enabled      := false;
  timerMessageShowTime.Interval     := 0;
  strShowOrHide                     := 'Hide';
  timerMessageBoxShowOrHide.Enabled := true;
end;

procedure TfrmMapaCacic.cbIdUnidOrganizacionalNivel1DrawItem(
  Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var sText : String;
begin
  sText := cbIdUnidOrganizacionalNivel1.Items[index];
  cbIdUnidOrganizacionalNivel1.Height := 30;
  cbIdUnidOrganizacionalNivel1.Canvas.FillRect(Rect);
  DrawText(cbIdUnidOrganizacionalNivel1.Canvas.Handle,PChar(sText),Length(sText),Rect,DT_VCENTER + DT_SINGLELINE + DT_CENTER);
end;

procedure TfrmMapaCacic.cbIdUnidOrganizacionalNivel1aDrawItem(
  Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var sText : String;
begin
  sText := cbIdUnidOrganizacionalNivel1a.Items[index];
  cbIdUnidOrganizacionalNivel1a.Height := 30;
  cbIdUnidOrganizacionalNivel1a.Canvas.FillRect(Rect);
  DrawText(cbIdUnidOrganizacionalNivel1a.Canvas.Handle,PChar(sText),Length(sText),Rect,DT_VCENTER + DT_SINGLELINE + DT_CENTER);
end;

procedure TfrmMapaCacic.cbIdUnidOrganizacionalNivel2DrawItem(
  Control: TWinControl; Index: Integer; Rect: TRect;
  State: TOwnerDrawState);
var sText : String;
begin
  sText := cbIdUnidOrganizacionalNivel2.Items[index];
  cbIdUnidOrganizacionalNivel2.Height := 30;
  cbIdUnidOrganizacionalNivel2.Canvas.FillRect(Rect);
  DrawText(cbIdUnidOrganizacionalNivel2.Canvas.Handle,PChar(sText),Length(sText),Rect,DT_VCENTER + DT_SINGLELINE + DT_CENTER);
end;

procedure TfrmMapaCacic.timerMessageBoxShowOrHideTimer(Sender: TObject);
begin
  if (strShowOrHide = 'Show') then
    if (strFrmAtual = 'Acesso') then
      frmAcesso.pnMessageBox.Height    := frmAcesso.pnMessageBox.Height + 1
    else
      frmMapaCacic.pnMessageBox.Height := frmMapaCacic.pnMessageBox.Height + 1
  else
    if (strFrmAtual = 'Acesso') then
      frmAcesso.pnMessageBox.Height    := frmAcesso.pnMessageBox.Height - 1
    else
      frmMapaCacic.pnMessageBox.Height := frmMapaCacic.pnMessageBox.Height - 1;

  if (strFrmAtual = 'Acesso')    and (frmAcesso.pnMessageBox.Height    = 0)  or
     (strFrmAtual = 'Acesso')    and (frmAcesso.pnMessageBox.Height    = 45) or
     (strFrmAtual = 'Principal') and (frmMapaCacic.pnMessageBox.Height = 0)  or
     (strFrmAtual = 'Principal') and (frmMapaCacic.pnMessageBox.Height = 45) then
  Begin
    timerMessageBoxShowOrHide.Enabled := false;
    if timerMessageShowTime.Interval > 0 then
      timerMessageShowTime.Enabled := true;
  End;
end;

end.
