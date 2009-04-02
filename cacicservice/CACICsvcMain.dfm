object CACICservice: TCACICservice
  OldCreateOrder = False
  DisplayName = 'CACICservice'
  Interactive = True
  AfterInstall = ServiceAfterInstall
  OnExecute = ServiceExecute
  OnStart = ServiceStart
  OnStop = ServiceStop
  Left = 192
  Top = 107
  Height = 375
  Width = 544
  object Timer_CHKsis: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = Timer_CHKsisTimer
    Left = 464
    Top = 16
  end
end
