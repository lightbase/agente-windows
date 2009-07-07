/* 
 * Classe que trata os eventos da janela de autenticação.
 */

#ifndef _WINVNC_VNCPASSDIALOG
#define _WINVNC_VNCPASSDIALOG

#include "stdhdrs.h"
#include "resource.h"
#include "vncPasswd.h"
#include <vector>
using namespace std;
#include <string>
using namespace std;

//extern int MAX_VNC_CLIENTS;

#define ATT_MSG "ATENÇÃO: Esta autenticação, que precede a abertura de sessão para suporte remoto, atribui ao usuário a total responsabilidade por todo e qualquer tipo de dano lógico à estação que porventura seja causado por acesso externo indevido."

#pragma once

// struct referente a um domínio
struct Dominio {
	string id;
	string nome;
};

class vncPassDlg {

public:
	static enum EAuthCode { AUTENTICADO = 1, // usuario autenticado
							FALHA_AUTENTICACAO = 2, // falha ao autenticar, ex: usuário e/ou senha inválidos
							ESPERANDO_AUTENTICACAO = 3,  // autenticação ainda não efetuada
							SEM_AUTENTICACAO = 4 }; // não necessita de autenticação

	vncPassDlg(vector<Dominio> &listaDominios);
	virtual ~vncPassDlg();

	char m_usuario[32]; // nome de usuário
	char m_senha[32]; // senha de usuário
	char m_dominio[16]; // id do domínio selecionado

	vector<Dominio> m_listaDominios;

	EAuthCode m_authStat;

	BOOL DoDialog(EAuthCode authStat, string msgInfo);

private:
	static BOOL CALLBACK vncAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static BOOL CALLBACK vncNoAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static void changeFont(HWND hwndDlg, int dlgItem);

	string m_msgInfo;

	UINT m_indiceDominio; // índice selecionado no combobox de domínios
};

#endif
