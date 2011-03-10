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

unit frmConfiguracoes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Buttons, StdCtrls, ExtCtrls, main,dialogs;

type
  TFormConfiguracoes = class(TForm)
    Label_WebManagerAddress: TLabel;
    Edit_WebManagerAddress: TEdit;
    BtN_Confirmar: TButton;
    Bv1_Configuracoes: TBevel;
    Btn_Cancelar: TButton;
    Btn_OK: TButton;
    procedure pro_Btn_OK(Sender: TObject);
    procedure pro_Btn_Cancelar(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure pro_Btn_Confirmar(Sender: TObject);
    procedure AtualizaConfiguracoes(p_strSectionName, p_strKeyName, p_strValue : String);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormConfiguracoes: TFormConfiguracoes;

implementation

uses CACIC_Library;


{$R *.dfm}

procedure TFormConfiguracoes.AtualizaConfiguracoes(p_strSectionName, p_strKeyName, p_strValue : String);
begin
    g_oCacic.setValueToFile(p_strSectionName, p_strKeyName, g_oCacic.enCrypt( p_strValue), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
end;

procedure TFormConfiguracoes.pro_Btn_OK(Sender: TObject);
begin
    AtualizaConfiguracoes('Configs','TeWebManagerAddress',Edit_WebManagerAddress.Text);
    Btn_Cancelar.Click;
end;

procedure TFormConfiguracoes.pro_Btn_Cancelar(Sender: TObject);
begin
  release;
  Close;
end;


procedure TFormConfiguracoes.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Btn_Cancelar.Click;
end;


procedure TFormConfiguracoes.FormCreate(Sender: TObject);
begin
  Edit_WebManagerAddress.Text      := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
end;

procedure TFormConfiguracoes.pro_Btn_Confirmar(Sender: TObject);
Begin
   If Trim(Edit_WebManagerAddress.Text) = '' Then
   Begin
      MessageDlg('Erro na configuração: ' + #13#10 + 'Não foi especificado o endereço do servidor do CACIC.', mtInformation, [mbOk], 0);
      Exit;
   end;

   try
     FormConfiguracoes.AtualizaConfiguracoes('Configs','TeWebManagerAddress',Trim(Edit_WebManagerAddress.Text));
   finally
   end;
   Btn_Cancelar.Click;
end;

end.
