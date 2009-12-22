/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe singleton responsável pela autenticação no gerente web.
 */

#ifndef _CACIC_AUTH_
#define _CACIC_AUTH_

#include <vector>
#include <string>
using namespace std;

#include "supInfoDlg.h"

class CACIC_Auth {

public:

	/**
	 * Nome do arquivo temporário de trava.
	 * Utilizado para que o cacic impeça a execução de coletas com o suporte ativo.
	 */
	static const string AGUARDE_FILENAME;

	/**
	 * Tempo máximo que o servidor pode ficar aberto sem conexões. (mins)
	 */
	static const UINT TEMPO_IDLE;

	/** Lista de usuários cliente. */
	vector<ClienteSRC> m_listaClientes;

	/** Último usuário cliente conectado. */
	ClienteSRC m_novoCliente;

	/**
	 * Janela com informações sobre o cliente conectado.
	 * Exibida enquanto há suporte em andamento.
	 */
	supInfoDlg m_infoDlg;

	/**
	 * Variável de decisão sobre o logout do sistema após o suporte.
	 */
	bool m_efetuarLogout;

	/** Singleton. */
	static CACIC_Auth* getInstance()
	{
		if (!m_instance) m_instance = new CACIC_Auth();
		return m_instance;
	}

	/* MÉTODOS DE ENCAPSULAMENTO --> */
	void setServidorWeb(string newServidorWeb) {m_servidorWeb = newServidorWeb;}
	string getServidorWeb() {return m_servidorWeb;}
	void setScriptsPath(string newScriptsPath) {m_scriptsPath = newScriptsPath;}
	void setTempPath(string newTempPath) {m_tempPath = newTempPath;}
	void setSOVersion(char* newSOVersion) {m_soVersion = newSOVersion;}
	void setNodeAdress(char* newNodeAdress) {m_nodeAdress = newNodeAdress;}
	void setPalavraChave(char* newPalavraChave) {m_palavraChave = newPalavraChave;}
	void setPorta(UINT newPorta) {m_porta = newPorta;}
	UINT getPorta() {return m_porta;}
	void setTimeout(UINT newNuTimeout) {m_nuTimeout = newNuTimeout;}
	UINT getTimeout() {return m_nuTimeout;}
	/* <-- MÉTODOS DE ENCAPSULAMENTO */

	/**
	 * Retorna os valores padrão de post, usados na 
	 * comunicação com o gerente web.
	 * te_so, te_node_address, te_palavra_chave
	 * @return String com o post padrão formatado.
	 */
	string getPostComum();

	/**
	 * Remove o usuário cliente da lista.
	 * @param vncCID ID do cliente VNC, utilizado para
	 * diferenciar os clientes, caso haja mais de um.
	 */
	void removeCliente(short vncCID);

	/**
	 * Faz a comunicação com o gerente web para validar a palavra chave
	 * e criar uma nova sessão para o suporte remoto.
	 * @return bool Status da autenticação.
	 */
	bool autentica();

	/**
	 * Se comunica com o gerente web para validar o usuário cliente.
	 * Se o usuário for válido, ele cria uma nova sessão de conexão.
	 * @param nm_usuario_cli String codificada contendo o nome de usuário.
	 * @param te_senha_cli String codificada contendo a senha do usuário.
	 * @param te_node_address_cli String codificada contendo o MAC address do cliente.
	 * @param te_documento_referencial String codificada contendo o Documento de Referência do suporte remoto.
	 * @param te_motivo_conexao String codificada contendo o motivo do suporte remoto.
	 * @param te_so_cli String codificada contendo a identificação do SO do cliente.
	 * @param vncCID ID do cliente VNC.
	 * @param peerName String contendo o endereço ip do cliente.
	 */
	bool validaTecnico(char nm_usuario_cli[], char te_senha_cli[], char te_node_address_cli[],
					   char te_documento_referencial[], char te_motivo_conexao[], char te_so_cli[], 
					   const short vncCID, const char peerName[]);
	
	/**
	 * Se comunica com o gerente web para atualizar a sessão de suporte.
	 */
	void atualizaSessao();

	/**
	 * Envia o log do chat para o gerente web durante o suporte remoto.
	 * @param te_mensagem Mensagem recebida/enviada.
	 * @param cs_origem Origem da mensagem, cliente/servidor.
	 */
	void sendChatText(char te_mensagem[], char cs_origem[]); 

	/** Fecha o servidor. */
	void finalizaServidor();

private:

	/** Singleton. */
	static CACIC_Auth* m_instance;

	CACIC_Auth() {
		m_idleTime = TEMPO_IDLE;
		m_efetuarLogout = true;
	}

	virtual ~CACIC_Auth() {}

	/** Endereço do servidor web. */
	string m_servidorWeb;
	/** Caminho dos scripts no servidor web. */
	string m_scriptsPath;
	/** Caminho estático para a pasta temp do cacic. */
	string m_tempPath;

	/** Usuário host do suporte. */
	string m_usuario;
	/** ID da sessão iniciada pelo usuário host. */
	string m_idSessao;

	/** Versão do sistema operacional do host. */
	string m_soVersion;
	/** MAC Address do host. */
	string m_nodeAdress;
	/** Palavra chave. Utilizada na comunicação com o gerente web. */
	string m_palavraChave;

	/** Porta de escuta. */
	UINT m_porta;
	/** Tempo limite que o srcacic pode ficar ocioso antes de fechar-se. */
	UINT m_nuTimeout;
	/** Tempo que o servidor está ocioso */
	UINT m_idleTime;

	/** Nome do script de configurações do gerente web. */
	static const string GET_CONFIG_SCRIPT;
	/** Nome do script de sessões do gerente web. */
	static const string SET_SESSION_SCRIPT;
	/** Nome do script de autenticação do gerente web. */
	static const string AUTH_CLIENT_SCRIPT;
	/** Tamanho padrão da resposta recebida pela requisição http. */
	static const unsigned int TAMANHO_RESPOSTA;
	/** Nome do arquivo temporário de atualização da palavra chave. */
	static const string COOKIE_FILENAME;

	/**
	 * Apresenta o diálogo de login do usuário host e
	 * valida os dados no gerente web.
	 * @param listaDominios Lista de domínios obtida na autenticação.
	 */
	bool autenticaUsuario(vector<Dominio> &listaDominios);

	/**
	 * Verifica a autenticação da chave no gerente web.
	 * @param resposta Resposta XML gerada na comunicação com o gerente web.
	 * @param listaDominios Lista de domínios obtida na autenticação.
	 */
	bool verificaAuthChave(char resposta[], vector<Dominio> &listaDominios);

	/**
	 * Verifica se a resposta da autenticação do usuário host foi positiva.
	 * @param resposta Resposta XML gerada na comunicação com o gerente web.
	 */
	bool verificaAuthDominio(char resposta[]);

	/**
	 * Verifica se a resposta da autenticação do técnico foi positiva,
	 * armazena o novo cliente na lista e exibe a tela de informações do suporte.
	 * @param nm_usuario_cli String codificada contendo o nome de usuário.
	 * @param te_senha_cli String codificada contendo a senha do usuário.
	 * @param te_node_address_cli String codificada contendo o MAC address do cliente.
	 * @param te_documento_referencial String codificada contendo o Documento de Referência do suporte remoto.
	 * @param te_motivo_conexao String codificada contendo o motivo do suporte remoto.
	 * @param te_so_cli String codificada contendo a identificação do SO do cliente.
	 * @param vncCID ID do cliente VNC.
	 * @param peerName String contendo o endereço ip do cliente.
	 */
	bool verificaAuthTecnico(char resposta[], char te_node_address_cli[], char te_documento_referencial[],
							 char te_motivo_conexao[], char te_so_cli[], 
							 const short vncCID, const char peerName[]);

	/**
	 * Verifica o valor de retorno STATUS que é enviado pelo gerente web
	 * após cada comunicação para confirmar a operação.
	 * <b>Valores retornados:</b><br />
	 * OK: A operação teve êxito.<br />ERRO: A operação falhou.
	 * @param resposta Resposta XML gerada na comunicação com o gerente web.
	 */
	bool verificaStatus(char resposta[]);
};

#endif
