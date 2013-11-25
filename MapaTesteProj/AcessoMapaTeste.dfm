object frmAcesso: TfrmAcesso
  Left = 0
  Top = 0
  Caption = 'Acessar'
  ClientHeight = 309
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btAcesso: TButton
    Left = 177
    Top = 260
    Width = 105
    Height = 33
    Caption = 'Acessar'
    Default = True
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object btCancela: TButton
    Left = 333
    Top = 260
    Width = 105
    Height = 33
    Caption = 'Cancelar'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object pnAcesso: TPanel
    Left = 2
    Top = 3
    Width = 602
    Height = 196
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 2
    object lbNomeUsuarioAcesso: TLabel
      Left = 109
      Top = 42
      Width = 127
      Height = 20
      Caption = 'Nome de Usu'#225'rio:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbSenhaAcesso: TLabel
      Left = 106
      Top = 82
      Width = 130
      Height = 20
      Caption = 'Senha de Acesso:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbAviso: TLabel
      Left = 4
      Top = 171
      Width = 593
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object edNomeUsuarioAcesso: TEdit
      Left = 239
      Top = 39
      Width = 250
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      TabOrder = 0
      Visible = False
    end
    object edSenhaAcesso: TEdit
      Left = 239
      Top = 79
      Width = 250
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      PasswordChar = #7
      TabOrder = 1
      Visible = False
    end
  end
  object pnMessageBox: TPanel
    Left = 1
    Top = 198
    Width = 602
    Height = 45
    BevelInner = bvLowered
    Color = clGradientInactiveCaption
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGradientActiveCaption
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    Visible = False
    object lbMensagens: TLabel
      Left = 2
      Top = 2
      Width = 598
      Height = 41
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
  end
end
