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

unit FormConfig;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  main,
  NTFileSecurity,
  Buttons,
  ExtCtrls, ComCtrls;

type
  TConfigs = class(TForm)
    Edit_TeWebManagerAddress: TEdit;
    Edit_TeLocalFolder: TEdit;
    gbMandatory: TGroupBox;
    Label_TeWebManagerAddress: TLabel;
    Label_TeLocalFolder: TLabel;
    gbOptional: TGroupBox;
    lbMensagemNaoAplicavel: TLabel;
    Label_TeProcessInformations: TLabel;
    Button_ConfirmProcess: TButton;
    Memo_TeExtrasProcessInformations: TMemo;
    checkboxInShowProcessInformations: TCheckBox;
    Button_ExitProcess: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    pnVersao: TPanel;
    gbProgress: TGroupBox;
    memoProgress: TMemo;
    pnStatus: TPanel;
    staticStatus: TStaticText;
    timerGeneral: TTimer;
    labelMandatoryField: TStaticText;
    labelActionsLog: TStaticText;
    labelOptionalsInformations: TStaticText;
    staticClickToExpand: TStaticText;
    procedure Button_ConfirmProcessClick(Sender: TObject);
    procedure checkboxInShowProcessInformationsClick(Sender: TObject);
    procedure Button_ExitProcessClick(Sender: TObject);
    procedure Edit_TeWebManagerAddressExit(Sender: TObject);
    procedure StatusBar_TestAndVersionDrawPanel(StatusBar: TStatusBar;
      Panel: TStatusPanel; const Rect: TRect);

    procedure FormActivate(Sender: TObject);
    procedure ResizeGbOptional;
    procedure timerGeneralTimer(Sender: TObject);
    procedure staticClickToExpandClick(Sender: TObject);
    procedure labelOptionalsInformationsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Configs: TConfigs;
  strAction : String;


implementation

{$R *.dfm}

procedure TConfigs.Button_ConfirmProcessClick(Sender: TObject);
begin
  if trim(Edit_TeLocalFolder.Text) = '' then
    Edit_TeLocalFolder.Text := 'Cacic';

  if trim(Edit_TeWebManagerAddress.Text)  = '' then
    Edit_TeWebManagerAddress.SetFocus
  else
    Begin
      main.GravaConfiguracoes;
      Close;
//      Application.terminate;
    End;
end;

procedure TConfigs.checkboxInShowProcessInformationsClick(Sender: TObject);
begin
  if checkboxInShowProcessInformations.Checked then
    Begin
      Memo_TeExtrasProcessInformations.Enabled := true;
      Memo_TeExtrasProcessInformations.Color   := clWindow;
      v_InShowProcessInformations := 'S';
    End
  else
    Begin
      Memo_TeExtrasProcessInformations.Enabled := false;
      Memo_TeExtrasProcessInformations.Color   := clInactiveBorder;
      v_InShowProcessInformations := 'N';
    End;
end;

procedure TConfigs.Button_ExitProcessClick(Sender: TObject);
begin
  Close;
  Halt(0);
end;

procedure TConfigs.Edit_TeWebManagerAddressExit(Sender: TObject);
begin
  if (trim(Edit_TeWebManagerAddress.Text)<> '') then
    Begin
      v_TeWebManagerAddress   := Configs.Edit_TeWebManagerAddress.text;

      staticStatus.Caption := 'Efetuando comunicação com o endereço informado...';

      tstringlistRequest_Config.Clear;
      tstringlistRequest_Config.Values['in_chkcacic'] := 'chkcacic_GetTest';

      Edit_TeWebManagerAddress.Text := StringReplace(Edit_TeWebManagerAddress.Text,'http://','',[rfReplaceAll]);
      Button_ConfirmProcess.Enabled := frmChkCACIC.CommunicateTo(Edit_TeWebManagerAddress.Text + '/ws/get_test.php',tstringlistRequest_Config);

      if Button_ConfirmProcess.Enabled then
        Begin
          staticStatus.Caption := 'Teste de Comunicação Efetuado Com Sucesso!';
          staticStatus.Font.Color := clGreen;
        End
      else
        Begin
          staticStatus.Caption := 'Insucesso no Teste de Comunicação com o Endereço Informado!';
          staticStatus.Font.Color := clRed;
        End;
    End
  else
    staticStatus.Caption := '';
end;

procedure TConfigs.StatusBar_TestAndVersionDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
begin

with StatusBar.Canvas do
   begin
     case Panel.Index of
       0: //fist panel
       begin
         if Button_ConfirmProcess.Enabled or (trim(Panel.Text)='') then
           Brush.Color := clCream
         else
           Brush.Color := clYellow;

         Panel.Alignment := taCenter;
         Font.Color := clNavy;
         Font.Style := [fsBold];
       end;
       1: //second panel
       begin
         Brush.Color := clCream;
         Font.Color := clBlack;
         Font.Style := [];
         Panel.Alignment := taCenter;
       end;
     end;
     //Panel background color
     FillRect(Rect) ;

     //Panel Text
     TextRect(Rect,Rect.Left,Rect.Top,Panel.Text) ;
   end;
end;

procedure TConfigs.FormActivate(Sender: TObject);
begin
  Edit_TeWebManagerAddressExit(nil);
end;

procedure TConfigs.timerGeneralTimer(Sender: TObject);
begin
if (Copy(strAction,1,17) = 'Resize_gbOptional') then
  Begin
    if (Trim(Copy(strAction,19,4)) = 'DOWN') then
      gbOptional.Height := gbOptional.Height + 1
    else
      gbOptional.Height := gbOptional.Height - 1;

    if (gbOptional.Height = 0) or (gbOptional.Height = 200) then
      Begin
        timerGeneral.Enabled := false;
        if (gbOptional.Height = 200) then
          staticClickToExpand.Caption := '(Clique para ENCOLHER o Painel)'
        else
          staticClickToExpand.Caption := '(Clique para EXPANDIR o Painel)';
      End;
  End;
end;

procedure TConfigs.staticClickToExpandClick(Sender: TObject);
begin
  ResizeGbOptional;
end;

procedure TConfigs.labelOptionalsInformationsClick(Sender: TObject);
begin
  ResizeGbOptional;
end;

procedure TConfigs.ResizeGbOptional;
Begin
  strAction := 'Resize_gbOptional_';
  if (gbOptional.Height = 0) then
    strAction := strAction + 'DOWN'
  else
    strAction := strAction + 'UP';

  staticClickToExpand.Caption := '';
  timerGeneral.Enabled  := false;
  timerGeneral.Interval := 10;
  timerGeneral.Enabled  := true;
End;
end.
