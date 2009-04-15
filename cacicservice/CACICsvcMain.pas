(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)
unit CACICsvcMain;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  SvcMgr,
  strUtils,
  ExtCtrls,
  CACIC_Library;

var
  boolStarted   : boolean;
  g_oCacic      : TCACIC;

type
  TCACICservice = class(TService)
    Timer_CHKsis: TTimer;
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure Timer_CHKsisTimer(Sender: TObject);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private

    { Internal Start & Stop methods }
    function  GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
    procedure logDEBUG(Msg : String);
    Procedure WMEndSession(var Msg : TWMEndSession) ;  message WM_ENDSESSION;
    procedure ExecutaCACIC;
  public
    { Public declarations }

    function GetServiceController: TServiceController; override;
  end;

var
  CACICservice: TCACICservice;

implementation

{$R *.DFM}
procedure TCACICservice.WMEndSession(var Msg : TWMEndSession) ;
begin
  if Msg.EndSession = TRUE then
    logDEBUG('Windows finalizado em ' + FormatDateTime('c', Now)) ;
  inherited;
  Application.Free;
end;

// Funções Auxiliares
function TCACICservice.GetValorChaveRegIni(p_Secao, p_Chave, p_File : String): String;
//Para buscar do Arquivo INI...
// Marreta devido a limitações do KERNEL w9x no tratamento de arquivos texto e suas seções
//function GetValorChaveRegIni(p_SectionName, p_KeyName, p_IniFileName : String) : String;
var
  FileText : TStringList;
  i, j, v_Size_Section, v_Size_Key : integer;
  v_SectionName, v_KeyName : string;
  begin
    logDEBUG('GetVCRini: Secao: '+p_Secao+' Chave: '+p_Chave+' File: '+p_File);
    Result := '';
    v_SectionName := '[' + p_Secao + ']';
    v_Size_Section := strLen(PChar(v_SectionName));
    v_KeyName := p_Chave + '=';
    v_Size_Key     := strLen(PChar(v_KeyName));
    FileText := TStringList.Create;
    try
      FileText.LoadFromFile(p_File);
      For i := 0 To FileText.Count - 1 Do
        Begin
          if (LowerCase(Trim(PChar(Copy(FileText[i],1,v_Size_Section)))) = LowerCase(Trim(PChar(v_SectionName)))) then
            Begin
              For j := i to FileText.Count - 1 Do
                Begin
                  if (LowerCase(Trim(PChar(Copy(FileText[j],1,v_Size_Key)))) = LowerCase(Trim(PChar(v_KeyName)))) then
                    Begin
                      Result := PChar(Copy(FileText[j],v_Size_Key + 1,strLen(PChar(FileText[j]))-v_Size_Key));
                      Break;
                    End;
                End;
            End;
          if (Result <> '') then break;
        End;
    finally
      FileText.Free;
    end;
  end;

procedure TCACICservice.logDEBUG(Msg : String);
var fLog: textfile;
begin
  // Somente gravarei informações para debug se o arquivo "<HomeDrive>:\CACICsvc.log" existir
  if FileExists(g_oCacic.Windows.getHomeDrive + g_oCacic.Windows.getWinDir + 'CACICsvc.log') then
    Begin
      AssignFile(fLog, g_oCacic.Windows.getHomeDrive + g_oCacic.Windows.getWinDir + 'CACICsvc.log');
      if FileExists(g_oCacic.Windows.getHomeDrive + g_oCacic.Windows.getWinDir + 'CACICsvc.log') then
        Append(fLog)
      else
        Rewrite(fLog);
      Writeln(fLog,FormatDateTime('dd/mm hh:nn:ss ', Now) + '[CACICsvc][DEBUG] : ' +msg);
      CloseFile(fLog);
    End;
End;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  CACICservice.Controller(CtrlCode);
end;

function TCACICservice.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TCACICservice.ServiceExecute(Sender: TService);
begin
     { Loop while service is active in SCM }
     While NOT Terminated do
     Begin
          { Process Service Requests }
          ServiceThread.ProcessRequests( False );
          { Allow system some time }
          Sleep(1);
     End;
end;

procedure TCACICservice.ServiceStart(Sender: TService; var Started: Boolean);
begin

  g_oCacic := TCACIC.Create;
  g_oCacic.setCacicPath(GetValorChaveRegIni('Cacic2', 'cacic_dir', g_oCacic.getWinDir + 'chksis.ini'));
  CACICservice.logDEBUG('TCACICservice.ExecutaCACIC : setCacicPath => '+GetValorChaveRegIni('Cacic2', 'cacic_dir', g_oCacic.getWinDir + 'chksis.ini'));

  CACICservice.logDEBUG('TCACICservice.ServiceStart');
  Started := true;

  ExecutaCACIC;

  Timer_CHKsis.Interval := 60000;
  Timer_CHKsis.Enabled  := true;

  While not Terminated do
    Sleep(250);
end;

procedure TCACICservice.ExecutaCACIC;
Begin
  CACICservice.logDEBUG('TCACICservice.ExecutaCACIC : deleteFile => '+g_oCacic.getCacicPath + 'aguarde_CACIC.txt');
  DeleteFile(g_oCacic.getCacicPath + 'aguarde_CACIC.txt');
  Sleep(3000);

  // Se o arquivo indicador de execução não existir...
  if not (FileExists(g_oCacic.getCacicPath + 'aguarde_CACIC.txt')) then
    Begin
      // Executo o CHKsis, verificando a estrutura do sistema
      Try
        CACICservice.logDEBUG('TCACICservice.ExecutaCACIC : winExec => '+g_oCacic.getWinDir + 'chksis.exe');
        g_oCacic.createSampleProcess(g_oCacic.getWinDir + 'chksis.exe',false);
      Except
      End;

      While not (FileExists(g_oCacic.getCacicPath + 'cacic2.exe')) do
        Sleep(5000); // Espero 5 segundos...

      // Executo o Agente Principal do CACIC
      Try
        CACICservice.logDEBUG('TCACICservice.ExecutaCACIC : winExec => '+g_oCacic.getCacicPath + 'cacic2.exe');
        g_oCacic.createSampleProcess(g_oCacic.getCacicPath + 'cacic2.exe',false);
      Except
      End;
    End;
End;

procedure TCACICservice.ServiceAfterInstall(Sender: TService);
begin
  ServiceStart(nil,boolStarted);
  CACICservice.logDEBUG('TCACICservice.ServiceAfterInstall');
end;

procedure TCACICservice.Timer_CHKsisTimer(Sender: TObject);
begin
  CACICservice.logDEBUG('TCACICservice.Timer_CHKsisTimer');
  ExecutaCACIC;

  // Verificações diversas

end;

procedure TCACICservice.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  CACICservice.logDEBUG('TCACICservice.ServiceStop');
  Stopped := true;
end;

end.
