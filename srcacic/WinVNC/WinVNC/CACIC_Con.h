/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe para envio de requisições html ao gerente web.
 * API das funções wininet:
 * http://msdn.microsoft.com/en-us/library/aa385473(VS.85).aspx
 */

#ifndef _CACIC_CON_
#define _CACIC_CON_

#include <string>
using namespace std;

#include <windows.h>
#include <wininet.h>

#include "CACIC_Exception.h"
#include "CACIC_Utils.h"

#define HTTP_POST "POST"
#define HTTP_GET "GET"

class CACIC_Con {

private:

	/** Header padrão das requisições. */
	static const TCHAR DEFAULT_HEADER[];

	/** Handler da sessão. */
	HINTERNET m_hSession;
	/** Handler da conexao. */
	HINTERNET m_hConnect;
	/** Handler da resposta da requisição. */
	HINTERNET m_hRequest;

	/** Número de bytes lidos na última requisição. */
	unsigned long m_lBytesRead;
	/** Nome do servidor que sofrerá a ação. */
	LPCSTR m_server;

public:

	CACIC_Con() {}

	/**
	 * Destrutor da classe.
	 * Libera os handlers que estiverem abertos.
	 */
	virtual ~CACIC_Con()
	{
		if(m_hSession != NULL) InternetCloseHandle(m_hSession);
		if(m_hConnect != NULL) InternetCloseHandle(m_hConnect);
		if(m_hRequest != NULL) InternetCloseHandle(m_hRequest);
	}

	/**
	 * Altera o servidor.
	 * @param server String com o nome do servidor.
	 */
	void setServer(LPCSTR server){m_server = server;}

	/**
	 * Retorna o nome do servidor.
	 * @return String com o nome do servidor.
	 */
	LPCSTR getServer(){return m_server;}

	/**
	 * Efetua a conexão com o servidor.
	 */
	void conecta();

	/**
	 * Envia uma requisição ao servidor.
	 * @param metodo String com o tipo da requisição. (GET/POST)
	 * @param script String com o nome do script que será acessado.
	 * @param frmdata String com os dados que irão ser passados como parâmetro ao script.
	 */
	void sendRequest(LPCTSTR metodo, LPCTSTR script, TCHAR frmdata[]);

	/**
	 * Retorna a resposta gerada pelo servidor que recebeu a requisição.
	 * @param buff Buffer para armazenar o resultado da requisição.
	 * @param sz Tamanho do buffer.
	 * @return bool Boleano com o estado da requisição.
	 */
	bool getResponse(char buff[], unsigned long sz);

	/**
	 * Método estático que faz uma requisição ao servidor passado e
	 * já retorna a resposta através do buffer "resposta".
	 * @param servidor String com o nome do servidor.
	 * @param script String com o nome do script.
	 * @param post String com os parãmetros a serem passados ao script.
	 * @param resposta Buffer de resposta da requisição.
	 * @param sz Tamanho da resposta.
	 */
	static void sendHtppPost(const string &servidor, const string &script, string &post,
							 char resposta[], unsigned long sz);

};

#endif
