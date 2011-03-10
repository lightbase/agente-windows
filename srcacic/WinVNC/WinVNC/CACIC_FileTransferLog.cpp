/**
* Copyright (C) 2010 DATAPREV-ES
* @author Filyppe Meneses Coelho
* @author Roberto Guimarães Morati Jr.
*
* Classe para criar post com log da transferencia de arquivos na conexao remota.
*/

#include "CACIC_FileTransferLog.h"

void CACIC_FileTransferLog::setIdConexao(int id_conexao){
	this->id_conexao =  id_conexao;
}

void CACIC_FileTransferLog::setDtSystemTime(char* dt_systemtime){
	this->dt_systemtime = dt_systemtime;
}

void CACIC_FileTransferLog::setNuStartTime(char* nu_starttime){
	this->nu_endtime = nu_endtime;
}

void CACIC_FileTransferLog::setNuEndTime(char* nu_endtime){
	this->nu_endtime = nu_endtime;
}

string CACIC_FileTransferLog::getNuDuracao(){
    
	string nu_duracao = "";
	
	float min1=0,min2=0,duracao;
	
	//tratando hora inicial e final
	min1 = nu_starttime[0];
	min2 = nu_endtime[0];
	
	min1 += (nu_starttime[1] * 10);
	min2 += (nu_endtime[1] * 10);

	min1 += (nu_starttime[3] * 60);
	min2 += (nu_endtime[3] * 60);

	//if(strlen(nu_starttime)==5) {
		min1 += (nu_starttime[4] * 600);
	//}

	//if(strlen(nu_starttime)==5) {
		min2 += (nu_endtime[4] * 600);
	//}

	if(min2 > min1)
		duracao = min2 - min1;
	else
		duracao = (1440 - min1) + min2;

	nu_duracao = "" + (int)(duracao/60);
	nu_duracao += ":" + (((int)duracao)%60);
	
	return nu_duracao;
}

void CACIC_FileTransferLog::setTePathOrigem(char* te_path_origem){
	this->te_path_origem = te_path_origem;
}

void CACIC_FileTransferLog::setTePathDestino(char* te_path_destino){
	this->te_path_destino =  te_path_destino;
}
	
void CACIC_FileTransferLog::setNmArquivo(char* nm_arquivo){
	this->nm_arquivo =  nm_arquivo;
}

void CACIC_FileTransferLog::setNuTamanhoArquivo(int nu_tamanho_arquivo){
	this->nu_tamanho_arquivo = nu_tamanho_arquivo;
}
	
void CACIC_FileTransferLog::setCsStatus(char status){
	this->status = status;
}

void CACIC_FileTransferLog::setCsOperacao(char operacao){
	this->operacao = operacao;
}

string CACIC_FileTransferLog::getPostFileTransfer(){

	string post = CACIC_Auth::getInstance()->getPostComum();

    post += "#fd#dt_systemtime=";
	post += CACIC_Crypt::codifica(dt_systemtime);
	post += "#fd#nu_duracao=";
	post += getNuDuracao();
	post += "#fd#te_path_origem=";
	post += te_path_origem;
	post += "#fd#te_path_destino=";
	post += te_path_destino;
	post += "#fd#nm_arquivo=";
	post += nm_arquivo;
	post += "#fd#nu_tamanho_arquivo=";
	post += nu_tamanho_arquivo;
	post += "#fd#cs_status=";
	post += status;
	post += "#fd#cs_operacao=";
	post += operacao;
	post += "#fd#id_conexao=";
	post += id_conexao;
		
	return post;
}
