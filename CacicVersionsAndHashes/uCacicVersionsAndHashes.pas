unit uCacicVersionsAndHashes;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  StdCtrls,
  StrUtils,
  ExtCtrls,
  ImgList,
  ComCtrls,
  inifiles,
  dialogs,
  CACIC_Library;

type
  TfrmCacicVersionsAndHashes = class(TForm)
    ItemsList           : TListView;
    Label1              : TLabel;
    Label2              : TLabel;
    ImageList1          : TImageList;
    pnVersion: TPanel;
    pnComandos          : TPanel;
    btRenew: TButton;
    Bt_Fechar           : TButton;
    Panel2              : TPanel;
    lbMensagens         : TLabel;
    procedure           FormCreate(Sender: TObject);
    procedure           Bt_FecharClick(Sender: TObject);
    procedure           RefreshList;
    procedure           btRenewClick(Sender: TObject);
    procedure           ItemsListAdvancedCustomDrawSubItem(Sender: TCustomListView;Item: TListItem; SubItem: Integer; State: TCustomDrawState;Stage:  TCustomDrawStage; var DefaultDraw: Boolean);
    procedure           RemontaVersoesINI(pStrSectionsIdentsAndValues : String);
    function            InsertItemLISTA(pStrName , pStrVerINI , pStrVerEXE , pStrSize , pStrDate , pStrHashINI , pStrHashEXE : string; pBoolEqualsVersions : boolean) : boolean;
    function            getLinuxItemData(pStrLinuxItemName:String) : TStrings;
    function            getOnlyFileName(pStrFileNameWithSlashs : String) : String;
  private
    { Private declarations }
  public
  end;

var
  frmCacicVersionsAndHashes: TfrmCacicVersionsAndHashes;
  g_oCacic                 : TCACIC;
  arrItemData,
  arrItemDefinitions       : TStrings;
  strVersionsIniFileName   : String;
  boolIsLinuxItem          : boolean;

implementation

{$R *.DFM}
function  TfrmCacicVersionsAndHashes.getOnlyFileName(pStrFileNameWithSlashs : String) : String;
var tstrGOFN : TStrings;
    strGOFN  : String;
Begin
  if (pStrFileNameWithSlashs <> '') then
    Begin
      tstrGOFN := g_oCacic.explode(pStrFileNameWithSlashs,',');
      strGOFN  := StringReplace(tstrGOFN[0],'/','#SLASH#',[rfReplaceAll]);
      strGOFN  := StringReplace(strGOFN    ,'\','#SLASH#',[rfReplaceAll]);
      tstrGOFN := g_oCacic.explode(strGOFN,'#SLASH#');
      Result   := tstrGOFN[tstrGOFN.count - 1];
    End
  else
    Result     := '';
End;

procedure TfrmCacicVersionsAndHashes.FormCreate(Sender: TObject);
var strAux : String;
begin
  g_oCacic               := TCACIC.Create;
  pnVersion.Caption      := 'v: ' + g_oCacic.getVersionInfo(ParamStr(0));

  strVersionsIniFileName := ExtractFilePath(ParamStr(0)) + 'versions_and_hashes.ini';

  if not FileExists(strVersionsIniFileName) then
    Begin
      g_oCacic.setValueToFile('Importante'      ,'Atenção '     ,'> Os ítems devem se referir aos caminhos relativos à posição do CacicVersionsAndHashes.exe.' , strVersionsIniFileName);
      g_oCacic.setValueToFile('Importante'      ,'Informação 1:','Nome do ítem a ser identificado e listado;'                                                  , strVersionsIniFileName);
      g_oCacic.setValueToFile('Importante'      ,'Informação 2:','S/N -> Indica se o ítem deve ser mostrado na opção "Downloads" do Gerente WEB;'              , strVersionsIniFileName);
      g_oCacic.setValueToFile('Importante'      ,'Informação 3:','S/N -> Indica se o ítem refere-se ao S.O. GNU/Linux.'                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_1'       ,'cacic280.exe    ,N,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_2'       ,'cacicservice.exe,N,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_3'       ,'chksis.exe      ,N,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_4'       ,'gercols.exe     ,N,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_5'       ,'installcacic.exe,S,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_6'       ,'mapacacic.exe   ,S,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_7'       ,'srcacicsrv.exe  ,N,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_8'       ,'srcaciccli.exe  ,S,N'                                                                        , strVersionsIniFileName);
      g_oCacic.setValueToFile('ItemsDefinitions','Item_9'       ,'pyCACIC         ,S,S'                                                                        , strVersionsIniFileName);
    End;

  arrItemDefinitions := g_oCacic.explode(g_oCacic.getValueFromFile('ItemsDefinitions' , 'Item_1', strVersionsIniFileName),',');
  if not FileExists(trim(arrItemDefinitions[0])) then
    btRenewClick(nil)
  else
    RefreshList;
end;

procedure TfrmCacicVersionsAndHashes.RemontaVersoesINI(pStrSectionsIdentsAndValues : String);
var iniFile                     : TIniFile;
    intLoopItemsRemontaINI      : integer;
    arrSectionsIdentsAndValues,
    arrItemsRemontaINI          : TStrings;
begin
  arrItemsRemontaINI  := g_oCacic.explode(pStrSectionsIdentsAndValues,'#');
  iniFile             := TIniFile.Create(strVersionsIniFileName);

  if (FileGetAttr(strVersionsIniFileName) and faReadOnly) > 0 then
     FileSetAttr(strVersionsIniFileName, FileGetAttr(strVersionsIniFileName) xor faReadOnly);

  for intLoopItemsRemontaINI := 0 to (arrItemsRemontaINI.Count -1) do
    Begin
      arrSectionsIdentsAndValues := g_oCacic.explode(arrItemsRemontaINI[intLoopItemsRemontaINI],',');
      iniFile.WriteString(arrSectionsIdentsAndValues[0], arrSectionsIdentsAndValues[1],arrSectionsIdentsAndValues[2]);
    End;

  iniFile.Free;
End;

function TfrmCacicVersionsAndHashes.InsertItemLISTA(pStrName , pStrVerINI , pStrVerEXE , pStrSize , pStrDate , pStrHashINI , pStrHashEXE : string; pBoolEqualsVersions : boolean) : boolean;
var intLoopInserItemLISTA : integer;
Begin
  if (pStrHashEXE <> '0') then
    Begin
      intLoopInserItemLISTA := frmCacicVersionsAndHashes.ItemsList.Items.Count;

      frmCacicVersionsAndHashes.ItemsList.Items.Add;
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].Caption := '';
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrName);
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrVerINI);
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrVerEXE);
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrSize);
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrDate);
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrHashINI);
      frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].SubItems.Add(pStrHashEXE);

      if pBoolEqualsVersions then
        frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].ImageIndex := 1
      else
        frmCacicVersionsAndHashes.ItemsList.Items[intLoopInserItemLISTA].ImageIndex := 0;
    End;
End;

procedure TfrmCacicVersionsAndHashes.RefreshList;
var strThinNameItemToRefresh      : string;
    boolActivateRenew,
    boolEqualsVersions            : boolean;
    intLoopItemsRefresh           : integer;
begin
  Screen.Cursor := crHourglass;
  ItemsList.Clear;

  boolActivateRenew           := false;

  intLoopItemsRefresh         := 0;
  strThinNameItemToRefresh    := '.';

  Try
    While (strThinNameItemToRefresh <> '') do
      Begin
        inc(intLoopItemsRefresh);
        boolEqualsVersions       := true;
        strThinNameItemToRefresh := '';
        arrItemDefinitions       := g_oCacic.explode(g_oCacic.getValueFromFile('ItemsDefinitions' , 'Item_' + IntToStr(intLoopItemsRefresh) , strVersionsIniFileName),',');

        if FileExists(Trim(arrItemDefinitions[0])) then
          Begin
            strThinNameItemToRefresh := getOnlyFileName(Trim(arrItemDefinitions[0]));
            boolIsLinuxItem := ((arrItemDefinitions.Count > 2) and (Trim(arrItemDefinitions[2]) = 'S'));
            if boolIsLinuxItem then
              arrItemData := getLinuxItemData(Trim(arrItemDefinitions[0]))
            else
              arrItemData := g_oCacic.explode(Trim(arrItemDefinitions[0])                                         + ',' +
                                              g_oCacic.getVersionInfo(Trim(arrItemDefinitions[0]))                + ',' +
                                              g_oCacic.getFileHash(Trim(arrItemDefinitions[0]))                   + ',' +
                                              DateToStr(FileDateToDateTime(FileAge(Trim(arrItemDefinitions[0])))) + ',' +
                                              g_oCacic.getFileSize(Trim(arrItemDefinitions[0]),true),',');

            if (g_oCacic.getValueFromFile('ItemsValues' , strThinNameItemToRefresh + '_VER' , strVersionsIniFileName) = '') then
              Begin
                g_oCacic.setValueToFile('ItemsValues' , strThinNameItemToRefresh + '_PATH' , arrItemData[0], strVersionsIniFileName);
                g_oCacic.setValueToFile('ItemsValues' , strThinNameItemToRefresh + '_VER'  , arrItemData[1], strVersionsIniFileName);
                g_oCacic.setValueToFile('ItemsValues' , strThinNameItemToRefresh + '_HASH' , arrItemData[2], strVersionsIniFileName);
                g_oCacic.setValueToFile('ItemsValues' , strThinNameItemToRefresh + '_DATE' , arrItemData[3], strVersionsIniFileName);
                g_oCacic.setValueToFile('ItemsValues' , strThinNameItemToRefresh + '_SIZE' , arrItemData[4], strVersionsIniFileName);
              End
            else if (g_oCacic.getValueFromFile('ItemsValues' , strThinNameItemToRefresh + '_HASH' , strVersionsIniFileName) <> arrItemData[2]) then
              Begin
                boolEqualsVersions := false;
                boolActivateRenew  := true;
              End;

            InsertItemLISTA(strThinNameItemToRefresh,
                            g_oCacic.getValueFromFile('ItemsValues' , strThinNameItemToRefresh + '_VER' , strVersionsIniFileName),
                            arrItemData[1],
                            g_oCacic.getFileSize(Trim(arrItemDefinitions[0]),true),
                            arrItemData[3],
                            g_oCacic.getValueFromFile('ItemsValues' ,strThinNameItemToRefresh + '_HASH' , strVersionsIniFileName),
                            arrItemData[2],
                            boolEqualsVersions);
          End; //      if ( strNameItemToRefresh <> '') then
      End;
  finally
    ItemsList.Show;
    Screen.Cursor   := crDefault;
    btRenew.Enabled := boolActivateRenew;
  end;
end;

function TfrmCacicVersionsAndHashes.getLinuxItemData(pStrLinuxItemName:String) : TStrings;
Begin
  Result := g_oCacic.Explode(StringReplace(pStrLinuxItemName,'.tgz','',[rfReplaceAll]),'_');
End;

procedure TfrmCacicVersionsAndHashes.Bt_FecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCacicVersionsAndHashes.btRenewClick(Sender: TObject);
var iniFile : TIniFile;
begin
  iniFile := TIniFile.Create(strVersionsIniFileName);
  iniFile.EraseSection('ItemsValues');
  iniFile.Free;

  RefreshList;
end;

procedure TfrmCacicVersionsAndHashes.ItemsListAdvancedCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
  // Verifico se a imagem para o ítem é 0(zero) => DIFERENTE ou 1(um) IGUAL
  // Coloco em vermelho quando for DIFERENTE...
  if (item.ImageIndex = 0) then
    Begin
      Sender.Canvas.Font.Color := clRed;
      if (SubItem = 2) or (SubItem = 3) then Sender.Canvas.Font.Style := Sender.Canvas.Font.Style + [fsBold];
    End;
end;
end.
