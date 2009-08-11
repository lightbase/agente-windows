//  Copyright (C) 2007 Ultr@VNC Team Members. All Rights Reserved.
//  Copyright (C) 1999 AT&T Laboratories Cambridge. All Rights Reserved.
//
//  This file is part of the VNC system.
//
//  The VNC system is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
// If the source code for the VNC system is not available from the place 
// whence you received this file, check http://www.uk.research.att.com/vnc or contact
// the authors on vnc@uk.research.att.com for information on obtaining it.

// WinVNC.cpp

// 24/11/97		WEZ

// WinMain and main WndProc for the new version of WinVNC

////////////////////////////
// System headers
#include "stdhdrs.h"

#include "mmsystem.h"

////////////////////////////
// Custom headers
#include "VSocket.h"
#include "WinVNC.h"

#include "vncServer.h"
#include "vncMenu.h"
#include "vncInstHandler.h"
#include "vncService.h"
///unload driver
#include "vncOSVersion.h"
#include "videodriver.h"

FILE *pFile;
MMRESULT mmCRes;
// Allocating and initializing GlobalClass's
// static data member.  The pointer is being
// allocated - not the object inself.
CACIC_Auth *CACIC_Auth::m_instance = 0;

//#define CRASH_ENABLED
#ifdef CRASH_ENABLED
#ifndef _CRASH_RPT_
#include "crashrpt.h"
#pragma comment(lib, "crashrpt.lib")
#endif
#endif

#define LOCALIZATION_MESSAGES   // ACT: full declaration instead on extern ones
#include "localization.h" // Act : add localization on messages

// Application instance and name
HINSTANCE	hAppInstance;
const char	*szAppName = "WinVNC";
DWORD		mainthreadId;
BOOL		fRunningFromExternalService=false;

// sf@2007 - New shutdown order handling stuff (with uvnc_service)
bool			fShutdownOrdered = false;
static HANDLE		hShutdownEvent = NULL;
MMRESULT			mmRes;

void WRITETOLOG(char *szText, int size, DWORD *byteswritten, void *);

//// Handle Old PostAdd message
bool PostAddAutoConnectClient_bool=false;
bool PostAddNewClient_bool=false;
bool PostAddAutoConnectClient_bool_null=false;
char pszId_char[20];
VCard32 address_vcard;
int port_int;

int start_service(char *cmd);
int install_service(void);
int uninstall_service(void);
extern char service_name[];

void Real_stop_service();
void Set_stop_service_as_admin();
void Real_start_service();
void Set_start_service_as_admin();
void Real_settings(char *mycommand);
void Set_settings_as_admin(char *mycommand);
void Set_uninstall_service_as_admin();
void Set_install_service_as_admin();
void winvncSecurityEditorHelper_as_admin();

// [v1.0.2-jp1 fix] Load resouce from dll
HINSTANCE	hInstResDLL;

// winvnc.exe will also be used for helper exe
// This allow us to minimize the number of seperate exe
bool
Myinit(HINSTANCE hInstance)
{
	SetOSVersion();
	setbuf(stderr, 0);

	// [v1.0.2-jp1 fix] Load resouce from dll
	hInstResDLL = NULL;
	hInstResDLL = LoadLibrary("vnclang_server.dll");
	if (hInstResDLL == NULL)
	{
		hInstResDLL = hInstance;
	}
	//	RegisterLinkLabel(hInstResDLL);

	//Load all messages from ressource file
	Load_Localization(hInstResDLL) ;

	//char WORKDIR[MAX_PATH];
	//if (GetModuleFileName(NULL, WORKDIR, MAX_PATH))
	//{
	//	char* p = strrchr(WORKDIR, '\\');
	//	if (p == NULL) return 0;
	//	*p = '\0';
	//}
	//strcat(WORKDIR,"\\");
	//strcat(WORKDIR,"srCACIC.log");

	//vnclog.SetFile(WORKDIR, true);
	//vnclog.SetMode(2);
	//vnclog.SetLevel(5);

#ifdef _DEBUG
	{
		// Get current flag
		int tmpFlag = _CrtSetDbgFlag( _CRTDBG_REPORT_FLAG );

		// Turn on leak-checking bit
		tmpFlag |= _CRTDBG_LEAK_CHECK_DF;

		// Set flag to the new value
		_CrtSetDbgFlag( tmpFlag );
	}
#endif

	// Save the application instance and main thread id
	hAppInstance = hInstance;
	mainthreadId = GetCurrentThreadId();

	// Initialise the VSocket system
	VSocketSystem socksys;
	if (!socksys.Initialised())
	{
		MessageBox(NULL, sz_ID_FAILED_INIT, szAppName, MB_OK);
		return 0;
	}	
	return 1;
}

// WinMain parses the command line and either calls the main App
// routine or, under NT, the main service routine.
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
	SetOSVersion();
	setbuf(stderr, 0);

	// [v1.0.2-jp1 fix] Load resouce from dll
	hInstResDLL = NULL;
	hInstResDLL = LoadLibrary("vnclang_server.dll");
	if (hInstResDLL == NULL)
	{
		hInstResDLL = hInstance;
	}
	//	RegisterLinkLabel(hInstResDLL);

	//Load all messages from ressource file
	Load_Localization(hInstResDLL) ;

	char WORKDIR[MAX_PATH];
	if (GetModuleFileName(NULL, WORKDIR, MAX_PATH))
	{
		char* p = strrchr(WORKDIR, '\\');
		if (p == NULL) return 0;
		*p = '\0';
	}
	strcat(WORKDIR,"\\");
	strcat(WORKDIR,"srCACIC.log");

	vnclog.SetFile(WORKDIR, true);
	vnclog.SetMode(VNCLog::ToScript);
	vnclog.SetLevel(LL_SRLOG);

#ifdef _DEBUG
	{
		// Get current flag
		int tmpFlag = _CrtSetDbgFlag( _CRTDBG_REPORT_FLAG );

		// Turn on leak-checking bit
		tmpFlag |= _CRTDBG_LEAK_CHECK_DF;

		// Set flag to the new value
		_CrtSetDbgFlag( tmpFlag );
	}
#endif

	// Save the application instance and main thread id
	hAppInstance = hInstance;
	mainthreadId = GetCurrentThreadId();

	// Initialise the VSocket system
	VSocketSystem socksys;
	if (!socksys.Initialised())
	{
		MessageBox(NULL, sz_ID_FAILED_INIT, szAppName, MB_OK);
		return 0;
	}

	BOOL argfound = FALSE;

	if (strncmp(&szCmdLine[0], winvncKill, strlen(winvncKill)) == 0)
	{
		vnclog.Print(LL_SRLOG, VNCLOG("---> Comando -kill recebido.\n"));

		argfound = TRUE;

		static HANDLE hShutdownEvent;
		hShutdownEvent = OpenEvent(EVENT_ALL_ACCESS, FALSE, "Global\\SessionEventUltra");
		SetEvent(hShutdownEvent);
		CloseHandle(hShutdownEvent);
		HWND hservwnd;
							// UVNC Default: WinVNC Tray Icon
		hservwnd = FindWindow("srCACICsrv Tray Icon", NULL);
		if (hservwnd != NULL)
		{
			PostMessage(hservwnd, WM_COMMAND, 40002, 0);
			PostMessage(hservwnd, WM_CLOSE, 0, 0);
		}
		return 0;
	}

	if (strncmp(&szCmdLine[0], winvncStart, strlen(winvncStart)) == 0)
	{
		vnclog.Print(LL_SRLOG, VNCLOG("---> Comando -start recebido.\n"));
		argfound = TRUE;

		char* cmdln[8];
		cmdln[0] = strtok(&szCmdLine[strlen(winvncStart) + 1], "[]");
		int i = 0;
		while (cmdln[i] != NULL && i < 7)
		{
			cmdln[++i] = strtok (NULL, "[]");
		}

		if (i < 7) {
			MessageBox(NULL, "Número de parâmetros menor do que o esperado!", "ERRO!", MB_OK | MB_ICONERROR);
			vnclog.Print(LL_SRLOG, VNCLOG("Número de parâmetros menor do que o esperado!\n"));
			return 0;
		}

		// seta o caminho da pasta temp do cacic
		CACIC_Auth::getInstance()->setTempPath(cmdln[5]);

		// Cria o arquivo temporário de travamento do CACIC
		string filePath = string(cmdln[5]);
		filePath += CACIC_Auth::AGUARDE_FILENAME;
		pFile = fopen(filePath.data(), "w+");
		vnclog.Print(LL_SRLOG, VNCLOG("Criando arquivo temporário: aguarde_SRCACIC.txt!\n"));

		// decodifica o host e o script do gerente web
		string te_end_serv_dec;
		te_end_serv_dec = CACIC_Crypt::decodifica(cmdln[0]);

		string te_end_ws_dec;
		te_end_ws_dec = CACIC_Crypt::decodifica(cmdln[1]);

		CACIC_Auth::getInstance()->setServidorWeb(te_end_serv_dec);
		CACIC_Auth::getInstance()->setScriptsPath(te_end_ws_dec);
		CACIC_Auth::getInstance()->setSOVersion(cmdln[2]);
		CACIC_Auth::getInstance()->setNodeAdress(cmdln[3]);
		CACIC_Auth::getInstance()->setPalavraChave(cmdln[4]);
		UINT porta;
		stringstream portBuffer(cmdln[6]);
		portBuffer >> porta;
		CACIC_Auth::getInstance()->setPorta(porta);
		UINT timeout;
		stringstream timeoutBuffer(cmdln[7]);
		timeoutBuffer >> timeout;
		CACIC_Auth::getInstance()->setTimeout(timeout);

		if (CACIC_Auth::getInstance()->autentica()) {
			iniciaTimer();
			if (!Myinit(hInstance)) return 0;
			return WinVNCAppMain();
		}

	}

	if (!argfound) {
		// If no arguments were given then do not run
		MessageBox(NULL, "Execução incorreta!", "ERRO!", MB_OK | MB_ICONERROR);
		vnclog.Print(LL_SRLOG, VNCLOG("Tentativa incorreta de execução!\n"));
		return 0;
	}

	return 0;
}

// rdv&sf@2007 - New TrayIcon impuDEsktop/impersonation thread stuff
// Todo: cleanup
HINSTANCE hInst_;
HWND hwnd_;
HANDLE Token_;
HANDLE process_;

// Todo: use same security.cpp function instead
DWORD GetCurrentUserToken_()
{
	HWND tray = FindWindow(("Shell_TrayWnd"), 0);
	if (!tray)
		return 0;

	DWORD processId = 0;
	GetWindowThreadProcessId(tray, &processId);
	if (!processId)
		return 0;

	process_ = OpenProcess(MAXIMUM_ALLOWED, FALSE, processId);
	if (!process_)
		return 0;

	OpenProcessToken(process_, MAXIMUM_ALLOWED, &Token_);
	return 2;
}

// Todo: use same security.cpp function instead
bool ImpersonateCurrentUser_()
{
	SetLastError(0);
	process_=0;
	Token_=NULL;
	if (GetCurrentUserToken_()==0)
	{
		vnclog.Print(LL_INTERR, VNCLOG("!GetCurrentUserToken_ \n"));
		return false;
	}
	bool test=(FALSE != ImpersonateLoggedOnUser(Token_));
	if (test==1) vnclog.Print(LL_INTERR, VNCLOG("ImpersonateLoggedOnUser OK \n"));
	if (process_) CloseHandle(process_);
	if (Token_) CloseHandle(Token_);
	return test;
}


DWORD WINAPI imp_desktop_thread(LPVOID lpParam)
{
	vncServer *server = (vncServer *)lpParam;

	HDESK desktop;
	//vnclog.Print(LL_INTERR, VNCLOG("SelectDesktop \n"));
	//vnclog.Print(LL_INTERR, VNCLOG("OpenInputdesktop2 NULL\n"));
	desktop = OpenInputDesktop(0, FALSE,
		DESKTOP_CREATEMENU | DESKTOP_CREATEWINDOW |
		DESKTOP_ENUMERATE | DESKTOP_HOOKCONTROL |
		DESKTOP_WRITEOBJECTS | DESKTOP_READOBJECTS |
		DESKTOP_SWITCHDESKTOP | GENERIC_WRITE
		);

	if (desktop == NULL)
		vnclog.Print(LL_INTERR, VNCLOG("OpenInputdesktop Error \n"));
	else 
		vnclog.Print(LL_INTERR, VNCLOG("OpenInputdesktop OK\n"));

	HDESK old_desktop = GetThreadDesktop(GetCurrentThreadId());
	DWORD dummy;

	char new_name[256];

	if (!GetUserObjectInformation(desktop, UOI_NAME, &new_name, 256, &dummy))
	{
		vnclog.Print(LL_INTERR, VNCLOG("!GetUserObjectInformation \n"));
	}

	vnclog.Print(LL_INTERR, VNCLOG("SelectHDESK to %s (%x) from %x\n"), new_name, desktop, old_desktop);

	if (!SetThreadDesktop(desktop))
	{
		vnclog.Print(LL_INTERR, VNCLOG("SelectHDESK:!SetThreadDesktop \n"));
	}

	if (!CloseDesktop(old_desktop))
		vnclog.Print(LL_INTERR, VNCLOG("SelectHDESK failed to close old desktop %x (Err=%d)\n"), old_desktop, GetLastError());

	//	ImpersonateCurrentUser_();

	char m_username[200];
	HWINSTA station = GetProcessWindowStation();
	if (station != NULL)
	{
		DWORD usersize;
		GetUserObjectInformation(station, UOI_USER_SID, NULL, 0, &usersize);
		DWORD  dwErrorCode = GetLastError();
		SetLastError(0);
		if (usersize != 0)
		{
			DWORD length = usersize;
			if (GetUserName(m_username, &length) == 0)
			{
				UINT error = GetLastError();
				if (error == ERROR_NOT_LOGGED_ON)
				{
				}
				else
				{
					vnclog.Print(LL_INTERR, VNCLOG("getusername error %d\n"), GetLastError());
					return FALSE;
				}
			}
		}
	}
	vnclog.Print(LL_INTERR, VNCLOG("Username %s \n"),m_username);

	// Create tray icon and menu
	vncMenu *menu = new vncMenu(server);
	if (menu == NULL)
	{
		vnclog.Print(LL_INTERR, VNCLOG("failed to create tray menu\n"));
		PostQuitMessage(0);
	}

	// This is a good spot to handle the old PostAdd messages
	if (PostAddAutoConnectClient_bool)
		vncService::PostAddAutoConnectClient( pszId_char );
	if (PostAddAutoConnectClient_bool_null)
		vncService::PostAddAutoConnectClient( NULL );
	if (PostAddNewClient_bool)
		vncService::PostAddNewClient(address_vcard, port_int);

	MSG msg;
	while (GetMessage(&msg,0,0,0) != 0 && !fShutdownOrdered)
	{
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	// sf@2007 - Close all (vncMenu,tray icon, connections...)
	menu->Shutdown();

	if (menu != NULL)
		delete menu;

	//vnclog.Print(LL_INTERR, VNCLOG("GetMessage stop \n"));
	CloseDesktop(desktop);
	//	RevertToSelf();
	return 0;

}


// sf@2007 - For now we use a mmtimer to test the shutdown event periodically
// Maybe there's a less rude method...
void CALLBACK fpTimer(UINT uID, UINT uMsg, DWORD dwUser, DWORD dw1, DWORD dw2)
{
	if (hShutdownEvent)
	{
		// vnclog.Print(LL_INTERR, VNCLOG("****************** SDTimer tic\n"));
		DWORD result=WaitForSingleObject(hShutdownEvent, 0);
		if (WAIT_OBJECT_0==result)
		{
			ResetEvent(hShutdownEvent);
			fShutdownOrdered = true;
			vnclog.Print(LL_INTERR, VNCLOG("****************** WaitForSingleObject - Shutdown server\n"));
		}
	}
}

void InitSDTimer()
{
	if (mmRes != -1) return;
	vnclog.Print(LL_INTERR, VNCLOG("****************** Init SDTimer\n"));
	mmRes = timeSetEvent( 2000, 0, (LPTIMECALLBACK)fpTimer, NULL, TIME_PERIODIC );
}


void KillSDTimer()
{
	vnclog.Print(LL_INTERR, VNCLOG("****************** Kill SDTimer\n"));
	timeKillEvent(mmRes);
	mmRes = -1;
}



// This is the main routine for WinVNC when running as an application
// (under Windows 95 or Windows NT)
// Under NT, WinVNC can also run as a service.  The WinVNCServerMain routine,
// defined in the vncService header, is used instead when running as a service.
int WinVNCAppMain()
{
	SetOSVersion();
	vnclog.Print(LL_INTINFO, VNCLOG("***** DBG - WinVNCAPPMain\n"));
#ifdef CRASH_ENABLED
	LPVOID lpvState = Install(NULL,  "rudi.de.vos@skynet.be", "UltraVnc");
#endif

	// Set this process to be the last application to be shut down.
	// Check for previous instances of WinVNC!
	vncInstHandler *instancehan = new vncInstHandler;

	if (!instancehan->Init())
	{	
		// We don't allow multiple instances!
		MessageBox(NULL, sz_ID_ANOTHER_INST, szAppName, MB_OK);
		return 0;
	}

	//vnclog.Print(LL_INTINFO, VNCLOG("***** DBG - Previous instance checked - Trying to create server\n"));
	// CREATE SERVER
	vncServer server;

	// Set the name and port number
	server.SetName(szAppName);
	server.SetPort(CACIC_Auth::getInstance()->getPorta());
	server.SetAutoIdleDisconnectTimeout(CACIC_Auth::getInstance()->getTimeout());
	server.SockConnect(TRUE);
	vnclog.Print(LL_STATE, VNCLOG("Servidor inicializado com sucesso!\n"));
	//uninstall driver before cont

	// sf@2007 - Set Application0 special mode
	server.RunningFromExternalService(fRunningFromExternalService);
	
	// sf@2007 - New impersonation thread stuff for tray icon & menu
	// Subscribe to shutdown event
	hShutdownEvent = OpenEvent(EVENT_ALL_ACCESS, FALSE, "Global\\SessionEventUltra");
	if (hShutdownEvent) ResetEvent(hShutdownEvent);
	vnclog.Print(LL_STATE, VNCLOG("SDEvent criado.\n"));
	// Create the timer that looks periodicaly for shutdown event
	mmRes = -1;
	InitSDTimer();

	while (!fShutdownOrdered)
	{
		//vnclog.Print(LL_STATE, VNCLOG("################## Creating Imp Thread : %d \n"), nn);

		HANDLE threadHandle;
		DWORD dwTId;
		threadHandle = CreateThread(NULL, 0, imp_desktop_thread, &server, 0, &dwTId);

		WaitForSingleObject( threadHandle, INFINITE );
		CloseHandle(threadHandle);
		vnclog.Print(LL_STATE, VNCLOG("Fechando a imp thread...\n"));
	}

	if (instancehan!=NULL)
		delete instancehan;

	if (hShutdownEvent)CloseHandle(hShutdownEvent);
	vnclog.Print(LL_STATE, VNCLOG("Finalizando o servidor...\n"));
	return 1;
};

// cria um novo timer para atualizar a sessão do técnico que está efetuando o suporte.
void CALLBACK atualizaSessao(UINT uID, UINT uMsg, DWORD dwUser, DWORD dw1, DWORD dw2)
{
	CACIC_Auth::getInstance()->atualizaSessao();
}

void iniciaTimer()
{
	if (mmCRes != -1) mmCRes = -1;
	mmCRes = timeSetEvent( 60000, 0, (LPTIMECALLBACK) atualizaSessao, NULL, TIME_PERIODIC );
}

void paraTimer()
{
	timeKillEvent(mmCRes);
	mmCRes = -1;
}

