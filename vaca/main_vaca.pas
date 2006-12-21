unit main_vaca;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ImgList, ComCtrls, PJVersionInfo, inifiles;

type
  TForm1 = class(TForm)
    List: TListView;
    Bt_Fechar: TButton;
    Bt_VAI: TButton;
    PJVersionInfo1: TPJVersionInfo;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ImageList1: TImageList;
    Image1: TImage;
    Panel1: TPanel;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Bt_FecharClick(Sender: TObject);
    function  GetVersionInfo(p_File: string):string;
    function  VerFmt(const MS, LS: DWORD): string;
    Function  ListFileDir(Path,p_exception : string):string;
    Function  Explode(Texto, Separador : String) : TStrings;
    function  SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
    function  GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
    function  Get_File_Size(sFileToExamine: string; bInKBytes: Boolean): string;
    procedure Refresh;
    procedure Bt_VAIClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure ListAdvancedCustomDrawSubItem(Sender: TCustomListView;
      Item: TListItem; SubItem: Integer; State: TCustomDrawState;
      Stage: TCustomDrawStage; var DefaultDraw: Boolean);
  private
    { Private declarations }
  public
  end;

var
  Form1: TForm1;
  v_versao_INI, v_versao_EXE : string;

implementation

{$R *.DFM}
//Para gravar no Arquivo INI...
function TForm1.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
    File_Ini    : TextFile;
begin
//    FileSetAttr (p_Path,0);
    {
    To remove write protection on a file:
    Den Schreibschutz einer Datei aufheben:
    }
    if (FileGetAttr(p_Path) and faReadOnly) > 0 then
      FileSetAttr(p_Path, FileGetAttr(p_Path) xor faReadOnly);

    Reg_Ini := TIniFile.Create(p_Path);
    Reg_Ini.WriteString(p_Secao, p_Chave, p_Valor);
    Reg_Ini.Free;
end;

//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
function TForm1.GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    Result := '';
    v_SectionName := '[' + p_SectionName + ']';
    v_Size_Section := strLen(PChar(v_SectionName));
    v_KeyName := p_KeyName + '=';
    v_Size_Key     := strLen(PChar(v_KeyName));
    FileText := TStringList.Create;
    try
      FileText.LoadFromFile(p_IniFileName);
      For i := 0 To FileText.Count - 1 Do
        Begin
          if (LowerCase(Trim(PChar(Copy(FileText[i],1,v_Size_Section)))) = LowerCase(Trim(PChar(v_SectionName)))) then
            Begin
              For j := i to FileText.Count - 1 Do
                Begin
                  if (LowerCase(Trim(PChar(Copy(FileText[j],1,v_Size_Key)))) = LowerCase(Trim(PChar(v_KeyName)))) then
                    Begin
                      Result := PChar(Copy(FileText[j],v_Size_Key + 1,strLen(PChar(FileText[j]))-v_Size_Key));
                      Break;
                    End;
                End;
            End;
          if (Result <> '') then break;
        End;
    finally
      FileText.Free;
    end;
  end;
function TForm1.Get_File_Size(sFileToExamine: string; bInKBytes: Boolean): string;
var
  SearchRec: TSearchRec;
  sgPath: string;
  inRetval, I1: Integer;
begin
  sgPath := ExpandFileName(sFileToExamine);
  try
    inRetval := FindFirst(ExpandFileName(sFileToExamine), faAnyFile, SearchRec);
    if inRetval = 0 then
        if bInKBytes then I1 := SearchRec.Size DIV 1024 else I1 := SearchRec.Size
    else
      I1 := -1;
  finally
    SysUtils.FindClose(SearchRec);
  end;
  Result := IntToStr(I1);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Label4.Caption := 'v: '+GetVersionInfo(ExtractFilePath(Application.Exename)+'vaca.exe');
  Refresh;
end;

procedure TForm1.Refresh;
var v_modulos : string;
    v_array_modulos : TStrings;
    intAux, v_conta_itens, v_pointer : integer;
    v_mostra_atualiza : boolean;
begin
  Caption:='VACA - Versões de Agentes do CACIC';
  Screen.Cursor:=crHourglass;
  List.Clear;
  v_mostra_atualiza := false;
  v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'*.exe',ExtractFileName(Application.Exename));
  v_pointer := 0;
  Try
    if (v_modulos <> '') then
      Begin
        v_array_modulos := explode(v_modulos,'#');
        v_conta_itens :=0;
        if FileExists(ExtractFilePath(Application.Exename)+'versoes_agentes.ini') then
          Begin
            For intAux := 0 To v_array_modulos.count -1 Do
              Begin
                if (GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
                  Begin
                    v_versao_INI := GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
                    v_versao_EXE := GetVersionInfo(v_array_modulos[intAux]);
                    List.Items.Add;
                    List.Items[v_conta_itens].Caption := '';
                    List.Items[v_conta_itens].SubItems.Add(v_array_modulos[intAux]);
                    List.Items[v_conta_itens].SubItems.Add(v_versao_INI);
                    List.Items[v_conta_itens].SubItems.Add(v_versao_EXE);
                    List.Items[v_conta_itens].SubItems.Add(Get_File_Size(v_array_modulos[intAux],true));
                    List.Items[v_conta_itens].SubItems.Add(DateToStr(FileDateToDateTime(FileAge(v_array_modulos[intAux]))));

                    if (v_versao_INI = GetVersionInfo(v_array_modulos[intAux])) then
                      List.Items[v_conta_itens].ImageIndex := 1
                    else
                      Begin
                        List.Items[v_conta_itens].ImageIndex := 0;
                        v_mostra_atualiza := true;
                      End;

                    v_conta_itens := v_conta_itens + 1;
                  End;
              End;
          End
        else
          Begin
            For intAux := 0 To v_array_modulos.count -1 Do
              Begin
                v_versao_EXE := GetVersionInfo(v_array_modulos[intAux]);
                v_versao_INI := v_versao_EXE;
                SetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],v_versao_INI,ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
                List.Items.Add;
                List.Items[v_conta_itens].Caption := '';
                List.Items[v_conta_itens].SubItems.Add(v_array_modulos[intAux]);
                List.Items[v_conta_itens].SubItems.Add(v_versao_INI);
                List.Items[v_conta_itens].SubItems.Add(v_versao_EXE);
                List.Items[v_conta_itens].SubItems.Add(Get_File_Size(v_array_modulos[intAux],true));
                List.Items[v_conta_itens].SubItems.Add(DateToStr(FileDateToDateTime(FileAge(v_array_modulos[intAux]))));
                List.Items[v_conta_itens].ImageIndex := 1;
                v_conta_itens := v_conta_itens + 1;
              End;
          End;
      End;
  finally
    List.Show;
    Screen.Cursor:=crdefault;
    Bt_VAI.Enabled := v_mostra_atualiza;
  end;
end;

Function TForm1.ListFileDir(Path,p_exception : string):string;
var
  SR: TSearchRec;
  FileList : string;
begin
  if FindFirst(Path, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) and (SR.Name <> p_exception) then
      begin
        if (FileList<>'') then FileList := FileList + '#';
        FileList := FileList + SR.Name;
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
    Result := FileList;
  end;
end;

procedure TForm1.Bt_FecharClick(Sender: TObject);
begin
  Close;
end;
function TForm1.GetVersionInfo(p_File: string):string;
begin
  PJVersionInfo1.FileName := PChar(p_File);
  Result := Form1.VerFmt(Form1.PJVersionInfo1.FixedFileInfo.dwFileVersionMS, Form1.PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
end;

function TForm1.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

Function TForm1.Explode(Texto, Separador : String) : TStrings;
var
    strItem : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres, I : Integer;
Begin
    ListaAuxUTILS := TStringList.Create;
    strItem := '';
    NumCaracteres := Length(Texto);
    For I := 0 To NumCaracteres Do
    If (Texto[I] = Separador) or (I = NumCaracteres) Then
    Begin
       If (I = NumCaracteres) then strItem := strItem + Texto[I];
       ListaAuxUTILS.Add(Trim(strItem));
       strItem := '';
    end
    Else strItem := strItem + Texto[I];
      Explode := ListaAuxUTILS;
end;

procedure TForm1.Bt_VAIClick(Sender: TObject);
var v_modulos : string;
    v_array_modulos : TStrings;
    intAux : integer;
begin
  Screen.Cursor:=crHourglass;
  v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'*.exe',ExtractFileName(Application.Exename));

  Try
    if (v_modulos <> '') then
      Begin
        v_array_modulos := explode(v_modulos,'#');
        For intAux := 0 To v_array_modulos.count -1 Do
          Begin
            if (GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
              Begin
                SetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],GetVersionInfo(v_array_modulos[intAux]),ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
              End;
          End;
      End;
  finally
    Screen.Cursor:=crdefault;
    Refresh;
  end;
end;

procedure TForm1.Image1Click(Sender: TObject);
begin
  Refresh;
end;

procedure TForm1.ListAdvancedCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
  // Verifico se a imagem para o ítem é 0(zero) => DIFERENTE ou 1(um) IGUAL
  // Coloco em vermelho quando for DIFERENTE...
  if (item.ImageIndex = 0) then
    bEGIN
      Sender.Canvas.Font.Color := clRed;
      if (SubItem = 2) or (SubItem = 3) then Sender.Canvas.Font.Style := Sender.Canvas.Font.Style + [fsBold];
    eND;

end;
end.
