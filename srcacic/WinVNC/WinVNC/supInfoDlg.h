/* 
 * Classe que trata os eventos da janela de autenticação.
 */

#ifndef _WINVNC_SUPINFODLG
#define _WINVNC_SUPINFODLG

#include "stdhdrs.h"
#include "resource.h"
#include <string>
using namespace std;

#include "CACIC_Utils.h"

#pragma once

class supInfoDlg {

public:
	supInfoDlg();
	virtual ~supInfoDlg();

	HWND showInfoDialog();
	HWND closeInfoDialog();
	
	string m_nomeVisitante;
	string m_ip;
	string m_dataInicio;
	string m_documentoReferencia;

private:
	HANDLE m_hInfoDlgThread;

	static LRESULT CALLBACK supInfoDlg::showDialog(LPVOID lpParameter);
	static BOOL CALLBACK supInfoDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
};

#endif
