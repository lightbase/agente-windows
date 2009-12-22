/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns métodos utilitários.
 */

#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

#include <string>
using namespace std;

#include "windows.h"

/**
 * Struct referente a um usuário cliente.
 */
struct ClienteSRC {
	short vncCID;
	string peerName;
	string id_usuario_visitante; 
	string id_usuario_cli; 
	string id_conexao; 
	string nm_usuario_completo; 
	string te_node_address_visitante; 
	string te_node_address_cli; 
	string te_documento_referencial; 
	string te_motivo_conexao; 
	string te_so_visitante; 
	string te_so_cli; 
	string dt_hr_inicio_sessao; 
};

/**
 * Struct referente a um domínio de autenticação.
 */
struct Dominio {
	Dominio(string p_id, string p_nome) : id(p_id), nome(p_nome) {}
	Dominio() : id(""), nome("") {}
	Dominio(const Dominio& d) : id(d.id), nome(d.nome) {}
	string id;
	string nome;
};

class CACIC_Utils {

public:

	/** Fonte padrão usado nos diálogos. */
	static const string F_SANS_SERIF;

	/**
	 * Método bruto para ler uma tag específica de um arquivo xml.
	 * @param xml String no formato de arquivo xml.
	 * @param tagname String com o nome da tag a ser pesquisada.
	 * @param conteudo String com o conteúdo da tag pesquisada.
	 * @trows CACIC_Exception caso a tag não seja encontrada.
	 */
	static void leTag(char xml[], char tagname[], string &conteudo);

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

	/**
	 * Método para separar a string em partes delimitadas por um, ou um conjunto,
	 * de caracteres.
	 * @param str String a ser tokenizada.
	 * @param tokens Vetor de saída dos tokens gerados.
	 * @param delimiters Delimitadores que serão usados para separar a string.
	 * @note http://www.linuxselfhelp.com/HOWTO/C++Programming-HOWTO-7.html
	 */
	//static void tokenize(const string &str, vector<string> &tokens, const string &delimiters = " ");

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