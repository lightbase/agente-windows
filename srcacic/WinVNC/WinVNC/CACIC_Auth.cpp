/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe singleton responsável pela autenticação no gerente web.
 */

#include "CACIC_Auth.h"

const string CACIC_Auth::GET_CONFIG_SCRIPT = "srcacic_get_config.php";
const string CACIC_Auth::SET_SESSION_SCRIPT = "srcacic_set_session.php";
const string CACIC_Auth::AUTH_CLIENT_SCRIPT = "srcacic_auth_client.php";
const unsigned int CACIC_Auth::TAMANHO_RESPOSTA = 1025;
const string CACIC_Auth::AGUARDE_FILENAME = "aguarde_srCACIC.txt";
const string CACIC_Auth::COOKIE_FILENAME = "cacic_ck.txt";
const UINT CACIC_Auth::TEMPO_IDLE = 5;

bool CACIC_Auth::autentica()
{
	vnclog.Print(LL_SRLOG, VNCLOG("Autenticando o usuário no gerente web.\n"));

	string post = getPostComum();

	string config_script = m_scriptsPath;
	config_script += GET_CONFIG_SCRIPT;

	char resposta[TAMANHO_RESPOSTA];
	CACIC_Con::sendHtppPost(m_servidorWeb, config_script, post, resposta, TAMANHO_RESPOSTA);

	vector<Dominio> listaDominios;
	if (!verificaAuthChave(resposta, listaDominios)) return false;

	if (!autenticaUsuario(listaDominios)) return false;

	vnclog.Print(LL_SRLOG, VNCLOG("Autenticação OK!\n"));

	return true;
}

bool CACIC_Auth::autenticaUsuario(vector<Dominio> &listaDominios)
{
	string post;
	char resposta[TAMANHO_RESPOSTA];

	vncPassDlg passDlg(listaDominios);

	if (listaDominios.at(0).id.compare("0") == 0) {
		passDlg.m_authStat = vncPassDlg::SEM_AUTENTICACAO;
	} else {
		passDlg.m_authStat = vncPassDlg::ESPERANDO_AUTENTICACAO;
	}

	// apresenta o dialogo de autenticação
	do
	{
		if (!passDlg.DoDialog()) return false;
		
		post.clear();
		post = getPostComum();
		
		post += "&nm_nome_acesso_autenticacao=";
		post += CACIC_Crypt::codifica(passDlg.m_usuario);
		post += "&te_senha_acesso_autenticacao=";
		post += CACIC_Crypt::codifica(passDlg.m_senha);
		post += "&id_servidor_autenticacao=";
		post += CACIC_Crypt::codifica(passDlg.m_dominio);

		vnclog.Print(LL_SRLOG, post.data());

		string session_script = m_scriptsPath;
		session_script.append(SET_SESSION_SCRIPT);

		CACIC_Con::sendHtppPost(m_servidorWeb, session_script, post, resposta, TAMANHO_RESPOSTA);
		
		if(verificaAuthDominio(resposta)) {
			passDlg.m_authStat = vncPassDlg::AUTENTICADO;
		} else {
			passDlg.m_authStat = vncPassDlg::FALHA_AUTENTICACAO;
		}
	}
	while (passDlg.m_authStat != vncPassDlg::AUTENTICADO);

	if (passDlg.m_authStat != vncPassDlg::SEM_AUTENTICACAO)
	{
		string msginfo = "Usuário Autenticado: ";
		msginfo += m_usuario;
		passDlg.m_authStat = vncPassDlg::AUTENTICADO;
		passDlg.m_msgInfo = msginfo;
		if (!passDlg.DoDialog()) return false;
	}

	return true;
}

bool CACIC_Auth::validaTecnico(char nm_usuario_cli[], char te_senha_cli[], char te_node_address_cli[], 
							   char te_documento_referencial[], char te_motivo_conexao[], char te_so_cli[], 
							   const vncClientId vncCID, const char peerName[])
{
	string post = getPostComum();

	post += "&id_sessao=";
	post += m_idSessao;

	post += "&nm_usuario_cli=";
	post += nm_usuario_cli;
	post += "&te_senha_cli=";
	post += te_senha_cli;
	post += "&te_node_address_cli=";
	post += te_node_address_cli;
	post += "&te_documento_referencial=";
	post += te_documento_referencial;
	post += "&te_motivo_conexao=";
	post += te_motivo_conexao;
	post += "&te_so_cli=";
	post += te_so_cli;

	string auth_client_script = m_scriptsPath;
	auth_client_script += AUTH_CLIENT_SCRIPT;

	char resposta[TAMANHO_RESPOSTA];
	CACIC_Con::sendHtppPost(m_servidorWeb, auth_client_script, post, resposta, TAMANHO_RESPOSTA);

	if (!verificaAuthTecnico(resposta, te_node_address_cli, te_documento_referencial, 
							 te_motivo_conexao, te_so_cli, vncCID, peerName))
	{
		return false;
	}

	return true;
}

bool CACIC_Auth::verificaAuthChave(char resposta[], vector<Dominio> &listaDominios)
{
	try
	{
		if (!verificaStatus(resposta)) throw SRCException("Falha na verificação da chave!");

		string dominios;
		dominios = CACIC_Utils::leTag(resposta, "SERVIDORES_AUTENTICACAO");

		string dominios_dec;
		dominios_dec = CACIC_Crypt::decodifica(dominios.c_str());

		char* dominios_dec_str = (char*)malloc(sizeof(char)*(dominios_dec.length() + 1));
		string::traits_type::copy(dominios_dec_str, dominios_dec.c_str(), dominios_dec.length() + 1);
		char* id_dominio = strtok(dominios_dec_str, ";");
		char* nm_dominio = strtok(NULL, ";");
		
		while (id_dominio != NULL)
		{
			listaDominios.push_back(Dominio(id_dominio, nm_dominio));

			id_dominio = strtok(NULL, ";");
			nm_dominio = strtok(NULL, ";");
		}
		delete dominios_dec_str;
		delete id_dominio;
		delete nm_dominio;

		if (listaDominios.empty()) throw SRCException("A lista de domínios está vazia.");

		return true;
	}
	catch(SRCException ex)
	{
		MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		vnclog.Print(LL_SRLOG, VNCLOG(ex.getMessage().c_str()));
		return false;
	}
}

bool CACIC_Auth::verificaAuthDominio(char resposta[])
{
	try
	{
		if (!verificaStatus(resposta)) return false;//throw SRCException("Falha na autenticação do usuário.");

		string nm_completo;
		nm_completo = CACIC_Utils::leTag(resposta, "NM_COMPLETO");

		string nome_dec;
		nome_dec.append(CACIC_Crypt::decodifica(nm_completo.c_str()));

		string id_sessao;
		id_sessao = CACIC_Utils::leTag(resposta, "ID_SESSAO");

		m_usuario = nome_dec;
		m_idSessao = id_sessao;

		return true;
	}
	catch(SRCException ex)
	{
		MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		vnclog.Print(LL_SRLOG, VNCLOG(ex.getMessage().c_str()));
		return false;
	}
}

bool CACIC_Auth::verificaAuthTecnico(char resposta[], char te_node_address_cli[], char te_documento_referencial[],
						 char te_motivo_conexao[], char te_so_cli[], const vncClientId vncCID, const char peerName[])
{
	try
	{
		string status;
		status = CACIC_Utils::leTag(resposta, "STATUS");

		string status_dec;
		status_dec = CACIC_Crypt::decodifica(status.c_str());

		// neste caso não estou utilizando a função verifica status
		// para poder pegar a resposta de erro que vem na tag STATUS
		if (status_dec.compare("OK") != 0) throw SRCException(status_dec.c_str());

		string id_usuario_cli;
		id_usuario_cli = CACIC_Utils::leTag(resposta, "ID_USUARIO_CLI");

		string id_conexao;
		id_conexao = CACIC_Utils::leTag(resposta, "ID_CONEXAO");

		string nm_usuario_completo;
		nm_usuario_completo = CACIC_Utils::leTag(resposta, "NM_USUARIO_COMPLETO");

		string dt_hr_inicio_sessao;
		dt_hr_inicio_sessao = CACIC_Utils::leTag(resposta, "DT_HR_INICIO_SESSAO");

		string nm_usuario_completo_dec;
		nm_usuario_completo_dec.append(CACIC_Crypt::decodifica(nm_usuario_completo.c_str()));

		string te_documento_referencial_dec;
		te_documento_referencial_dec.append(CACIC_Crypt::decodifica(te_documento_referencial));

		string te_motivo_conexao_dec;
		te_motivo_conexao_dec.append(CACIC_Crypt::decodifica(te_motivo_conexao));

		string dt_hr_inicio_sessao_dec;
		dt_hr_inicio_sessao_dec.append(CACIC_Crypt::decodifica(dt_hr_inicio_sessao.c_str()));

		// cria um novo usuário com os dados pegos da resposta
		ClienteSRC novoCliente = {0};
		novoCliente.vncCID = vncCID;
		novoCliente.id_usuario_visitante = id_usuario_cli;
		novoCliente.id_conexao = id_conexao;
		novoCliente.nm_usuario_completo = nm_usuario_completo_dec;
		novoCliente.te_node_address_visitante = te_node_address_cli;
		novoCliente.te_documento_referencial = te_documento_referencial_dec;
		novoCliente.te_motivo_conexao = te_motivo_conexao_dec;
		novoCliente.te_so_visitante = te_so_cli;
		novoCliente.dt_hr_inicio_sessao = dt_hr_inicio_sessao_dec;
		novoCliente.peerName = peerName;

		// adiciona o novo usuario a lista de usuarios visitantes
		m_listaClientes.push_back(novoCliente);
		
		m_novoCliente = novoCliente;

		m_infoDlg.m_nomeVisitante = m_novoCliente.nm_usuario_completo;
		m_infoDlg.m_dataInicio = m_novoCliente.dt_hr_inicio_sessao;
		m_infoDlg.m_ip = m_novoCliente.peerName;
		m_infoDlg.m_documentoReferencia = m_novoCliente.te_documento_referencial;

		return true;
	}
	catch(SRCException ex)
	{
		MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		vnclog.Print(LL_SRLOG, VNCLOG(ex.getMessage().c_str()));
		return false;
	}
}


void CACIC_Auth::atualizaSessao()
{
	// Verifica, antes de atualizar a sessão, se a palavra 
	// chave foi trocada enquanto o servidor estava aberto.
	FILE *pFile;
	string filePath = m_tempPath + CACIC_Auth::COOKIE_FILENAME;
	pFile = fopen(filePath.data(), "r");
	char newKey[256];

	if(pFile != NULL)
	{
		if (fgets(newKey, 256, pFile))
			m_palavraChave = newKey;

		fclose(pFile);
		remove(filePath.data());
	}

	string post = getPostComum();

	post += "&id_sessao=";
	post += m_idSessao;

	if (m_listaClientes.empty())
	{
		post += "&id_usuario_visitante=";
		post += "pibWRa7Dc7gciUJjHEB4Ww==";
		post += "&id_conexao=";
		post += "pibWRa7Dc7gciUJjHEB4Ww==";
		post += "&te_node_address_visitante=";
		post += "pibWRa7Dc7gciUJjHEB4Ww==";
		post += "&te_so_visitante=";
		post += "pibWRa7Dc7gciUJjHEB4Ww==";
	}
	else
	{
		string listaIDUsuario = "&id_usuario_visitante=";
		string listaIDConexao = "&id_conexao=";
		string listaNodeAddress = "&te_node_address_visitante=";
		string listaID_SO = "&te_so_visitante=";
		for (int i = 0; i < m_listaClientes.size(); i++)
		{
			listaIDUsuario += m_listaClientes[i].id_usuario_visitante;
			if (i < m_listaClientes.size() - 1) listaIDUsuario += "<REG>";
			listaIDConexao += m_listaClientes[i].id_conexao;
			if (i < m_listaClientes.size() - 1) listaIDConexao += "<REG>";
			listaNodeAddress += m_listaClientes[i].te_node_address_visitante;
			if (i < m_listaClientes.size() - 1) listaNodeAddress += "<REG>";
			listaID_SO += m_listaClientes[i].te_so_visitante;
			if (i < m_listaClientes.size() - 1) listaID_SO += "<REG>";
		}
		post += listaIDUsuario;
		post += listaIDConexao;
		post += listaNodeAddress;
		post += listaID_SO;
	}

	string session_script = m_scriptsPath.c_str();
	session_script.append("srcacic_set_session.php");

	char resposta[TAMANHO_RESPOSTA];
	CACIC_Con::sendHtppPost(m_servidorWeb, session_script, post, resposta, TAMANHO_RESPOSTA);

	if (!verificaStatus(resposta))
	{
		MessageBox(NULL, "Ocorreu um erro ao atualizar a sessão! O programa será fechado.", "Erro!", MB_OK | MB_ICONERROR);
		finalizaServidor();
	}

	// verifica se o servidor está sem receber conexão por 
	// mais tempo que o limite, caso esteja, o processo é finalizado.
	if (m_listaClientes.empty())
	{
		m_idleTime--;
		if (m_idleTime <= 0)
		{
			vnclog.Print(LL_SRLOG, "Fechando o servidor por atingir o tempo máximo de idle.");
			finalizaServidor();
		}
	}
	else
	{
		m_idleTime = TEMPO_IDLE;
	}
}

void CACIC_Auth::sendChatText(char te_mensagem[], char cs_origem[])
{
	string te_mensagem_enc = CACIC_Crypt::codifica(te_mensagem);
	string cs_origem_enc = CACIC_Crypt::codifica(cs_origem);

	string post;
	post += "id_sessao=";
	post += m_idSessao;
	post += "&id_conexao=";
	post += m_novoCliente.id_conexao;
	post += "&te_mensagem=";
	post += te_mensagem_enc;
	post += "&cs_origem=";
	post += cs_origem_enc;

	string session_script = m_scriptsPath.c_str();
	session_script.append("srcacic_set_session.php");

	char resposta[TAMANHO_RESPOSTA];
	CACIC_Con::sendHtppPost(m_servidorWeb, session_script, post, resposta, TAMANHO_RESPOSTA);
}

void CACIC_Auth::removeCliente(vncClientId vncCID)
{
	// Atualiza a sessão antes de remover o cliente.
	atualizaSessao();
	m_infoDlg.closeInfoDialog();

	for (int i = 0; i < m_listaClientes.size(); i++)
	{
		if (m_listaClientes[i].vncCID == vncCID)
		{
			m_listaClientes.erase(m_listaClientes.begin() + i);
			return;
		}
	}

	// Apagando os dados do último cliente conectado.
	ClienteSRC novoCliente = {0};
	m_novoCliente = novoCliente;
}

string CACIC_Auth::getPostComum()
{
	string post = "";
	post += "te_so=";
	post += m_soVersion;
	post += "&te_node_address=";
	post += m_nodeAdress;
	post += "&te_palavra_chave=";
	post += m_palavraChave;

	return post;
}

bool CACIC_Auth::verificaStatus(char resposta[])
{
	string status;
	status = CACIC_Utils::leTag(resposta, "STATUS");

	string status_dec;
	status_dec = CACIC_Crypt::decodifica(status.c_str());

	if (status_dec.compare("OK") != 0) return false;

	return true;
}

void CACIC_Auth::finalizaServidor()
{
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
}
