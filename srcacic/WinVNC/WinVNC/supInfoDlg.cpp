#include "supInfoDlg.h"

extern HINSTANCE hInstResDLL;

supInfoDlg::supInfoDlg() {
	m_timeoutCount = 20;
}

supInfoDlg::~supInfoDlg()
{
}

HWND supInfoDlg::showInfoDialog()
{	
	DWORD threadID;
	m_hInfoDlgThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE) supInfoDlg::showDialog, (LPVOID) this, 0, &threadID);
	ResumeThread(m_hInfoDlgThread);

	return (HWND) 0;
}

HWND supInfoDlg::closeInfoDialog()
{
	TerminateThread(m_hInfoDlgThread, 0);

	return (HWND) 0;
}

LRESULT CALLBACK supInfoDlg::showDialog(LPVOID lpParameter)
{
	supInfoDlg *_this = (supInfoDlg*)lpParameter;

	DialogBoxParam(hInstResDLL, MAKEINTRESOURCE(IDD_INFO_DLG), 
		NULL, (DLGPROC) supInfoDlgProc, (LONG) _this);
	
	return 0;
}

BOOL CALLBACK supInfoDlg::supInfoDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. We use Allen Hadden's (ahadden@taratec.com) suggestion 
	// from a newsgroup to get the pseudo-this.
	#ifndef _X64
		supInfoDlg *_this = (supInfoDlg*)GetWindowLong(hwnd, GWL_USERDATA);
	#else
		supInfoDlg *_this = (supInfoDlg*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
	#endif

	static HBRUSH vrsBkColor;

	switch (uMsg)
	{
		case WM_INITDIALOG:
		{
			// Save the lParam into our user data so that subsequent calls have
			// access to the parent C++ object
			#ifndef _X64
				SetWindowLong(hwnd, GWL_USERDATA, lParam);
			#else
				SetWindowLongPtr(hwnd, GWLP_USERDATA, lParam);
			#endif
			
			supInfoDlg *_this = (supInfoDlg *) lParam;
			_this->hwInfoDlg = hwnd;

			vrsBkColor = CreateSolidBrush(RGB(255, 255, 160));

			ShowWindow(GetDlgItem(hwnd, IDC_ATENCAO_STATIC), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_AVISO_SUPORTE), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_NOME_LBL), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_IP_LBL), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_INICIO_LBL), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_DOC_LBL), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_NOME), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_IP), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_INICIO), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_REFERENCIA), TRUE);
			ShowWindow(GetDlgItem(hwnd, IDC_AVISO_LOGOUT), FALSE);

			// Fazendo o diálogo ficar transparente.
			// Fonte: http://weseetips.com/2008/10/07/how-to-set-transparent-dialogs/
			LONG ExtendedStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
			SetWindowLong(hwnd, GWL_EXSTYLE, ExtendedStyle | WS_EX_LAYERED);
			double TransparencyPercentage = 65.0;
			double fAlpha = TransparencyPercentage * (255.0 /100);
			BYTE byAlpha = static_cast<BYTE>(fAlpha);
			SetLayeredWindowAttributes(hwnd, 0, byAlpha, LWA_ALPHA);

			// Posicionando o diálogo no canto superior direito da tela.
			RECT deskRect;
			RECT dlgRect;
			GetWindowRect(GetDesktopWindow(), &deskRect);
			GetWindowRect(hwnd, &dlgRect);
			SetWindowPos(hwnd, 
				HWND_TOPMOST,
				deskRect.right - (dlgRect.left + dlgRect.right) - 15,
				deskRect.top + 15,
				dlgRect.right - dlgRect.left,
				dlgRect.bottom - dlgRect.top,
				SWP_SHOWWINDOW);

			SetDlgItemText(hwnd, IDC_INFO_NOME, (LPSTR) _this->m_nomeVisitante.data());
			SetDlgItemText(hwnd, IDC_INFO_IP, (LPSTR) _this->m_ip.data());
			SetDlgItemText(hwnd, IDC_INFO_INICIO, (LPSTR) _this->m_dataInicio.data());
			SetDlgItemText(hwnd, IDC_INFO_REFERENCIA, (LPSTR) _this->m_documentoReferencia.data());

			CACIC_Utils::changeFont(hwnd, IDC_ATENCAO_STATIC, 16, CACIC_Utils::F_SANS_SERIF, true);

			/*WINDOWPLACEMENT wndpl;
			GetWindowPlacement(hwnd, &wndpl);
			wndpl.rcNormalPosition.bottom *= 2;
			SetWindowPlacement(hwnd, &wndpl);*/
		}
		break;

		// Timer event
		case WM_TIMER:
		{
			_this->m_timeoutCount--;

			// Update the displayed count
			char temp[256];
			sprintf(temp, "ATENÇÃO: O sistema efetuará logout em %u segundos!", (_this->m_timeoutCount));
			SetDlgItemText(hwnd, IDC_AVISO_LOGOUT, temp);
		}
		break;

		case WM_LOGOUT_WARNING:
		{
			// Fazendo o diálogo ficar opaco novamente.
			// Fonte: http://weseetips.com/2008/10/07/how-to-set-transparent-dialogs/
			LONG ExtendedStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
			SetWindowLong(hwnd, GWL_EXSTYLE, ExtendedStyle | WS_EX_LAYERED);
			double TransparencyPercentage = 100.0;
			double fAlpha = TransparencyPercentage * (255.0 /100);
			BYTE byAlpha = static_cast<BYTE>(fAlpha);
			SetLayeredWindowAttributes(hwnd, 0, byAlpha, LWA_ALPHA);

			CACIC_Utils::changeFont(hwnd, IDC_AVISO_LOGOUT, 26, CACIC_Utils::F_SANS_SERIF, true);

			ShowWindow(GetDlgItem(hwnd, IDC_ATENCAO_STATIC), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_AVISO_SUPORTE), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_NOME_LBL), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_IP_LBL), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_INICIO_LBL), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_DOC_LBL), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_NOME), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_IP), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_INICIO), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_INFO_REFERENCIA), FALSE);
			ShowWindow(GetDlgItem(hwnd, IDC_AVISO_LOGOUT), TRUE);

			SetTimer(hwnd, 1, 1000, NULL);
		}
		break;

		case WM_COMMAND:
		{
			switch (LOWORD(wParam))
			{
				case ID_POK:
				{
					EndDialog(hwnd, IDOK);

					return TRUE;
				}
				break;

				case ID_PCANCELAR:
					EndDialog(hwnd, FALSE);
				break;
			}
		}
		break;

		// muda a cor de fundo dos itens do dialog
		case WM_CTLCOLORSTATIC:
		{
			HDC hdc = (HDC)wParam;
			HWND hwndStatic = (HWND)lParam;

			if (hwndStatic == GetDlgItem(hwnd, IDC_AVISO_LOGOUT))
			{
				SetTextColor(hdc, RGB(255, 0, 0));
				//SetBkMode(hdc, TRANSPARENT);
				//return (BOOL)GetStockObject(NULL_BRUSH);
			}

			/*if (hwndStatic == GetDlgItem(hwnd, IDC_AVISO_SUPORTE))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
			}
			if (hwndStatic == GetDlgItem(hwnd, IDC_ATENCAO_STATIC))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
			}*/

			SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
		}
		break;

		// muda a cor de fundo do dialog
		case WM_CTLCOLORDLG:
			return (LONG)vrsBkColor;
		break;

	}

	return FALSE;
}
