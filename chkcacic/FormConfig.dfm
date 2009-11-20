object Configs: TConfigs
  Left = 260
  Top = 102
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Configura'#231#245'es do CHKCACIC'
  ClientHeight = 367
  ClientWidth = 490
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
  object gbOpcional: TGroupBox
    Left = 5
    Top = 91
    Width = 480
    Height = 219
    Caption = 'Opcional'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    object lbMensagemNaoAplicavel: TLabel
      Left = 265
      Top = 25
      Width = 192
      Height = 13
      Caption = '(N'#227'o aplicar ao chkCACIC do NetLogon)'
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
      Top = 66
      Width = 462
      Height = 144
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
      Width = 256
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
  object gbObrigatorio: TGroupBox
    Left = 5
    Top = 8
    Width = 480
    Height = 76
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
      Left = 260
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
    object Label1: TLabel
      Left = 8
      Top = 57
      Width = 195
      Height = 12
      Caption = 'Informe apenas o endere'#231'o IP ou nome (DNS)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 259
      Top = 57
      Width = 212
      Height = 12
      Caption = 'Pasta a ser criada na unidade padr'#227'o (HomeDrive)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
  end
  object Edit_ip_serv_cacic: TEdit
    Left = 13
    Top = 42
    Width = 195
    Height = 21
    MaxLength = 100
    TabOrder = 0
  end
  object Edit_cacic_dir: TEdit
    Left = 265
    Top = 42
    Width = 211
    Height = 21
    MaxLength = 100
    TabOrder = 1
    Text = 'Cacic'
  end
  object Button_Gravar: TButton
    Left = 48
    Top = 314
    Width = 214
    Height = 35
    Caption = 'Concluir Instala'#231#227'o/Atualiza'#231#227'o'
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
    Left = 291
    Top = 314
    Width = 150
    Height = 35
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
  object pnVersao: TPanel
    Left = 426
    Top = 354
    Width = 58
    Height = 14
    BevelOuter = bvLowered
    TabOrder = 6
    object lbVersao: TLabel
      Left = 4
      Top = 1
      Width = 53
      Height = 12
      Alignment = taCenter
      AutoSize = False
      Caption = 'V:2.00.00.00'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
  end
  object PJVersionInfo1: TPJVersionInfo
    Left = 5
    Top = 323
  end
end
