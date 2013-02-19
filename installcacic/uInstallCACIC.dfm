object frmInstallCACIC: TfrmInstallCACIC
  Left = 409
  Top = 3
  Width = 600
  Height = 620
  BorderIcons = [biSystemMenu]
  Caption = 'InstallCACIC'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsMinimized
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnVersao: TPanel
    Left = 477
    Top = 3
    Width = 100
    Height = 20
    BevelInner = bvLowered
    Caption = 'Vers'#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object gbMandatory: TGroupBox
    Left = 4
    Top = 25
    Width = 575
    Height = 67
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object lbWebManagerAddress: TLabel
      Left = 5
      Top = 9
      Width = 564
      Height = 13
      Alignment = taCenter
      AutoSize = False
      Caption = 'Endere'#231'o de Acesso ao Gerente WEB CACIC'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object lbInformeEndereco: TLabel
      Left = 108
      Top = 50
      Width = 355
      Height = 12
      Alignment = taCenter
      AutoSize = False
      Caption = 'Informe o endere'#231'o como usado no navegador web'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -9
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object edWebManagerAddress: TEdit
      Left = 106
      Top = 25
      Width = 361
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
    end
  end
  object btConfirmProcess: TButton
    Left = 90
    Top = 144
    Width = 238
    Height = 35
    Caption = 'Concluir Instala'#231#227'o/Verifica'#231#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = btConfirmProcessClick
  end
  object btExit: TButton
    Left = 379
    Top = 144
    Width = 107
    Height = 35
    Caption = 'Sair'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = btExitClick
  end
  object lbActionsLog: TStaticText
    Left = 5
    Top = 197
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
    TabOrder = 4
  end
  object gbProgress: TGroupBox
    Left = 4
    Top = 213
    Width = 575
    Height = 364
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    object richProgress: TRichEdit
      Left = 3
      Top = 7
      Width = 568
      Height = 353
      Color = clBackground
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object staticStatus: TStaticText
    Left = 2
    Top = 101
    Width = 578
    Height = 32
    Alignment = taCenter
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
  end
end
