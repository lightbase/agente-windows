/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe para lidar com as mensagens de erro.
 */

#ifndef _CACIC_EXCEPTION_
#define _CACIC_EXCEPTION_

#include <windows.h>

class SRCException {

private:

	/** Mensagem de erro. */
	string m_err;

public:

	/**
	 * Construtor da classe.
	 * @param err String com a mensagem de erro.
	 */
	SRCException(string err) {
		m_err = err;
	}

	/**
	 * Retorna a mensagem de erro armazenada.
	 * @return string String com a mensagem de erro.
	 */
	string getMessage() {
		return m_err;
	}

};

#endif
