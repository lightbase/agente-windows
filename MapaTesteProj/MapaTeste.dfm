object frmMapaCacic: TfrmMapaCacic
  Left = 0
  Top = -55
  Caption = 'frmMapaCacic'
  ClientHeight = 634
  ClientWidth = 789
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    789
    634)
  PixelsPerInch = 96
  TextHeight = 13
  object edWebManagerAddress: TLabel
    Left = 155
    Top = 682
    Width = 500
    Height = 14
    Anchors = [akBottom]
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitLeft = 159
    ExplicitTop = 537
  end
  object lbWebManagerAddress: TLabel
    Left = 0
    Top = 683
    Width = 153
    Height = 13
    Anchors = [akLeft, akBottom]
    AutoSize = False
    Caption = 'Endere'#231'o do Servidor de Aplica'#231#227'o:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    ExplicitTop = 538
  end
  object btGravarInformacoes: TButton
    Left = 188
    Top = 580
    Width = 401
    Height = 35
    Anchors = []
    Caption = 'Grava e Envia Informa'#231#245'es Patrimoniais ao Gerente WEB'
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Visible = False
    OnClick = AtualizaPatrimonio
  end
  object gbInformacoesSobreComputador: TGroupBox
    Left = 1
    Top = 64
    Width = 780
    Height = 497
    Anchors = []
    Caption = 
      ' Informa'#231#245'es sobre localiza'#231#227'o f'#237'sica e patrimonial deste comput' +
      'ador '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object lbEtiqueta1: TLabel
      Left = 6
      Top = 226
      Width = 45
      Height = 13
      Caption = 'Etiqueta1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiqueta2: TLabel
      Left = 266
      Top = 226
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Etiqueta2'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiqueta3: TLabel
      Left = 530
      Top = 226
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Etiqueta3'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiqueta4: TLabel
      Left = 3
      Top = 275
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Etiqueta4'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiqueta5: TLabel
      Left = 266
      Top = 275
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Etiqueta5'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiqueta6: TLabel
      Left = 530
      Top = 275
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Etiqueta6'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiquetaUserLogado: TLabel
      Left = 420
      Top = 33
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Usu'#225'rio Logado'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiquetaNomeComputador: TLabel
      Left = 107
      Top = 146
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Computador'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiquetaCpfUser: TLabel
      Left = 420
      Top = 89
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'CPF'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiquetaIpComputador: TLabel
      Left = 420
      Top = 146
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'IP'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiquetaPatrimonioPc: TLabel
      Left = 107
      Top = 33
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Patrim'#244'nio'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object lbEtiquetaNome: TLabel
      Left = 107
      Top = 89
      Width = 250
      Height = 13
      AutoSize = False
      Caption = 'Nome'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Visible = False
    end
    object edTeInfoPatrimonio1: TEdit
      Left = 5
      Top = 245
      Width = 251
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Visible = False
    end
    object edTeInfoPatrimonio4: TEdit
      Left = 6
      Top = 294
      Width = 250
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      Visible = False
    end
    object edTeInfoPatrimonio2: TEdit
      Left = 262
      Top = 245
      Width = 250
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Visible = False
    end
    object edTeInfoPatrimonio3: TEdit
      Left = 530
      Top = 245
      Width = 250
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      Visible = False
    end
    object edTeInfoPatrimonio5: TEdit
      Left = 266
      Top = 294
      Width = 250
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      Visible = False
    end
    object edTeInfoPatrimonio6: TEdit
      Left = 530
      Top = 294
      Width = 250
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      Visible = False
    end
    object pnDivisoria01: TPanel
      Left = 3
      Top = 211
      Width = 772
      Height = 3
      TabOrder = 6
    end
    object btCombosUpdate: TButton
      Left = 684
      Top = 10
      Width = 94
      Height = 20
      Caption = 'Recarregar'
      Enabled = False
      TabOrder = 7
      OnClick = btCombosUpdateClick
    end
    object edTeInfoUserLogado: TEdit
      Left = 420
      Top = 52
      Width = 250
      Height = 24
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
      Visible = False
    end
    object edTeInfoNomeComputador: TEdit
      Left = 107
      Top = 165
      Width = 250
      Height = 24
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 9
      Visible = False
    end
    object edTeInfoCpfUser: TEdit
      Left = 420
      Top = 108
      Width = 250
      Height = 24
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 10
      Visible = False
    end
    object edTeInfoIpComputador: TEdit
      Left = 420
      Top = 165
      Width = 250
      Height = 24
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 11
      Visible = False
    end
    object edTePatrimonioPc: TEdit
      Left = 107
      Top = 52
      Width = 250
      Height = 24
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 12
      Visible = False
    end
    object edTeInfoNome: TEdit
      Left = 107
      Top = 108
      Width = 250
      Height = 24
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 13
      Visible = False
    end
    object bgTermoResponsabilidade: TGroupBox
      Left = 8
      Top = 328
      Width = 761
      Height = 161
      Caption = 'Termo de Responsabilidade'
      TabOrder = 14
      object mmTermoResponsabilidade: TMemo
        Left = 8
        Top = 21
        Width = 745
        Height = 108
        Enabled = False
        Lines.Strings = (
          'mmTermoResponsabilidade')
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object rdConcordaTermos: TRadioButton
        Left = 24
        Top = 135
        Width = 337
        Height = 17
        Caption = 'Eu aceito os termos e condi'#231#245'es etc...'
        TabOrder = 1
        OnClick = rdConcordaTermosClick
      end
    end
  end
  object gbLeiaComAtencao: TGroupBox
    Left = 1
    Top = 11
    Width = 780
    Height = 53
    Anchors = []
    Caption = ' Leia com aten'#231#227'o '
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    TabOrder = 2
    DesignSize = (
      780
      53)
    object lbLeiaComAtencao: TLabel
      Left = 14
      Top = 18
      Width = 769
      Height = 32
      Anchors = []
      AutoSize = False
      Caption = 
        'O preenchimento correto dos campos abaixo define a exatid'#227'o do c' +
        'ontrole de patrim'#244'nio e localiza'#231#227'o f'#237'sica do equipamento.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
  end
  object pnVersao: TPanel
    Left = 676
    Top = 676
    Width = 105
    Height = 20
    Anchors = [akRight, akBottom]
    BevelInner = bvLowered
    Caption = 'Vers'#227'o'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object pnMessageBox: TPanel
    Left = 1
    Top = 246
    Width = 780
    Height = 45
    BevelInner = bvLowered
    Color = clInactiveBorder
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMenuHighlight
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 4
    Visible = False
    object lbMensagens: TLabel
      Left = 2
      Top = 2
      Width = 776
      Height = 41
      Align = alClient
      Alignment = taCenter
      AutoSize = False
      Color = clGrayText
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = -38
      ExplicitTop = 4
    end
  end
  object timerMessageBoxShowOrHide: TTimer
    Enabled = False
    Interval = 500
    Left = 34
    Top = 569
  end
  object timerMessageShowTime: TTimer
    Enabled = False
    Interval = 0
    OnTimer = timerMessageShowTimeTimer
    Left = 2
    Top = 569
  end
  object timerProcessos: TTimer
    Enabled = False
    Interval = 1
    OnTimer = timerProcessosTimer
    Left = 66
    Top = 569
  end
  object IdIPWatch1: TIdIPWatch
    Active = False
    HistoryFilename = 'iphist.dat'
    Left = 96
    Top = 568
  end
end
