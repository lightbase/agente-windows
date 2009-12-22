/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe para criptografia de dados.
 */

#ifndef _CACIC_CRYPT_
#define _CACIC_CRYPT_

#include <string>
using namespace std;

class CACIC_Crypt {

public:

	/**
	 * Remove da String de entrada os caracteres colocados pela URLEncode, 
	 * tira do Base64 e depois decodifica usando o Rijndael.
	 * @param entrada String a ser decodificada.
	 * @param saida String decodificada.
	 */
	static string decodifica(const char* entrada);

	/**
	 * Codifica a String passada com o algoritmo Rijndael e coloca no Base64.
	 * @param entrada String a ser codificada.
	 * @param saida String codificada.
	 */
	static string codifica(const char* entrada);

private:

	/** Tamanho padrão do bloco. */
	static const unsigned int SRCACIC_BLOCK_SIZE;
	/** Tamanho padrão da chave. */
	static const unsigned int SRCACIC_KEY_SIZE;
	/** Chave de codificação. */
	static const char SRCACIC_KEY[17];
	/** Vetor de inicialização. */
	static const char SRCACIC_IV[17];

	/**	
	 * Este método virtual puro é um truque para que a classe
	 * se torne abstrata e não possa ser instanciada.
	 */
	virtual void ccrypt() = 0;
};

#endif
