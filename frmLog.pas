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

unit frmLog;

interface
uses Forms, StdCtrls, Classes, Controls, SysUtils, ExtCtrls;
{
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, Buttons, Dialogs, Grids;
}

type
  TFormLog = class(TForm)
    MemoLog: TMemo;
    Bt_Fechar_Log: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Bt_Fechar_LogClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormLog: TFormLog;

implementation

{$R *.dfm}

Uses main;

procedure TFormLog.FormCreate(Sender: TObject);
var
  sl: TStringList;
  begin
    sl := TStringList.Create;
    try
      FormularioGeral.log_diario('');

      sl.LoadFromFile(ExtractFilePath(Application.Exename) + '\cacic2.log');
      MemoLog.Text := '';
      MemoLog.SetSelTextBuf(PChar(sl.Text));
    finally
      sl.Free;
  end;
end;


procedure TFormLog.Bt_Fechar_LogClick(Sender: TObject);
begin
  Release;
  Close;
end;


procedure TFormLog.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   Release;
   Close;
end;


end.
