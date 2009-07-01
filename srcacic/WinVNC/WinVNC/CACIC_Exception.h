#ifndef _CACIC_EXCEPTION_
#define _CACIC_EXCEPTION_

#include <windows.h>

// exceção padrao do srCACIC
class SRCException {
private:
	string m_err;
public:
	SRCException(string err) {
		m_err = err;
	}
	string getMessage() {
		return m_err;
	}
};

#endif