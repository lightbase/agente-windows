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

program MapaCacic;

uses
  Forms,
  Windows,
  uMainMapa in 'uMainMapa.pas' {frmMapaCacic},
  uAcessoMapa in 'uAcessoMapa.pas' {frmAcesso},
  CACIC_Library in '..\CACIC_Library.pas',
  CACIC_Comm in '..\CACIC_Comm.pas';

{$R *.res}

const APP_NAME = 'MapaCacic.exe';

var   hwind:HWND;
      oCacic : TCACIC;

begin
   oCacic := TCACIC.Create();

   if( oCacic.isAppRunning( APP_NAME ) )
     then begin
        hwind := 0;
        repeat			// The string 'My app' must match your App Title (below)
           hwind:=Windows.FindWindowEx(0,hwind,'TApplication', APP_NAME );
        until (hwind<>Application.Handle);
        IF (hwind<>0) then
        begin
           Windows.ShowWindow(hwind,SW_SHOWNORMAL);
           Windows.SetForegroundWindow(hwind);
        end;
        FreeMemory(0);
     end
     else
        begin
          Application.Initialize;
          Application.CreateForm(TfrmMapaCacic, frmMapaCacic);
  Application.Run;
        end;
     oCacic.Free();
end.
