unit main_VACON;

interface

uses
  Windows,
  SysUtils,
  Forms,
  DCPcrypt2,
  DCPrijndael,
  DCPbase64,
  StdCtrls,
  Controls, Classes, Dialogs;

type
  TFormVACON = class(TForm)
    Bt_Sair: TButton;
    OpenDialog1: TOpenDialog;
    Bt_Abrir_Outro: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    GB_Chave: TGroupBox;
    Ed_Chave: TEdit;
    Label2: TLabel;
    Bt_OK_Chave: TButton;
    Bt_Trocar_Chave: TButton;
    Lb_Chave_Separadora: TLabel;
    Ed_Chave_Separadora: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure Bt_SairClick(Sender: TObject);
    function  DeCrypt(p_Data : String) : String;
    function  PadWithZeros(const str : string; size : integer) : string;
    function  RemoveZerosFimString(Texto : String) : String;
    function  Explode(Texto, Separador : String) : TStrings;
    procedure Mostra(p_DatFileName: string);
    procedure Bt_Abrir_OutroClick(Sender: TObject);
    procedure Abrir;
    procedure Bt_OK_ChaveClick(Sender: TObject);
    procedure PegaChave(Sender: TObject);
    procedure Ed_ChaveKeyPress(Sender: TObject; var Key: Char);
    procedure Ed_Chave_SeparadoraKeyPress(Sender: TObject; var Key: Char);
    procedure Ed_Chave_SeparadoraEnter(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormVACON: TFormVACON;
  v_CipherKey,
  v_IV : string;

// Some constants that are dependant on the cipher being used
// Assuming MCRYPT_RIJNDAEL_128 (i.e., 128bit blocksize, 256bit keysize)
const KeySize = 32; // 32 bytes = 256 bits
      BlockSize = 16; // 16 bytes = 128 bits



implementation

{$R *.dfm}
// Pad a string with zeros so that it is a multiple of size
function TFormVACON.PadWithZeros(const str : string; size : integer) : string;
var
  origsize, i : integer;
begin
  Result := str;
  origsize := Length(Result);
  if ((origsize mod size) <> 0) or (origsize = 0) then
  begin
    SetLength(Result,((origsize div size)+1)*size);
    for i := origsize+1 to Length(Result) do
      Result[i] := #0;
  end;
end;

function TFormVACON.DeCrypt(p_Data : String) : String;
var
  l_Cipher : TDCP_rijndael;
  l_Data, l_Key, l_IV : string;
begin
  Try
    v_IV                 := 'abcdefghijklmnop';

    // Pad Key and IV with zeros as appropriate
    l_Key := PadWithZeros(v_CipherKey,KeySize);
    l_IV := PadWithZeros(v_IV,BlockSize);

    // Decode the Base64 encoded string
    l_Data := Base64DecodeStr(p_Data);

    // Create the cipher and initialise according to the key length
    l_Cipher := TDCP_rijndael.Create(nil);
    if Length(v_CipherKey) <= 16 then
      l_Cipher.Init(l_Key[1],128,@l_IV[1])
    else if Length(v_CipherKey) <= 24 then
      l_Cipher.Init(l_Key[1],192,@l_IV[1])
    else
      l_Cipher.Init(l_Key[1],256,@l_IV[1]);

    // Decrypt the data
    l_Cipher.DecryptCBC(l_Data[1],l_Data[1],Length(l_Data));

    // Free the cipher and clear sensitive information
    l_Cipher.Free;
    FillChar(l_Key[1],Length(l_Key),0);

    // Return the result
    Result := trim(RemoveZerosFimString(l_Data));
  Except
  End;
end;

Function TFormVACON.RemoveZerosFimString(Texto : String) : String;
var I       : Integer;
    strAux  : string;
Begin
   strAux := '';
   if (Length(trim(Texto))>0) then
     For I := Length(Texto) downto 0 do
       if (ord(Texto[I])<>0) Then
         strAux := Texto[I] + strAux;
   Result := trim(strAux);
end;

Function TFormVACON.Explode(Texto, Separador : String) : TStrings;
var
    strItem       : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres,
    TamanhoSeparador,
    I : Integer;
Begin
    ListaAuxUTILS    := TStringList.Create;
    strItem          := '';
    NumCaracteres    := Length(Texto);
    TamanhoSeparador := Length(Separador);
    I                := 1;
    While I <= NumCaracteres Do
      Begin
        If (Copy(Texto,I,TamanhoSeparador) = Separador) or (I = NumCaracteres) Then
          Begin
            if (I = NumCaracteres) then strItem := strItem + Texto[I];
            ListaAuxUTILS.Add(trim(strItem));
            strItem := '';
            I := I + (TamanhoSeparador-1);
          end
        Else
            strItem := strItem + Texto[I];

        I := I + 1;
      End;
    Explode := ListaAuxUTILS;
end;


procedure TFormVACON.FormCreate(Sender: TObject);
begin
  FormVACON.Visible := true;
  Abrir;
end;

procedure TFormVACON.Abrir;
begin
  OpenDialog1             := TOpenDialog.Create(self);
  OpenDialog1.InitialDir  := GetCurrentDir;
  OpenDialog1.Filter      := 'Arquivos de Configuração (.DAT)|*.dat';
  OpenDialog1.FilterIndex := 2;
  if v_CipherKey = '' then
    Begin
      PegaChave(nil);
    End
  else if OpenDialog1.Execute then Mostra(OpenDialog1.FileName);

end;

procedure TFormVACON.PegaChave(Sender: TObject);
begin
  GB_Chave.Visible := true;
  Ed_Chave.SetFocus;
  Ed_Chave.PasswordChar := #42;
  Ed_Chave_Separadora.PasswordChar := #42;
end;


procedure TFormVACON.Bt_SairClick(Sender: TObject);
begin
  Application.Terminate;
  Close;
end;

procedure TFormVACON.Mostra(p_DatFileName: string);
var v_tstrCipherOpened: TStrings;
    v_DatFile         : TextFile;
    v_strCipherOpened,
    v_strCipherClosed : string;
begin
      AssignFile(v_DatFile,p_DatFileName);
      {$IOChecks off}
      Reset(v_DatFile);
      {$IOChecks on}

      Readln(v_DatFile,v_strCipherClosed);
      while not EOF(v_DatFile) do Readln(v_DatFile,v_strCipherClosed);

      CloseFile(v_DatFile);
      v_strCipherOpened:= Decrypt(v_strCipherClosed);

    if (trim(v_strCipherOpened)<>'') then
      v_tstrCipherOpened := explode(v_strCipherOpened,trim(Ed_Chave_Separadora.Text));

    if v_tstrCipherOpened.Count mod 2 = 0 then
        v_tstrCipherOpened.Add('');

    Label1.Caption := p_DatFileName;
    Memo1.Visible := false;
    Memo1.Text := '';
    Memo1.SetSelTextBuf(PChar(v_tstrCipherOpened.Text));
    Memo1.Visible := true;
    Bt_Abrir_Outro.Visible := true;
end;

procedure TFormVACON.Bt_Abrir_OutroClick(Sender: TObject);
begin
  Abrir;
end;

procedure TFormVACON.Bt_OK_ChaveClick(Sender: TObject);
begin
  v_CipherKey := trim(Ed_Chave.Text);
  if v_CipherKey <> '' then
      Bt_Trocar_Chave.Visible   := true;

  GB_Chave.Visible := false;
  if OpenDialog1.FileName <> '' then Mostra(OpenDialog1.FileName)
  else Abrir;
end;


procedure TFormVACON.Ed_ChaveKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then Ed_Chave_Separadora.SetFocus;
end;

procedure TFormVACON.Ed_Chave_SeparadoraKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then Bt_OK_ChaveClick(nil);
end;

procedure TFormVACON.Ed_Chave_SeparadoraEnter(Sender: TObject);
begin
  Ed_Chave_Separadora.Text := Ed_Chave.Text;
end;

end.
