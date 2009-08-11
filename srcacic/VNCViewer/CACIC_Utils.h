#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns métodos utilitários.
 */

#include "stdhdrs.h"

#include <Iphlpapi.h>
#pragma comment(lib, "iphlpapi.lib")

#include <math.h>

#include <sstream>

#include "Rijndael.h"
#include "base64.h"

class CACIC_Utils {

public:

	/**
	 * Troca caracteres específicos de uma string.
	 * @param str String a ser modificada.
	 * @param key String com o caractere ou conjunto de caracteres que serão substituídos.
	 * @param newKey String com o caractere ou conjunto de caracteres que irão substituir.
	 */
	static void replaceAll(string &str, string key, string newkey);

	/**
	 * Mesma função do urlEncode, porém os caracteres serão substituídos
	 * por tags específicas, e não pelo código.
	 * @param entrada String que será codificada.
	 */
	static void simpleUrlEncode(string &entrada);

	/**
	 * Faz o inverso do simpleUrlEncode, trocando as tags específicas pelos
	 * respectivos caracteres.
	 * @param entrada String que será codificada.
	 */
	static void simpleUrlDecode(string &entrada);

	/**
	 * Obtém o MAC Address da placa de rede.<br />
	 * TODO: Quando houver mais de uma placa de rede no pc, verificar qual
	 * está se comunicando com o servidor para enviar o MAC certo.
	 */
	static string getMACAddress();

	/**
	 * Obtém a identificação do sistema operacional.<br />
	 * Artigo sobre SOID:<br />
	 * http://www.codeguru.com/cpp/w-p/system/systeminformation/article.php/c8973__2/
	 */
	static string getSOID();

private:

	/**	
	 * Este método virtual puro é um truque para que a classe
	 * se torne abstrata e não possa ser instanciada.
	 */
	virtual void cutils() = 0;

};

#endif
