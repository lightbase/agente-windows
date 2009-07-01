/* 
 * Classe que trata os eventos da janela de autenticação.
 */

#ifndef _WINVNC_SUPINFODLG
#define _WINVNC_SUPINFODLG

#include "stdhdrs.h"
#include "resource.h"
#include <string>
using namespace std;

#pragma once

#define TEXTO_SUPORTE "ESTA ESTAÇÃO ENCONTRA-SE EM SUPORTE REMOTO."

class supInfoDlg {

public:
	supInfoDlg();
	virtual ~supInfoDlg();

	HWND showInfoDialog();
	HWND closeInfoDialog();
	
	string nomeVisitante;
	string dataInicio;

private:
	HANDLE infoDlgThread;

	static LRESULT CALLBACK supInfoDlg::showDialog(LPVOID lpParameter);
	static BOOL CALLBACK supInfoDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static void changeFont(HWND hwndDlg, int dlgItem);
};

#endif
