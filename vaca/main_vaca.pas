unit main_vaca;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  ImgList,
  ComCtrls,
  PJVersionInfo,
  inifiles,
  md5;

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
      Stage:  TCustomDrawStage; var DefaultDraw: Boolean);
    function  InsertItemLISTA(strName,strVerINI,strVerEXE,strSize,strDate : string; boolOK : boolean) : boolean;
    function  getDadosAgenteLinux(strNomeAgenteLinux:String) : TStrings;
    procedure RemontaINI(strTripaChavesValores,p_Path : String);
    function  GetFileHash(strFileName : String) : String;
  private
    { Private declarations }
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}
//Para gravar no Arquivo INI...
function TForm1.SetValorChaveRegIni(p_Secao: String; p_Chave: String; p_Valor: String; p_Path : String): String;
var Reg_Ini     : TIniFile;
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
    Try
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
    Except
    End;
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
  SetValorChaveRegIni('Informação','Nota','Versoes dos Agentes do Sistema CACIC',ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
  Refresh;
end;
// Para cálculo de HASH de determinado arquivo.
// Objetivo principal: Verificar autenticidade de agentes para trabalho cooperativo
// Anderson Peterle - Dataprev/ES - 08/Maio/2008
function TForm1.GetFileHash(strFileName : String) : String;
Begin
  Result := 'Arquivo "'+strFileName+'" Inexistente!';
  if (FileExists(strFileName)) then
    Result := MD5Print(MD5File(strFileName));
End;

procedure TForm1.RemontaINI(strTripaChavesValores,p_Path : String);
var Reg_Ini : TIniFile;
    intAux  : integer;
    tstrAux1,
    tstrAux2 : TStrings;
begin
  tstrAux1 := TStrings.Create;
  tstrAux1 := explode(strTripaChavesValores,'#');
  tstrAux2 := TStrings.Create;

  Reg_Ini := TIniFile.Create(p_Path);
  if (FileGetAttr(p_Path) and faReadOnly) > 0 then
     FileSetAttr(p_Path, FileGetAttr(p_Path) xor faReadOnly);

  Reg_Ini.EraseSection('versoes_agentes');

  for intAux := 0 to (tstrAux1.Count -1) do
    Begin
      tstrAux2 := explode(tstrAux1[intAux],'=');
      Reg_Ini.WriteString('versoes_agentes', tstrAux2[0], tstrAux2[1]);
    End;

  tstrAux1.Free;
  tstrAux2.Free;
  Reg_Ini.Free;
End;

function TForm1.InsertItemLISTA(strName,strVerINI,strVerEXE,strSize,strDate : string; boolOK : boolean) : boolean;
var intAux : integer;
Begin
  intAux := Form1.List.Items.Count;

  Form1.List.Items.Add;
  Form1.List.Items[intAux].Caption := '';
  Form1.List.Items[intAux].SubItems.Add(strName);
  Form1.List.Items[intAux].SubItems.Add(strVerINI);
  Form1.List.Items[intAux].SubItems.Add(strVerEXE);
  Form1.List.Items[intAux].SubItems.Add(strSize);
  Form1.List.Items[intAux].SubItems.Add(strDate);

  if boolOK then
    Form1.List.Items[intAux].ImageIndex := 1
  else
    Form1.List.Items[intAux].ImageIndex := 0;
End;

procedure TForm1.Refresh;
var v_modulos,
    strNomePacoteLinux,
    strVersaoPacoteLinux,
    strAux,
    strTripaVersoesValidas : string;
    v_array_modulos,
    tstrAux,
    tstrDadosAgenteLinux : TStrings;
    intAux : integer;
    boolAtivarAtualizaVersoes,
    boolVersoesIguais : boolean;
begin
  Caption:='VACA - Versões de Agentes do CACIC';
  Screen.Cursor:=crHourglass;
  List.Clear;

  boolAtivarAtualizaVersoes := false;

  v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'*.exe',ExtractFileName(Application.Exename));

  Try
    if (v_modulos <> '') then
      Begin
        v_array_modulos := explode(v_modulos,'#');
        For intAux := 0 To v_array_modulos.count -1 Do
          Begin
            boolVersoesIguais := true;
            if (GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')='') then
              SetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],GetVersionInfo(v_array_modulos[intAux]),ExtractFilePath(Application.Exename)+'versoes_agentes.ini')
            else if (GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>GetVersionInfo(v_array_modulos[intAux])) then
              Begin
                boolVersoesIguais         := false;
                boolAtivarAtualizaVersoes := true;
              End;

            InsertItemLISTA(v_array_modulos[intAux],
                            GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini'),
                            GetVersionInfo(v_array_modulos[intAux]),
                            Get_File_Size(v_array_modulos[intAux],true),
                            DateToStr(FileDateToDateTime(FileAge(v_array_modulos[intAux]))),
                            boolVersoesIguais);

            if (strTripaVersoesValidas <> '') then
              strTripaVersoesValidas := strTripaVersoesValidas + '#';
            strTripaVersoesValidas := strTripaVersoesValidas + v_array_modulos[intAux] + '=' + GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
            strTripaVersoesValidas := strTripaVersoesValidas + '#';
            strTripaVersoesValidas := strTripaVersoesValidas + v_array_modulos[intAux] + '_HASH=' + GetFileHash(v_array_modulos[intAux]);
          End;
      End;
  Except
  End;

  Try
    tstrAux := TStrings.Create;
    v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'agentes_linux\*.tgz',ExtractFileName(Application.Exename));
    Try
      if (v_modulos <> '') then
        Begin
          v_array_modulos := explode(v_modulos,'#');
          tstrDadosAgenteLinux := TStrings.Create;
          For intAux := 0 To v_array_modulos.count -1 Do
            Begin
              boolVersoesIguais     := true;
              tstrDadosAgenteLinux       := getDadosAgenteLinux(v_array_modulos[intAux]);

              if (GetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')='') then
                  SetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],tstrDadosAgenteLinux[1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')
              else if (GetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],ExtractFilePath(Application.Exename)+'versoes_agentes.ini') <> tstrDadosAgenteLinux[1]) then
                Begin
                  boolVersoesIguais         := false;
                  boolAtivarAtualizaVersoes := true;
                End;

              InsertItemLISTA(tstrDadosAgenteLinux[0],
                              GetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],ExtractFilePath(Application.Exename)+'versoes_agentes.ini'),
                              tstrDadosAgenteLinux[1],
                              Get_File_Size(ExtractFilePath(Application.Exename)+'agentes_linux\'+v_array_modulos[intAux],true),
                              DateToStr(FileDateToDateTime(FileAge(ExtractFilePath(Application.Exename)+'agentes_linux\'+v_array_modulos[intAux]))),
                              boolVersoesIguais);

              if (strTripaVersoesValidas <> '') then
                strTripaVersoesValidas  := strTripaVersoesValidas + '#';
              strTripaVersoesValidas    := strTripaVersoesValidas + tstrDadosAgenteLinux[0] + '=' + GetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],ExtractFilePath(Application.Exename)+'versoes_agentes.ini');

              strTripaVersoesValidas    := strTripaVersoesValidas + '#';

              strTripaVersoesValidas    := strTripaVersoesValidas + 'te_pacote_PyCACIC=' + v_array_modulos[intAux];
              strTripaVersoesValidas    := strTripaVersoesValidas + '#';
              strTripaVersoesValidas    := strTripaVersoesValidas + 'te_pacote_PyCACIC_HASH= ' + GetFileHash(ExtractFilePath(Application.Exename)+'agentes_linux\'+v_array_modulos[intAux]);
            End;
        End;
    Except
    End;
  finally
    RemontaINI(strTripaVersoesValidas,ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
    List.Show;
    Screen.Cursor:=crdefault;
    Bt_VAI.Enabled := boolAtivarAtualizaVersoes;
  end;
end;

function TForm1.getDadosAgenteLinux(strNomeAgenteLinux:String) : TStrings;
var tstrAux : TStrings;
    strAux  : String;
Begin
  strAux  := StringReplace(strNomeAgenteLinux,'.tgz','',[rfReplaceAll]);
  tstrAux := TStrings.Create;
  tstrAux := Explode(strAux,'_');
  Result := tstrAux;
End;

Function TForm1.ListFileDir(Path,p_exception : string):string;
var
  SR: TSearchRec;
  FileList : string;
begin
  if FindFirst(Path, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr <> faDirectory) and (SR.Name <> p_exception) then
        Begin
          if (FileList <> '') then FileList := FileList + '#';
          FileList := FileList + SR.Name;
        End
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
    v_array_modulos,
    tstrDadosAgenteLinux : TStrings;
    intAux : integer;
begin
  Screen.Cursor:=crHourglass;
  v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'*.exe',ExtractFileName(Application.Exename));

  Try
    if (v_modulos <> '') then
      Begin
        v_array_modulos := explode(v_modulos,'#');
        For intAux := 0 To v_array_modulos.count -1 Do
            if (GetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
                SetValorChaveRegIni('versoes_agentes',v_array_modulos[intAux],GetVersionInfo(v_array_modulos[intAux]),ExtractFilePath(Application.Exename)+'versoes_agentes.ini');
      End;
  finally
    Screen.Cursor:=crdefault;
    Refresh;
  end;


  tstrDadosAgenteLinux := TStrings.Create;
  v_modulos := ListFileDir(ExtractFilePath(Application.Exename)+'agentes_linux/*.tgz',ExtractFileName(Application.Exename));

  Try
    if (v_modulos <> '') then
      Begin
        v_array_modulos := explode(v_modulos,'#');
        For intAux := 0 To v_array_modulos.count -1 Do
            tstrDadosAgenteLinux := getDadosAgenteLinux(v_array_modulos[intAux]);
            if (GetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')<>'') then
                SetValorChaveRegIni('versoes_agentes',tstrDadosAgenteLinux[0],tstrDadosAgenteLinux[1],ExtractFilePath(Application.Exename)+'versoes_agentes.ini')
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
