/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe para criptografia de dados.
 */

#include "CACIC_Crypt.h"

#include "CACIC_Utils.h"

#include <math.h>

#include "Rijndael.h"
#include "base64.h"

const unsigned int CACIC_Crypt::SRCACIC_BLOCK_SIZE = 16;
const unsigned int CACIC_Crypt::SRCACIC_KEY_SIZE = 16;
const char CACIC_Crypt::SRCACIC_KEY[17] = "CacicBrasil";
const char CACIC_Crypt::SRCACIC_IV[17] = "abcdefghijklmnop";

string CACIC_Crypt::decodifica(const char* entrada)
{
	string decode_base64;
	string entradaStr = string(entrada);

	CACIC_Utils::simpleUrlDecode(entradaStr);

	decode_base64 = base64_decode(entradaStr);

	const unsigned int saidaLen = decode_base64.length();

	const unsigned int buffLen = saidaLen + 1;
	char* saidaBuff = new char[buffLen];
	memset(saidaBuff, 0, buffLen);

	CRijndael oRijndael;
	oRijndael.MakeKey(SRCACIC_KEY, SRCACIC_IV, SRCACIC_KEY_SIZE, SRCACIC_BLOCK_SIZE);
	oRijndael.Decrypt(decode_base64.c_str(), saidaBuff, saidaLen, CRijndael::CBC);

	string saida = string(saidaBuff);
	delete []saidaBuff;
	return saida;
}

string CACIC_Crypt::codifica(const char* entrada)
{
	const unsigned int entradaLen = strlen(entrada);
	const unsigned int saidaLen = (int)ceil((float)(entradaLen)/SRCACIC_BLOCK_SIZE)*SRCACIC_BLOCK_SIZE;

	const unsigned int buffLen = saidaLen + 1;
	char* saidaBuff = new char[buffLen];
	memset(saidaBuff, 0, buffLen);
	char* zerofEntrada = new char[buffLen];
	memset(zerofEntrada, 0, buffLen);

	strncpy(zerofEntrada, entrada, entradaLen);

	CRijndael oRijndael;
	oRijndael.MakeKey(SRCACIC_KEY, SRCACIC_IV, SRCACIC_KEY_SIZE, SRCACIC_BLOCK_SIZE);
	oRijndael.Encrypt(zerofEntrada, saidaBuff, saidaLen, CRijndael::CBC);

	string saida = base64_encode(reinterpret_cast<const unsigned char*>(saidaBuff), saidaLen);
	delete []saidaBuff;
	delete []zerofEntrada;
	return saida;
}
