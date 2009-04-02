object Form1: TForm1
  Left = 453
  Top = 340
  Width = 123
  Height = 157
  Caption = 'chkcacic'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PJVersionInfo1: TPJVersionInfo
  end
  object IdFTP1: TIdFTP
    MaxLineAction = maException
    ReadTimeout = 0
    ProxySettings.ProxyType = fpcmNone
    ProxySettings.Port = 0
    Left = 32
  end
  object FS: TNTFileSecurity
    Left = 64
  end
end
