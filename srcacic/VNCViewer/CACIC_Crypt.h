/* 
 * Classe para criptografia de dados
 */

#ifndef _CACIC_CRYPT_
#define _CACIC_CRYPT_

#include <math.h>

#include "CACIC_Utils.h"

#include "Rijndael.h"
#include "base64.h"

class CACIC_Crypt {

public:

	static string decodifica(const char* entrada);
	static string codifica(const char* entrada);

private:

	static const unsigned int SRCACIC_BLOCK_SIZE; // tamanho padrao do bloco
	static const unsigned int SRCACIC_KEY_SIZE; // tamanho padrao da chave
	static const char SRCACIC_KEY[17]; // chave de en/dec
	static const char SRCACIC_IV[17]; // vetor de inicializacao

	virtual void ccrypt() = 0; // Truque para tornar a classe abstrata.
};

#endif
