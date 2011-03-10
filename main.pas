(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

unit main;

interface

uses
  Windows,
  Messages,
  Forms,
  Menus,
  Classes,
  SysUtils,
  Controls,
  StdCtrls,
  ExtCtrls,
  ShellAPI,
  registry,
  dialogs,
  ComCtrls,
  IdBaseComponent,
  IdComponent,
  Buttons,
  CACIC_Library,
  ImgList,
  Graphics,
  USBdetectClass,
  LibXmlParser, // Usado em MontaVetoresPatrimonio
  WinSVC;

  //IdTCPServer;
  //IdFTPServer;

const
  WM_MYMESSAGE   = WM_USER+100;
  KBYTE          = Sizeof(Byte) shl 10;
  MBYTE          = KBYTE shl 10;
  GBYTE          = MBYTE shl 10;
  NORMAL         = 0; // Normal
  OCUPADO        = 1; // Raio - Coletando
  DESCONFIGURADO = 2; // Interrogação - Identificando Host
  AGUARDE        = 3; // Ampulheta - Aguardando ação local (recuperação de agentes, etc.)

// Declaração das variáveis globais.
var
  p_Shell_Command,
  p_Shell_Path,
  v_versao,
  v_DataCacic3DAT,
  v_Tamanho_Arquivo,
  strConfigsPatrimonio      : string;

var
  g_intTaskBarAtual,
  g_intTaskBarAnterior,
  g_intStatus               : integer;

var
  boolWinIniChange          : Boolean;

var
  g_oCacic: TCACIC;

type
  TFormularioGeral = class(TForm)
    Pn_InfosGerais: TPanel;
    Pn_SisMoni: TPanel;
    Lb_SisMoni: TLabel;
    Pn_TCPIP: TPanel;
    Lb_TCPIP: TLabel;
    GB_InfosTCPIP: TGroupBox;
    ST_VL_MacAddress: TStaticText;
    ST_LB_MacAddress: TStaticText;
    ST_LB_NomeHost: TStaticText;
    ST_VL_NomeHost: TStaticText;
    ST_LB_IpEstacao: TStaticText;
    ST_LB_IpRede: TStaticText;
    ST_LB_DominioDNS: TStaticText;
    ST_LB_DnsPrimario: TStaticText;
    ST_LB_DnsSecundario: TStaticText;
    ST_LB_Gateway: TStaticText;
    ST_LB_Mascara: TStaticText;
    ST_LB_ServidorDHCP: TStaticText;
    ST_LB_WinsPrimario: TStaticText;
    ST_LB_WinsSecundario: TStaticText;
    ST_VL_IpEstacao: TStaticText;
    ST_VL_DNSPrimario: TStaticText;
    ST_VL_DNSSecundario: TStaticText;
    ST_VL_Gateway: TStaticText;
    ST_VL_Mascara: TStaticText;
    ST_VL_ServidorDHCP: TStaticText;
    ST_VL_WinsPrimario: TStaticText;
    ST_VL_WinsSecundario: TStaticText;
    ST_VL_DominioDNS: TStaticText;
    ST_VL_IpRede: TStaticText;
    Pn_Linha1_TCPIP: TPanel;
    Pn_Linha2_TCPIP: TPanel;
    Pn_Linha3_TCPIP: TPanel;
    Pn_Linha4_TCPIP: TPanel;
    Pn_Linha6_TCPIP: TPanel;
    Pn_Linha5_TCPIP: TPanel;
    Timer_Nu_Intervalo: TTimer;
    Timer_Nu_Exec_Apos: TTimer;
    Popup_Menu_Contexto: TPopupMenu;
    Mnu_LogAtividades: TMenuItem;
    Mnu_Configuracoes: TMenuItem;
    Mnu_ExecutarAgora: TMenuItem;
    Mnu_InfosTCP: TMenuItem;
    Mnu_FinalizarCacic: TMenuItem;
    listSistemasMonitorados: TListView;
    pnColetasRealizadasNestaData: TPanel;
    lbColetasRealizadasNestaData: TLabel;
    listaColetas: TListView;
    teDataColeta: TLabel;
    pnInformacoesPatrimoniais: TPanel;
    lbInformacoesPatrimoniais: TLabel;
    gpInfosPatrimoniais: TGroupBox;
    st_lb_Etiqueta5: TStaticText;
    st_lb_Etiqueta1: TStaticText;
    st_vl_Etiqueta1: TStaticText;
    st_lb_Etiqueta1a: TStaticText;
    st_lb_Etiqueta2: TStaticText;
    st_lb_Etiqueta7: TStaticText;
    st_lb_Etiqueta6: TStaticText;
    st_lb_Etiqueta8: TStaticText;
    st_vl_Etiqueta1a: TStaticText;
    st_vl_Etiqueta2: TStaticText;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel11: TPanel;
    st_lb_Etiqueta4: TStaticText;
    st_lb_Etiqueta3: TStaticText;
    st_vl_Etiqueta3: TStaticText;
    st_lb_Etiqueta9: TStaticText;
    st_vl_etiqueta4: TStaticText;
    st_vl_etiqueta5: TStaticText;
    st_vl_etiqueta6: TStaticText;
    st_vl_etiqueta7: TStaticText;
    st_vl_etiqueta8: TStaticText;
    st_vl_etiqueta9: TStaticText;
    Mnu_SuporteRemoto: TMenuItem;
    lbSemInformacoesPatrimoniais: TLabel;
    pnServidores: TPanel;
    lbServidores: TLabel;
    GroupBox1: TGroupBox;
    staticVlServidorUpdates: TStaticText;
    staticNmServidorUpdates: TStaticText;
    staticNmServidorAplicacao: TStaticText;
    staticVlServidorAplicacao: TStaticText;
    Panel4: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    pnVersao: TPanel;
    bt_Fechar_Infos_Gerais: TBitBtn;
    Timer_InicializaTray: TTimer;
    imgList_Icones: TImageList;
    procedure RemoveIconesMortos;
    procedure ChecaCONFIGS;
    procedure CriaFormSenha(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Sair(Sender: TObject);
    procedure MinimizaParaTrayArea(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ExecutaCacic(Sender: TObject);
    procedure SetaVariaveisGlobais;
    procedure ExibirLogAtividades(Sender: TObject);
    procedure ExibirConfiguracoes(Sender: TObject);
    procedure HabilitaTCP;
    procedure HabilitaSuporteRemoto;
    procedure Mnu_InfosTCPClick(Sender: TObject);
    procedure Bt_Fechar_InfosGeraisClick(Sender: TObject);

    function  ChecaGERCOLS : boolean;
//    function  ConditionalCipherOpen : boolean;
    function  FindWindowByTitle(WindowTitle: string): Hwnd;
    function  GetFileSize(sFileToExamine: string): integer;
    function  getSizeInBytes(Value: Real; Mode: string): string;
    function  InActivity : boolean;
    function  Posso_Rodar : boolean;
{
    procedure IdHTTPServerCACICCommandGet(AThread: TIdPeerThread;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);

    procedure IdFTPServer1UserLogin(ASender: TIdFTPServerThread;
      const AUsername, APassword: String; var AAuthenticated: Boolean);
}
    procedure Mnu_SuporteRemotoClick(Sender: TObject);
    procedure Popup_Menu_ContextoPopup(Sender: TObject);
    procedure Timer_InicializaTrayTimer(Sender: TObject);
  private
    FUsb : TUsbClass;
    ShutdownEmExecucao : Boolean;
    IsMenuOpen : Boolean;
    NotifyStruc : TNotifyIconData; {Estrutura do tray icon}
    procedure UsbIN(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
    procedure UsbOUT(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
    procedure InicializaTray;
    procedure Finaliza;
    procedure MontaVetoresPatrimonio(p_strConfigs : String);
    Function  RetornaValorVetorUON1(id1 : string) : String;
    Function  RetornaValorVetorUON1a(id1a : string) : String;
    Function  RetornaValorVetorUON2(id2, idLocal: string) : String;
    function  ServiceStart(sMachine,sService : string ) : boolean;
    procedure Invoca_GerCols(p_acao:string; boolShowInfo : Boolean = true; boolCheckExecution : Boolean = false);
    procedure CheckIfDownloadedVersion;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure TrayMessage(var Msg: TMessage); message WM_MYMESSAGE; {The tray procedure to look for mouse input}
    // A procedure WMQueryEndSession é usada para detectar o
    // Shutdown do Windows e "derrubar" o Cacic.
    procedure WMQueryEndSession(var Msg : TWMQueryEndSession); Message WM_QUERYENDSESSION;
    procedure WMMENUSELECT(var msg: TWMMENUSELECT); message WM_MENUSELECT;
  protected
    procedure WndProc(var Message: TMessage); override;
  public
//    Procedure CipherCloseGenerico(p_TstrCipherOpened : TStrings; p_StrFileName : String);
//    Procedure CipherOpenGenerico(var p_TstrCipherOpened : TStrings; p_StrFileName : String);
    function  URLDecode(const S: string): string;
    Procedure EqualizaInformacoesPatrimoniais;
  end;

var FormularioGeral             : TFormularioGeral;
    boolServerON                : Boolean;

implementation


{$R *.dfm}

Uses  StrUtils,
      Inifiles,
      frmConfiguracoes,
      frmSenha,
      frmLog,
      Math;
//      ,      WinVNC;

// Estruturas de dados para armazenar os itens da uon1, uon1a e uon2
type
  TRegistroUON1 = record
    id1 : String;
    nm1 : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON1a = record
    id1     : String;
    id1a    : String;
    nm1a    : String;
    id_local: String;
  end;

  TVetorUON1a = array of TRegistroUON1a;

  TRegistroUON2 = record
    id1a    : String;
    id2     : String;
    nm2     : String;
    id_local: String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1  : TVetorUON1;
    VetorUON1a : TVetorUON1a;
    VetorUON2  : TVetorUON2;


Function TFormularioGeral.RetornaValorVetorUON1(id1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].id1 = id1) Then Result := VetorUON1[I].nm1;
end;

Function TFormularioGeral.RetornaValorVetorUON1a(id1a : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1a)-1)  Do
       If (VetorUON1a[I].id1a     = id1a) Then Result := VetorUON1a[I].nm1a;
end;

Function TFormularioGeral.RetornaValorVetorUON2(id2, idLocal: string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].id2      = id2) and
          (VetorUON2[I].id_local = idLocal) Then Result := VetorUON2[I].nm2;
end;

function TFormularioGeral.ServiceStart(sMachine,sService : string ) : boolean;
var
  schm, // Service Control Manager Handle
  schs   : SC_Handle;  // Service Handle
  ss     : TServiceStatus;  // Service Status
  psTemp : PChar;   // Temp Char Pointer
  dwChkP : DWord;   // Check Point
begin
//  ss.dwCurrentState := -1;
  g_oCacic.writeDebugLog('ServiceStart => ' + sService + ' - Iniciando!');
  ss.dwCurrentState := 0;

  // connect to the Service Control Manager
  schm := OpenSCManager(PChar(sMachine),Nil,SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
  begin
    // open a handle to the specified service
    schs := OpenService(schm,PChar(sService),SERVICE_START or SERVICE_QUERY_STATUS);  // we want to start the service and query service status

    // if successful...
    if(schs > 0)then
    begin
      psTemp := Nil;
      if(StartService(
           schs,
           0,
           psTemp))then
      begin
        // check status
        if(QueryServiceStatus(
             schs,
             ss))then
        begin
          while(SERVICE_RUNNING
            <> ss.dwCurrentState)do
          begin
            //
            // dwCheckPoint contains a value that the service
            // increments periodically to report its progress
            // during a lengthy operation.
            //
            // save current value
            //
            dwChkP := ss.dwCheckPoint;

            //
            // wait a bit before checking status again
            //
            // dwWaitHint is the estimated amount of time
            // the calling program should wait before calling
            // QueryServiceStatus() again
            //
            // idle events should be handled here...
            //
            Sleep(ss.dwWaitHint);

            if(not QueryServiceStatus(
                 schs,
                 ss))then
            begin
              // couldn't check status break from the loop
              break;
            end;

            if(ss.dwCheckPoint <
              dwChkP)then
            begin
              // QueryServiceStatus didn't increment dwCheckPoint as it
              // should have.
              // avoid an infinite loop by breaking
              break;
            end;
          end;
        end;
      end;

      // close service handle
      CloseServiceHandle(schs);
    end;

    // close service control manager handle
    CloseServiceHandle(schm);
  end;

  // return TRUE if the service status is running
  Result := SERVICE_RUNNING = ss.dwCurrentState;
  if Result then
    g_oCacic.writeDebugLog('ServiceStart => ' + sService + ' - OK!')
  else
    g_oCacic.writeDebugLog('ServiceStart => ' + sService + ' - Não Foi Possível Iniciar!');
end;
procedure TFormularioGeral.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_WININICHANGE :
      Begin
        // Esta mensagem é recebida quando efetuado LogOff/LogOn em máquinas com VISTA,
        boolWinIniChange := true;
      End;
  end;
  inherited;
end;

// Início de Procedimentos para monitoramento de dispositivos USB - Anderson Peterle - 02/2010
procedure TFormularioGeral.UsbIN(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
begin
  // Envio de valores ao Gerente WEB
  // Formato: USBinfo=I_ddmmyyyyhhnnss_ADeviceID
  // Os valores serão armazenados localmente (cacic3.inf) se for impossível o envio.
  g_oCacic.writeDebugLog('<< USB INSERIDO .:. Vendor ID => ' + AVendorID + ' .:. Device ID = ' + ADeviceID);
  Invoca_GerCols('USBinfo=I_'+FormatDateTime('yyyymmddhhnnss', now) + '_' + AVendorID + '_' + ADeviceID, false, false);
end;


procedure TFormularioGeral.UsbOUT(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
begin
  // Envio de valores ao Gerente WEB
  // Formato: USBinfo=O_ddmmyyyyhhnnss_ADeviceID
  // Os valores serão armazenados localmente (cacic3.inf) se for impossível o envio.
  g_oCacic.writeDebugLog('>> USB REMOVIDO .:. Vendor ID => ' + AVendorID + ' .:. Device ID = ' + ADeviceID);
  Invoca_GerCols('USBinfo=O_'+FormatDateTime('yyyymmddhhnnss', now) + '_' + AVendorID + '_' + ADeviceID, false, false);
end;

// Fim de Procedimentos para monitoramento de dispositivos USB - Anderson Peterle - 02/2010

procedure TFormularioGeral.MontaVetoresPatrimonio(p_strConfigs : String);
var Parser   : TXmlParser;
    i        : integer;
    strAux,
    strAux1,
    strTagName,
    strItemName  : string;
begin

  Parser := TXmlParser.Create;
  Parser.Normalize := True;
  Parser.LoadFromBuffer(PAnsiChar(p_strConfigs));
  g_oCacic.writeDebugLog('MontaVetores.p_strConfigs: '+p_strConfigs);

  // Código para montar o vetor UON1
  Parser.StartScan;
  i := -1;
  strItemName := '';
  strTagName  := '';
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
          strTagName := 'IT1';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1')Then
       Begin
         strAux1 := g_oCacic.deCrypt(Parser.CurContent);
         if      (strItemName = 'ID1') then
           Begin
             VetorUON1[i].id1 := strAux1;
             g_oCacic.writeDebugLog('Gravei VetorUON1.id1: "'+strAux1+'"');
           End
         else if (strItemName = 'NM1') then
           Begin
             VetorUON1[i].nm1 := strAux1;
             g_oCacic.writeDebugLog('Gravei VetorUON1.nm1: "'+strAux1+'"');
           End;
       End;
    End;

  // Código para montar o vetor UON1a
  Parser.StartScan;
  strTagName := '';
  strAux1    := '';
  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1A') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1a, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
          strTagName := 'IT1A';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1A') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1A')Then
        Begin
          strAux1 := g_oCacic.deCrypt(Parser.CurContent);
          if      (strItemName = 'ID1') then
            Begin
              VetorUON1a[i].id1 := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.id1: "'+strAux1+'"');
            End
          else if (strItemName = 'SG_LOC') then
            Begin
              strAux := ' ('+strAux1 + ')';
            End
          else if (strItemName = 'ID1A') then
            Begin
              VetorUON1a[i].id1a := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'NM1A') then
            Begin
              VetorUON1a[i].nm1a := strAux1+strAux;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.nm1a: "'+strAux1+strAux+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON1a[i].id_local := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON1a.id_local: "'+strAux1+'"');
            End;

        End;
    end;

  // Código para montar o vetor UON2
  Parser.StartScan;
  strTagName := '';
  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT2') Then
       Begin
          i := i + 1;
          SetLength(VetorUON2, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o número de itens recebidos.
          strTagName := 'IT2';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT2') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT2')Then
        Begin
          strAux1  := g_oCacic.deCrypt(Parser.CurContent);
          if      (strItemName = 'ID1A') then
            Begin
              VetorUON2[i].id1a := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'ID2') then
            Begin
              VetorUON2[i].id2 := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.id2: "'+strAux1+'"');
            End
          else if (strItemName = 'NM2') then
            Begin
              VetorUON2[i].nm2 := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.nm2: "'+strAux1+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON2[i].id_local := strAux1;
              g_oCacic.writeDebugLog('Gravei VetorUON2.id_local: "'+strAux1+'"');
            End;

        End;
    end;
  Parser.Free;
end;

function TFormularioGeral.InActivity : boolean;
Begin
  // Se eu conseguir matar os arquivos abaixo é porque srCACICsrv, Ger_Cols e mapaCACIC já finalizaram suas atividades...
  g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','aguarde_GER.txt');
  g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','aguarde_SRCACIC.txt');
  g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','aguarde_MAPACACIC.txt');

  Result := (FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_GER.txt')     or
             FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_SRCACIC.txt') or
             FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_MAPACACIC.txt'));
End;

function Pode_Coletar : boolean;
var v_JANELAS_EXCECAO,
    v_plural1,
    v_plural2   : string;
    tstrJANELAS : TStrings;
    h : hwnd;
    v_contador, intContaJANELAS, intAux : integer;
Begin
    intContaJANELAS := 0;
    h := 0;

    if not FormularioGeral.InActivity then
        Begin
          // Verificação das janelas abertas para que não aconteça coletas caso haja aplicações pesadas rodando (configurado no Módulo Gerente)
          v_JANELAS_EXCECAO := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TE_JANELAS_EXCECAO',g_oCacic.getLocalFolder + 'GER_COLS.inf'));

          g_oCacic.writeDebugLog('Verificando Janelas para Exceção...');
          tstrJANELAS := TStrings.Create;
          if (v_JANELAS_EXCECAO <> '') then
            Begin
              tstrJANELAS := g_oCacic.explode(trim(v_JANELAS_EXCECAO),',');
              if (tstrJANELAS.Count > 0) then
                  for intAux := 0 to tstrJANELAS.Count-1 Do
                    Begin

                      h := FormularioGeral.FindWindowByTitle(tstrJANELAS[intAux]);
                      if h <> 0 then intContaJANELAS := 1;
                      break;
                    End;
            End;

          // Caso alguma janela tenha algum nome de aplicação cadastrada como "crítica" ou "pesada"...
          if (intContaJANELAS > 0) then
            Begin
              g_oCacic.writeDailyLog('EXECUÇÃO DE ATIVIDADES ADIADA!');
              v_contador := 0;
              v_plural1 := '';
              v_plural2 := 'ÃO';
              for intAux := 0 to tstrJANELAS.Count-1 Do
                Begin
                  h := FormularioGeral.FindWindowByTitle(tstrJANELAS[intAux]);
                  if h <> 0 then
                    Begin
                      v_contador := v_contador + 1;
                      g_oCacic.writeDailyLog('Aplicação/Janela ' + inttostr(v_contador) + ': ' + tstrJANELAS[intAux]);
                    End;
                End;
              if (v_contador > 1) then
                Begin
                  v_plural1  := 'S';
                  v_plural2 := 'ÕES';
                End;
              g_oCacic.writeDailyLog('-> PARA PROCEDER, FINALIZE A' + v_plural1 + ' APLICAÇ' + v_plural2 + ' LISTADA' + v_plural1 + ' ACIMA.');

              // Número de minutos para iniciar a execução (60.000 milisegundos correspondem a 1 minuto). Acrescento 1, pois se for zero ele não executa.
              FormularioGeral.Timer_Nu_Exec_Apos.Enabled  := False;
              FormularioGeral.Timer_Nu_Exec_Apos.Interval := strtoint(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_EXEC_APOS',g_oCacic.getLocalFolder + 'GER_COLS.inf'))) * 60000;
              FormularioGeral.Timer_Nu_Exec_Apos.Enabled  := True;
            End;
        End;

     if (intContaJANELAS = 0) and (h = 0) and not FormularioGeral.InActivity then
       Result := true
     else
        Begin
          g_oCacic.writeDebugLog('A Ação foi NEGADA!');
          if (intContaJANELAS=0) then
            Begin
              if (FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_SRCACIC.txt')) then
                g_oCacic.writeDebugLog('Suporte Remoto em atividade.');

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_GER.txt')) then
                g_oCacic.writeDebugLog('Gerente de Coletas em atividade.');

              if (FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_MAPACACIC.txt')) then
                g_oCacic.writeDebugLog('Módulo Avulso para Coleta de Patrimônio em atividade.');
            End;
          //else
          //  g_oCacic.cipherClose(g_oCacic.getLocalFolder + g_oCacic.getDatFileName,v_tstrCipherOpened);
          Result := false;
        End;

End;

Function TFormularioGeral.getSizeInBytes(Value: Real; Mode: string): string;
  function FltToStr(F: Extended): string;
    begin
      Result := FloatToStrF(Round(F), ffNumber, 18, 0);
    end;
Begin
  if Mode = '0' then
    Result := FltTostr(Value);
  if Mode = '' then
    begin
      if Value > GBYTE then
        Result := FltTostr(Value / GBYTE) + ' G'
      else
        if Value > MBYTE then
          Result := FltToStr(Value / MBYTE) + ' M'
        else
          if Value > KBYTE then
            Result := FltTostr(Value / KBYTE) + ' K'
          else
            Result := FltTostr(Value) + ' B'; { 04.08.96 sb }
          exit;
    end;

  if Mode = '-1' then
    begin
      if Value > GBYTE then
        Result := FltToStr(Value / MBYTE) + ' M'
      else
        if Value > MBYTE then
          Result := FltTostr(Value / KBYTE) + ' K'
        else
          Result := FltTostr(Value) + ' B'; { 04.08.96 sb }
        exit;
     end;

  if Mode = 'GB' then
    Result := FltTostr(Value / GBYTE) + ' G';

  if Mode = 'MB' then
    Result := FltTostr(Value / MBYTE) + ' M';

  if Mode = 'KB' then
    Result := FltTostr(Value / KBYTE) + ' K';

  if Mode = 'B' then
    Result := FltTostr(Value) + ' B';

  Result := Trim(Result);
end;
//
function TFormularioGeral.GetFileSize(sFileToExamine: string): integer;
var
  SearchRec: TSearchRec;
  inRetval: Integer;
begin
  try
    inRetval := FindFirst(ExpandFileName(sFileToExamine), faAnyFile, SearchRec);
    if inRetval = 0 then
      Result := SearchRec.Size
    else
      Result := -1;
  finally
    SysUtils.FindClose(SearchRec);
  end;
end;

Procedure TFormularioGeral.RemoveIconesMortos;
var
  TrayWindow : HWnd;
  WindowRect : TRect;
  SmallIconWidth : Integer;
  SmallIconHeight : Integer;
  CursorPos : TPoint;
  Row : Integer;
  Col : Integer;
begin
  { Get tray window handle and bounding rectangle }
  TrayWindow := FindWindowEx(FindWindow('Shell_TrayWnd',NIL),0,'TrayNotifyWnd',NIL);
  if not GetWindowRect(TrayWindow,WindowRect) then
    Exit;
  { Get small icon metrics }
  SmallIconWidth := GetSystemMetrics(SM_CXSMICON);
  SmallIconHeight := GetSystemMetrics(SM_CYSMICON);
  { Save current mouse position }
  GetCursorPos(CursorPos);
  { Sweep the mouse cursor over each icon in the tray in both dimensions }
  with WindowRect do
  begin
    for Row := 0 to (Bottom - Top) DIV SmallIconHeight do
    begin
      for Col := 0 to (Right - Left) DIV SmallIconWidth do
      begin
        SetCursorPos(Left + Col * SmallIconWidth, Top + Row * SmallIconHeight);
        Sleep(0);
      end;
    end;
  end;
  { Restore mouse position }
  SetCursorPos(CursorPos.X,CursorPos.Y);
  { Redraw tray window (to fix bug in multi-line tray area) }
  RedrawWindow(TrayWindow,NIL,0,RDW_INVALIDATE OR RDW_ERASE OR RDW_UPDATENOW);
End;

procedure TFormularioGeral.WMMENUSELECT(var msg: TWMMENUSELECT);
begin
  inherited;
  IsMenuOpen := not ((msg.MenuFlag and $FFFF > 0) and
    (msg.Menu = 0));
end;

// Verifico a existência do Gerente de Coletas, caso não exista, o chksis.exe fará download!
function TFormularioGeral.ChecaGERCOLS : boolean;
Begin
  g_oCacic.writeDebugLog('ChecaGERCOLS - BEGIN');
  Result := true;

  g_oCacic.writeDebugLog('ChecaGERCOLS - Verificando existência e tamanho do Gerente de Coletas...');

  v_Tamanho_Arquivo := intToStr( GetFileSize(g_oCacic.getLocalFolder + '\modulos\ger_cols.exe'));

  g_oCacic.writeDebugLog('ChecaGERCOLS - Tamanho: #'+v_Tamanho_Arquivo);

  if (v_Tamanho_Arquivo = '0') or (v_Tamanho_Arquivo = '-1') then
    Begin
      Result := false;

      g_oCacic.killFiles(g_oCacic.getLocalFolder + '\modulos\','ger_cols.exe');

      InicializaTray;

      g_oCacic.writeDailyLog('Acionando recuperador de Módulo Gerente de Coletas.');
      g_oCacic.writeDebugLog('Recuperador de Módulo Gerente de Coletas: '+g_oCacic.getWinDir + 'chksis.exe');
      g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);

      sleep(30000); // 30 segundos de espera para download do ger_cols.exe
      v_Tamanho_Arquivo := intToStr( GetFileSize(g_oCacic.getLocalFolder + '\modulos\ger_cols.exe'));
      if not(v_Tamanho_Arquivo = '0') and not(v_Tamanho_Arquivo = '-1') then
        Begin
          g_oCacic.writeDailyLog('Módulo Gerente de Coletas RECUPERADO COM SUCESSO!');
          InicializaTray;
          Result := True;
        End
      else
          g_oCacic.writeDailyLog('Módulo Gerente de Coletas NÃO RECUPERADO!');
    End;
  g_oCacic.writeDebugLog('ChecaGERCOLS - END');
End;

procedure ExibirConfiguracoes(Sender: TObject);
begin
  // SJI = Senha Já Informada...
  // Esse valor é inicializado com "N"
  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','SJI',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') and
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'GER_COLS.inf')) <> '') then
    begin
      FormularioGeral.CriaFormSenha(nil);
      formSenha.ShowModal;
    end;

  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','SJI',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) <> '') or
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'GER_COLS.inf')) = '') then
    begin
      Application.CreateForm(TFormConfiguracoes, FormConfiguracoes);
      FormConfiguracoes.ShowModal;
    end;
end;

procedure TFormularioGeral.CriaFormSenha(Sender: TObject);
begin
    g_oCacic.setValueToFile('Configs','TE_SENHA_ADM_AGENTE', (g_oCacic.GetValueFromFile('Configs','TE_SENHA_ADM_AGENTE',g_oCacic.getLocalFolder + 'GER_COLS.inf')),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    // Caso ainda não exista senha para administração do CACIC, define ADMINCACIC como inicial.
    if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TE_SENHA_ADM_AGENTE',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') Then
      g_oCacic.setValueToFile('Configs','TE_SENHA_ADM_AGENTE', g_oCacic.enCrypt( 'ADMINCACIC'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

    Application.CreateForm(TFormSenha, FormSenha);
end;

procedure TFormularioGeral.ChecaCONFIGS;
var strAux        : string;
Begin

  // Verifico se o endereço do servidor do cacic foi configurado.
  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'GER_COLS.inf')) = '') then
    Begin
      strAux := g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getWinDir + 'chksis.ini');

      if (strAux = '') then
        begin
          strAux := 'ATENÇÃO: Endereço do servidor do CACIC ainda não foi configurado.';
          g_oCacic.writeDailyLog(strAux);
          g_oCacic.writeDailyLog('Ativando módulo de configuração de endereço de servidor.');
          MessageDlg(strAux + #13#10 + 'Por favor, informe o endereço do servidor do CACIC na tela que será exibida a seguir.', mtWarning, [mbOk], 0);
          ExibirConfiguracoes(Nil);
        end
      else
        Begin
          g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.enCrypt( strAux),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
          g_oCacic.setValueToFile('Configs','TeWebManagerAddress',strAux,g_oCacic.getWinDir + 'chksis.ini');
        End;
    End;

end;

procedure TFormularioGeral.HabilitaTCP;
Begin
  // Procedimento para que sejam igualadas as informações de patrimônio caso seja usado o MapaCACIC
  FormularioGeral.EqualizaInformacoesPatrimoniais;

  // Desabilita/Habilita a opção de Informações de TCP/IP
  Mnu_InfosTCP.Enabled := (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_NOME_HOST'      ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_IP'             ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','ID_IP_REDE'        ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_DOMINIO_DNS'    ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_DNS_PRIMARIO'   ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_DNS_SECUNDARIO' ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_GATEWAY'        ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_MASCARA'        ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_SERV_DHCP'      ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_WINS_PRIMARIO'  ,g_oCacic.getLocalFolder + 'GER_COLS.inf')) +
                           g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_WINS_SECUNDARIO',g_oCacic.getLocalFolder + 'GER_COLS.inf')) <> '');
End;

procedure TFormularioGeral.HabilitaSuporteRemoto;
Begin
  // Desabilita/Habilita a opção de Suporte Remoto
  Mnu_SuporteRemoto.Enabled := (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','CS_SUPORTE_REMOTO',g_oCacic.getLocalFolder + 'GER_COLS.inf')) = 'S') and (FileExists(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe'));
End;

function TFormularioGeral.Posso_Rodar : boolean;
Begin
  result := false;

  g_oCacic.writeDebugLog('Verificando concomitância de sessões');
  // Se eu conseguir matar o arquivo abaixo é porque não há outra sessão deste agente aberta... (POG? Nããão!  :) )
  g_oCacic.killFiles(g_oCacic.getLocalFolder,'aguarde_CACIC.txt');
  if  (not (FileExists(g_oCacic.getLocalFolder + 'aguarde_CACIC.txt'))) then
    result := true;
End;

procedure TFormularioGeral.FormCreate(Sender: TObject);
var strAux,
    v_TeWebManagerAddress : string;
    intAux : integer;
    v_Aguarde : TextFile;
begin

      // Criação do objeto para monitoramento de dispositivos USB
      FUsb                := TUsbClass.Create;
      FUsb.OnUsbInsertion := UsbIN;
      FUsb.OnUsbRemoval   := UsbOUT;

      // Essas variáveis ajudarão a controlar o redesenho do ícone no systray,
      // evitando o "roubo" do foco.
      g_intTaskBarAtual    := 0;
      g_intTaskBarAnterior := 0;
      boolWinIniChange     := false;

      // Não mostrar o formulário...
      Application.ShowMainForm:=false;

      g_oCacic := TCACIC.Create;

      g_oCacic.setBoolCipher(true);
      g_oCacic.setMainProgramName(ExtractFileName( ParamStr(0) ));
      g_oCacic.setMainProgramHash(g_oCacic.getFileHash(ParamStr(0) ));

      //g_oCacic.showTrayIcon(false);


      Try
         v_TeWebManagerAddress := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getWinDir + 'chksis.ini'));
         g_oCacic.setWebManagerAddress(v_TeWebManagerAddress) ;
         g_oCacic.setLocalFolder(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeLocalFolder',g_oCacic.getWinDir + 'chksis.ini'))) ;

         if not DirectoryExists(g_oCacic.getLocalFolder + 'Temp') then
           begin
             ForceDirectories(g_oCacic.getLocalFolder + 'Temp');
             g_oCacic.writeDailyLog('Criando pasta '+g_oCacic.getLocalFolder + 'Temp');
           end;

         if not DirectoryExists(g_oCacic.getLocalFolder + 'Modulos') then
           begin
             ForceDirectories(g_oCacic.getLocalFolder + 'Modulos');
             g_oCacic.writeDailyLog('Criando pasta '+g_oCacic.getLocalFolder + 'Modulos');
           end;

         g_oCacic.checkDebugMode;

         g_oCacic.writeDebugLog('Pasta Local do Sistema: "' + g_oCacic.getLocalFolder + '"');

         if Posso_Rodar then
            Begin
              // Uma forma fácil de evitar que outra sessão deste agente seja iniciada! (POG? Nããããooo!) :))))
              AssignFile(v_Aguarde,g_oCacic.getLocalFolder + 'aguarde_CACIC.txt'); {Associa o arquivo a uma variável do tipo TextFile}
              {$IOChecks off}
              Reset(v_Aguarde); {Abre o arquivo texto}
              {$IOChecks on}
              if (IOResult <> 0) then // Arquivo não existe, será recriado.
                Rewrite (v_Aguarde);

              Append(v_Aguarde);
              Writeln(v_Aguarde,'Apenas um pseudo-cookie para evitar sessões concomitantes...');
              Append(v_Aguarde);
              Writeln(v_Aguarde,'Futuramente penso em colocar aqui o pID, para possibilitar finalização via software externo...');
              Append(v_Aguarde);

              //v_DataCacic3DAT             := '';
              //v_tstrCipherOpened          := TStrings.Create;
              //v_tstrCipherOpened          := g_oCacic.cipherOpen(g_oCacic.getLocalFolder + g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              //FormularioGeral.ConditionalCipherOpen;

              g_oCacic.setValueToFile('Configs','TeMainProgramName',g_oCacic.enCrypt( g_oCacic.getMainProgramName),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
              g_oCacic.setValueToFile('Configs','TeMainProgramHash',g_oCacic.enCrypt( g_oCacic.getMainProgramHash),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

              if FileExists(g_oCacic.getLocalFolder + 'cacic3.inf') then
                Begin
                  g_oCacic.writeDebugLog('O arquivo "'+g_oCacic.getLocalFolder + 'cacic3.inf" existe. Vou resgatar algumas chaves/valores');
                  v_TeWebManagerAddress := g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + 'cacic3.inf');

                  g_oCacic.setValueToFile('Configs','TeWebServicesFolder' ,g_oCacic.enCrypt( g_oCacic.GetValueFromFile('Configs','TeWebServicesFolder',g_oCacic.getLocalFolder + 'cacic3.inf')),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                  g_oCacic.killFiles(g_oCacic.getLocalFolder,'cacic3.inf');
                End;

              g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.enCrypt( v_TeWebManagerAddress),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

              // Procedimento para que sejam igualadas as informações de patrimônio caso seja usado o MapaCACIC
              EqualizaInformacoesPatrimoniais;

              Try
                // Inicializo bloqueando o módulo de suporte remoto seguro na FireWall nativa.
                if FileExists(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe') then
                  g_oCacic.addApplicationToFirewall('srCACIC - Suporte Remoto Seguro do Sistema CACIC',g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe', false);
              Except
              End;

              CheckIfDownloadedVersion;

              if (ParamCount > 0) then //Caso o Cacic3 seja chamado com passagem de parâmetros...
                Begin
                  // Parâmetros possíveis (aceitos)
                  //   /TeWebManagerAddress =>  Endereço do Módulo Gerente WEB. Ex.: pwebcgi01/cacic3
                  //   /atualizacao   =>  O CACIC foi chamado pelo batch de AutoUpdate e deve ir direto para o ExecutaCacic.

                  // Chamada com parâmetros pelo chkcacic.exe ou linha de comando
                  For intAux := 1 to ParamCount do
                    Begin
                      if (Copy(ParamStr(intAux),1,21) = '/TeWebManagerAddress=') then
                        begin
                          g_oCacic.writeDebugLog('Parâmetro /TeWebManagerAddress recebido...');
                          strAux := Trim(Copy(ParamStr(intAux),22,Length((ParamStr(intAux)))));
                          g_oCacic.writeDebugLog('strAux = "'+strAux+'"');
                          v_TeWebManagerAddress := Trim(Copy(strAux,0,Pos(' ', strAux) - 1));
                          If (v_TeWebManagerAddress = '') Then v_TeWebManagerAddress := strAux;
                          g_oCacic.setValueToFile('Configs','TeWebManagerAddress',g_oCacic.enCrypt( v_TeWebManagerAddress),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
                        end;
                    end;

                    If  FindCmdLineSwitch('execute', True) or
                        FindCmdLineSwitch('atualizacao', True) Then
                        begin
                          if FindCmdLineSwitch('atualizacao', True) then
                            begin
                              g_oCacic.writeDebugLog('Opção /atualizacao recebida...');
                              g_oCacic.writeDailyLog('Reinicializando com versão '+ g_oCacic.GetVersionInfo(ParamStr(0)));
                            end
                          else
                            begin
                              g_oCacic.writeDebugLog('Opção /execute recebida...');
                              g_oCacic.writeDailyLog('Opção para execução imediata encontrada...');
                            end;
                          ExecutaCacic(nil);
                        end;
                End;

              // Os timers iniciam-se desabilitados... Mais à frente receberão parâmetros de tempo para execução.
              Timer_Nu_Exec_Apos.Enabled  := False;
              Timer_Nu_Intervalo.Enabled  := False;

              // Derruba o cacic durante o shutdown do windows.
              ShutdownEmExecucao := False;

              // Não mostrar o formulário...
              //Application.ShowMainForm:=false;

              Try
                // A chamada abaixo define os valores usados pelo agente principal.
                SetaVariaveisGlobais;
              Except
                g_oCacic.writeDailyLog('PROBLEMAS SETANDO VARIÁVEIS GLOBAIS!');
              End;

              InicializaTray;

              //g_oCacic.cipherClose(g_oCacic.getLocalFolder + g_oCacic.getLocalFolder + g_oCacic.getInfFileName,v_tstrCipherOpened);
            End
         else
            Begin
              g_oCacic.writeDebugLog('Agente finalizado devido a concomitância de sessões...');

              Finaliza;
            End;
      Except
        Begin
          g_oCacic.writeDailyLog('PROBLEMAS NA INICIALIZAÇÃO (2)');
          Finaliza;
        End;
      End;
end;

Procedure TFormularioGeral.EqualizaInformacoesPatrimoniais;
Begin
  // Caso as informações patrimoniais coletadas pelo MapaCACIC sejam mais atuais, obtenho-as...
  if FileExists(g_ocacic.getLocalFolder + 'MapaCACIC.inf') and
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_ocacic.getLocalFolder + 'MapaCACIC.inf')) <> '') and
     ((g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) = '') or
     (StrToInt64(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_ocacic.getLocalFolder + 'MapaCACIC.inf'))) > StrToInt64(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))))) then
    Begin
      g_oCacic.setValueToFile('Patrimonio','id_unid_organizacional_nivel1' , g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel1' ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','id_unid_organizacional_nivel1a', g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel1a',g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','id_unid_organizacional_nivel2' , g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel2' ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','id_local'                      , g_oCacic.GetValueFromFile('Patrimonio','id_local'                      ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_localizacao_complementar'   , g_oCacic.GetValueFromFile('Patrimonio','te_localizacao_complementar'   ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio1'           , g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio1'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio2'           , g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio2'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio3'           , g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio3'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio4'           , g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio4'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio5'           , g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio5'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','te_info_patrimonio6'           , g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio6'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','ultima_rede_obtida'            , g_oCacic.GetValueFromFile('Patrimonio','ultima_rede_obtida'            ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','dt_ultima_renovacao'           , g_oCacic.GetValueFromFile('Patrimonio','dt_ultima_renovacao'           ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Patrimonio','Configs'                       , g_oCacic.GetValueFromFile('Patrimonio','Configs'                       ,g_ocacic.getLocalFolder + 'MapaCACIC.inf'), g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

      g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio1', g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio1',g_ocacic.getLocalFolder + 'MapaCACIC.inf')));
      g_oCacic.setValueRegistryKey('HKEY_LOCAL_MACHINE\SOFTWARE\Dataprev\Patrimonio\te_info_patrimonio4', g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio4',g_ocacic.getLocalFolder + 'MapaCACIC.inf')));
    End;
End;

procedure TFormularioGeral.SetaVariaveisGlobais;
var v_aux : string;
Begin
  Try
    // Inicialização do indicador de SENHA JÁ INFORMADA
    g_oCacic.setValueToFile('Configs','SJI',g_oCacic.enCrypt( ''),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

    g_oCacic.setValueToFile('Configs','IN_EXIBE_BANDEJA' , g_oCacic.GetValueFromFile('Configs','IN_EXIBE_BANDEJA' ,g_oCacic.getLocalFolder + 'GER_COLS.inf') ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    g_oCacic.setValueToFile('Configs','NU_EXEC_APOS'     , g_oCacic.GetValueFromFile('Configs','NU_EXEC_APOS'     ,g_oCacic.getLocalFolder + 'GER_COLS.inf') ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    g_oCacic.setValueToFile('Configs','NU_INTERVALO_EXEC', g_oCacic.GetValueFromFile('Configs','NU_INTERVALO_EXEC',g_oCacic.getLocalFolder + 'GER_COLS.inf') ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

    if (Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_EXIBE_BANDEJA' ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) = '') then g_oCacic.setValueToFile('Configs','IN_EXIBE_BANDEJA' , g_oCacic.enCrypt( 'S')    ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    if (Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_EXEC_APOS'     ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) = '') then g_oCacic.setValueToFile('Configs','NU_EXEC_APOS'     , g_oCacic.enCrypt( '12345'),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    if (Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_INTERVALO_EXEC',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) = '') then g_oCacic.setValueToFile('Configs','NU_INTERVALO_EXEC', g_oCacic.enCrypt( '4')    ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
    // IN_EXIBE_BANDEJA     O valor padrão é mostrar o ícone na bandeja.
    // NU_EXEC_APOS         Assumirá o padrão de 0 minutos para execução imediata em caso de primeira execução (instalação).
    // NU_INTERVALO_EXEC    Assumirá o padrão de 4 horas para o intervalo, no caso de problemas.

    // Número de horas do intervalo (3.600.000 milisegundos correspondem a 1 hora).
    Timer_Nu_Intervalo.Enabled  := False;
    Timer_Nu_Intervalo.Interval := strtoint(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_INTERVALO_EXEC',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) * 3600000;
    Timer_Nu_Intervalo.Enabled  := True;

    // Número de minutos para iniciar a execução (60.000 milisegundos correspondem a 1 minuto). Acrescento 1, pois se for zero ele não executa.
    Timer_Nu_Exec_Apos.Enabled  := False;
    Timer_Nu_Exec_Apos.Interval := strtoint(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_EXEC_APOS',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))) * 60000;

    // Se for a primeiríssima execução do agente naquela máquina (após sua instalação) já faz todas as coletas configuradas, sem esperar os minutos definidos pelo administrador.
    // Também armazena os Hash-Codes dos módulos principais, evitando novo download...
    If (g_oCacic.GetValueFromFile('Configs','NU_EXEC_APOS',g_oCacic.getLocalFolder + g_oCacic.getInfFileName) = '12345') then // Flag usada na inicialização. Só entra nesse if se for a primeira execução do cacic após carregado.
      begin
        Timer_Nu_Exec_Apos.Interval := 60000; // 60 segundos para chamar Ger_Cols /coletas
        g_oCacic.setValueToFile('Configs','TE_HASH_' + UpperCase(StringReplace(LowerCase(ExtractFileName( ParamStr(0))),'.exe','',[rfReplaceAll])) ,g_oCacic.enCrypt(  g_oCacic.getFileHash(ParamStr(0))),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Configs','TE_HASH_GER_COLS'     , g_oCacic.enCrypt( g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'modulos\ger_cols.exe')),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
        g_oCacic.setValueToFile('Configs','TE_HASH_CHKSIS'       , g_oCacic.enCrypt( g_oCacic.getFileHash(g_oCacic.getWinDir    + 'chksis.exe'))            ,g_oCacic.getLocalFolder + g_oCacic.getInfFileName);
      end
    else
      g_oCacic.writeDailyLog('Executar as ações automaticamente a cada ' +g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_INTERVALO_EXEC',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) + ' horas.');

    Timer_Nu_Exec_Apos.Enabled  := True;

    v_aux := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','DT_HR_ULTIMA_COLETA',g_oCacic.getLocalFolder + 'GER_COLS.inf')));
    if (v_aux <> '') and (Copy(v_aux, 1, 8) <> FormatDateTime('YYYYmmdd', Now)) then Timer_Nu_Exec_Apos.Enabled  := True;

    // Desabilita/Habilita a opção de Informações Gerais
    HabilitaTCP;

    // Desabilita/Habilita a opção de Suporte Remoto
    HabilitaSuporteRemoto;
  Except
    g_oCacic.writeDailyLog('PROBLEMAS NA INICIALIZAÇÃO (1)');
  End;
end;

procedure TFormularioGeral.Finaliza;
Begin
  Try
    Shell_NotifyIcon(NIM_Delete,@NotifyStruc);
    Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);
    RemoveIconesMortos;
  Except
    g_oCacic.writeDailyLog('PROBLEMAS NA FINALIZAÇÃO');
  End;
  g_oCacic.Free;
  FreeAndNil(FUsb);
  FreeMemory(0);
  Application.Terminate;
End;

procedure TFormularioGeral.Sair(Sender: TObject);
begin
  CriaFormSenha(nil);
  formSenha.ShowModal;
  If (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','SJI',g_oCacic.getLocalFolder + g_oCacic.getInfFileName)) =  'S') Then Finaliza;
end;

procedure TFormularioGeral.Invoca_GerCols(p_acao:string; boolShowInfo : Boolean = true; boolCheckExecution : Boolean = false);
begin
  if not boolCheckExecution or
     (boolCheckExecution and
      not InActivity) then
     Begin
        // Caso exista o Gerente de Coletas será verificada a versão e excluída caso antiga(Uma forma de ação pró-ativa)
        if ChecaGERCOLS then
          Begin
            Timer_InicializaTray.Enabled := False;
            ChecaCONFIGS;
//            g_oCacic.cipherClose(g_oCacic.getLocalFolder + g_oCacic.getLocalFolder + g_oCacic.getInfFileName,v_tstrCipherOpened);
            if boolShowInfo then
              g_oCacic.writeDailyLog('Invocando Gerente de Coletas com ação: "'+p_acao+'"')
            else
              g_oCacic.writeDebugLog('Invocando Gerente de Coletas com ação: "'+p_acao+'"');
            Timer_Nu_Exec_Apos.Enabled  := False;
            g_oCacic.writeDebugLog('Criando Processo Ger_Cols => "'+g_oCacic.getLocalFolder + 'modulos\GER_COLS.EXE /'+p_acao+' /LocalFolder='+g_oCacic.getLocalFolder + ' /WebManagerAddress=' + g_oCacic.getWebManagerAddress + '"');
            g_oCacic.createOneProcess(g_oCacic.getLocalFolder + 'modulos\GER_COLS.EXE /'+p_acao+' /LocalFolder='+g_oCacic.getLocalFolder + ' /WebManagerAddress=' + g_oCacic.getWebManagerAddress + ' /MainProgramName=' + g_oCacic.getMainProgramName + ' /MainProgramHash=' + g_oCacic.getMainProgramHash,false,SW_HIDE);
            Timer_InicializaTray.Enabled := True;
          End
        else
          g_oCacic.writeDailyLog('Não foi possível invocar o Gerente de Coletas!');
     End;
end;

function TFormularioGeral.FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..260] of char;
begin
  // Get the first window
  NextHandle := GetWindow(Application.Handle, GW_HWNDFIRST);
  while NextHandle > 0 do
  begin
    // retrieve its text
    GetWindowText(NextHandle, NextTitle, 255);
    if (trim(StrPas(NextTitle))<> '') and (Pos(strlower(pchar(WindowTitle)), strlower(PChar(StrPas(NextTitle)))) <> 0) then
    begin
      Result := NextHandle;
      Exit;
    end
    else
      // Get the next window
      NextHandle := GetWindow(NextHandle, GW_HWNDNEXT);
  end;
  Result := 0;
end;

procedure TFormularioGeral.ExecutaCacic(Sender: TObject);
var intAux,
    intContaExec    : integer;
    v_mensagem,
    v_tipo_mensagem,
    v_TE_FILA_FTP,
    v_Aux1,
    v_Aux2          : string;
    v_MsgDlgType    : TMsgDlgType;
    v_Repete        : boolean;
begin
   g_oCacic.writeDebugLog('ExecutaCacic - BEGIN');
   g_oCacic.setValueToFile('Configs','TE_SO',g_oCacic.enCrypt( g_oCacic.getWindowsStrId),g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

   try
     if FindCmdLineSwitch('execute', True) or
        FindCmdLineSwitch('atualizacao', True) or
        Pode_Coletar Then
        Begin
          g_oCacic.writeDebugLog('ExecutaCacic - Preparando chamada ao Gerente de Coletas...');

          v_Aux1 := Mnu_InfosTCP.Caption;
          v_Aux2 := Mnu_ExecutarAgora.Caption;

          // Se foi gerado o arquivo ger_erro.txt o Log conterá a mensagem alí gravada como valor de chave
          // O Gerente de Coletas deverá ser eliminado para que seja baixado novamente por ChecaGERCOLS
          if (FileExists(g_oCacic.getLocalFolder + 'ger_erro.txt')) then
            Begin
              g_oCacic.writeDailyLog('Gerente de Coletas eliminado devido a falha:');
              g_oCacic.writeDailyLog(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Mensagens','TeMensagem',g_oCacic.getLocalFolder + 'GER_COLS.inf')));
              SetaVariaveisGlobais;
              g_oCacic.killFiles(g_oCacic.getLocalFolder,'ger_erro.txt');
              g_oCacic.killFiles(g_oCacic.getLocalFolder+'modulos\','ger_cols.exe');
            End;

          if (FileExists(g_oCacic.getLocalFolder + 'Temp\reset.txt')) then
            Begin
              g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','reset.txt');
              g_oCacic.writeDailyLog('Reinicializando...');
              SetaVariaveisGlobais;
            End;
          Timer_Nu_Exec_Apos.Enabled  := False;

          intContaExec := 1;
          //If (FileExists(g_oCacic.getLocalFolder + 'temp\cacic3.bat') or
          //    FileExists(g_oCacic.getLocalFolder + 'temp\ger_cols.exe')) Then
          //    intContaExec := 2;

          // Muda HINT
          InicializaTray;

          // Loop para possível necessidade de updates de Agente Principal e/ou Gerente de Coletas
          For intAux := intContaExec to 2 do
            Begin
              if (intAux = 1) then
                Begin
                  g_oCacic.writeDebugLog('ExecutaCacic - Controle de Execuções='+inttostr(intContaExec));
                  g_oCacic.writeDailyLog('Iniciando execução de atividades.');

                  v_Repete := true;
                  while v_Repete do
                    Begin
                      v_Repete := false;
                      Mnu_InfosTCP.Enabled          := False;
                      Mnu_ExecutarAgora.Enabled     := False;
                      Mnu_InfosTCP.Caption          := 'Aguarde, coleta em ação!';
                      Mnu_ExecutarAgora.Caption     := Mnu_InfosTCP.Caption;

                      g_oCacic.writeDebugLog('ExecutaCacic - Primeira chamada ao Gerente de Coletas...');
                      Invoca_GerCols('coletas');
                      sleep(3000); // Pausa para início do Gerente de Coletas e criação do arquivo temp\aguarde_GER.txt

                      InicializaTray;

                      // Pausas de 15 segundos para o caso de ser(em) baixada(s) nova(s) versão(ões) de Ger_Cols e/ou Cacic3.
                      while not Pode_Coletar do
                        Begin
                          g_oCacic.writeDebugLog('ExecutaCacic - Aguardando mais 15 segundos...');
                          sleep(15000);
                          InicializaTray;
                        End;
                      Mnu_InfosTCP.Caption          := v_Aux1;
                      Mnu_ExecutarAgora.Caption     := v_Aux2;
                      Mnu_ExecutarAgora.Enabled     := true;

 //                     FormularioGeral.ConditionalCipherOpen;

                      // Neste caso o Gerente de Coletas deverá fazer novo contato devido à permissão de criptografia ter sido colocada em espera pelo próximo contato.
                      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','CS_CIPHER',g_oCacic.getLocalFolder + 'GER_COLS.inf')) = '2') then
                        Begin
                          v_Repete := true;
                          g_oCacic.writeDebugLog('ExecutaCacic - Criptografia será colocada em nível 2...');
                        End;
                    End;

                  // Verifico se foi gravada alguma mensagem pelo Gerente de Coletas e mostro
                  //if ConditionalCipherOpen then
                  //  Begin
                      v_mensagem      := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Mensagens','TeMensagem',g_oCacic.getLocalFolder + 'GER_COLS.inf'));
                      v_tipo_mensagem := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Mensagens','CsTipo'    ,g_oCacic.getLocalFolder + 'GER_COLS.inf'));
                      if (v_mensagem <> '') then
                        Begin
                          if      (v_tipo_mensagem='mtError')       then v_MsgDlgType := mtError
                          else if (v_tipo_mensagem='mtInformation') then v_MsgDlgType := mtInformation
                          else if (v_tipo_mensagem='mtWarning')     then v_MsgDlgType := mtWarning;
                          MessageDlg(v_mensagem,v_MsgDlgType, [mbOk], 0);
                          g_oCacic.setValueToFile('Mensagens','TeMensagem', g_oCacic.enCrypt( ''), g_oCacic.getLocalFolder + 'GER_COLS.inf');
                          g_oCacic.setValueToFile('Mensagens','CsTipo'    , g_oCacic.enCrypt( ''), g_oCacic.getLocalFolder + 'GER_COLS.inf');
                        End;

                      // Verifico se TE_FILA_FTP foi setado (por Ger_Cols) e obedeço ao intervalo para nova tentativa de coletas
                      // Caso TE_FILA_FTP inicie com # é porque já passou nessa condição e deve iniciar nova tentativa de FTP...
                      v_TE_FILA_FTP := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TE_FILA_FTP',g_oCacic.getLocalFolder + 'GER_COLS.inf'));
                      if (Copy(v_TE_FILA_FTP,1,1) <> '#') and
                         (v_TE_FILA_FTP <> '0') and
                         (v_TE_FILA_FTP <> '') then
                        Begin
                          // Busquei o número de milisegundos setados em TE_FILA_FTP e o obedeço...
                          // 60.000 milisegundos correspondem a 60 segundos (1 minuto).
                          // Acrescento 1, pois se for zero ele não executa.
                          Timer_Nu_Exec_Apos.Enabled  := False;
                          Timer_Nu_Exec_Apos.Interval :=  strtoint(v_TE_FILA_FTP) * 60000;
                          Timer_Nu_Exec_Apos.Enabled  := True;
                          g_oCacic.writeDailyLog('FTP de coletores adiado pelo Módulo Gerente.');
                          g_oCacic.writeDailyLog('Nova tentativa em aproximadamente ' + v_TE_FILA_FTP+ ' minuto(s).');
                          g_oCacic.setValueToFile('Configs','TE_FILA_FTP',g_oCacic.enCrypt( '#' + v_TE_FILA_FTP),g_oCacic.getLocalFolder + 'GER_COLS.inf');
                        End;
                  //  End;

                  // Desabilita/Habilita a opção de Informações de TCP/IP
                  HabilitaTCP;

                  // Desabilita/Habilita a opção de Suporte Remoto
                  HabilitaSuporteRemoto;

                  // Para evitar uma reexecução de Ger_Cols sem necessidade...
                  intContaExec := 3;
                End;

              // Caso tenha sido baixada nova cópia do Gerente de Coletas, esta deverá ser movida para cima da atual
              if (FileExists(g_oCacic.getLocalFolder + 'Temp\ger_cols.exe')) then
                Begin
                  g_oCacic.writeDailyLog('Atualizando versão do Gerente de Coletas para '+g_oCacic.getVersionInfo(g_oCacic.getLocalFolder + 'Temp\ger_cols.exe'));
                  // O MoveFileEx não se deu bem no Win98!  :|
                  // MoveFileEx(PChar(g_oCacic.getLocalFolder + 'temp\ger_cols.exe'),PChar(g_oCacic.getLocalFolder + 'modulos\ger_cols.exe'),MOVEFILE_REPLACE_EXISTING);

                  CopyFile(PChar(g_oCacic.getLocalFolder + 'Temp\ger_cols.exe'),PChar(g_oCacic.getLocalFolder + 'modulos\ger_cols.exe'),false);
                  sleep(2000); // 2 segundos de espera pela cópia!  :) (Rwindows!)

                  g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','ger_cols.exe');
                  sleep(2000); // 2 segundos de espera pela deleção!

                  intContaExec := 2; // Forçará uma reexecução de Ger_Cols...
                End;

              // A existência de "temp\cacic3.bat" significa AutoUpdate já executado!
              // Essa verificação foi usada no modelo antigo de AutoUpdate e deve ser mantida
              // até a total convergência de versões para 2.0.1.16+...
              if (FileExists(g_oCacic.getLocalFolder + 'Temp\cacic3.bat')) then
                  g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','cacic3.bat');

              // O loop 1 foi dedicado a atualizações de versões e afins...
              // O loop 2 deverá invocar as coletas propriamente ditas...
              if (intContaExec = 2) then
                Begin
                  g_oCacic.writeDebugLog('ExecutaCacic - Segunda chamada ao Gerente de Coletas...');
                  Invoca_GerCols('coletas');
                  intContaExec := 3;
                End;
            End;
            
          Mnu_InfosTCP.Caption      := v_Aux1;
          Mnu_ExecutarAgora.Caption := v_Aux2;
          Mnu_InfosTCP.Enabled      := true;
          Mnu_ExecutarAgora.Enabled := true;
        End;

        InicializaTray;

    except
      g_oCacic.writeDailyLog('PROBLEMAS AO TENTAR ATIVAR COLETAS.');
    end;

   g_oCacic.writeDebugLog('ExecutaCacic - END');
end;

procedure TFormularioGeral.ExibirLogAtividades(Sender: TObject);
begin
     Application.CreateForm(tformLog,formLog);
     formLog.ShowModal;
end;

procedure TFormularioGeral.ExibirConfiguracoes(Sender: TObject);
begin
  // SJI = Senha Já Informada...
  // Esse valor é inicializado com "N"
  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','SJI',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))='') and
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))<>'') then
    begin
      FormularioGeral.CriaFormSenha(nil);
      formSenha.ShowModal;
    end;

  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','SJI',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))<>'') or
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress',g_oCacic.getLocalFolder + g_oCacic.getInfFileName))='') then
    begin
      Application.CreateForm(TFormConfiguracoes, FormConfiguracoes);
      FormConfiguracoes.ShowModal;
    end;

end;

//=======================================================================
// Todo o código deste ponto em diante está relacionado às rotinas de
// de inclusão do ícone do programa na bandeja do sistema
//=======================================================================
procedure TFormularioGeral.InicializaTray;
var Icon              : TIcon;
    v_strHint,
    v_strAux          : String;
begin
    g_oCacic.writeDebugLog('InicializaTray - BEGIN');

    Icon := TIcon.Create;

    // Monto a frase a ser colocada no Hint
    v_strHint := 'CACIC  v:' + g_oCacic.getVersionInfo(ParamStr(0));
    v_strAux  := Trim( g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_IP', g_oCacic.getLocalFolder + 'GER_COLS.inf')) );
    if not (v_strAux = '') then
      v_strHint := v_strHint + chr(13) + chr(10) + 'IP: ' + v_strAux;

    // Mostro a versão no painel de Informações Gerais
    pnVersao.Caption := 'V. ' + g_oCacic.getVersionInfo(ParamStr(0));

    // Estrutura do tray icon sendo criada.
    with NotifyStruc do
      Begin
        cbSize           := SizeOf(NotifyStruc);
        Wnd              := self.Handle;
        uID              := 1;
        uFlags           := NIF_ICON or NIF_TIP or NIF_MESSAGE;
        uCallbackMessage := WM_MYMESSAGE; //User defined message
      End;

    g_intStatus := NORMAL;

    g_oCacic.killFiles(g_oCacic.getLocalFolder + 'Temp','aguarde_GER.txt');
    g_oCacic.killFiles(g_oCacic.getLocalFolder + 'Temp','aguarde_srCACIC.txt');

    if not InActivity then
      Begin
        g_oCacic.writeDebugLog('InicializaTray - NOT InActivity');
        if not (UpperCase( g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','ConexaoOK',g_oCacic.getLocalFolder + 'GER_COLS.inf')) ) = 'S') then
          Begin
            v_strHint := v_strHint + '  IDENTIFICAÇÃO LOCAL...';
            g_intStatus := DESCONFIGURADO;
          End;
      End
    else
      Begin
        g_oCacic.writeDebugLog('InicializaTray - InActivity');
        if FileExists(g_oCacic.getLocalFolder+'Temp\recuperasr.txt') then
          Begin
            g_intStatus := AGUARDE;
            v_strHint := 'Aguarde...';
          End
        else
          Begin
            g_oCacic.writeDebugLog('InicializaTray - v_strHint Antes = "'+v_strHint+'"');
            if FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_GER.txt') then
              v_strHint := v_strHint + chr(13) + chr(10) + ' Coletas em Execução...'
            else if FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_srCACIC.txt') then
              v_strHint := v_strHint + chr(13) + chr(10) + ' Em Suporte Remoto...';

            g_oCacic.writeDebugLog('InicializaTray - v_strHint Depois = "'+v_strHint+'"');
            g_intStatus := OCUPADO;
          End;
      End;

   imgList_Icones.GetIcon(g_intStatus,Icon);

//   NotifyStruc.hIcon := Icon.Handle;

    if Self.Icon.Handle > 0 then
      NotifyStruc.hIcon := Icon.Handle
    else
      NotifyStruc.hIcon := Application.Icon.Handle;

   g_oCacic.writeDebugLog('InicializaTray - Setando o HINT do Systray para: "'+v_strHint+'"');

   // Atualiza o conteúdo do tip da bandeja
   StrPCopy(NotifyStruc.szTip, v_strHint);

   if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_EXIBE_BANDEJA', g_oCacic.getLocalFolder + 'GER_COLS.inf')) <> 'N') Then
    Begin
      g_oCacic.writeDebugLog('InicializaTray - Adicionando Ícone ao Systray...');
      Shell_NotifyIcon(NIM_ADD, @NotifyStruc);
    End
   else
    Begin
      g_oCacic.writeDebugLog('InicializaTray - Retirando Ícone do Systray...');
      Shell_NotifyIcon(HIDE_WINDOW,@NotifyStruc);
      Shell_NotifyIcon(NIM_Delete,@NotifyStruc);
    End;

   g_oCacic.writeDebugLog('InicializaTray - Aplicando Modificação de Ícone do Systray...');
   Shell_NotifyIcon(NIM_MODIFY,@NotifyStruc);

   Application.ProcessMessages;

   Icon.Free;
   g_oCacic.writeDebugLog('InicializaTray - END');
end;

procedure TFormularioGeral.WMSysCommand;
begin  // Captura o minimizar da janela
  if (Msg.CmdType = SC_MINIMIZE) or (Msg.CmdType = SC_MAXIMIZE) then
  Begin
       MinimizaParaTrayArea(Nil);
       Exit;
  end;
  DefaultHandler(Msg);
end;

procedure TFormularioGeral.TrayMessage(var Msg: TMessage);
var Posicao : TPoint;
begin

  if (Msg.LParam=WM_RBUTTONDOWN) then
    Begin

       // Habilita a opção de menu caso o suporte remoto esteja habilitado.
       HabilitaSuporteRemoto;

       SetForegroundWindow(Handle);
       GetCursorPos(Posicao);
       Popup_Menu_Contexto.Popup(Posicao.X, Posicao.Y);
    end;

end;

procedure TFormularioGeral.MinimizaParaTrayArea(Sender: TObject);
begin
    FormularioGeral.Visible:=false;
    if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_EXIBE_BANDEJA', g_oCacic.getLocalFolder + 'GER_COLS.inf')) <> 'N') Then
      Begin
        Shell_NotifyIcon(NIM_ADD,@NotifyStruc);
      End
    else
      Begin
        Shell_NotifyIcon(HIDE_WINDOW,@NotifyStruc);
        Shell_NotifyIcon(nim_Modify,@NotifyStruc);
      End;
end;
// -------------------------------------
// Fim dos códigos da bandeja do sistema
// -------------------------------------

procedure TFormularioGeral.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   // Esse evento é colocado em Nil durante o shutdown do windows.
   // Ver o evento WMQueryEndSession.
   CanClose := False;
   MinimizaParaTrayArea(Nil);
end;

procedure TFormularioGeral.WMQueryEndSession(var Msg: TWMQueryEndSession);
begin
   // Quando há um shutdown do windows em execução, libera o close.
   OnCloseQuery := Nil;
   FreeAndNil(FUsb);
   Application.Terminate;
   inherited // Continue ShutDown request
end;

procedure TFormularioGeral.Mnu_InfosTCPClick(Sender: TObject);
var v_tripa_perfis, v_tripa_infos_coletadas,strAux : string;
    v_array_perfis, v_array_tripa_infos_coletadas, v_array_infos_coletadas : tstrings;
    v_conta_perfis, v_conta_infos_coletadas, intAux : integer;
    v_achei : boolean;
begin
    g_oCacic.writeDebugLog('Mnu_InfosTCPClick - BEGIN');
    FormularioGeral.Enabled       := true;
    FormularioGeral.Visible       := true;

    ST_VL_NomeHost.Caption        := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_NOME_HOST'       , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_IPEstacao.Caption       := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_IP'              , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_MacAddress.Caption      := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_NODE_ADDRESS'    , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_IPRede.Caption          := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','ID_IP_REDE'         , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_DominioDNS.Caption      := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_DOMINIO_DNS'     , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_DNSPrimario.Caption     := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_DNS_PRIMARIO'    , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_DNSSecundario.Caption   := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_DNS_SECUNDARIO'  , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_Gateway.Caption         := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_GATEWAY'         , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_Mascara.Caption         := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_MASCARA'         , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_ServidorDHCP.Caption    := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_SERV_DHCP'       , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_WinsPrimario.Caption    := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_WINS_PRIMARIO'   , g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    ST_VL_WinsSecundario.Caption  := g_oCacic.deCrypt(g_oCacic.GetValueFromFile('TcpIp','TE_WINS_SECUNDARIO' , g_oCacic.getLocalFolder + 'GER_COLS.inf'));

    // Exibição das informações de Sistemas Monitorados...
    v_conta_perfis := 1;
    v_conta_infos_coletadas := 0;
    v_tripa_perfis := '*';

    while v_tripa_perfis <> '' do
      begin

        v_tripa_perfis := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','SIS' + trim(inttostr(v_conta_perfis)), g_oCacic.getLocalFolder + 'GER_COLS.inf'));
        g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Perfil => Coletas.SIS' + trim(inttostr(v_conta_perfis))+' => '+v_tripa_perfis);
        v_conta_perfis := v_conta_perfis + 1;

        if (trim(v_tripa_perfis) <> '') then
          Begin
            v_array_perfis := g_oCacic.explode(v_tripa_perfis,',');

            // ATENÇÃO!!! Antes da implementação de INFORMAÇÕES GERAIS o Count ia até 11, ok?!
            if (v_array_perfis.Count > 11) and (v_array_perfis[11]='S') then
              Begin
                v_tripa_infos_coletadas := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','Sistemas_Monitorados', g_oCacic.getLocalFolder + 'GER_COLS.inf'));
                g_oCacic.writeDebugLog('Coletas de S.M. Efetuadas => ' + v_tripa_infos_coletadas);
                if (trim(v_tripa_infos_coletadas) <> '') then
                  Begin
                    v_array_tripa_infos_coletadas := g_oCacic.explode(v_tripa_infos_coletadas,'#');
                    for intAux := 0 to v_array_tripa_infos_coletadas.Count-1 Do
                      Begin
                        v_array_infos_coletadas := g_oCacic.explode(v_array_tripa_infos_coletadas[intAux],',');

                        g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Verificando perfil[0]:' + v_array_perfis[0]);
                        if (v_array_infos_coletadas[0]=v_array_perfis[0]) then
                          Begin
                            g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Verificando valores condicionais [1]:"'+trim(v_array_infos_coletadas[1])+'" e [3]:"'+trim(v_array_infos_coletadas[3])+'"');
                            if  ((trim(v_array_infos_coletadas[1])<>'') and (trim(v_array_infos_coletadas[1])<>'?')) or
                                ((trim(v_array_infos_coletadas[3])<>'') and (trim(v_array_infos_coletadas[3])<>'?')) then
                              Begin
                                v_achei := false;
                                listSistemasMonitorados.Items.Add;
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].Caption := Format('%2d', [v_conta_infos_coletadas+1])+') '+v_array_perfis[12];
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].SubItems.Add(v_array_infos_coletadas[1]);
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].SubItems.Add(v_array_infos_coletadas[3]);
                                v_conta_infos_coletadas := v_conta_infos_coletadas + 1;

                              End;
                          End;
                        Application.ProcessMessages;
                      End;
                  End;
              End;
          End;
      end;

    teDataColeta.Caption := '('+FormatDateTime('dd/mm/yyyy', now)+')';
    staticVlServidorAplicacao.Caption := '"'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress', g_oCacic.getLocalFolder + 'GER_COLS.inf'))+'"';
    staticVlServidorUpdates.Caption   := '"'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','Te_Serv_Updates', g_oCacic.getLocalFolder + 'GER_COLS.inf'))+'"';

    strAux := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','HOJE', g_oCacic.getLocalFolder + 'GER_COLS.inf'));
    if (strAux <> '') then
      Begin
        if (copy(strAux,0,8) = FormatDateTime('yyyymmdd', Date)) then
          Begin
            // Vamos reaproveitar algumas variáveis!...

            v_array_perfis := g_oCacic.explode(strAux,'#');
            for intAux := 1 to v_array_perfis.Count-1 Do
              Begin
                v_array_infos_coletadas := g_oCacic.explode(v_array_perfis[intAux],',');
                listaColetas.Items.Add;
                listaColetas.Items[intAux-1].Caption := v_array_infos_coletadas[0];
                listaColetas.Items[intAux-1].SubItems.Add(v_array_infos_coletadas[1]);

                // Verifico se houve problema na coleta...
                if (v_array_infos_coletadas[2]<>'99999999') then
                  listaColetas.Items[intAux-1].SubItems.Add(v_array_infos_coletadas[2])
                else
                  Begin
                    listaColetas.Items[intAux-1].SubItems.Add('--------');
                    v_array_infos_coletadas[3] := v_array_infos_coletadas[2];
                  End;

                // Códigos Possíveis: -1 : Problema no Envio da Coleta
                //                     1 : Coleta Enviada
                //                     0 : Sem Coleta para Envio
                strAux := IfThen(v_array_infos_coletadas[3]='1','Coleta Enviada ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='-1','Problema Enviando Coleta ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='0','Sem Coleta para Envio ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='99999999','Problema no Processo de Coleta!','Status Desconhecido!'))));
                listaColetas.Items[intAux-1].SubItems.Add(strAux);

                Application.ProcessMessages;
              End;
          End
      End
    else
      Begin
        listSistemasMonitorados.Items.Add;
        listSistemasMonitorados.Items[0].Caption := 'Não Há Coletas Registradas Nesta Data';
      End;

   FormularioGeral.EqualizaInformacoesPatrimoniais;

   strConfigsPatrimonio      := g_oCacic.GetValueFromFile('Patrimonio','Configs', g_oCacic.getLocalFolder + g_oCacic.getInfFileName);

   MontaVetoresPatrimonio(strConfigsPatrimonio);

   if (strConfigsPatrimonio = '') then
    lbSemInformacoesPatrimoniais.Visible := true
   else
    lbSemInformacoesPatrimoniais.Visible := false;

   st_lb_Etiqueta1.Caption  := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta1', strConfigsPatrimonio));
   st_lb_Etiqueta1.Caption  := st_lb_Etiqueta1.Caption + IfThen(st_lb_Etiqueta1.Caption='','',':');
   st_vl_Etiqueta1.Caption  := RetornaValorVetorUON1(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel1', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)));

   st_lb_Etiqueta1a.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta1a', strConfigsPatrimonio));
   st_lb_Etiqueta1a.Caption := st_lb_Etiqueta1a.Caption + IfThen(st_lb_Etiqueta1a.Caption='','',':');
   st_vl_Etiqueta1a.Caption := RetornaValorVetorUON1a(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel1a', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)));

   st_lb_Etiqueta2.Caption  := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta2', strConfigsPatrimonio));
   st_lb_Etiqueta2.Caption  := st_lb_Etiqueta2.Caption + IfThen(st_lb_Etiqueta2.Caption='','',':');
   st_vl_Etiqueta2.Caption  := RetornaValorVetorUON2(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_unid_organizacional_nivel2', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','id_local', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)));

   st_lb_Etiqueta3.Caption  := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta3', strConfigsPatrimonio));
   st_lb_Etiqueta3.Caption  := st_lb_Etiqueta3.Caption + IfThen(st_lb_Etiqueta3.Caption='','',':');
   st_vl_Etiqueta3.Caption  := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_localizacao_complementar', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));


   g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Decriptografia de in_exibir_etiqueta4 => "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta4', strConfigsPatrimonio))+'"');
   if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta4', strConfigsPatrimonio)) = 'S') then
    begin
      st_lb_Etiqueta4.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta4', strConfigsPatrimonio));
      st_lb_Etiqueta4.Caption := st_lb_Etiqueta4.Caption + IfThen(st_lb_Etiqueta4.Caption='','',':');
      st_lb_Etiqueta4.Visible := true;
      st_vl_etiqueta4.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio1', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta4.Visible := false;
      st_vl_etiqueta4.Visible := false;
    End;

   g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Decriptografia de in_exibir_etiqueta5 => "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta5', strConfigsPatrimonio))+'"');
   if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta5', strConfigsPatrimonio)) = 'S') then
    begin
      st_lb_Etiqueta5.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta5', strConfigsPatrimonio));
      st_lb_Etiqueta5.Caption := st_lb_Etiqueta5.Caption + IfThen(st_lb_Etiqueta5.Caption='','',':');
      st_lb_Etiqueta5.Visible := true;
      st_vl_etiqueta5.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio2', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta5.Visible := false;
      st_vl_etiqueta5.Visible := false;
    End;

   g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Decriptografia de in_exibir_etiqueta6 => "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta6', strConfigsPatrimonio))+'"');
   if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta6', strConfigsPatrimonio)) = 'S') then
    begin
      st_lb_Etiqueta6.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta6', strConfigsPatrimonio));
      st_lb_Etiqueta6.Caption := st_lb_Etiqueta6.Caption + IfThen(st_lb_Etiqueta6.Caption='','',':');
      st_lb_Etiqueta6.Visible := true;
      st_vl_etiqueta6.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio3', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta6.Visible := false;
      st_vl_etiqueta6.Visible := false;
    End;

   g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Decriptografia de in_exibir_etiqueta7 => "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta7', strConfigsPatrimonio))+'"');
   if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta7', strConfigsPatrimonio)) = 'S') then
    begin
      st_lb_Etiqueta7.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta7', strConfigsPatrimonio));
      st_lb_Etiqueta7.Caption := st_lb_Etiqueta7.Caption + IfThen(st_lb_Etiqueta7.Caption='','',':');
      st_lb_Etiqueta7.Visible := true;
      st_vl_etiqueta7.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio4', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta7.Visible := false;
      st_vl_etiqueta7.Visible := false;
    End;

   g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Decriptografia de in_exibir_etiqueta8 => "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta8', strConfigsPatrimonio))+'"');
   if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta8', strConfigsPatrimonio)) = 'S') then
    begin
      st_lb_Etiqueta8.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta8', strConfigsPatrimonio));
      st_lb_Etiqueta8.Caption := st_lb_Etiqueta8.Caption + IfThen(st_lb_Etiqueta8.Caption='','',':');
      st_lb_Etiqueta8.Visible := true;
      st_vl_etiqueta8.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio5', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta8.Visible := false;
      st_vl_etiqueta8.Visible := false;
    End;

   g_oCacic.writeDebugLog('Mnu_InfosTCPClick - Decriptografia de in_exibir_etiqueta9 => "'+g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta9', strConfigsPatrimonio))+'"');
   if (g_oCacic.deCrypt(g_oCacic.xmlGetValue('in_exibir_etiqueta9', strConfigsPatrimonio)) = 'S') then
    begin
      st_lb_Etiqueta9.Caption := g_oCacic.deCrypt(g_oCacic.xmlGetValue('te_etiqueta9', strConfigsPatrimonio));
      st_lb_Etiqueta9.Caption := st_lb_Etiqueta9.Caption + IfThen(st_lb_Etiqueta9.Caption='','',':');
      st_lb_Etiqueta9.Visible := true;
      st_vl_etiqueta9.Caption := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Patrimonio','te_info_patrimonio6', g_oCacic.getLocalFolder + g_oCacic.getInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta9.Visible := false;
      st_vl_etiqueta9.Visible := false;
    End;

    g_oCacic.writeDebugLog('Mnu_InfosTCPClick - END');
  end;

procedure TFormularioGeral.Bt_Fechar_InfosGeraisClick(Sender: TObject);
  begin
    FormularioGeral.Enabled := false;
    FormularioGeral.Visible := false;
  end;


// Solução baixada de http://www.delphidabbler.com/codesnip.php?action=named&routines=URLDecode&showsrc=1
function TFormularioGeral.URLDecode(const S: string): string;
var
  Idx: Integer;   // loops thru chars in string
  Hex: string;    // string of hex characters
  Code: Integer;  // hex character code (-1 on error)
begin
  // Intialise result and string index
  Result := '';
  Idx := 1;
  // Loop thru string decoding each character
  while Idx <= Length(S) do
  begin
    case S[Idx] of
      '%':
      begin
        // % should be followed by two hex digits - exception otherwise
        if Idx <= Length(S) - 2 then
        begin
          // there are sufficient digits - try to decode hex digits
          Hex := S[Idx+1] + S[Idx+2];
          Code := SysUtils.StrToIntDef('$' + Hex, -1);
          Inc(Idx, 2);
        end
        else
          // insufficient digits - error
          Code := -1;
        // check for error and raise exception if found
        if Code = -1 then
          raise SysUtils.EConvertError.Create(
            'Invalid hex digit in URL'
          );
        // decoded OK - add character to result
        Result := Result + Chr(Code);
      end;
      '+':
        // + is decoded as a space
        Result := Result + ' '
      else
        // All other characters pass thru unchanged
        Result := Result + S[Idx];
    end;
    Inc(Idx);
  end;
end;
{
procedure TFormularioGeral.IdHTTPServerCACICCommandGet(
  AThread: TIdPeerThread; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var strXML,
    strCmd,
    strFileName,
    strFileHash : String;
    intAux : integer;
    boolOK : boolean;
begin

  // **********************************************************************************************************
  // Esta procedure tratará os comandos e suas ações, enviados em um pacote XML na requisição, conforme abaixo:
  // **********************************************************************************************************
  // Execute  -> Comando que forçará a execução do Gerente de Coletas (Sugestão: Configurar coletas forçadas no Gerente WEB e executar esse comando)
  //             Requisição: Tag <Execute>
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK'
  //
  // Ask      -> Comando que perguntará sobre a existência de um determinado arquivo na estação.
  //             Requisição: Tag <FileName>: Nome do arquivo a pesquisar no repositório local
  //                         Tag <FileHash>: Hash referente ao arquivo a ser pesquisado no repositório local
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK';
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'Tenho' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'NaoTenho' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'Baixando' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'Ocupado'.
  //
  //
  // Erase    -> Comando que provocará a exclusão de determinado arquivo.
  //             Deverá ser acompanhado das tags <FileName> e <FileHash>
  //             Requisição: Tag <FileName>: Nome do arquivo a ser excluído do repositório local
  //                         Tag <FileHash>: Hash referente ao arquivo a ser excluído do repositório local
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK';
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'AcaoExecutada' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'ArquivoNaoEncontrado' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'EscritaNaoPermitida';
  //
  // Registry -> Comando que provocará ação no Registry de estações com MS-Windows.
  //             Deverá ser acompanhado das tags <Path>, <Action>, <Condition> e <Value>
  //             Requisição: Tag <Path>      : Caminho no Registry
  //                         Tag <Action>    : Ação para execução
  //                                           SAVE   => Salva o valor contido na tag <Value> de acordo com condição contida na tag <Condition>
  //                                           ERASE  => Apaga a chave de acordo com condição contida na tag <Condition>
  //                         Tag <Condition> : Condiçção para execução da ação
  //                                           EQUAL  => Se o valor contido na tag <Value> for IGUAL     ao valor encontrado na chave
  //                                           DIFFER => Se o valor contido na tag <Value> for DIFERENTE ao valor encontrado na chave
  //                                           NONE   => Nenhuma condição, permitindo a execução da ação de forma incondicional
  //                         Tag <Value>     : Valor a ser utilizado na ação
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK';
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'AcaoExecutada' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'ChaveNaoEncontrada' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'EscritaNaoPermitida';
  //
  // Exit     -> Comando para finalização do agente principal (bandeja)

  // Palavra Chave definida por Ger_Cols, enviada e armazenada no BD. A autenticação da comunicação é baseada na verificação deste valor.
  // A geração da palavra chave dar-se-á a cada contato do Ger_Cols com o módulo Gerente WEB
  // te_palavra_chave -> <TE_PALAVRA_CHAVE>

  // Tratamento da requisição http...
  strXML := URLDecode(ARequestInfo.UnparsedParams);
  intAux := Pos('=',strXML);
  strXML := copy(strXML,(intAux+1),StrLen(PAnsiChar(strXML))-intAux);
  strXML := g_oCacic.deCrypt(strXML);



  // Autenticação e tratamento da requisição
  if (g_oCacic.xmlGetValue('te_palavra_chave',strXML) = g_oCacic.getValueMemoryData('Configs.te_palavra_chave',v_tstrCipherOpened)) then
    Begin
      strCmd := g_oCacic.xmlGetValue('cmd',strXML);
      // As ações terão seus valores

      if (strCmd = 'Execute')   or
         (strCmd = 'Ask')       or
         (strCmd = 'Erase')     or
         (strCmd = 'Registry')  or
         (strCmd = 'Exit')      then
          AResponseinfo.ContentText := 'OK'
      else
        AResponseinfo.ContentText := 'COMANDO NÃO RECONHECIDO!';
    End
  else
    AResponseinfo.ContentText := 'ACESSO NÃO PERMITIDO!';

  if      (strCmd = 'Execute')  then
      ExecutaCacic(nil)
  else if (strCmd = 'Ask')      then
    Begin
      strFileName := g_oCacic.xmlGetValue('FileName',strXML);
      strFileHash := g_oCacic.xmlGetValue('FileHash',strXML);
    End
  else if (strCmd = 'Erase')    then
  else if (strCmd = 'Registry') then
  else if (strCmd = 'Exit')     then
    Finaliza;
end;

procedure TFormularioGeral.IdFTPServer1UserLogin(ASender: TIdFTPServerThread; const AUsername, APassword: String; var AAuthenticated: Boolean);
begin
  AAuthenticated := false;
  if (AUsername = 'CACIC') and
     (APassword=g_oCacic.getValueMemoryData('Configs.PalavraChave',v_tstrCipherOpened)) then
    AAuthenticated := true;
end;
}
procedure TFormularioGeral.Mnu_SuporteRemotoClick(Sender: TObject);
var v_strTeWebManagerServer,
    v_strTeWebManagerFolder,
    v_strTeSO,
    v_strTeNodeAddress,
    v_strNuPortaSR,
    v_strNuTimeOutSR,
    v_strKeyWord : String;
    intPausaRecupera,
    intLoop           : integer;
    fileAguarde       : TextFile;
    tstrAux           : TStrings;
begin
  g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - BEGIN');
  if boolServerON then // Ordeno ao SrCACICsrv que auto-finalize
    Begin
      g_oCacic.writeDailyLog('Desativando o Módulo de Suporte Remoto Seguro.');

      g_oCacic.createOneProcess(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe -kill',false,SW_HIDE);

      Try
        // Bloqueio o módulo de suporte remoto seguro na FireWall nativa.
        g_oCacic.addApplicationToFirewall('srCACIC - Suporte Remoto Seguro do Sistema CACIC',g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe', false);
      Except
      End;

      Sleep(3000); // Pausa para liberação do aguarde_srCACIC.txt
      InicializaTray;

      boolServerON := false;
    End
  else
    Begin
      g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Invocando "'+g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe"...');
      g_oCacic.writeDailyLog('Ativando Suporte Remoto Seguro.');

      v_strKeyWord := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','te_palavra_chave', g_oCacic.getLocalFolder + 'GER_COLS.inf'));
      g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Palavra-chave: "'+v_strKeyWord+'"');

      v_strKeyWord := StringReplace(g_oCacic.enCrypt(v_strKeyWord)      ,'+' ,'<MAIS>'    ,[rfReplaceAll]);
      v_strKeyWord := StringReplace(v_strKeyWord                        ,' ' ,'<ESPACE>'  ,[rfReplaceAll]);
      v_strKeyWord := StringReplace(v_strKeyWord                        ,'"' ,'<AD>'      ,[rfReplaceAll]);
      v_strKeyWord := StringReplace(v_strKeyWord                        ,'''','<AS>'      ,[rfReplaceAll]);
      v_strKeyWord := StringReplace(v_strKeyWord                        ,'\' ,'<BarrInv>' ,[rfReplaceAll]);

      g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Criando "'+g_oCacic.getLocalFolder + 'cacic_keyword.txt" para srCACICsrv com nova palavra-chave.');
      g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Texto gravado no cookie para o Suporte Remoto Seguro: "'+v_strKeyWord+'"');

      AssignFile(fileAguarde,g_oCacic.getLocalFolder + 'cacic_keyword.txt');
      Rewrite(fileAguarde);
      Append(fileAguarde);
      Writeln(fileAguarde,v_strKeyWord);
      CloseFile(fileAguarde);

      v_strTeSO          := trim(StringReplace(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TE_SO', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),' ','<ESPACE>',[rfReplaceAll]));
      v_strTeSO          := g_oCacic.enCrypt(v_strTeSO);
      v_strTeSO          := StringReplace(v_strTeSO,'+','<MAIS>',[rfReplaceAll]);

      v_strTeNodeAddress := trim(StringReplace(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_NODE_ADDRESS'   , g_oCacic.getLocalFolder + 'GER_COLS.inf')),' ','<ESPACE>'  ,[rfReplaceAll]));
      v_strTeNodeAddress := g_oCacic.enCrypt(v_strTeNodeAddress);
      v_strTeNodeAddress := StringReplace(v_strTeNodeAddress,'+','<MAIS>',[rfReplaceAll]);

      v_strNuPortaSR     := trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_PORTA_SRCACIC'              , g_oCacic.getLocalFolder + 'GER_COLS.inf')));
      v_strNuTimeOutSR   := trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','NU_TIMEOUT_SRCACIC'            , g_oCacic.getLocalFolder + 'GER_COLS.inf')));

      // Detectar versão do Windows antes de fazer a chamada seguinte...
      try
        AssignFile(fileAguarde,g_oCacic.getLocalFolder + 'Temp\aguarde_srCACIC.txt');
        {$IOChecks off}
        Reset(fileAguarde); {Abre o arquivo texto}
        {$IOChecks on}
        if (IOResult <> 0) then // Arquivo não existe, será recriado.
          begin
            Rewrite (fileAguarde);
            Append(fileAguarde);
            Writeln(fileAguarde,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Pseudo-Cookie para o srCACICsrv.exe <=======================');
          end;

        CloseFile(fileAguarde);
      Finally
      End;

      g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Verificando validade do módulo srCACICsrv para chamada!');

      g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - g_oCacic.getFileHash('+g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe'+') = "'+g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe'+'"'));

      // Executarei o srCACICsrv após batimento do HASHCode
      if (g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe') = g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TE_HASH_SRCACICSRV', g_oCacic.getLocalFolder + 'GER_COLS.inf'))) then
        Begin
          v_strTeWebManagerServer := g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebManagerAddress', g_oCacic.getLocalFolder + 'GER_COLS.inf'));

          tstrAux := g_oCacic.explode(v_strTeWebManagerServer,'/');
          v_strTeWebManagerFolder := '';
          for intLoop := 1 to (tstrAux.Count-1) do
            Begin
              v_strTeWebManagerFolder := v_strTeWebManagerFolder + IfThen(v_strTeWebManagerFolder <> '','/','');
              v_strTeWebManagerFolder := v_strTeWebManagerFolder + tstrAux[intLoop];
            End;

          v_strTeWebManagerServer := tstrAux[0];

          g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Invocando (Criptografado)"'+g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe -start [' + g_oCacic.enCrypt(v_strTeWebManagerServer)                                                                                                             + ']' +
                                                                                                                                               '[' + g_oCacic.enCrypt(v_strTeWebManagerFolder) + '/' + g_oCacic.GetValueFromFile('Configs','TeWebServicesFolder', g_oCacic.getLocalFolder + 'GER_COLS.inf') + ']' +
                                                                                                                                               '[' + v_strTeSO                                                                                                                                             + ']' +
                                                                                                                                               '[' + v_strTeNodeAddress                                                                                                                                    + ']' +
                                                                                                                                               '[' + g_oCacic.getLocalFolder                                                                                                                               + ']' +
                                                                                                                                               '[' + v_strNuPortaSR                                                                                                                                        + ']' +
                                                                                                                                               '[' + v_strNuTimeOutSR                                                                                                                                      + ']');

          g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - Invocando (Decriptografado)"'+g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe -start [' + v_strTeWebManagerServer                                                                                                                                                     + ']' +
                                                                                                                                                 '[' + StringReplace( v_strTeWebManagerFolder + '/' + g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebServicesFolder', g_oCacic.getLocalFolder + 'GER_COLS.inf')),'//','/',[rfReplaceAll]) + ']' +
                                                                                                                                                 '[' + trim(StringReplace(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TE_SO', g_oCacic.getLocalFolder + g_oCacic.getInfFileName)),' ','<ESPACE>',[rfReplaceAll]))        + ']' +
                                                                                                                                                 '[' + trim(StringReplace(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('TcpIp','TE_NODE_ADDRESS'   , g_oCacic.getLocalFolder + 'GER_COLS.inf')),' ','<ESPACE>'  ,[rfReplaceAll]))    + ']' +
                                                                                                                                                 '[' + g_oCacic.getLocalFolder                                                                                                                                                     + ']' +
                                                                                                                                                 '[' + v_strNuPortaSR                                                                                                                                                              + ']' +
                                                                                                                                                 '[' + v_strNuTimeOutSR                                                                                                                                                            + ']');

          Try
            // Libero o módulo de suporte remoto seguro na FireWall nativa.
            g_oCacic.addApplicationToFirewall('srCACIC - Suporte Remoto Seguro do Sistema CACIC',g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe', true);
          Except
          End;

          g_oCacic.createOneProcess(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe -start [' + g_oCacic.enCrypt(v_strTeWebManagerServer)                                                                                                                                                      + ']' +
                                                                                            '[' + g_oCacic.enCrypt( StringReplace( v_strTeWebManagerFolder + '/' + g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeWebServicesFolder', g_oCacic.getLocalFolder + 'GER_COLS.inf')),'//','/',[rfReplaceAll])) + ']' +
                                                                                            '[' + v_strTeSO                                                                                                                                                                                      + ']' +
                                                                                            '[' + v_strTeNodeAddress                                                                                                                                                                             + ']' +
                                                                                            '[' + g_oCacic.getLocalFolder                                                                                                                                                                        + ']' +
                                                                                            '[' + v_strNuPortaSR                                                                                                                                                                                 + ']' +
                                                                                            '[' + v_strNuTimeOutSR                                                                                                                                                                               + ']',false,SW_NORMAL);
          tstrAux.Free;
          Sleep(3000); // Pausa para criação do aguarde_srCACIC.txt
          InicializaTray;
          BoolServerON := true;
        End
      else
        Begin
          g_oCacic.writeDailyLog('Execução de srCACICsrv impedida por falta de integridade!');
          g_oCacic.writeDailyLog('Providenciando nova cópia.');
          g_oCacic.killFiles(g_oCacic.getLocalFolder + 'modulos\','srcacicsrv.exe');
          Invoca_GerCols('recuperaSR');
          intPausaRecupera := 0;
          while (intPausaRecupera < 10) do
            Begin
              Sleep(3000);
              if FileExists(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe') then
                intPausaRecupera := 10;
              inc(intPausaRecupera);
            End;
          if FileExists(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe') then
            Mnu_SuporteRemotoClick(nil);
        End;
    End;
  g_oCacic.writeDebugLog('Mnu_SuporteRemotoClick - END');
end;

procedure TFormularioGeral.Popup_Menu_ContextoPopup(Sender: TObject);
begin
  g_oCacic.checkDebugMode;

  if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','CS_SUPORTE_REMOTO', g_oCacic.getLocalFolder + 'GER_COLS.inf')) = 'S') and
     (FileExists(g_oCacic.getLocalFolder + 'modulos\srcacicsrv.exe')) then
    Mnu_SuporteRemoto.Enabled := true
  else
    Mnu_SuporteRemoto.Enabled := false;

  boolServerON := false;
  g_oCacic.killFiles(g_oCacic.getLocalFolder+'Temp\','aguarde_SRCACIC.txt');
  if  FileExists(g_oCacic.getLocalFolder + 'Temp\aguarde_SRCACIC.txt') then
    Begin
      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','CS_PERMITIR_DESATIVAR_SRCACIC', g_oCacic.getLocalFolder + 'GER_COLS.inf')) = 'S') then
        Begin
          Mnu_SuporteRemoto.Caption := 'Desativar Suporte Remoto';
          Mnu_SuporteRemoto.Enabled := true;
        End
      else
        Begin
          Mnu_SuporteRemoto.Caption := 'Suporte Remoto Ativo!';
          Mnu_SuporteRemoto.Enabled := false;
        End;

      boolServerON := true;
    End
  else
    Begin
      Mnu_SuporteRemoto.Caption := 'Ativar Suporte Remoto';
      HabilitaSuporteRemoto;
    End;
end;

procedure TFormularioGeral.Timer_InicializaTrayTimer(Sender: TObject);
var intAux : integer;
Begin
  g_oCacic.checkDebugMode;

  g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - BEGIN');

  Timer_InicializaTray.Enabled := false;

  Try
    if g_oCacic.inDebugMode and FileExists(g_oCacic.getLocalFolder + 'Temp\STOP.txt') then
      Finaliza
    else if not InActivity THEN
      Begin
        if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','ConexaoOK', g_oCacic.getLocalFolder + 'GER_COLS.inf')) <> 'S') then
          Begin
            g_oCacic.killFiles(g_oCacic.getLocalFolder,'Temp\ck_conexao.ini');
            ExecutaCacic(nil);
          End;
        g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - Verificando existência de nova versão de CACICservice para atualização');
        // Verificação de existência de nova versão do CACICservice para substituição e execução
        if FileExists(g_oCacic.getWinDir + 'Temp\cacicservice.exe') then
          Begin
            g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - Eliminando "'+g_oCacic.getWinDir + 'cacicservice.exe"');
            g_oCacic.killFiles(g_oCacic.getWinDir,'cacicservice.exe');

            sleep(2000);

            if not FileExists(g_oCacic.getWinDir + 'cacicservice.exe') then
              Begin
                g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - Eliminação OK! Movendo "'+g_oCacic.getWinDir + 'Temp\cacicservice.exe" para "'+g_oCacic.getWinDir + 'cacicservice.exe"');
                MoveFile(PChar(g_oCacic.getWinDir + 'Temp\cacicservice.exe'),PChar(g_oCacic.getWinDir + 'cacicservice.exe'));
                sleep(2000);

                ServiceStart('','CacicSustainService');
              End
            else
              g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - Impossível Eliminar "'+g_oCacic.getWinDir + 'cacicservice.exe"');
          End;
      End;
  Finally
    g_intTaskBarAtual := FindWindow('Shell_TrayWnd', Nil);

    g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - Valores para Condição de Redesenho do ícone no SysTRAY...');
    g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - g_intTaskBarAnterior : ' + IntToStr(g_intTaskBarAnterior));
    g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - g_intTaskBarAtual : ' + IntToStr(g_intTaskBarAtual));
    g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - boolWinIniChange : ' + BoolToStr(boolWinIniChange));
    g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - g_intStatus : ' + IntToStr( g_intStatus));
    g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - InActivity : ' + BoolToStr(InActivity));

    if ((g_intTaskBarAnterior = 0) and (g_intTaskBarAtual > 0)) or
       (boolWinIniChange) OR
       ((g_intStatus <> 0) and not InActivity)then
      Begin
        g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - Redesenhando ícone no SysTRAY...');
        InicializaTray;
      End;

    g_intTaskBarAnterior := g_intTaskBarAtual;

    CheckIfDownloadedVersion;
    Timer_InicializaTray.Enabled := true;
  End;
  g_oCacic.writeDebugLog('Timer_InicializaTrayTimer - END');
End;

procedure TFormularioGeral.CheckIfDownloadedVersion;
Begin
  g_oCacic.writeDebugLog('CheckIfDownloadedVersion - BEGIN');
  g_oCacic.writeDebugLog('CheckIfDownloadedVersion - Verificando existência de nova versão baixada do Agente Principal...');

  // Caso tenha sido baixada nova cópia do Agente Principal, esta deverá ser movida para cima da atual pelo Gerente de Coletas...
  if (FileExists(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName)) then
    Begin
      g_oCacic.writeDebugLog('CheckIfDownloadedVersion - Hash Code de Executável("'+g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName+'") = "' + g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName) + '"');
      g_oCacic.writeDebugLog('CheckIfDownloadedVersion - Hash Code Desejável     = "' + g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeMainProgramHash',g_oCacic.getWinDir + 'chksis.ini')) + '"');
      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','TeMainProgramHash',g_oCacic.getWinDir + 'chksis.ini')) = g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName)) then  //AutoUpdate!
        Begin
          g_oCacic.writeDebugLog('CheckIfDownloadedVersion - Encontrei a nova versão em '+g_oCacic.getLocalFolder + 'Temp\');
          if (g_oCacic.getFileHash(g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName) = g_oCacic.getFileHash(g_oCacic.getLocalFolder + g_oCacic.getMainProgramName)) then
            Begin
              g_oCacic.writeDebugLog('CheckIfDownloadedVersion - Os hashs codes entre '+g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName + ' e ' + g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' são iguais!');
              g_oCacic.killFiles(g_oCacic.getLocalFolder + 'Temp\',g_oCacic.getMainProgramName)
            End
          else
            Begin
              g_oCacic.writeDebugLog('CheckIfDownloadedVersion - Os hashs codes entre '+g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getMainProgramName + ' e ' + g_oCacic.getLocalFolder + g_oCacic.getMainProgramName + ' são diferentes!');
              g_oCacic.writeDailyLog('Versão Nova de '+g_oCacic.getMainProgramName+' Encontrada.');
              g_oCacic.writeDailyLog('Finalizando para Auto-Atualização.');
              Finaliza;
            End;
        End;
    End;
  g_oCacic.writeDebugLog('CheckIfDownloadedVersion - END');
End;

end.

***** Verificar a atualização de CacicService!!!!!!!!!!!!!!!
