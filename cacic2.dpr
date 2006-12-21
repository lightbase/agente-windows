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

program cacic2;

uses
  Forms,
  Windows,
  Dialogs,
  main in 'main.pas' {FormularioGeral},
  frmSenha in 'frmsenha.pas' {formSenha},
  frmConfiguracoes in 'frmConfiguracoes.pas' {FormConfiguracoes},
  frmLog in 'frmLog.pas' {FormLog};

{$R *.res}

VAR								// Add Vars
	MutexHandle: THandle;
	hwind:HWND;

begin

   // Esse código evita que mais de uma cópia do cacic seja instanciada.
   MutexHandle := CreateMutex(nil, TRUE, 'cacic2'); // should be a unique string
   IF MutexHandle <> 0 then
   begin
      IF GetLastError = ERROR_ALREADY_EXISTS then
      begin
        CloseHandle(MutexHandle);
        hwind := 0;
        repeat			// The string 'My app' must match your App Title (below)
           hwind:=Windows.FindWindowEx(0,hwind,'TApplication','cacic2');
        until (hwind<>Application.Handle);
        IF (hwind<>0) then
        begin
           Windows.ShowWindow(hwind,SW_SHOWNORMAL);
           Windows.SetForegroundWindow(hwind);
        end;

        FreeMemory(0);
        Halt(0);
      end
   end;

   // Preventing application button showing in the task bar
   SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW and not WS_EX_APPWINDOW );
   Application.Initialize;
   Application.Title := 'cacic2';
   Application.CreateForm(TFormularioGeral, FormularioGeral);
  Application.Run;
end.
