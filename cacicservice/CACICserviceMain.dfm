object CacicSustainService: TCacicSustainService
  OldCreateOrder = False
  DisplayName = 'Sustenta'#231#227'o do Agente Principal do Sistema CACIC'
  Interactive = True
  OnExecute = ServiceExecute
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Left = 192
  Top = 107
  Height = 375
  Width = 544
  object timerToCHKSIS: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = timerToCHKSISTimer
    Left = 464
    Top = 16
  end
end
