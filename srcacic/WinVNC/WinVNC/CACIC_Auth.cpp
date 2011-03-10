/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 *         Roberto Guimaraes Morati Junior
 *		   Fylippe Meneses Coello
 *
 * Classe singleton responsável pela autenticação no gerente web.
 */

#include "CACIC_Auth.h"

#include <sstream>
#include <fstream>

#include "vncPassDlg.h"

#include "CACIC_Con.h"
#include "CACIC_Crypt.h"
#include "CACIC_Exception.h"
#include "CACIC_Utils.h"
#include "string"
#include <stdlib.h>


using namespace std;

const string CACIC_Auth::GET_CONFIG_SCRIPT = "srcacic_get_config.php";
const string CACIC_Auth::SET_SESSION_SCRIPT = "srcacic_set_session.php";
const string CACIC_Auth::AUTH_CLIENT_SCRIPT = "srcacic_auth_client.php";
const unsigned int CACIC_Auth::TAMANHO_RESPOSTA = 1025;
const string CACIC_Auth::AGUARDE_FILENAME = "Temp/aguarde_srCACIC.txt";
const string CACIC_Auth::COOKIE_FILENAME = "cacic_keyword.txt";
const string CACIC_Auth::TOKEN_FILENAME = "Temp/ck_conexao.ini";
const UINT CACIC_Auth::TEMPO_IDLE = 30;

string ID_SESSAO_CK;
string sm_TempPath;

using namespace std;

bool CACIC_Auth::autentica()
{
	vnclog.Print(LL_SRLOG, VNCLOG("Autenticando o usuário no gerente web."));

	string post = getPostComum();
	//Arquivo de Debug...
	//ofstream file;
	//file.open("C:/Cacic/getPostComum.txt");
	//file << "Post get:" << post.c_str() << endl;
	//file << "Post get :" << post << endl;
	
	
	string config_script = m_scriptsPath;
	config_script += GET_CONFIG_SCRIPT;
	//file << "config_script get :" << config_script << endl;
	char resposta[TAMANHO_RESPOSTA];
    //file << "Send Http Post" << endl;
	//file << "m_servidorWeb " << m_servidorWeb << endl;
	//file << "config_script " << config_script << endl;
	//file << "post " << post << endl;
	//file << "resposta " << resposta << endl;
	//file << "tamanho_respsota " << TAMANHO_RESPOSTA << endl;
	CACIC_Con::sendHtppPost(m_servidorWeb, config_script, post, resposta, TAMANHO_RESPOSTA);

	vector<Dominio> listaDominios;
	/*int i;
	for(i = 0; i <= (int) listaDominios.size() ; i++){
		file << "ID " << listaDominios.at(i).id.c_str() << endl;
		file << "NOME " << listaDominios.at(i).nome.c_str() << endl;
	}*/
	if (!verificaAuthChave(resposta, listaDominios)) return false;

	if (!autenticaUsuario(listaDominios)) return false;

	vnclog.Print(LL_SRLOG, VNCLOG("Autenticação OK!"));
    //file.close();

	return true;
}

bool CACIC_Auth::autenticaUsuario(vector<Dominio> &listaDominios)
{
	string post ;
	char resposta[TAMANHO_RESPOSTA];


	vncPassDlg passDlg(listaDominios);

	if (listaDominios.at(0).id.compare("0") == 0) {
		passDlg.m_authStat = vncPassDlg::SEM_AUTENTICACAO;
	} else {
		passDlg.m_authStat = vncPassDlg::ESPERANDO_AUTENTICACAO;
	}

	// apresenta o dialogo de autenticação
	do{
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

	   
		if (listaDominios.at(0).id.compare("0") == 0) {
			//Usuario sem autenticação
			//Não necessita da atualização da "Janela"
		    return true;
		} else {
			//Usuario autenticado.
			//Ocorre atualização da "Janela" de autenticação.
			if (!passDlg.DoDialog()) return false;
		 }
	}
   
	return true;
}


bool CACIC_Auth::validaTecnico(char nm_usuario_cli[], char te_senha_cli[], char te_node_address_cli[], 
							   char te_documento_referencial[], char te_motivo_conexao[], char te_so_cli[], 
							   const short vncCID, const char peerName[])
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

    //Arquivo token para reconexão do suporte remoto.
	FILE *fileToken = NULL;
	string filePathToken = m_tempPath + CACIC_Auth::TOKEN_FILENAME;

	fileToken = fopen(filePathToken.data(),"w");
	//fileToken = fopen("C:/Cacic/Temp/ck_conexao.ini","w"); 

    fprintf(fileToken, "[startsession]\n");
	fprintf(fileToken, "[startconnection]\n");
	fprintf(fileToken, "m_idSessao=%s\n",ID_SESSAO_CK.c_str());
	fprintf(fileToken, "nm_usuario_cli=%s\n",nm_usuario_cli);
	fprintf(fileToken, "te_senha_cli=%s\n",te_senha_cli);
	
	//Fecha arquivo token
	fclose(fileToken);

	/*FILE *arq = NULL;

	arq = fopen("C:/Cacic/Temp/ck_conexao.ini","w");
	
	fprintf(arq,"[startsession]\n");

    fprintf(arq, "nm_usuario_cli=%s\n",nm_usuario_cli);
	fprintf(arq, "te_senha_cli=%s\n",te_senha_cli);
	
	fclose(arq);*/
	
	string auth_client_script = m_scriptsPath;
	auth_client_script += AUTH_CLIENT_SCRIPT;

	char resposta[TAMANHO_RESPOSTA];
	char ip_cliente[16];

	//(Provisório)
	//Salva ip do cliente para ser utilizado na estação de trabalho de suporte remoto.
	//Após sendHttpPost() peerName irá possuir o IP do servidor.
	sprintf(ip_cliente, "%s",peerName);
    

	CACIC_Con::sendHtppPost(m_servidorWeb, auth_client_script, post, resposta, TAMANHO_RESPOSTA);

	
	
    //Passando ip_cliente no lugar de peerName
	if (!verificaAuthTecnico(resposta, te_node_address_cli, te_documento_referencial, 
							 te_motivo_conexao, te_so_cli, vncCID, ip_cliente))
	{
		m_efetuarLogout = false;
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
		CACIC_Utils::leTag(resposta, "SERVIDORES_AUTENTICACAO", dominios);

		string dominios_dec;
		dominios_dec = CACIC_Crypt::decodifica(dominios.c_str());

		stringstream dominiosStream(dominios_dec);
		string id_dominio;
		string nm_dominio;

		while (getline(dominiosStream, id_dominio, ';') && 
			   getline(dominiosStream, nm_dominio, ';'))
		{ 
			listaDominios.push_back(Dominio(id_dominio, nm_dominio));
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

bool CACIC_Auth::verificaAuthDominio(char resposta[])
{
	try
	{
		if (!verificaStatus(resposta)) return false;//throw SRCException("Falha na autenticação do usuário.");

		string nm_completo;
		CACIC_Utils::leTag(resposta, "NM_COMPLETO", nm_completo);

		string nome_dec;
		nome_dec.append(CACIC_Crypt::decodifica(nm_completo.c_str()));

		string id_sessao;
		CACIC_Utils::leTag(resposta, "ID_SESSAO", id_sessao);

		m_usuario = nome_dec;
		m_idSessao = id_sessao;
        ID_SESSAO_CK = m_idSessao;

		FILE *fileToken = NULL;
	    string filePathToken = m_tempPath + CACIC_Auth::TOKEN_FILENAME;
        fileToken = fopen(filePathToken.data(),"w");
		sm_TempPath = filePathToken;

	    fprintf(fileToken,"[startsession]\n");
	    fprintf(fileToken,"m_idSessao=");
		fprintf(fileToken,"%s\n",ID_SESSAO_CK.c_str());

		fclose(fileToken);


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
						 char te_motivo_conexao[], char te_so_cli[], const short vncCID, const char peerName[])
{
	try
	{
		string status;
		CACIC_Utils::leTag(resposta, "STATUS", status);

		string status_dec;
		status_dec = CACIC_Crypt::decodifica(status.c_str());

		// neste caso não estou utilizando a função verifica status
		// para poder pegar a resposta de erro que vem na tag STATUS
		if (status_dec.compare("OK") != 0) throw SRCException(status_dec.c_str());

		string id_usuario_cli;
		CACIC_Utils::leTag(resposta, "ID_USUARIO_CLI", id_usuario_cli);

		string id_conexao;
		CACIC_Utils::leTag(resposta, "ID_CONEXAO", id_conexao);

		string nm_usuario_completo;
		CACIC_Utils::leTag(resposta, "NM_USUARIO_COMPLETO", nm_usuario_completo);

		string dt_hr_inicio_sessao;
		CACIC_Utils::leTag(resposta, "DT_HR_INICIO_SESSAO", dt_hr_inicio_sessao);

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
		//MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		vnclog.Print(LL_SRLOG, VNCLOG(ex.getMessage().c_str()));
		return false;
	}
}
/**
*Não esta sendo usado nesta versao
*
void CACIC_Auth::verifyTimeOutCon()
{

	time_t now, before = 0;
	now = time(NULL);

	// abre o arquivo e verifica se a hora atual é superior a do arquivo em 30 minutos
	// caso positivo, deleta o arquivo
	FILE * arqT;
	arqT = fopen("C:/Cacic/Temp/last_con_timer.dat","r");
	fscanf(arqT,"%ld",before);

	if((now - before) > 120)
	{
		remove("C:/Cacic/Temp/ck_conexao.ini");
	}	
	
}*/


void CACIC_Auth::atualizaSessao()
{
	// Verifica se a última sessão foi finalizada há mais de 30 minutos
	// verifyTimeOutCon();

	// Verifica, antes de atualizar a sessão, se a palavra 
	// chave foi trocada enquanto o servidor estava aberto.
	FILE *pFile;
	string filePath = m_tempPath + CACIC_Auth::COOKIE_FILENAME;
	pFile = fopen(filePath.data(), "r");
	char newKey[512];

	if(pFile != NULL)
	{
		if (fgets(newKey, 512, pFile))
			m_palavraChave = newKey;		
		fclose(pFile);
		//remove(filePath.data());
	}else{
		 MessageBox(NULL, "Error ao abrir o arquivo cacic_keyword.txt!", "Atualiza Sessao.", MB_OK);
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
		
	//Desabilitado nesta versão. 
	    //FILE *arq = NULL;
		//FILE *arqT = NULL;
		//FILE *arqV = NULL;
		BOOL verif = true;

		// arqT = fopen("C:/Cacic/Temp/last_con_timer.dat","w");
		// arqV = arq;
	    
		/*if(!verificaArq("m_idSessao",ID_SESSAO_CK.c_str(),arqV)){
			 fprintf(arq, "m_idSessao=%s\n",m_idSessao.c_str());
		}*/
		   //time_t now;
		   //now = time(NULL);

		   //fprintf(arqT,"%ld",now);

		for (int i = 0; i < m_listaClientes.size(); i++)
		{
		
		 
			listaIDUsuario += m_listaClientes[i].id_usuario_visitante;
			//if(!verificaArq("id_usuario_visitante",CACIC_Crypt::decodifica(m_listaClientes[i].id_usuario_visitante.c_str()),arqV))
				//fprintf(arq, "id_usuario_visitante=%s\n",CACIC_Crypt::decodifica(m_listaClientes[i].id_usuario_visitante.c_str()).c_str());
			if (i < m_listaClientes.size() - 1) listaIDUsuario += "<REG>";

			listaIDConexao += m_listaClientes[i].id_conexao;
			//if(!verificaArq("id_conexao",CACIC_Crypt::decodifica(m_listaClientes[i].id_conexao.c_str()),arqV))
				//fprintf(arq, "id_conexao=%s\n",CACIC_Crypt::decodifica(m_listaClientes[i].id_conexao.c_str()).c_str());
			if (i < m_listaClientes.size() - 1) listaIDConexao += "<REG>";

			listaNodeAddress += m_listaClientes[i].te_node_address_visitante;
			//fprintf(arq, "%s\n",CACIC_Crypt::decodifica(m_listaClientes[i].te_node_address_visitante.c_str()).c_str());
			if (i < m_listaClientes.size() - 1) listaNodeAddress += "<REG>";

			listaID_SO += m_listaClientes[i].te_so_visitante;
			//fprintf(arq, "%s\n",CACIC_Crypt::decodifica(m_listaClientes[i].te_so_visitante.c_str()).c_str());
			if (i < m_listaClientes.size() - 1) listaID_SO += "<REG>";
		}

		//fclose(arq);
		//arq = NULL;

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
		MessageBox(NULL, "Ocorreu um erro ao atualizar a sessão!! O programa será fechado.", "Erro!", MB_OK | MB_ICONERROR);
		finalizaServidor();
	}

    string filePathToken = m_tempPath + CACIC_Auth::TOKEN_FILENAME;
	// verifica se o servidor está sem receber conexão por 
	// mais tempo que o limite, caso esteja, o processo é finalizado.
	if (m_listaClientes.empty())
	{
		m_idleTime--;

		if(m_idleTime == 15)
		{
			FILE * arqE;
			if((arqE = fopen(filePathToken.data(), "r")) != NULL)
			{
				if(verificaArq("[startconnection]",arqE) == 1)
				{
					fclose(arqE);

					FILE *arq = NULL;
					arq  = fopen(filePathToken.data(),"w");
					fprintf(arq, "[endsession4idle@re-con]\n");
					fclose(arq);
				}
				else
				{
					fclose(arqE);
					m_idleTime = 0;
				}
			}
		}
		if(m_idleTime == 0)
		{
			FILE *arq = NULL;
			arq  = fopen(filePathToken.data(),"w");
			fprintf(arq, "[endsession4idle@srcacic]\n");
			fclose(arq);

			vnclog.Print(LL_SRLOG, "Fechando o servidor por atingir o tempo máximo de ociosidade.");
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

void CACIC_Auth::removeCliente(short vncCID)
{
	// Atualiza a sessão antes de remover o cliente.
	atualizaSessao();

	for (int i = 0; i < m_listaClientes.size(); i++)
	{
		if (m_listaClientes[i].vncCID == vncCID)
		{
			m_listaClientes.erase(m_listaClientes.begin() + i);
			break;
		}
	}

	// Apagando os dados do último cliente conectado.
	ClienteSRC novoCliente = {0};
	m_novoCliente = novoCliente;
	
	// Teste para demonstração ao Anderson
	if (m_efetuarLogout == true) {

		// Envia uma mensagem para o diáligo, dizendo para ele
		// trocar o label que é mostrado.
		//PostMessage(m_infoDlg.hwInfoDlg, WM_LOGOUT_WARNING, 0, 0);

		//Sleep(20000);
		//CACIC_Auth::getInstance()->finalizaServidor();
		//ExitWindowsEx(EWX_LOGOFF | EWX_FORCE, 0);
	}
	else {
		
		// update cookie
		string filePathToken = m_tempPath + CACIC_Auth::TOKEN_FILENAME;
		
		FILE *fileToken = NULL;
		fileToken  = fopen(filePathToken.data(),"w");
		fprintf(fileToken, "[endconnection]\n");
		fclose(fileToken);

		// remove(filePathToken.data());
	}
	m_infoDlg.closeInfoDialog();
	m_efetuarLogout = true;
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
	//Arquivo de debug...
	//ofstream file;
	//file.open("C:/Cacic/post.txt");
	//file << "Post:" << post.c_str() << endl;
	//file << "Post :" << post << endl;
 
	//file.close();
	return post;
}

bool CACIC_Auth::verificaStatus(char resposta[])
{
	string status;
	CACIC_Utils::leTag(resposta, "STATUS", status);

	string status_dec;
	status_dec = CACIC_Crypt::decodifica(status.c_str());
	
	 if (status_dec.compare("OK") != 0){
		 /*ofstream file;
		 file.open("C:/Cacic/respostaVerificaStatus.txt");
		 file << "Respsota codificada: " << resposta << endl;
		 file.close();*/
		// MessageBox(NULL, resposta, "verificaStatus", MB_OK);
		 MessageBox(NULL, status_dec.c_str(), "verificaStatus", MB_OK);
		 return false;
	 }
	// MessageBox(NULL, resposta, "verificaStatus", MB_OK);
	 //MessageBox(NULL, status_dec.c_str(), "verificaStatus", MB_OK);
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


BOOL CACIC_Auth::verificaArq(string name, string value, FILE* arq){

	// o ponteiro arq passa a apontar para o início do arquivo
	rewind(arq);

	if (arq == NULL)
		return false;

	//FILE *arq2;
	char* end;
	char linha[100];
	//arq2 = fopen("linha.txt","a");
	string busca;
	busca = name + "=" + value + "\n";
	

	/*fputs("\n",arq2);
	fputs("\n",arq2);
	fputs("Abriu o arquivo\n",arq2);
	fputs("\n",arq2);
	fputs("\n",arq2);*/
								
	while(true){	
		end = fgets(linha,99,arq);
	 if(end == NULL){
		 //fputs("Fechou o arquivo\n",arq2);
		 //fputs("false\n",arq2);
		//fclose(arq2);
		return false;
	  }else{
		
		 /* fputs(busca.c_str(),arq2);
		  fputs("\n",arq2);
		  fputs(linha ,arq2);
		  fputs("\n",arq2);*/

		  if(strcmp(linha, busca.c_str()) == 0){
			 // fputs("true\n",arq2);
			 // fclose(arq2);
			  return true;
		  }
	   }
	}
}

BOOL CACIC_Auth::verificaArq(string name, FILE* arq){

	// o ponteiro arq passa a apontar para o início do arquivo
	rewind(arq);

	if (arq == NULL)
		return false;

	char* end;
	char linha[100];
	string busca;
	busca = name + "\n";
								
	while(true){	
		end = fgets(linha,99,arq);
	 if(end == NULL){
		return false;
	  }else{
		  if(strcmp(linha, busca.c_str()) == 0){
			  return true;
		  }
	   }
	}
}

bool CACIC_Auth::autorizaReconexao(char nm_usuario_cli[],char te_senha_cli[]){
	bool permissao = false;
	FILE * arq;
	// string filePathToken = sm_tempPath;
	//filePathToken += CACIC_Auth::TOKEN_FILENAME;

	if((arq = fopen(sm_TempPath.data(),"r")) != NULL){
	//arq = fopen(filePathToken.data(),"r");

		if(verificaArq("nm_usuario_cli",nm_usuario_cli,arq) == 1){
			permissao = true;
		}else{
			permissao = false;
		}

		if(verificaArq("te_senha_cli",te_senha_cli,arq) == 1 && permissao == true){
			permissao = true;
		}else {
			permissao = false;
		}
		
		if(verificaArq("m_idSessao",ID_SESSAO_CK,arq) == 1 && permissao == true){
			permissao = true;
		}else {
			permissao = false;
		}
	}
	else{
		arq = fopen(sm_TempPath.data(),"w");
	}

	fclose(arq);
	arq = NULL;

return permissao;
}

void CACIC_Auth::deletaDataServer(){
	//nao implementado
}