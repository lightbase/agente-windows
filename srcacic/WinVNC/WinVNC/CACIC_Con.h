// Classe para conexao do vnc com o gerente web do Cacic.
// API das funcoes da classe wininet.h:
// http://msdn.microsoft.com/en-us/library/aa385473(VS.85).aspx

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

static const TCHAR hdrs[] = "Content-Type: application/x-www-form-urlencoded";

class CACIC_Con {

private:

	HINTERNET m_hSession; // handle da sessao
	HINTERNET m_hConnect; // handle da conexao
	HINTERNET m_hRequest; // handle da resposta da requisicao

	unsigned long m_lBytesRead;
	LPCSTR m_server;

public:

	CACIC_Con();
	virtual ~CACIC_Con();

	void setServer(LPCSTR server){m_server = server;}
	LPCSTR getServer(){return m_server;}

	void conecta(); // conecta ao servidor
	// envia uma requisicao ao script atraves de POST/GET
	void sendRequest(LPCTSTR metodo, LPCTSTR script, TCHAR frmdata[]);
	bool getResponse(char buff[], unsigned long sz); // recebe a resposta da execucao do script

	static void sendHtppPost(const string &servidor, const string &script, string &post,
							 char resposta[], unsigned long sz);

};

#endif
