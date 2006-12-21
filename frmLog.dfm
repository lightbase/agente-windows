object FormLog: TFormLog
  Left = 44
  Top = 17
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'CACIC - Log de Atividades'
  ClientHeight = 355
  ClientWidth = 675
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object MemoLog: TMemo
    Left = 4
    Top = 4
    Width = 668
    Height = 306
    Lines.Strings = (
      'MemoLog')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Bt_Fechar_Log: TButton
    Left = 297
    Top = 321
    Width = 95
    Height = 25
    Cancel = True
    Caption = 'Fechar'
    Default = True
    TabOrder = 1
    OnClick = Bt_Fechar_LogClick
  end
end
