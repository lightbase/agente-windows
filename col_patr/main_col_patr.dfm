object FormPatrimonio: TFormPatrimonio
  Left = 137
  Top = 173
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'CACIC - Coletor de Informa'#231#245'es Patrimoniais'
  ClientHeight = 286
  ClientWidth = 782
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbVersao: TLabel
    Left = 672
    Top = 273
    Width = 108
    Height = 12
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'v: X.X.X.X'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
  end
  object GroupBox1: TGroupBox
    Left = 2
    Top = -1
    Width = 780
    Height = 75
    Caption = ' Leia com aten'#231#227'o '
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    object Label10: TLabel
      Left = 5
      Top = 14
      Width = 769
      Height = 32
      AutoSize = False
      Caption = 
        'O preenchimento correto dos campos abaixo '#233' de extrema import'#226'nc' +
        'ia para um efetivo controle patrimonial e de localiza'#231#227'o de equi' +
        'pamentos.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object Label11: TLabel
      Left = 6
      Top = 54
      Width = 475
      Height = 16
      Caption = 
        'Por favor, atualize as informa'#231#245'es abaixo. Agradecemos pela sua ' +
        'colabora'#231#227'o.'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
  end
  object GroupBox2: TGroupBox
    Left = 2
    Top = 77
    Width = 780
    Height = 144
    Caption = 
      'Informa'#231#245'es sobre localiza'#231#227'o f'#237'sica e patrimonial deste computa' +
      'dor'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Etiqueta1: TLabel
      Left = 3
      Top = 17
      Width = 48
      Height = 13
      Caption = 'Etiqueta 1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta2: TLabel
      Left = 3
      Top = 101
      Width = 48
      Height = 13
      Caption = 'Etiqueta 2'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta3: TLabel
      Left = 341
      Top = 17
      Width = 48
      Height = 13
      Caption = 'Etiqueta 3'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta4: TLabel
      Left = 341
      Top = 59
      Width = 48
      Height = 13
      Caption = 'Etiqueta 4'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta5: TLabel
      Left = 492
      Top = 59
      Width = 48
      Height = 13
      Caption = 'Etiqueta 5'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta6: TLabel
      Left = 645
      Top = 59
      Width = 48
      Height = 13
      Caption = 'Etiqueta 6'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta7: TLabel
      Left = 341
      Top = 101
      Width = 48
      Height = 13
      Caption = 'Etiqueta 7'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta8: TLabel
      Left = 492
      Top = 101
      Width = 48
      Height = 13
      Caption = 'Etiqueta 8'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta9: TLabel
      Left = 645
      Top = 101
      Width = 48
      Height = 13
      Caption = 'Etiqueta 9'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Etiqueta1a: TLabel
      Left = 3
      Top = 60
      Width = 54
      Height = 13
      Caption = 'Etiqueta 1a'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object id_unid_organizacional_nivel1: TComboBox
      Left = 3
      Top = 31
      Width = 325
      Height = 21
      Hint = 'Esse '#233' o texto de ajuda da "Etiqueta 1"'
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnChange = id_unid_organizacional_nivel1Change
    end
    object id_unid_organizacional_nivel2: TComboBox
      Left = 3
      Top = 115
      Width = 325
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
    end
    object te_localizacao_complementar: TEdit
      Left = 341
      Top = 31
      Width = 434
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 100
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object te_info_patrimonio3: TEdit
      Left = 645
      Top = 73
      Width = 130
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
    end
    object te_info_patrimonio1: TEdit
      Left = 341
      Top = 73
      Width = 130
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
    end
    object te_info_patrimonio2: TEdit
      Left = 492
      Top = 73
      Width = 130
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
    end
    object te_info_patrimonio6: TEdit
      Left = 645
      Top = 115
      Width = 130
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
    end
    object te_info_patrimonio4: TEdit
      Left = 341
      Top = 115
      Width = 130
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
    end
    object te_info_patrimonio5: TEdit
      Left = 492
      Top = 115
      Width = 130
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
    end
    object id_unid_organizacional_nivel1a: TComboBox
      Left = 3
      Top = 73
      Width = 325
      Height = 21
      Hint = 'Esse '#233' o texto de ajuda da "Etiqueta 1"'
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 9
      OnChange = id_unid_organizacional_nivel1aChange
    end
    object Panel1: TPanel
      Left = 333
      Top = 15
      Width = 2
      Height = 125
      Caption = 'Panel1'
      TabOrder = 10
    end
  end
  object Button2: TButton
    Left = 290
    Top = 237
    Width = 212
    Height = 33
    Caption = 'Gravar Informa'#231#245'es Patrimoniais'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = AtualizaPatrimonio
  end
end
