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
uses  Forms,
      StdCtrls,
      Classes,
      Controls,
      SysUtils,
      ExtCtrls,
      ComCtrls;

type
  TFormLog = class(TForm)
    MemoLog: TMemo;
    Bt_Fechar_Log: TButton;
    listLogsDisponiveis: TListView;
    staticLogsDisponiveis: TStaticText;
    staticVisualizacao: TStaticText;
    procedure Bt_Fechar_LogClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure listLogsDisponiveisClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    procedure findLogFiles;
  public
    { Public declarations }
  end;

var
  FormLog           : TFormLog;
  itemIndexAtual    : integer;
  strLogsFolderName : String;

implementation

{$R *.dfm}

Uses main;

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


procedure TFormLog.listLogsDisponiveisClick(Sender: TObject);
var sl: TStringList;
begin
  if (listLogsDisponiveis.ItemIndex >= 0) then
    Begin
      sl := TStringList.Create;
      sl.Sorted := false;

      try
        MemoLog.Clear;
        sl.LoadFromFile(objCACIC.getLocalFolderName + strLogsFolderName + '\' + listLogsDisponiveis.Items[listLogsDisponiveis.ItemIndex].Caption);
        staticVisualizacao.Caption := 'Visualização (' + objCACIC.getLocalFolderName + strLogsFolderName + '\' + listLogsDisponiveis.Items[listLogsDisponiveis.ItemIndex].Caption + ')';
        itemIndexAtual := listLogsDisponiveis.ItemIndex;
        MemoLog.SetSelTextBuf(PChar(sl.Text));
      finally
        sl.Free;
      end;
    End
  else
    listLogsDisponiveis.ItemIndex := itemIndexAtual;
end;

procedure TFormLog.findLogFiles;
var SearchRec : TSearchRec;
    intSearch : Integer;
    listItem  : TListItem;
begin
  objCACIC.writeDebugLog('findLogFiles: BEGIN');
  listLogsDisponiveis.Clear;

  Try
    intSearch := FindFirst(objCACIC.getLocalFolderName + strLogsFolderName + '\*.log', faAnyFile, SearchRec);

    while intSearch = 0 do
      begin
        listItem := listLogsDisponiveis.Items.Add;
        listItem.Caption := SearchRec.Name;

        listItem.SubItems.Add(DateToStr(FileDateToDateTime(FileAge(objCACIC.getLocalFolderName + strLogsFolderName + '\' + SearchRec.Name))));
        listItem.SubItems.Add(objCACIC.getFileSize(objCACIC.getLocalFolderName + strLogsFolderName +  '\' + SearchRec.Name,true));

        intSearch := FindNext(SearchRec);
      end;
    listLogsDisponiveis.ItemIndex := itemIndexAtual;
  Finally
    SysUtils.FindClose(SearchRec);
  End;
  objCACIC.writeDebugLog('findLogFiles: END');
end;

procedure TFormLog.FormActivate(Sender: TObject);
begin
  itemIndexAtual    := 0;
  g_intStatus       := -1;
  strLogsFolderName := 'Logs';

  findLogFiles;
  listLogsDisponiveisClick(self);
end;

end.
