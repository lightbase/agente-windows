unit main_testacrypt;

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
  XML,
  LibXmlParser,
  IdHTTP,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  StdCtrls,
  WinSock,
  NB30,
  ComCtrls,
  PJVersionInfo,
  JvExComCtrls,
  JvStatusBar,
  CACIC_Library;

type
  TForm1 = class(TForm)
    GroupBox_Conexao: TGroupBox;
    Label_CaminhoScript: TLabel;
    Edit_ScriptPath: TEdit;
    GroupBox_TestesCliente: TGroupBox;
    Label_FraseOriginal: TLabel;
    Label_FraseCriptografadaEnviadaEstacao: TLabel;
    Edit_FraseOriginal: TEdit;
    Edit_FraseCriptografadaEnviadaEstacao: TEdit;
    Button_EfetuaTeste: TButton;
    Button_Finaliza: TButton;
    Label_IVStation: TLabel;
    Edit_IVStation: TEdit;
    GroupBox_TesteServidor: TGroupBox;
    Label_CipherKeyStation: TLabel;
    Edit_CipherKeyStation: TEdit;
    Label_IVServer: TLabel;
    Label_CipherKeyServer: TLabel;
    Edit_IVServer: TEdit;
    Edit_CipherKeyServer: TEdit;
    Label_FraseCriptografadaRecebidaServidor: TLabel;
    Edit_FraseCriptografadaRecebidaServidor: TEdit;
    GroupBox_Resultado: TGroupBox;
    Label_FraseDecriptografadaDevolvidaServidor: TLabel;
    Edit_FraseDecriptografadaDevolvidaServidor: TEdit;
    Label_OperacaoRecebidaServidor: TLabel;
    Edit_OperacaoRecebidaServidor: TEdit;
    PJVersionInfo1: TPJVersionInfo;
    StatusBar_Mensagens: TJvStatusBar;
    procedure Button_EfetuaTesteClick(Sender: TObject);
    function PadWithZeros(const str : string; size : integer) : string;
    procedure Button_FinalizaClick(Sender: TObject);
    procedure Edit_FraseOriginalKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Edit_FraseOriginalEnter(Sender: TObject);
    Procedure InicializaCampos;
    procedure Edit_FraseCriptografadaEnviadaEstacaoChange(Sender: TObject);
    procedure Edit_IVServerChange(Sender: TObject);
    procedure Edit_OperacaoRecebidaServidorChange(Sender: TObject);
    procedure ProcessaPausa;
    procedure Edit_CipherKeyStationChange(Sender: TObject);
    procedure Edit_FraseOriginalExit(Sender: TObject);
    procedure CriptografaPalavra;
    procedure Edit_IVStationExit(Sender: TObject);
    procedure Edit_CipherKeyStationExit(Sender: TObject);
    function  VerFmt(const MS, LS: DWORD): string;
    function  GetVersionInfo(p_File: string):string;
    procedure Edit_ScriptPathChange(Sender: TObject);
    procedure DesfazCriticas;
    procedure Edit_IVStationChange(Sender: TObject);
    procedure Edit_FraseCriptografadaEnviadaEstacaoExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var   Form1: TForm1;
      boolProcessaPausa : boolean;

var
  g_oCacic: TCACIC;

implementation

{$R *.dfm}
procedure TForm1.CriptografaPalavra;
Begin
  if (trim(form1.Edit_FraseOriginal.Text)<>'') then
    Begin
      Form1.Edit_FraseCriptografadaEnviadaEstacao.Text := g_oCacic.enCrypt(trim(form1.Edit_FraseOriginal.Text))
    //else if (trim(form1.Edit_FraseCriptografadaEnviadaEstacao.Text)<>'') then
    //  Form1.Edit_FraseOriginal.Text := g_oCacic.deCrypt(trim(form1.Edit_FraseCriptografadaEnviadaEstacao.Text));
    end;
End;

procedure TForm1.Button_EfetuaTesteClick(Sender: TObject);
var v_retorno,
    v_strAux,
    v_Status : String;

    Request_Config  : TStringList;
    Response_Config : TStringStream;
    IdHTTP1: TIdHTTP;
    intAux : integer;
begin
  if (Trim(Edit_FraseCriptografadaEnviadaEstacao.Text) <> '') then
    Begin
      boolProcessaPausa := true;
    //  InicializaCampos;
      CriptografaPalavra;

      intAux := POS('255.255.255.255',Edit_ScriptPath.Text);
      if (intAux > 0) then
        Begin
          StatusBar_Mensagens.Panels[0].Text := 'ATENÇÃO: Caso não seja um teste local, informe um endereço válido.';
          StatusBar_Mensagens.Color := clYellow;
          Edit_ScriptPath.SetFocus;
        End
      else
        Begin

          Request_Config                            := TStringList.Create;
          Request_Config.Values['cs_operacao']      := 'TestaCrypt';
          Request_Config.Values['cs_cipher']        := '1';
          Request_Config.Values['te_CipheredText']  := trim(Form1.Edit_FraseCriptografadaEnviadaEstacao.Text);
          Response_Config                           := TStringStream.Create('');

          Try
               idHTTP1 := TIdHTTP.Create(nil);
               idHTTP1.AllowCookies                     := true;
               idHTTP1.ASCIIFilter                      := false;
               idHTTP1.AuthRetries                      := 1;
               idHTTP1.BoundPort                        := 0;
               idHTTP1.HandleRedirects                  := false;
               idHTTP1.ProxyParams.BasicAuthentication  := false;
               idHTTP1.ProxyParams.ProxyPort            := 0;
               idHTTP1.ReadTimeout                      := 0;
               idHTTP1.RecvBufferSize                   := 32768;
               idHTTP1.RedirectMaximum                  := 15;
               idHTTP1.Request.Accept                   := 'text/html, */*';
               idHTTP1.Request.BasicAuthentication      := true;
               idHTTP1.Request.ContentLength            := -1;
               idHTTP1.Request.ContentRangeStart        := 0;
               idHTTP1.Request.ContentRangeEnd          := 0;
               idHTTP1.Request.ContentType              := 'text/html';
               idHTTP1.SendBufferSize                   := 32768;
               idHTTP1.Tag                              := 0;

               Form1.StatusBar_Mensagens.Panels[0].Text := 'Fazendo comunicação com "'+form1.Edit_ScriptPath.Text+'"';
               Sleep(1000);
               Form1.StatusBar_Mensagens.Panels[0].Text := '';

            IdHTTP1.Post(trim(Form1.Edit_ScriptPath.Text), Request_Config, Response_Config);

            //ShowMessage('Retorno: '+Response_Config.DataString);
            idHTTP1.Free;
            v_retorno := Response_Config.DataString;
            v_Status := XML_RetornaValor('STATUS',v_retorno);
          Except
            Begin
              Form1.StatusBar_Mensagens.Panels[0].Text := 'Problemas na comunicação...';
              Sleep(1000);
              Form1.StatusBar_Mensagens.Panels[0].Text := '';
            End;
          End;
          Request_Config.Free;
          Response_Config.Free;

          if (v_Status <> '') then
            Begin
              v_strAux := XML_RetornaValor('UnCipheredText',v_retorno);
              form1.Edit_IVServer.Text                              := XML_RetornaValor('IVServer',v_retorno);
              form1.Edit_CipherKeyServer.Text                       := XML_RetornaValor('CipherKeyServer',v_retorno);
              form1.Edit_FraseCriptografadaRecebidaServidor.Text    := XML_RetornaValor('CipheredTextRecepted',v_retorno);
              form1.Edit_OperacaoRecebidaServidor.Text              := XML_RetornaValor('CS_OPERACAO',v_retorno);
              if (v_strAux <> '') then
                Begin
                  form1.Edit_FraseDecriptografadaDevolvidaServidor.Text    := v_strAux;
                  if (trim(form1.Edit_FraseDecriptografadaDevolvidaServidor.Text) <> trim(form1.Edit_FraseOriginal.Text)) then
                    Begin
                      form1.Edit_FraseDecriptografadaDevolvidaServidor.Font.Color := clRed;
                      if (Edit_CipherKeyStation.Text <> Edit_CipherKeyServer.Text) then
                        Begin
                          Edit_CipherKeyStation.Color := clYellow;
                          Edit_CipherKeyServer.Color := clYellow;
                        End;
                      if (Edit_IVStation.Text <> Edit_IVServer.Text) then
                        Begin
                          Edit_IVStation.Color := clYellow;
                          Edit_IVServer.Color := clYellow;
                        End;

                    End
                  else
                    form1.Edit_FraseDecriptografadaDevolvidaServidor.Font.Color := clBlue;
                End
              else
                Begin
                  form1.Edit_FraseDecriptografadaDevolvidaServidor.Text := 'NÃO FOI POSSÍVEL DECRIPTOGRAFAR!!!';
                  form1.Edit_FraseDecriptografadaDevolvidaServidor.Font.Style := [fsBold];
                  form1.Edit_FraseDecriptografadaDevolvidaServidor.Font.Color := clRed;
                End;
              Form1.StatusBar_Mensagens.Panels[0].Text := 'Teste Concluído!';
            End
          else
            Begin
              Form1.StatusBar_Mensagens.Panels[0].Text := 'Problemas na comunicação...';
              Sleep(1000);
              Form1.StatusBar_Mensagens.Panels[0].Text := '';
            End;
        End;
    end;
end;
// Pad a string with zeros so that it is a multiple of size
function TForm1.PadWithZeros(const str : string; size : integer) : string;
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



procedure TForm1.Button_FinalizaClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Edit_FraseOriginalKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (form1.Edit_FraseOriginal.Text <> '') then
    Begin
      form1.Button_EfetuaTeste.Enabled := true;
    End;

end;
function TForm1.VerFmt(const MS, LS: DWORD): string;
  // Format the version number from the given DWORDs containing the info
begin
  Result := Format('%d.%d.%d.%d',
    [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)])
end;

function TForm1.GetVersionInfo(p_File: string):string;
var PJVersionInfo1: TPJVersionInfo;
begin
  PJVersionInfo1 := TPJVersionInfo.Create(nil);
  PJVersionInfo1.FileName := PChar(p_File);
  Result := VerFmt(PJVersionInfo1.FixedFileInfo.dwFileVersionMS, PJVersionInfo1.FixedFileInfo.dwFileVersionLS);
  PJVersionInfo1.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  g_oCacic := TCACIC.Create;
  g_oCacic.setBoolCipher(true);

  form1.Edit_IVStation.Text        := g_oCacic.getIV;
  form1.Edit_CipherKeyStation.Text := g_oCacic.getCipherKey;

  Form1.StatusBar_Mensagens.Panels[1].Text := 'v: '+getVersionInfo(ParamStr(0));
  boolProcessaPausa := false;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  form1.Edit_FraseOriginal.Enabled := true;
  form1.Edit_FraseOriginal.Visible := true;
  form1.Edit_FraseOriginal.SetFocus;

end;
procedure TForm1.Edit_FraseOriginalEnter(Sender: TObject);
begin
  InicializaCampos;
end;

procedure TForm1.Edit_FraseCriptografadaEnviadaEstacaoChange(
  Sender: TObject);
begin
  if trim(form1.Edit_FraseCriptografadaEnviadaEstacao.Text) = '' then
    form1.Button_EfetuaTeste.Enabled := true;
  ProcessaPausa;
end;

procedure TForm1.Edit_IVServerChange(Sender: TObject);
begin
  if trim(form1.Edit_IVServer.Text) = '' then
      form1.GroupBox_TesteServidor.Visible   := false
  else
      form1.GroupBox_TesteServidor.Visible   := true;

  ProcessaPausa;
end;

procedure TForm1.Edit_OperacaoRecebidaServidorChange(Sender: TObject);
begin
  if trim(form1.Edit_OperacaoRecebidaServidor.Text) = '' then
      form1.GroupBox_Resultado.Visible   := false
  else
      form1.GroupBox_Resultado.Visible   := true;

  ProcessaPausa;
end;

procedure TForm1.ProcessaPausa;
Begin
  if boolProcessaPausa then
    Begin
      boolProcessaPausa := false;
      sleep(500);
    End;
  Application.ProcessMessages;
End;
procedure TForm1.Edit_CipherKeyStationChange(Sender: TObject);
begin
  Form1.InicializaCampos;
  DesfazCriticas;
end;

procedure TForm1.Edit_FraseOriginalExit(Sender: TObject);
begin
  CriptografaPalavra;
end;

procedure TForm1.Edit_IVStationExit(Sender: TObject);
begin
  CriptografaPalavra;
end;

procedure TForm1.Edit_CipherKeyStationExit(Sender: TObject);
begin
  CriptografaPalavra;
end;

procedure TForm1.DesfazCriticas;
Begin
  Form1.StatusBar_Mensagens.Color                             := clBtnFace;
  Form1.Edit_CipherKeyStation.Color                           := clWindow;
  Form1.Edit_CipherKeyServer.Color                            := clWindow;
  Form1.Edit_IVStation.Color                                  := clWindow;
  Form1.Edit_IVServer.Color                                   := clWindow;

  Application.ProcessMessages;
End;

procedure TForm1.InicializaCampos;
Begin
  form1.GroupBox_TesteServidor.Visible                        := false;
  form1.GroupBox_Resultado.Visible                            := false;
//  Form1.Edit_FraseDecriptografadaDevolvidaServidor.Visible    := false;
//  form1.Edit_FraseCriptografadaRecebidaServidor.Visible       := false;
//  form1.Edit_FraseCriptografadaEnviadaEstacao.Visible         := false;
//  form1.Edit_FraseDecriptografadaDevolvidaServidor.Visible    := false;
//  form1.Edit_OperacaoRecebidaServidor.Visible                 := false;
//  form1.Edit_IVServer.Visible                                 := false;
//  form1.Edit_CipherKeyServer.Visible                          := false;

  Form1.Edit_FraseDecriptografadaDevolvidaServidor.Text       := '';
  form1.Edit_FraseCriptografadaRecebidaServidor.Text          := '';
//  form1.Edit_FraseCriptografadaEnviadaEstacao.Text            := '';
  form1.Edit_FraseDecriptografadaDevolvidaServidor.Text       := '';
  form1.Edit_OperacaoRecebidaServidor.Text                    := '';
  form1.Edit_IVServer.Text                                    := '';
  form1.Edit_CipherKeyServer.Text                             := '';
  form1.Edit_FraseDecriptografadaDevolvidaServidor.Font.Style := [];
  form1.Edit_FraseDecriptografadaDevolvidaServidor.Font.Color := clBlack;

  Application.ProcessMessages;

End;

procedure TForm1.Edit_ScriptPathChange(Sender: TObject);
begin
  InicializaCampos;
  DesfazCriticas;
end;

procedure TForm1.Edit_IVStationChange(Sender: TObject);
begin
  DesfazCriticas;
end;

procedure TForm1.Edit_FraseCriptografadaEnviadaEstacaoExit(
  Sender: TObject);
begin
  if (form1.Edit_FraseCriptografadaEnviadaEstacao.Text <> '') then
    Begin
      form1.Button_EfetuaTeste.Enabled := true;
    End;

end;

end.
