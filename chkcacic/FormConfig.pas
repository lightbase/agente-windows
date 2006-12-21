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
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,main, PJVersionInfo, NTFileSecurity;

type
  TConfigs = class(TForm)
    Edit_ip_serv_cacic: TEdit;
    Edit_cacic_dir: TEdit;
    GroupBox1: TGroupBox;
    Label_ip_serv_cacic: TLabel;
    Label_cacic_dir: TLabel;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label_te_instala_frase_sucesso: TLabel;
    Edit_te_instala_frase_sucesso: TEdit;
    Label_te_instala_frase_insucesso: TLabel;
    Edit_te_instala_frase_insucesso: TEdit;
    Label_te_instala_informacoes_extras: TLabel;
    Button_Gravar: TButton;
    Memo_te_instala_informacoes_extras: TMemo;
    PJVersionInfo1: TPJVersionInfo;
    Label2: TLabel;
    procedure Button_GravarClick(Sender: TObject);
    procedure Edit_ip_serv_cacicExit(Sender: TObject);
    procedure Edit_cacic_dirExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Configs: TConfigs;

implementation

{$R *.dfm}

procedure TConfigs.Button_GravarClick(Sender: TObject);
begin
  main.GravaConfiguracoes;
  Close;
end;
procedure TConfigs.Edit_ip_serv_cacicExit(Sender: TObject);
begin
if trim(Edit_ip_serv_cacic.Text) = '' then Edit_ip_serv_cacic.SetFocus;
end;

procedure TConfigs.Edit_cacic_dirExit(Sender: TObject);
begin
if trim(Edit_cacic_dir.Text) = '' then Edit_cacic_dir.Text := 'Cacic';
end;

end.
