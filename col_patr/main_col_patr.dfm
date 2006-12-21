object FormPatrimonio: TFormPatrimonio
  Left = 65
  Top = 67
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'CACIC - Coletor Informa'#231#245'es Patrimoniais'
  ClientHeight = 246
  ClientWidth = 605
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
  object GroupBox1: TGroupBox
    Left = 5
    Top = -1
    Width = 596
    Height = 67
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
      Width = 588
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
      Top = 46
      Width = 456
      Height = 16
      Caption = 
        'Por favor, atualize as informa'#231#245'es abaixo. Agradecemos a sua col' +
        'abora'#231#227'o.'
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
    Left = 5
    Top = 69
    Width = 596
    Height = 144
    Caption = ' Informa'#231#245'es sobre este computador '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Etiqueta1: TLabel
      Left = 11
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
      Left = 185
      Top = 17
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
      Left = 430
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
      Left = 11
      Top = 57
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
      Left = 185
      Top = 57
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
      Left = 430
      Top = 57
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
      Left = 11
      Top = 98
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
      Left = 185
      Top = 98
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
      Left = 430
      Top = 98
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
    object id_unid_organizacional_nivel1: TComboBox
      Left = 9
      Top = 31
      Width = 157
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
      Left = 185
      Top = 31
      Width = 226
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
      Left = 430
      Top = 31
      Width = 157
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object te_info_patrimonio3: TEdit
      Left = 430
      Top = 71
      Width = 155
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
    end
    object te_info_patrimonio1: TEdit
      Left = 9
      Top = 71
      Width = 158
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
    end
    object te_info_patrimonio2: TEdit
      Left = 185
      Top = 71
      Width = 155
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
    end
    object te_info_patrimonio6: TEdit
      Left = 430
      Top = 112
      Width = 155
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
    end
    object te_info_patrimonio4: TEdit
      Left = 9
      Top = 112
      Width = 158
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
    end
    object te_info_patrimonio5: TEdit
      Left = 185
      Top = 112
      Width = 155
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
    end
  end
  object Button2: TButton
    Left = 435
    Top = 219
    Width = 155
    Height = 23
    Caption = 'Gravar Informa'#231#245'es'
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
