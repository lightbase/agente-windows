/* 
 * Classe para criptografia de dados
 */

#include "CACIC_Crypt.h"

const unsigned int CACIC_Crypt::SRCACIC_BLOCK_SIZE = 16;
const unsigned int CACIC_Crypt::SRCACIC_KEY_SIZE = 16;
const char CACIC_Crypt::SRCACIC_KEY[17] = "CacicBrasil";
const char CACIC_Crypt::SRCACIC_IV[17] = "abcdefghijklmnop";

// Tira do base64 e desencripta.
string CACIC_Crypt::decodifica(const char* entrada)
{
	string decode_base64;
	string entradaStr = string(entrada);

	CACIC_Utils::simpleUrlDecode(entradaStr);

	decode_base64 = base64_decode(entradaStr);

	unsigned int saida_len = decode_base64.length();

	char* saida = new char[saida_len + 1];
	memset(saida, 0, saida_len + 1);

	CRijndael oRijndael;
	oRijndael.MakeKey(SRCACIC_KEY, SRCACIC_IV, SRCACIC_KEY_SIZE, SRCACIC_BLOCK_SIZE);
	oRijndael.Decrypt(decode_base64.c_str(), saida, saida_len, CRijndael::CBC);

	string out(saida);

	delete []saida;
	return out;
}

// Encripta e coloca no base64.
string CACIC_Crypt::codifica(const char* entrada)
{
	unsigned int entrada_len = strlen(entrada);
	unsigned int saida_len = (int)ceil((float)(entrada_len)/SRCACIC_BLOCK_SIZE)*SRCACIC_BLOCK_SIZE;

	char* saida = new char[saida_len + 1];
	memset(saida, 0, saida_len + 1);
	char* zerof_entrada = new char[saida_len + 1];
	memset(zerof_entrada, 0, saida_len + 1);

	strncpy(zerof_entrada, entrada, entrada_len);

	CRijndael oRijndael;
	oRijndael.MakeKey(SRCACIC_KEY, SRCACIC_IV, SRCACIC_KEY_SIZE, SRCACIC_BLOCK_SIZE);
	oRijndael.Encrypt(zerof_entrada, saida, saida_len, CRijndael::CBC);

	string encode_base64;
	encode_base64 = base64_encode(reinterpret_cast<const unsigned char*>(saida), saida_len);

	delete []saida;
	delete []zerof_entrada;
	return encode_base64;
}
