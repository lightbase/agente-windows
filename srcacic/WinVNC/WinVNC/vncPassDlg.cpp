#include "vncPassDlg.h"
#include <iostream>  
#include <sstream>  

extern HINSTANCE hInstResDLL;

vncPassDlg::vncPassDlg(vector<Dominio> &listaDominios) {
	m_listaDominios = listaDominios;
	m_authStat = vncPassDlg::ESPERANDO_AUTENTICACAO;

	memset(m_usuario, 0, 33);
	memset(m_senha, 0, 33);
	memset(m_dominio, 0, 17);
}

vncPassDlg::~vncPassDlg() {
	memset(m_usuario, 0, 33);
	memset(m_senha, 0, 33);
	memset(m_dominio, 0, 17);
}

BOOL vncPassDlg::DoDialog()
{
	BOOL retVal;
	if (m_authStat == vncPassDlg::SEM_AUTENTICACAO)
	{
		strcpy(m_dominio, "0");
		strcpy(m_senha, "0");
		retVal = DialogBoxParam(hInstResDLL, MAKEINTRESOURCE(IDD_NO_AUTH_DLG), 
			NULL, (DLGPROC) vncNoAuthDlgProc, (LONG) this);
	}
	else
	{
		retVal = DialogBoxParam(hInstResDLL, MAKEINTRESOURCE(IDD_AUTH_DLG), 
			NULL, (DLGPROC) vncAuthDlgProc, (LONG) this);
	} 

	return retVal;
}

BOOL CALLBACK vncPassDlg::vncAuthDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. We use Allen Hadden's (ahadden@taratec.com) suggestion 
	// from a newsgroup to get the pseudo-this.
	#ifndef _X64
		vncPassDlg *_this = (vncPassDlg*)GetWindowLong(hwnd, GWL_USERDATA);
	#else
		vncPassDlg *_this = (vncPassDlg*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
	#endif

	static HBRUSH msgBkColor;
	static HBRUSH vrsBkColor;

	switch (uMsg)
	{
		/**	Os cases desse switch se referem as mensagens de notificação lançadas
		por processos de threads.*/

		case WM_INITDIALOG:
		/**	Case 1: Case de construção da janela de Autenticação. É um estado
		estático. Aqui a primeira janela de dialogo do suporte remoto é
		montada. De acordo com as respostas obtidas pela interação do usuario,
		essa janela é tambem aqui, reformulada.*/
		{
			// Save the lParam into our user data so that subsequent calls have
			// access to the parent C++ object
			#ifndef _X64
				SetWindowLong(hwnd, GWL_USERDATA, lParam);
			#else
				SetWindowLongPtr(hwnd, GWLP_USERDATA, lParam);
			#endif
			
			vncPassDlg *_this = (vncPassDlg *) lParam;

			vrsBkColor = CreateSolidBrush(RGB(238, 215, 184));

			CACIC_Utils::changeFont(hwnd, IDC_ATT_MSG, 13, CACIC_Utils::F_SANS_SERIF, true);

			//SendMessage (hwnd, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, MAKELONG (8, 8));

			// Limitando o tamanho dos campos para 32 caracteres.
			SendMessage(GetDlgItem(hwnd, IDC_USER_EDIT), EM_LIMITTEXT, WPARAM(32), 0);
			SendMessage(GetDlgItem(hwnd, IDC_PASS_EDIT), EM_LIMITTEXT, WPARAM(32), 0);

			string nm_dominio;
			HWND hDominios = GetDlgItem(hwnd, IDC_DOMAIN_CB);
			SendMessage(hDominios, CB_ADDSTRING, 0, (LPARAM) _this->m_listaDominios.at(0).nome.c_str());
			SendMessage(hDominios, CB_SETCURSEL, 0, 0);
			int found;
			for (int i = 1; i < _this->m_listaDominios.size(); i++)
			{
				nm_dominio = _this->m_listaDominios.at(i).nome;
				SendMessage(hDominios, CB_ADDSTRING, 0, (LPARAM) nm_dominio.c_str());
				found = nm_dominio.find("*"); // seleciona o domínio marcado com o *
				if (found != string::npos)
					SendMessage(hDominios, CB_SELECTSTRING, 0, (LPARAM) nm_dominio.c_str());
			}

			if (_this->m_authStat == vncPassDlg::FALHA_AUTENTICACAO)
			{	// Mensagem da faixa na cor vermelha, informando falha.
				msgBkColor = CreateSolidBrush(RGB(242, 0, 28));

				SendMessage(hDominios, CB_SELECTSTRING, 0, (LPARAM) _this->m_listaDominios.at(_this->m_indiceDominio).nome.c_str());
				SetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario);
				SetDlgItemText(hwnd, IDC_PASS_EDIT, _this->m_senha);

				SetDlgItemText(hwnd, IDC_MSG, (LPSTR) "Falha na Autenticação!");
			}
			else if (_this->m_authStat == vncPassDlg::AUTENTICADO)
			{	// Mensagem da faixa na cor verde, validando o suporte.
				msgBkColor = CreateSolidBrush(RGB(102, 255, 0));

				SendMessage(hDominios, CB_SELECTSTRING, 0, (LPARAM) _this->m_listaDominios.at(_this->m_indiceDominio).nome.c_str());
				SetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario);
				SetDlgItemText(hwnd, IDC_PASS_EDIT, _this->m_senha);

				HWND hDominios = GetDlgItem(hwnd, IDC_DOMAIN_CB);
				EnableWindow( hDominios, FALSE );
				HWND hUsuario = GetDlgItem(hwnd, IDC_USER_EDIT);
				EnableWindow( hUsuario, FALSE );
				HWND hSenha = GetDlgItem(hwnd, IDC_PASS_EDIT);
				EnableWindow( hSenha, FALSE );

				SetDlgItemText( hwnd, IDC_MSG, (LPSTR)_this->m_msgInfo.c_str() );

				//Lança um timeout sobre o botao de OK, confirmando a autenticação.
				_this->m_timeoutPassDlg = (UINT)5;
				SetTimer(hwnd,1,1000,NULL);
			}
			return TRUE;
		}
		break;

		case WM_COMMAND:
		/**	Case 2: Estado dinâmico interativo, onde os comandos são captados e exibidos
		em tempo de uso.*/
		{
			switch (LOWORD(wParam))
			{
				case ID_POK:
				{
					if (_this->m_authStat == vncPassDlg::AUTENTICADO)
					{
						EndDialog(hwnd, IDOK);
					}

					int ulen = GetWindowTextLength(GetDlgItem(hwnd, IDC_USER_EDIT));
					int plen = GetWindowTextLength(GetDlgItem(hwnd, IDC_PASS_EDIT));

					HWND hDominios = GetDlgItem(hwnd, IDC_DOMAIN_CB);
					_this->m_indiceDominio = SendMessage(hDominios, CB_GETCURSEL, 0, 0);

					memset(_this->m_usuario, 0, 33);
					memset(_this->m_senha, 0, 33);
					memset(_this->m_dominio, 0, 17);

					GetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario, 32);
					GetDlgItemText(hwnd, IDC_PASS_EDIT, _this->m_senha, 32);
					strcpy(_this->m_dominio, _this->m_listaDominios.at(_this->m_indiceDominio).id.c_str());

					if (_this->m_usuario[0] == 0 || _this->m_senha[0] == 0 || _this->m_dominio[0] == 0)
					{
						MessageBox(hwnd, "Os campos devem ser preenchidos!", "Erro!", MB_ICONERROR | MB_OK);
						return FALSE;
					}

					EndDialog(hwnd, IDOK);
				}
				break;

				case ID_PCANCELAR:
					EndDialog(hwnd, FALSE);
				break;
			}
		}
		break;
	
		case WM_TIMER:
		/**	Case 3: Estado de detecção de um timeout. Ele verifica que um timeout
		ocorreu em algum momento e a partir dele, toma as devidas ações.*/
		{
			//Atualiza a Mensagem no botão de OK da janela de Autenticação.
			char temp[256];
			sprintf(temp, "OK [%u]", (_this->m_timeoutPassDlg));
			SetDlgItemText(hwnd, ID_POK, temp);
			
			/**	Fecha a janela de autenticação "clicando automaticamente
			no botao OK".*/
			if (!(_this->m_timeoutPassDlg))	EndDialog(hwnd, ID_POK);
			_this->m_timeoutPassDlg--;
		}
		break;
		
		/**	Case 4: Estado de atualização da janela. De acordo com a interação
		com o menu, os campos mudam de layout, se tornando transparentes.*/
		case WM_CTLCOLORSTATIC:
		{
			HDC hdc = (HDC)wParam;
			HWND hwndStatic = (HWND)lParam;

			if (hwndStatic == GetDlgItem(hwnd, IDC_MSG))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)msgBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_AUTHDLG_VERSION))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_ATT_MSG))
			{
				SetTextColor(hdc, RGB(255, 0, 0));
				SetBkMode(hdc, TRANSPARENT);
				return (BOOL)GetStockObject(NULL_BRUSH);
			}
		}
		break;

	}

	return FALSE;
}

BOOL CALLBACK vncPassDlg::vncNoAuthDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. We use Allen Hadden's (ahadden@taratec.com) suggestion 
	// from a newsgroup to get the pseudo-this.
	#ifndef _X64
		vncPassDlg *_this = (vncPassDlg*)GetWindowLong(hwnd, GWL_USERDATA);
	#else
		vncPassDlg *_this = (vncPassDlg*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
	#endif

	static HBRUSH msgBkColor;
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
			
			vncPassDlg *_this = (vncPassDlg *) lParam;

			vrsBkColor = CreateSolidBrush(RGB(238, 215, 184));

			CACIC_Utils::changeFont(hwnd, IDC_ATT_MSG, 13, CACIC_Utils::F_SANS_SERIF, true);

			SendMessage (hwnd, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, MAKELONG (8, 8));

			SetDlgItemText( hwnd, IDC_MSG, (LPSTR)_this->m_msgInfo.c_str() );

			return TRUE;
		}
		break;

		case WM_COMMAND:
		{
			switch (LOWORD(wParam))
			{
				case ID_POK:
				{
					int ulen = GetWindowTextLength(GetDlgItem(hwnd, IDC_USER_EDIT));

					memset(_this->m_usuario, 0, 33);

					GetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario, 32);

					if (_this->m_usuario[0] == 0)
					{
						MessageBox(hwnd, "O campo deve ser preenchido.", "Erro!", MB_ICONERROR | MB_OK);
						return FALSE;
					}

					EndDialog(hwnd, IDOK);
				}
				break;

				case ID_PCANCELAR:
					EndDialog(hwnd, FALSE);
				break;
			}
		}
		break;

		case WM_CTLCOLORSTATIC:
		{
			HDC hdc = (HDC)wParam;
			HWND hwndStatic = (HWND)lParam;

			if (hwndStatic == GetDlgItem(hwnd, IDC_MSG))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)msgBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_AUTHDLG_VERSION))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_ATT_MSG))
			{
				SetTextColor(hdc, RGB(255, 0, 0));
				SetBkMode(hdc, TRANSPARENT);
				return (BOOL)GetStockObject(NULL_BRUSH);
			}
		}
		break;

	}

	return FALSE;
}
