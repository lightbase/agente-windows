#ifndef _CACIC_UTILS_
#define _CACIC_UTILS_

#include <string>
using namespace std;
#include <sstream>
#include <iostream>

#include "CACIC_Exception.h"

class CACIC_Utils {

public:

	static string leTag(char xml[], char tagname[]);

	static void replaceAll(string &str, string key, string newkey);

	static void urlEncode(string &decoded);
	static void urlDecode(string &encoded);

	static void simpleUrlEncode(string &entrada);
	static void simpleUrlDecode(string &entrada);

	static char hexToAscii(char first, char second);
	static void trim(string &str);

private:

	virtual void cutils() = 0; // Truque para tornar a classe abstrata.

};

#endif