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
  Buttons, StdCtrls, ExtCtrls, main, dialogs;

type
  TFormConfiguracoes = class(TForm)
    Lb_End_Serv_Aplicacao: TLabel;
    EditEnderecoServidorAplicacao: TEdit;
    BtN_Confirmar: TButton;
    Btn_Desinstalar: TButton;
    Bv1_Configuracoes: TBevel;
    Btn_Cancelar: TButton;
    Btn_OK: TButton;
    Lb_End_Serv_Updates: TLabel;
    EditEnderecoServidorUpdates: TEdit;
    procedure pro_Btn_OK(Sender: TObject);
    procedure pro_Btn_Cancelar(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure pro_Btn_Confirmar(Sender: TObject);
    procedure pro_Btn_Desinstalar(Sender: TObject);
    procedure AtualizaConfiguracoes(Chave, Valor : String);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormConfiguracoes: TFormConfiguracoes;

implementation


{$R *.dfm}

procedure TFormConfiguracoes.AtualizaConfiguracoes(Chave, Valor: String);
begin
    ///Falta validar se o endereco é valido. E se for nome?
    FormularioGeral.SetValorDatMemoria(Chave, Valor, v_tstrCipherOpened);
end;

procedure TFormConfiguracoes.pro_Btn_OK(Sender: TObject);
begin
    AtualizaConfiguracoes('Configs.EnderecoServidor',EditEnderecoServidorAplicacao.Text);
    AtualizaConfiguracoes('Configs.TE_SERV_UPDATES' ,EditEnderecoServidorUpdates.Text);
    FormularioGeral.CipherClose;
    release;
    Close;
end;

procedure TFormConfiguracoes.pro_Btn_Cancelar(Sender: TObject);
begin
  release;
  Close;
end;


procedure TFormConfiguracoes.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Release;
   close;
end;


procedure TFormConfiguracoes.FormCreate(Sender: TObject);
var v_ID_SO : String;
begin
  EditEnderecoServidorAplicacao.Text := FormularioGeral.GetValorDatMemoria('Configs.EnderecoServidor',v_tstrCipherOpened);
  EditEnderecoServidorUpdates.Text := FormularioGeral.GetValorDatMemoria('Configs.TE_SERV_UPDATES',v_tstrCipherOpened);
  v_ID_SO := trim(FormularioGeral.GetValorDatMemoria('Configs.ID_SO',v_tstrCipherOpened));
  Btn_Desinstalar.Visible := FALSE;
  If (v_ID_SO <> '') and (StrToInt(v_ID_SO) in [1, 2, 3, 4, 5]) then
    begin
    //Se for Win9x/ME
    Btn_Desinstalar.Visible := TRUE;
    end;
end;

procedure TFormConfiguracoes.pro_Btn_Confirmar(Sender: TObject);
Begin
   If Trim(EditEnderecoServidorAplicacao.Text) = '' Then
   Begin
      MessageDlg('Erro na instalação: ' + #13#10 + 'Não foi especificado o endereço do servidor do CACIC.', mtInformation, [mbOk], 0);
      Exit;
   end;
   If Trim(EditEnderecoServidorUpdates.Text) = '' Then
   Begin
      MessageDlg('Erro na instalação: ' + #13#10 + 'Não foi especificado o endereço do servidor de Updates do CACIC.', mtInformation, [mbOk], 0);
      Exit;
   end;

   try
     FormConfiguracoes.AtualizaConfiguracoes('Configs.EnderecoServidor',Trim(EditEnderecoServidorAplicacao.Text));
   finally
   end;
   try
     FormConfiguracoes.AtualizaConfiguracoes('Configs.TE_SERV_UPDATES',Trim(EditEnderecoServidorUpdates.Text));
   finally
   end;
   FormularioGeral.CipherClose;
   release;
   close;
end;




procedure TFormConfiguracoes.pro_Btn_Desinstalar(Sender: TObject);
begin
   FormularioGeral.DelValorReg('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\cacic2');
   FormConfiguracoes.Visible := false;
   MessageDlg('O CACIC não será mais executado automaticamente durante a inicialização do Windows. O arquivo ' + Application.ExeName + ' não será removido do seu computador, permitindo que seja realizada a instalação novamente.', mtInformation, [mbOk], 10);
   close;
end;
end.
