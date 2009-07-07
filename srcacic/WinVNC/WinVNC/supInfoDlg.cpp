#include "supInfoDlg.h"

extern HINSTANCE hInstResDLL;

supInfoDlg::supInfoDlg() {
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

			vrsBkColor = CreateSolidBrush(RGB(255, 255, 160));

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

			changeFont(hwnd, IDC_ATENCAO_STATIC);

			/*WINDOWPLACEMENT wndpl;
			GetWindowPlacement(hwnd, &wndpl);
			wndpl.rcNormalPosition.bottom *= 2;
			SetWindowPlacement(hwnd, &wndpl);*/
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

			SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;

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
		}
		break;

		// muda a cor de fundo do dialog
		case WM_CTLCOLORDLG:
			return (LONG)vrsBkColor;
		break;

	}

	return FALSE;
}

void supInfoDlg::changeFont(HWND hwndDlg, int dlgItem)
{
	HFONT hFont ;
	LOGFONT lfFont;

	memset(&lfFont, 0x00, sizeof(lfFont));
	memcpy(lfFont.lfFaceName, TEXT("Microsoft Sans Serif"), 16);

	lfFont.lfHeight   = 16;
	lfFont.lfWeight   = FW_BOLD;
	lfFont.lfCharSet  = ANSI_CHARSET;
	lfFont.lfOutPrecision = OUT_DEFAULT_PRECIS;
	lfFont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
	lfFont.lfQuality  = DEFAULT_QUALITY;

	// Create the font from the LOGFONT structure passed.
	hFont = CreateFontIndirect (&lfFont);

	SendMessage( GetDlgItem(hwndDlg, dlgItem), WM_SETFONT, (int)hFont, MAKELONG( TRUE, 0 ) );
}
