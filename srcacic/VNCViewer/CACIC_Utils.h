#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

#include "stdhdrs.h"

#include <Iphlpapi.h>
#pragma comment(lib, "iphlpapi.lib")

#include <math.h>

#include <sstream>

#include "Rijndael.h"
#include "base64.h"

class CACIC_Utils {

public:

	static void replaceAll(string &str, string key, string newkey);

	static void simpleUrlEncode(string &entrada);
	static void simpleUrlDecode(string &entrada);

	static string getMACAddress();
	static string getSOID();

private:

	virtual void cutils() = 0; // Truque para tornar a classe abstrata.

};

#endif
