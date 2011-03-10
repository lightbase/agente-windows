/**
 * Copyright (C) 2010 DATAPREV-ES
 * @author Filyppe Meneses Coelho
 * @author Roberto Guimarães Morati Jr.
 *
 * Classe para criar post com log da transferencia de arquivos na conexao remota.
 */

#include "CACIC_Auth.h"
#include "CACIC_Crypt.h"

#ifndef _CACIC_FILETRANSFERLOG_
#define _CACIC_FILETRANSFERLOG_

#include <string>
using namespace std;

class CACIC_FileTransferLog {

public:

	/** 
	 * Recebe id_conexao de transferencia
	 * @param id_conexao string
	 */
	void setIdConexao(int id_conexao);

	/**
	*
	*@dt_systemtime
	*/
	void setDtSystemTime(char* dt_systemtime);

	/**
	* Recebe hora inicial
	*@param nu_starttime
	*/
	void setNuStartTime(char* nu_starttime);

	
	/**
	* Recebe hora final
	*@param nu_endtime
	*/
	void setNuEndTime(char* nu_endtime);
	
	/**
	*Recebe o path de origem.
	*@param te_path_origem
	*/
	void setTePathOrigem(char* te_path_origem);

	/**
	*Recebe o path de destino.
	*@param te_path_destino
	*/
	void setTePathDestino(char* te_path_destino);

	/**
	*Recebe o nome do arquivo
	*@rm_arquivo
	*/
	void setNmArquivo(char* nm_arquivo);

	/*
	*Recebe o tamanho 
	*@nu_tamanho_arquivo
	*/
	void setNuTamanhoArquivo(int nu_tamanho_arquivo);

	/**
	*Recebe o status de transferencia do arquivo
	*@param status
	*/
	void setCsStatus(char status);

	
	/**
	*Recebe o tipo de transferência do arquivo.
	*@param operacao
	*/
	void setCsOperacao(char operacao);

	/**
	*Retorna o tempo de duração.
	*@return nu_duracao
	*/
	string getNuDuracao();
	
	/**
	*Retorna post de transferência de arquivo.
	*@return post
	*/
	string getPostFileTransfer();
	

private:

	int id_conexao, nu_tamanho_arquivo;

	char* nu_starttime;
	char* nu_endtime;
	char* dt_systemtime;
	char* te_path_origem;
	char* te_path_destino;
	char* nm_arquivo;

	char status, operacao;

	//virtual void ccrypt() = 0;

};

#endif