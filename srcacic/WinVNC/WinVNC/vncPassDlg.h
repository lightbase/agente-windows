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

#include "CACIC_Utils.h"

//extern int MAX_VNC_CLIENTS;

#define ATT_MSG "ATENÇÃO: Esta autenticação, que precede a abertura de sessão para suporte remoto, atribui ao usuário a total responsabilidade por todo e qualquer tipo de dano lógico à estação que porventura seja causado por acesso externo indevido."

#pragma once

/**
 * Struct referente a um domínio de autenticação.
 */
struct Dominio {
	Dominio(string p_id, string p_nome) : id(p_id), nome(p_nome) {}
	Dominio() : id(""), nome("") {}

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

	char m_usuario[33]; // nome de usuário
	char m_senha[33]; // senha de usuário
	char m_dominio[17]; // id do domínio selecionado

	vector<Dominio> m_listaDominios;

	EAuthCode m_authStat;
	string m_msgInfo;

	BOOL DoDialog();

private:
	static BOOL CALLBACK vncAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	static BOOL CALLBACK vncNoAuthDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);

	UINT m_indiceDominio; // índice selecionado no combobox de domínios
};

#endif
