object FormVACON: TFormVACON
  Left = 6
  Top = 5
  Width = 772
  Height = 543
  Caption = 'VACON - Visualizador de Arquivo de Configura'#231#227'o CACIC2.DAT'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Visible = True
  WindowState = wsMaximized
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 57
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
    Left = 6
    Top = 72
    Width = 754
    Height = 437
    Lines.Strings = (
      '')
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Bt_Sair: TButton
    Left = 649
    Top = 20
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
    Left = 476
    Top = 20
    Width = 159
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
    Left = 259
    Top = 174
    Width = 265
    Height = 163
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
      Top = 62
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
    object Ed_Chave: TEdit
      Left = 8
      Top = 28
      Width = 249
      Height = 21
      BevelInner = bvNone
      TabOrder = 0
      OnKeyPress = Ed_ChaveKeyPress
    end
    object Bt_OK_Chave: TButton
      Left = 95
      Top = 121
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
      Top = 79
      Width = 249
      Height = 21
      BevelInner = bvNone
      TabOrder = 1
      OnEnter = Ed_Chave_SeparadoraEnter
      OnKeyPress = Ed_Chave_SeparadoraKeyPress
    end
  end
  object Bt_Trocar_Chave: TButton
    Left = 256
    Top = 20
    Width = 216
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
  object OpenDialog1: TOpenDialog
    Left = 16
    Top = 16
  end
end
