object Configs: TConfigs
  Left = 217
  Top = 20
  AutoSize = True
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Configura'#231#245'es do chkCACIC'
  ClientHeight = 374
  ClientWidth = 575
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object gbOptional: TGroupBox
    Left = 0
    Top = 370
    Width = 575
    Height = 0
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
    object Label_TeProcessInformations: TLabel
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
    object Memo_TeExtrasProcessInformations: TMemo
      Left = 9
      Top = 66
      Width = 556
      Height = 126
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
    object checkboxInShowProcessInformations: TCheckBox
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
      OnClick = checkboxInShowProcessInformationsClick
    end
  end
  object gbMandatory: TGroupBox
    Left = 0
    Top = 16
    Width = 575
    Height = 112
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object Label_TeWebManagerAddress: TLabel
      Left = 7
      Top = 10
      Width = 232
      Height = 13
      Caption = '1 - Endere'#231'o de Acesso ao Gerente WEB CACIC'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label_TeLocalFolder: TLabel
      Left = 305
      Top = 10
      Width = 147
      Height = 13
      Caption = '2 - Pasta para Instala'#231#227'o Local'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label1: TLabel
      Left = 8
      Top = 48
      Width = 213
      Height = 12
      Caption = 'Informe o mesmo endere'#231'o de acesso via browser'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 305
      Top = 48
      Width = 253
      Height = 12
      Caption = 'Pasta a ser criada na unidade padr'#227'o do computador destino'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 358
      Top = 117
      Width = 211
      Height = 12
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object pnStatus: TPanel
      Left = 1
      Top = 83
      Width = 571
      Height = 26
      BevelInner = bvLowered
      TabOrder = 0
      object staticStatus: TStaticText
        Left = 2
        Top = 2
        Width = 567
        Height = 22
        Align = alClient
        Alignment = taCenter
        AutoSize = False
        Caption = 'staticStatus'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
  end
  object Edit_TeWebManagerAddress: TEdit
    Left = 8
    Top = 41
    Width = 260
    Height = 24
    BevelInner = bvLowered
    BevelKind = bkSoft
    CharCase = ecLowerCase
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    MaxLength = 100
    ParentFont = False
    TabOrder = 0
    Text = 'pwebcgi01/cacic3/'
    OnExit = Edit_TeWebManagerAddressExit
  end
  object Edit_TeLocalFolder: TEdit
    Left = 306
    Top = 41
    Width = 260
    Height = 24
    BevelInner = bvLowered
    BevelKind = bkSoft
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    MaxLength = 100
    ParentFont = False
    TabOrder = 1
    Text = 'Cacic'
  end
  object Button_ConfirmProcess: TButton
    Left = 12
    Top = 141
    Width = 250
    Height = 35
    Caption = 'Concluir Instala'#231#227'o/Atualiza'#231#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    OnClick = Button_ConfirmProcessClick
  end
  object Button_ExitProcess: TButton
    Left = 311
    Top = 141
    Width = 250
    Height = 35
    Caption = 'Sair'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    OnClick = Button_ExitProcessClick
  end
  object pnVersao: TPanel
    Left = 492
    Top = 0
    Width = 82
    Height = 20
    BevelInner = bvLowered
    Caption = 'Vers'#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
  end
  object gbProgress: TGroupBox
    Left = 0
    Top = 200
    Width = 575
    Height = 147
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
    object memoProgress: TMemo
      Left = 9
      Top = 17
      Width = 556
      Height = 120
      Color = clWhite
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object labelOptionalsInformations: TStaticText
    Left = 1
    Top = 356
    Width = 58
    Height = 14
    AutoSize = False
    Caption = 'Opcionais'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 10
    OnClick = labelOptionalsInformationsClick
  end
  object staticClickToExpand: TStaticText
    Left = 58
    Top = 356
    Width = 159
    Height = 18
    Cursor = crHandPoint
    Caption = '(Clique para EXPANDIR o Painel)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 11
    OnClick = staticClickToExpandClick
  end
  object labelMandatoryField: TStaticText
    Left = 1
    Top = 3
    Width = 162
    Height = 14
    AutoSize = False
    Caption = 'Preenchimento Obrigat'#243'rio'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
  end
  object labelActionsLog: TStaticText
    Left = 1
    Top = 188
    Width = 162
    Height = 14
    AutoSize = False
    Caption = 'Log de A'#231#245'es'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 9
  end
  object timerGeneral: TTimer
    OnTimer = timerGeneralTimer
    Left = 272
    Top = 168
  end
end
