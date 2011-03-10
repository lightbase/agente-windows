object CacicSustainService: TCacicSustainService
  OldCreateOrder = False
  DisplayName = 'Servi'#231'o para Sustenta'#231#227'o do Agente Principal do Sistema CACIC'
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
