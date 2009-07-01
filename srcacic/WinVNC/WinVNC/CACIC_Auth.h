#ifndef _CACIC_AUTH_
#define _CACIC_AUTH_

#include "stdhdrs.h"

#include <vector>
using namespace std;
#include <sstream>
#include <string>
using namespace std;

#include <math.h>

#include "vncPassDlg.h"
#include "supInfoDlg.h"

#include "CACIC_Con.h"
#include "CACIC_Crypt.h"
#include "CACIC_Exception.h"
#include "CACIC_Utils.h"

#include "vncClient.h"

#define AGUARDE_FILENAME "aguarde_srCACIC.txt";
#define COOKIE_FILENAME "cacic_ck.txt";

// struct referente a um usuario remoto
struct ClienteSRC {
	vncClientId vncCID;
	string id_usuario_visitante; 
	string id_usuario_cli; 
	string id_conexao; 
	string nm_usuario_completo; 
	string te_node_address_visitante; 
	string te_node_address_cli; 
	string te_documento_referencial; 
	string te_motivo_conexao; 
	string te_so_visitante; 
	string te_so_cli; 
	string dt_hr_inicio_sessao; 
};

class CACIC_Auth {

public:

	// lista de usuarios remotos
	vector<ClienteSRC> m_listaClientes;

	ClienteSRC m_novoCliente;

	supInfoDlg m_infoDlg;

	static CACIC_Auth* getInstance();

	void setServidorWeb(string newServidorWeb) {m_servidorWeb = newServidorWeb;}
	string getServidorWeb() {return m_servidorWeb;}
	void setScriptsPath(string newScriptsPath) {m_scriptsPath = newScriptsPath;}
	void setTempPath(string newTempPath) {m_tempPath = newTempPath;}
	void setSOVersion(char* newSOVersion) {m_soVersion = newSOVersion;}
	void setNodeAdress(char* newNodeAdress) {m_nodeAdress = newNodeAdress;}
	void setPalavraChave(char* newPalavraChave) {m_palavraChave = newPalavraChave;}
	void setPorta(UINT newPorta) {m_porta = newPorta;}
	UINT getPorta() {return m_porta;}

	string getPostComum();

	void removeCliente(vncClientId vncCID);

	bool autentica();
	bool validaTecnico(char nm_usuario_cli[], char te_senha_cli[], char te_node_address_cli[],
								   char te_documento_referencial[], char te_motivo_conexao[], char te_so_cli[], vncClientId vncCID);
	void atualizaSessao();
	void sendChatText(char te_mensagem[], char cs_origem[]); 

private:

	static CACIC_Auth* m_instance;

	CACIC_Auth();
	virtual ~CACIC_Auth();

	string m_servidorWeb; // endereco do servidor web
	string m_scriptsPath; // caminho dos scripts
	string m_tempPath; // caminho completo para a pasta temp do cacic

	string m_usuario; // usuario host do suporte
	string m_idSessao; // id da sessao iniciada pelo usuario host
	UINT m_nuTimeout; // valor do idle timeout

	string m_soVersion; // versao do sistema operacional do host
	string m_nodeAdress; // mac address do host
	string m_palavraChave; // palavra chave do cacic no momento da ativação do suporte remoto

	UINT m_porta;

	static const string GET_CONFIG_SCRIPT; // caminho para o script de configurações
	static const string SET_SESSION_SCRIPT; // caminho para o script de sessões
	static const string AUTH_CLIENT_SCRIPT; // caminho para o script de autenticação
	static const unsigned int TAMANHO_RESPOSTA; // tamanho maximo aceito pela resposta xml

	bool verificaAuthChave(char resposta[], vector<Dominio> &listaDominios);
	bool verificaAuthDominio(char resposta[]);
	bool verificaAuthTecnico(char resposta[], char te_node_address_cli[], char te_documento_referencial[],
							 char te_motivo_conexao[], char te_so_cli[], vncClientId vncCID);

	bool verificaStatus(char resposta[]);
};

#endif
