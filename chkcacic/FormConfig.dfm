object Configs: TConfigs
  Left = 258
  Top = 175
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Configura'#231#245'es do CHKCACIC'
  ClientHeight = 331
  ClientWidth = 453
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 402
    Top = 312
    Width = 27
    Height = 12
    Caption = 'Label1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
  object GroupBox2: TGroupBox
    Left = 5
    Top = 83
    Width = 444
    Height = 202
    Caption = 'Opcional'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    object Label1: TLabel
      Left = 63
      Top = -1
      Width = 200
      Height = 13
      Caption = '(N'#227'o aplic'#225'vel ao ChkCacic do NetLogon)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_te_instala_informacoes_extras: TLabel
      Left = 9
      Top = 50
      Width = 89
      Height = 13
      Caption = 'Informa'#231#245'es extras'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Memo_te_instala_informacoes_extras: TMemo
      Left = 9
      Top = 65
      Width = 426
      Height = 127
      Color = clInactiveBorder
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Lines.Strings = (
        'Empresa-UF / Suporte T'#233'cnico'
        ''
        'Emails: email1_do_suporte@xxxxxx.yyy.zz, '
        '            email2_do_suporte@xxxxxx.yyy.zz'
        ''
        'Fones: (xx) yyyy-zzzz  /  (xx) yyyy-zzzz'
        ''
        'Endere'#231'o: Rua Nome_da_Rua, N'#186' 99999'
        '                 Cidade/UF')
      ParentFont = False
      TabOrder = 1
    end
    object ckboxExibeInformacoes: TCheckBox
      Left = 9
      Top = 23
      Width = 424
      Height = 17
      Caption = 'Exibe informa'#231#245'es sobre o processo de instala'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = ckboxExibeInformacoesClick
    end
  end
  object GroupBox1: TGroupBox
    Left = 5
    Top = 8
    Width = 444
    Height = 64
    Caption = 'Obrigat'#243'rio'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object Label_ip_serv_cacic: TLabel
      Left = 8
      Top = 19
      Width = 143
      Height = 13
      Caption = 'Identificador do Servidor WEB'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_cacic_dir: TLabel
      Left = 236
      Top = 19
      Width = 103
      Height = 13
      Caption = 'Pasta para Instala'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
  end
  object Edit_ip_serv_cacic: TEdit
    Left = 13
    Top = 42
    Width = 200
    Height = 21
    MaxLength = 100
    TabOrder = 0
  end
  object Edit_cacic_dir: TEdit
    Left = 241
    Top = 42
    Width = 200
    Height = 21
    MaxLength = 100
    TabOrder = 1
    Text = 'Cacic'
  end
  object Button_Gravar: TButton
    Left = 62
    Top = 292
    Width = 150
    Height = 30
    Caption = 'Gravar Configura'#231#245'es'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = Button_GravarClick
  end
  object btSair: TButton
    Left = 242
    Top = 292
    Width = 150
    Height = 30
    Caption = 'Sair'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btSairClick
  end
  object PJVersionInfo1: TPJVersionInfo
    Left = 5
    Top = 293
  end
end
