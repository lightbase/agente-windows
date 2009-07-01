//  Copyright (C) 2002 Ultr@VNC Team Members. All Rights Reserved.
//
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


// AuthDialog.cpp: implementation of the AuthDialog class.

#include "stdhdrs.h"
#include "vncviewer.h"
#include "AuthDialog.h"
#include "Exception.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

//WNDPROC DefEditProc;
//LRESULT motivoEditProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

AuthDialog::AuthDialog()
{
	/*m_user[0]=__T('\0');
	m_passwd[0]=__T('\0');
	m_motivo[0]=__T('\0');*/
	memset(m_user, 0, 32);
	memset(m_passwd, 0, 32);
	memset(m_doc_ref, 0, 128);
	memset(m_motivo, 0, 5120);
}

AuthDialog::~AuthDialog()
{
}

int AuthDialog::DoDialog()
{
	return DialogBoxParam(pApp->m_instance, DIALOG_MAKEINTRESOURCE(IDD_AUTH_DIALOG), NULL, (DLGPROC) DlgProc, (LONG) this);
}

BOOL CALLBACK AuthDialog::DlgProc(  HWND hwnd,  UINT uMsg,  
									   WPARAM wParam, LPARAM lParam ) {
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. But we can get a pseudo-this from the parameter to 
	// WM_INITDIALOG, which we therafter store with the window and retrieve
	// as follows:
#ifndef _X64
	AuthDialog *_this = (AuthDialog *) GetWindowLong(hwnd, GWL_USERDATA);
#else
	AuthDialog *_this = (AuthDialog *) GetWindowLongPtr(hwnd, GWLP_USERDATA);
#endif

	switch (uMsg)
	{

		case WM_INITDIALOG:
		{
#ifndef _X64
			SetWindowLong(hwnd, GWL_USERDATA, lParam);
#else
			SetWindowLongPtr(hwnd, GWLP_USERDATA, lParam);
#endif
			_this = (AuthDialog *) lParam;

			CentreWindow(hwnd);
			SetForegroundWindow(hwnd);
				
			// Limitando o tamanho dos campos.
			SendMessage(GetDlgItem(hwnd, IDC_USER_EDIT), EM_LIMITTEXT, WPARAM(32), 0);
			SendMessage(GetDlgItem(hwnd, IDC_PASSWD_EDIT), EM_LIMITTEXT, WPARAM(32), 0);
			SendMessage(GetDlgItem(hwnd, IDC_MOTIVO_EDIT), EM_LIMITTEXT, WPARAM(5120), 0);
			SendMessage(GetDlgItem(hwnd, IDC_DOC_REF_EDIT), EM_LIMITTEXT, WPARAM(128), 0);

			//DefEditProc = (WNDPROC) SetWindowLong(GetDlgItem(hwnd, IDC_MOTIVO_EDIT), GWL_WNDPROC, (long) motivoEditProc);

			return TRUE;
		}
		case WM_COMMAND:
			switch (LOWORD(wParam)) {
				case IDC_MOTIVO_EDIT:
				{
					int intlen = GetWindowTextLength(GetDlgItem(hwnd, IDC_MOTIVO_EDIT));
					stringstream textlen;
					textlen << intlen;

					SetDlgItemText(hwnd, IDC_CHAR_COUNT, (LPCSTR) textlen.str().data());

					return TRUE;
				}
				case IDOK:
				{
					memset(_this->m_user, 0, 32);
					memset(_this->m_passwd, 0, 32);
					memset(_this->m_doc_ref, 0, 128);
					memset(_this->m_motivo, 0, 5120);

					int drlen = GetWindowTextLength(GetDlgItem(hwnd, IDC_DOC_REF_EDIT));
					int motlen = GetWindowTextLength(GetDlgItem(hwnd, IDC_MOTIVO_EDIT));

					if (drlen > 128)
					{
						MessageBox(hwnd, "O campo \"Referência\" dever ter no máximo 128 caracteres!", "Erro!", MB_ICONERROR | MB_OK);
						return FALSE;
					}
					if (motlen > 5120)
					{
						MessageBox(hwnd, "O campo \"Motivo do Suporte\" dever ter no máximo 5120 caracteres!", "Erro!", MB_ICONERROR | MB_OK);
						return FALSE;
					}

					UINT res = GetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_user, 32);
					res = GetDlgItemText(hwnd, IDC_PASSWD_EDIT, _this->m_passwd, 32);
					res = GetDlgItemText(hwnd, IDC_DOC_REF_EDIT, _this->m_doc_ref, 128);
					res = GetDlgItemText(hwnd, IDC_MOTIVO_EDIT, _this->m_motivo, 5120);

					if (_this->m_user[0] == 0 || _this->m_passwd[0] == 0 || _this->m_doc_ref[0] == 0 || _this->m_motivo[0] == 0)
					{
						MessageBox(hwnd, "Os campos devem ser preenchidos!", "Erro!", MB_ICONERROR | MB_OK);
					}
					else
					{
						EndDialog(hwnd, IDOK);
					}

					return TRUE;
				}
				case IDCANCEL:
					EndDialog(hwnd, FALSE);
					return TRUE;
			}
			break;

		case WM_DESTROY:
			EndDialog(hwnd, FALSE);
			return TRUE;

		case WM_CTLCOLORSTATIC:
		{
			HDC hdc = (HDC)wParam;
			HWND hwndStatic = (HWND)lParam;

			if (hwndStatic == GetDlgItem(hwnd, IDC_CHAR_COUNT))
			{
				SetTextColor(hdc, RGB(0, 0, 160));
				SetBkMode(hdc, TRANSPARENT);

				return NULL_BRUSH;
			}
		}
		break;
	}
	return 0;
}

//LRESULT motivoEditProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
//{
//	switch (uMsg)
//	{
//		case WM_CHAR:
//		{
//			HWND dlgHwnd = GetParent(hwnd);
//
//			int intlen = GetWindowTextLength(GetDlgItem(dlgHwnd, IDC_MOTIVO_EDIT));
//			stringstream textlen;
//			textlen << intlen;
//
//			SetDlgItemText(dlgHwnd, IDC_CHAR_COUNT, (LPCSTR) textlen.str().data());
//
//			return CallWindowProc(DefEditProc, hwnd, uMsg, wParam, lParam);
//		}
//		default:
//			return CallWindowProc(DefEditProc, hwnd, uMsg, wParam, lParam);
//	}
//
//	return FALSE;
//}
