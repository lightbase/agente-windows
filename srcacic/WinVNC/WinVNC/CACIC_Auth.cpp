#include "CACIC_Auth.h"

const string CACIC_Auth::GET_CONFIG_SCRIPT = "srcacic_get_config.php";
const string CACIC_Auth::SET_SESSION_SCRIPT = "srcacic_set_session.php";
const string CACIC_Auth::AUTH_CLIENT_SCRIPT = "srcacic_auth_client.php";
const unsigned int CACIC_Auth::TAMANHO_RESPOSTA = 1025;

CACIC_Auth::CACIC_Auth() {}

CACIC_Auth::~CACIC_Auth() {}

// autentica a sessão no servidor web de acordo com os parametros passados
bool CACIC_Auth::autentica()
{
	string post = getPostComum();

	vnclog.Print(LL_SRLOG, VNCLOG("Autenticando o usuário no gerente web.\n"));

	string config_script = m_scriptsPath;
	config_script += GET_CONFIG_SCRIPT;

	char resposta[TAMANHO_RESPOSTA];
	CACIC_Con::sendHtppPost(m_servidorWeb, config_script, post, resposta, TAMANHO_RESPOSTA);

	vector<Dominio> listaDominios;
	if (!verificaAuthChave(resposta, listaDominios)) return false;

	vncPassDlg::EAuthCode authStat;
	if (listaDominios.at(0).id == "0") {
		authStat = vncPassDlg::SEM_AUTENTICACAO;
	} else {
		authStat = vncPassDlg::ESPERANDO_AUTENTICACAO;
	}

	// apresenta o dialogo de autenticação
	vncPassDlg passDlg(listaDominios);
	do
	{
		if (!passDlg.DoDialog(authStat, "")) return 0;

		string nm_nome_acesso_autenticacao;
		nm_nome_acesso_autenticacao = CACIC_Crypt::codifica(passDlg.m_usuario);

		string te_senha_acesso_autenticacao;
		te_senha_acesso_autenticacao = CACIC_Crypt::codifica(passDlg.m_senha);

		string id_servidor_autenticacao;
		id_servidor_autenticacao = CACIC_Crypt::codifica(passDlg.m_dominio);

		post += "&nm_nome_acesso_autenticacao=";
		post += nm_nome_acesso_autenticacao;
		post += "&te_senha_acesso_autenticacao=";
		post += te_senha_acesso_autenticacao;
		post += "&id_servidor_autenticacao=";
		post += id_servidor_autenticacao;

		vnclog.Print(LL_SRLOG, post.data());

		string session_script = m_scriptsPath.c_str();
		session_script.append(SET_SESSION_SCRIPT);

		CACIC_Con::sendHtppPost(m_servidorWeb, session_script, post, resposta, TAMANHO_RESPOSTA);
		
		if(verificaAuthDominio(resposta)) {
			authStat = vncPassDlg::AUTENTICADO;
		} else {
			authStat = vncPassDlg::FALHA_AUTENTICACAO;
		}
	}
	while (authStat != vncPassDlg::AUTENTICADO);

	if (passDlg.m_authStat != vncPassDlg::SEM_AUTENTICACAO)
	{
		string msginfo = "Usuário Autenticado: ";
		msginfo += m_usuario;
		if (!passDlg.DoDialog(vncPassDlg::AUTENTICADO, msginfo)) return 0;
	}

	vnclog.Print(LL_SRLOG, VNCLOG("Autenticação OK!\n"));

	return true;
}

// autentica o técnico que irá realizar o suporte remoto
bool CACIC_Auth::validaTecnico(char nm_usuario_cli[], char te_senha_cli[], char te_node_address_cli[], 
							   char te_documento_referencial[], char te_motivo_conexao[], char te_so_cli[], vncClientId vncCID)
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
							 te_motivo_conexao, te_so_cli, vncCID))
	{
		return false;
	}

	return true;
}

// Verifica o status da chave passada ao agente.
bool CACIC_Auth::verificaAuthChave(char resposta[], vector<Dominio> &listaDominios)
{
	try
	{
		if (!verificaStatus(resposta)) throw SRCException("Falha na verificação da chave!");

		// pega o conteudo da tag de resposta <DOMINIOS>..</DOMINIOS>
		string dominios;
		dominios = CACIC_Utils::leTag(resposta, "SERVIDORES_AUTENTICACAO");

		string dominios_dec;
		dominios_dec = CACIC_Crypt::decodifica(dominios.c_str());

		char* id_dominio = strtok((char*)dominios_dec.data(), ";");
		char* nm_dominio = strtok(NULL, ";");
		
		// pega a lista de dominios e decodifica, adicionando-a no vetor
		while (id_dominio != NULL && nm_dominio != NULL)
		{
			Dominio novoDominio;
			novoDominio.id = id_dominio;
			novoDominio.nome = nm_dominio;

			listaDominios.push_back(novoDominio);

			id_dominio = strtok (NULL, ";");
			nm_dominio = strtok (NULL, ";");
		}

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

// verifica a resposta referente a antenticacao do host
bool CACIC_Auth::verificaAuthDominio(char resposta[])
{
	try
	{
		if (!verificaStatus(resposta)) throw SRCException("Falha na autenticação do usuário.");

		// pega o conteudo da tag de resposta <NM_COMPLETO>..</NM_COMPLETO>
		string nm_completo;
		nm_completo = CACIC_Utils::leTag(resposta, "NM_COMPLETO");

		// decodifica e compara a resposta
		string nome_dec;
		nome_dec.append(CACIC_Crypt::decodifica(nm_completo.c_str()));

		// pega o conteudo da tag de resposta <ID_SESSAO>..</ID_SESSAO>
		string id_sessao;
		id_sessao = CACIC_Utils::leTag(resposta, "ID_SESSAO");

		string nu_timeout_srcacic;
		nu_timeout_srcacic = CACIC_Utils::leTag(resposta, "NU_TIMEOUT_SRCACIC");

		string nu_timeout_srcacic_dec;
		nu_timeout_srcacic_dec = CACIC_Crypt::decodifica(nu_timeout_srcacic.c_str());

		m_usuario = nome_dec;
		m_idSessao = id_sessao;

		/*stringstream timeoutBuffer(nu_timeout_srcacic_dec);
		timeoutBuffer >> this->nuTimeout;
		m_server->SetAutoIdleDisconnectTimeout(this->nuTimeout);*/

		return true;
	}
	catch(SRCException ex)
	{
		MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		vnclog.Print(LL_SRLOG, VNCLOG(ex.getMessage().c_str()));
		return false;
	}
}

// verifica a resposta referente a antenticacao do técnico
bool CACIC_Auth::verificaAuthTecnico(char resposta[], char te_node_address_cli[], char te_documento_referencial[],
						 char te_motivo_conexao[], char te_so_cli[], vncClientId vncCID)
{
	try
	{
		// pega o conteudo da tag de resposta <STATUS>..</STATUS>
		string status;
		status = CACIC_Utils::leTag(resposta, "STATUS");
		// decodifica e compara a resposta
		string status_dec;
		status_dec = CACIC_Crypt::decodifica(status.c_str());

		// neste caso não estou utilizando a função verifica status
		// para poder pegar a resposta de erro que vem na tag STATUS
		if (status_dec.compare("OK") != 0) throw SRCException(status_dec.c_str());

		// pega o conteudo da tag de resposta <ID_USUARIO_CLI>..</ID_USUARIO_CLI>
		string id_usuario_cli;
		id_usuario_cli = CACIC_Utils::leTag(resposta, "ID_USUARIO_CLI");

		// pega o conteudo da tag de resposta <ID_CONEXAO>..</ID_CONEXAO>
		string id_conexao;
		id_conexao = CACIC_Utils::leTag(resposta, "ID_CONEXAO");

		// pega o conteudo da tag de resposta <NM_COMPLETO>..</NM_COMPLETO>
		string nm_usuario_completo;
		nm_usuario_completo = CACIC_Utils::leTag(resposta, "NM_USUARIO_COMPLETO");

		// decodifica e compara a resposta
		string nm_usuario_completo_dec;
		nm_usuario_completo_dec.append(CACIC_Crypt::decodifica(nm_usuario_completo.c_str()));

		string te_documento_referencial_dec;
		te_documento_referencial_dec.append(CACIC_Crypt::decodifica(te_documento_referencial));

		string te_motivo_conexao_dec;
		te_motivo_conexao_dec.append(CACIC_Crypt::decodifica(te_motivo_conexao));

		// pega o conteudo da tag de resposta <DT_HR_INICIO_SESSAO>..</DT_HR_INICIO_SESSAO>
		string dt_hr_inicio_sessao;
		dt_hr_inicio_sessao = CACIC_Utils::leTag(resposta, "DT_HR_INICIO_SESSAO");

		// decodifica e compara a resposta
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

		// adiciona o novo usuario a lista de usuarios visitantes
		m_listaClientes.push_back(novoCliente);
		
		m_novoCliente = novoCliente;

		m_infoDlg.m_nomeVisitante = m_novoCliente.nm_usuario_completo;
		m_infoDlg.m_dataInicio = m_novoCliente.dt_hr_inicio_sessao;

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
	// Verifica se a palavra chave foi trocada enquanto em execução.
	FILE *pFile;
	string filePath = m_tempPath + COOKIE_FILENAME;
	pFile = fopen(filePath.data(), "r");
	char newKey[256];

	// testa se o arquivo foi aberto com sucesso
	if(pFile != NULL)
	{
		if (fgets(newKey, 256, pFile))
			m_palavraChave = newKey;

		fclose(pFile); // libera o ponteiro para o arquivo
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
		string listaidusu = "&id_usuario_visitante=";
		string listaidcon = "&id_conexao=";
		string listanode = "&te_node_address_visitante=";
		string listaidso = "&te_so_visitante=";
		for (int i = 0; i < m_listaClientes.size(); i++)
		{
			listaidusu += m_listaClientes[i].id_usuario_visitante;
			if (i < m_listaClientes.size() - 1) listaidusu += "<REG>";
			listaidcon += m_listaClientes[i].id_conexao;
			if (i < m_listaClientes.size() - 1) listaidcon += "<REG>";
			listanode += m_listaClientes[i].te_node_address_visitante;
			if (i < m_listaClientes.size() - 1) listanode += "<REG>";
			listaidso += m_listaClientes[i].te_so_visitante;
			if (i < m_listaClientes.size() - 1) listaidso += "<REG>";
		}
		post += listaidusu;
		post += listaidcon;
		post += listanode;
		post += listaidso;
	}

	string session_script = m_scriptsPath.c_str();
	session_script.append("srcacic_set_session.php");

	char resposta[TAMANHO_RESPOSTA];
	CACIC_Con::sendHtppPost(m_servidorWeb, session_script, post, resposta, TAMANHO_RESPOSTA);

	if (!verificaStatus(resposta))
	{
		MessageBox(NULL, "Ocorreu um erro ao atualizar a sessão! O programa será fechado.", "Erro!", MB_OK | MB_ICONERROR);
		ExitProcess(0);
		return;
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

// remove o cliente com id vncid da lista de usuarios visitantes
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

CACIC_Auth* CACIC_Auth::getInstance()
{
	if (!m_instance)
	{
		m_instance = new CACIC_Auth();
	}
	return m_instance;
}

// pega os parametros comuns a todos os posts enviados
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

// verifica se a resposta enviada na tag status esta ok
bool CACIC_Auth::verificaStatus(char resposta[])
{
	// pega o conteudo da tag de resposta <STATUS>..</STATUS>
	string status;
	status = CACIC_Utils::leTag(resposta, "STATUS");

	// decodifica e compara a resposta
	string status_dec;
	status_dec = CACIC_Crypt::decodifica(status.c_str());

	if (status_dec.compare("OK") != 0)
	{
		string errorMsg = "Falha na autenticação do usuário no domínio.\n";
		errorMsg += status_dec;
		vnclog.Print(LL_SRLOG, VNCLOG(errorMsg.c_str()));
		return false;
	}

	return true;
}
