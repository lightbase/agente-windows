object FormVACON: TFormVACON
  Left = 135
  Top = 8
  Width = 767
  Height = 652
  Caption = 'VACON - Visualizador de Arquivo de Configura'#231#227'o CACIC2.DAT'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  Visible = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 19
    Top = 48
    Width = 5
    Height = 13
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -12
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Memo1: TMemo
    Left = 0
    Top = 46
    Width = 754
    Height = 549
    Lines.Strings = (
      '')
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Bt_Sair: TButton
    Left = 644
    Top = 6
    Width = 110
    Height = 35
    Caption = 'Sair'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = Bt_SairClick
  end
  object Bt_Abrir_Outro: TButton
    Left = 467
    Top = 6
    Width = 163
    Height = 35
    Caption = 'Abrir Outro Arquivo...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    Visible = False
    OnClick = Bt_Abrir_OutroClick
  end
  object GB_Chave: TGroupBox
    Left = 254
    Top = 165
    Width = 264
    Height = 220
    Color = clActiveBorder
    ParentColor = False
    TabOrder = 3
    Visible = False
    object Label2: TLabel
      Left = 8
      Top = 11
      Width = 242
      Height = 16
      Caption = 'Informe a Chave para Leitura do Arquivo:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Lb_Chave_Separadora: TLabel
      Left = 8
      Top = 77
      Width = 173
      Height = 16
      Caption = 'Informe a Chave Separadora'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object lbDefaultChaveLeArq: TLabel
      Left = 9
      Top = 51
      Width = 95
      Height = 12
      Caption = '(Default="CacicBrasil")'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object lbChaveSeparadora: TLabel
      Left = 9
      Top = 118
      Width = 99
      Height = 12
      Caption = '(Default="CacicIsFree")'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object Ed_Chave: TEdit
      Left = 8
      Top = 28
      Width = 249
      Height = 21
      BevelInner = bvNone
      TabOrder = 0
      Text = 'CacicBrasil'
      OnKeyPress = Ed_ChaveKeyPress
    end
    object Bt_OK_Chave: TButton
      Left = 95
      Top = 165
      Width = 75
      Height = 25
      Caption = 'OK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = Bt_OK_ChaveClick
    end
    object Ed_Chave_Separadora: TEdit
      Left = 8
      Top = 94
      Width = 249
      Height = 21
      BevelInner = bvNone
      TabOrder = 1
      Text = 'CacicIsFree'
      OnKeyPress = Ed_Chave_SeparadoraKeyPress
    end
    object chkboxExibeChaves: TCheckBox
      Left = 3
      Top = 201
      Width = 97
      Height = 17
      Caption = 'Exibe Chaves'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = chkboxExibeChavesClick
    end
  end
  object Bt_Trocar_Chave: TButton
    Left = 237
    Top = 6
    Width = 227
    Height = 35
    Caption = 'Trocar Chaves de Criptografia'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    Visible = False
    OnClick = PegaChave
  end
  object Panel1: TPanel
    Left = 695
    Top = 597
    Width = 59
    Height = 17
    BevelInner = bvLowered
    BevelOuter = bvLowered
    Caption = 'v:2.0.0.0'
    TabOrder = 5
  end
  object OpenDialog1: TOpenDialog
    Left = 16
    Top = 16
  end
  object PJVersionInfo1: TPJVersionInfo
    Left = 120
    Top = 16
  end
end
