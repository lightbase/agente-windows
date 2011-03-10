/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe para envio de requisições html ao gerente web.
 * API das funções wininet:
 * http://msdn.microsoft.com/en-us/library/aa385473(VS.85).aspx
 */

#include "CACIC_Con.h"

#include <sstream>
#include <fstream>

const TCHAR CACIC_Con::DEFAULT_HEADER[] = "Content-Type: application/x-www-form-urlencoded";

void CACIC_Con::conecta()
{
	m_hSession = InternetOpen("CACIC_Con", INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);

	if (!m_hSession)
	{
		throw SRCException("Circuito não disponível para abertura de sessão com o gerente web.");
		return;
	}

	m_hConnect = InternetConnect(m_hSession, m_server,
		INTERNET_DEFAULT_HTTP_PORT, NULL, NULL, INTERNET_SERVICE_HTTP, 0, NULL);

	if (!m_hConnect)
	{
		throw SRCException("Protocolo HTTP não disponível para conexão com o gerente web.");
		return;
	}
}

void CACIC_Con::sendRequest(LPCTSTR metodo, LPCTSTR script, TCHAR frmdata[])
{
	//Arquivo de Debug...
	//ofstream file;
	//file.open("C:/Cacic/m_hRequest.txt");
	//file << "m_hRequest " << m_hRequest << endl;
	//file << "script :" << script << endl;
	//file << "m_hConnect :" << m_hConnect << endl;
	//file << "metodo : " << metodo << endl;

	m_hRequest = HttpOpenRequest(m_hConnect, metodo, script, NULL, NULL, NULL, 0, 1);
	
	if (!m_hRequest)
       {
			DWORD dwErr = GetLastError();
			char message[1000];
			sprintf(message, "Erro ao enviar dados ao script = %u", dwErr);
			MessageBox(NULL, message, "HttpOpenRequest", MB_OK);
			return;
      }


	BOOL result = HttpSendRequest(m_hRequest, CACIC_Con::DEFAULT_HEADER, 
					strlen(CACIC_Con::DEFAULT_HEADER), 
					frmdata, strlen(frmdata));
	
	//file << "FFRMDATA :" << frmdata << endl;
	//file.close();
	if (result == false)
	{
		DWORD dwErr = GetLastError();
        char message[1000];
        sprintf(message, "Erro ao executar send request = %u", dwErr);
        MessageBox(NULL, message, "HttpSendRequest", MB_OK);
	}

}

bool CACIC_Con::getResponse(char buff[], unsigned long sz)
{
	if(!m_hRequest)
	{
		throw SRCException("Não há nenhuma requisição!");
		return false;
	}

	if(InternetReadFile(m_hRequest, buff, sz, &m_lBytesRead))
	{
		if(m_lBytesRead > sz)
		{
			throw SRCException("Buffer overflow!");
			return false;
		}

		buff[m_lBytesRead] = 0;
		return true;
	}

	return false;
}

void CACIC_Con::sendHtppPost(const string &servidor, const string &script, string &post,
							  char resposta[], unsigned long sz)
{
	//Arquivo debug...
	//ofstream file;
	//file.open("C:/Cacic/ConSenHttpPost.txt");
	memset(resposta, 0, sz);
	//file << "Resposta: " << resposta << endl;
	CACIC_Con cCon;
	//file << "Servidor: " << servidor.c_str() << endl;
	cCon.setServer(servidor.c_str());
	//file << "Post: " << post << endl; 
	try
	{
		cCon.conecta();

		CACIC_Utils::simpleUrlEncode(post);
		cCon.sendRequest(HTTP_POST, script.c_str(), (char*) post.c_str());
		BOOL result = cCon.getResponse(resposta, sz);
		if (result == false)
		{
		     MessageBox(NULL, "Error ao obter resposta.", "cCon.getResponse", MB_OK);
		}
		//file << "Resposta: " << resposta << endl;
		
	}
	catch(SRCException ex)
	{
		MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		return;
	}
	//file.close();
}
