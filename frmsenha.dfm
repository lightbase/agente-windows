object formSenha: TformSenha
  Left = 152
  Top = 110
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Senha'
  ClientHeight = 126
  ClientWidth = 244
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Lb_Texto_Senha: TLabel
    Left = 8
    Top = 7
    Width = 234
    Height = 26
    Caption = 
      'Essa op'#231#227'o requer que seja informada a senha que foi configurada' +
      ' pelo administrador do CACIC. '
    WordWrap = True
  end
  object Lb_Senha: TLabel
    Left = 10
    Top = 48
    Width = 34
    Height = 13
    Caption = 'Senha:'
  end
  object Lb_Msg_Erro_Senha: TLabel
    Left = 91
    Top = 68
    Width = 3
    Height = 13
    Alignment = taCenter
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
  end
  object EditSenha: TEdit
    Left = 50
    Top = 41
    Width = 185
    Height = 21
    PasswordChar = '*'
    TabOrder = 0
  end
  object Bt_OK_Senha: TButton
    Left = 34
    Top = 92
    Width = 83
    Height = 25
    Caption = '&OK'
    Default = True
    TabOrder = 1
    OnClick = Bt_OK_SenhaClick
  end
  object Bt_Cancelar_Senha: TButton
    Left = 134
    Top = 92
    Width = 83
    Height = 25
    Cancel = True
    Caption = '&Cancelar'
    TabOrder = 2
    OnClick = Bt_Cancelar_SenhaClick
  end
  object Tm_Senha: TTimer
    Interval = 3000
    OnTimer = Tm_SenhaTimer
    Top = 72
  end
end
