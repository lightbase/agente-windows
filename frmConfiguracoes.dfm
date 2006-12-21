object FormConfiguracoes: TFormConfiguracoes
  Left = 147
  Top = 108
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'CACIC - Configura'#231#245'es'
  ClientHeight = 137
  ClientWidth = 299
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Lb_End_Serv_Aplicacao: TLabel
    Left = 7
    Top = 7
    Width = 171
    Height = 13
    Caption = 'Endere'#231'o do Servidor da Aplica'#231#227'o:'
  end
  object Bv1_Configuracoes: TBevel
    Left = 8
    Top = 84
    Width = 283
    Height = 18
    Shape = bsBottomLine
  end
  object Lb_End_Serv_Updates: TLabel
    Left = 6
    Top = 49
    Width = 149
    Height = 13
    Caption = 'Endere'#231'o Servidor de Updates:'
  end
  object EditEnderecoServidorAplicacao: TEdit
    Left = 7
    Top = 22
    Width = 170
    Height = 21
    TabOrder = 0
  end
  object BtN_Confirmar: TButton
    Left = 200
    Top = 21
    Width = 75
    Height = 25
    Caption = 'Confirmar'
    TabOrder = 2
    OnClick = pro_Btn_Confirmar
  end
  object Btn_Desinstalar: TButton
    Left = 200
    Top = 56
    Width = 75
    Height = 25
    Caption = 'Desinstalar'
    TabOrder = 3
    OnClick = pro_Btn_Desinstalar
  end
  object Btn_Cancelar: TButton
    Left = 133
    Top = 107
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 4
    OnClick = pro_Btn_Cancelar
  end
  object Btn_OK: TButton
    Left = 216
    Top = 107
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 5
    OnClick = pro_Btn_OK
  end
  object EditEnderecoServidorUpdates: TEdit
    Left = 6
    Top = 64
    Width = 170
    Height = 21
    TabOrder = 1
  end
end
