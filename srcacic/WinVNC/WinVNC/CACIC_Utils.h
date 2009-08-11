/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns métodos utilitários.
 */

#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

#include <string>
using namespace std;
#include <sstream>
#include <iostream>

#include "CACIC_Exception.h"

class CACIC_Utils {

public:

	/** Fonte padrão usado nos diálogos. */
	static const string F_SANS_SERIF;

	/**
	 * Método bruto para ler uma tag específica de um arquivo xml.
	 * @param xml String no formato de arquivo xml.
	 * @param tagname String com o nome da tag a ser pesquisada.
	 * @return String com o conteúdo da tag pesquisada.
	 * @trows CACIC_Exception caso a tag não seja encontrada.
	 */
	static string leTag(char xml[], char tagname[]);

	/**
	 * Troca caracteres específicos de uma string.
	 * @param str String a ser modificada.
	 * @param key String com o caractere ou conjunto de caracteres que serão substituídos.
	 * @param newKey String com o caractere ou conjunto de caracteres que irão substituir.
	 */
	static void replaceAll(string &str, string key, string newkey);

	/**
	 * Codifica a string, removendo os caracteres especiais por %código dos mesmos.
	 * @param decoded String que será codificada.
	 */
	static void urlEncode(string &decoded);

	/**
	 * Decodifica a string, retornando os códigos dos caracteres pelos próprios caracteres.
	 * @param encoded String que será decodificada.
	 */
	static void urlDecode(string &encoded);

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
	 * Transforma o byte em codigo ascii, retornando o char correspondente.
	 * @param first Primeiro hexa do caractere.
	 * @param second Segundo hexa do caractere.
	 * @return Char correspondente ao código ascci encontrado.
	 */
	static char hexToAscii(char first, char second);

	/**
	 * Retira os espaços em branco do começo e fim da string.
	 * @param str String a ser modificada.
	 */
	static void trim(string &str);

	/**
	 * Método para alterar a fonte de um determinado elemento de um diálogo.
	 * @param dlgHandle Handler do diálogo.
	 * @param dlgItem Item do diálogo que terá a fonte trocada.
	 * @param fontSize Tamanho da fonte.
	 * @param fontName Nome da fonte.
	 * @param fontIsBold Define o peso da fonte: true = bold, false = normal.
	 */
	static void changeFont(HWND dlgHandle, int dlgItem, 
						   int fontSize, string fontName, 
						   bool fontIsBold = false);

private:

	/**	
	 * Este método virtual puro é um truque para que a classe
	 * se torne abstrata e não possa ser instanciada.
	 */
	virtual void cutils() = 0;

};

#endif