#include "CACIC_Utils.h"

void CACIC_Utils::replaceAll(string &str, string key, string newkey)
{
	int found = str.find(key, 0);
	while (found < str.length()) {
		if (found != string::npos) {
			str.replace(found, key.length(), newkey);
			found = str.find(key, found);
		}
	}
}

void CACIC_Utils::simpleUrlEncode(string &decoded)
{
	replaceAll(decoded, "+", "<MAIS>");
	replaceAll(decoded, " ", "<ESPACE>");
	replaceAll(decoded, "\"", "<AD>");
	replaceAll(decoded, "'", "<AS>");
	replaceAll(decoded, "\\", "<BarrInv>");
}

void CACIC_Utils::simpleUrlDecode(string &encoded)
{
	replaceAll(encoded, "<MAIS>", "+");
	replaceAll(encoded, "<ESPACE>", " ");
	replaceAll(encoded, "<AD>", "\"");
	replaceAll(encoded, "<AS>", "'");
	replaceAll(encoded, "<BarrInv>", "\\");
}

string CACIC_Utils::getMACAddress() {

	IP_ADAPTER_INFO AdapterInfo[16];			// Allocate information for up to 16 NICs
	DWORD dwBufLen = sizeof(AdapterInfo);		// Save the memory size of buffer

	DWORD dwStatus = GetAdaptersInfo(			// Call GetAdapterInfo
		AdapterInfo,							// [out] buffer to receive data
		&dwBufLen);								// [in] size of receive data buffer
	assert(dwStatus == ERROR_SUCCESS);			// Verify return value is valid, no buffer overflow

	PIP_ADAPTER_INFO pAdapterInfo = AdapterInfo;// Contains pointer to current adapter info
	//do {
	//	PrintMACaddress(pAdapterInfo->Address); // Print MAC address
	//	pAdapterInfo = pAdapterInfo->Next;    // Progress through linked list
	//} while(pAdapterInfo);                    // Terminate if last adapter

	char mac[18];
	
	sprintf(mac, "%02X-%02X-%02X-%02X-%02X-%02X", 
		pAdapterInfo->Address[0], pAdapterInfo->Address[1], pAdapterInfo->Address[2],
		pAdapterInfo->Address[3], pAdapterInfo->Address[4], pAdapterInfo->Address[5]);

	string macstr = mac;

	return macstr;

}

string CACIC_Utils::getSOID() {
	OSVERSIONINFO osver;
	ZeroMemory(&osver, sizeof(OSVERSIONINFO));
	osver.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	GetVersionEx(&osver);

	std::stringstream spid;
	std::stringstream smajorv;
	std::stringstream sminorv;
	std::stringstream csd;

	std::string soIDStr;
	
	spid << osver.dwPlatformId;
	soIDStr = spid.str();
	smajorv << osver.dwMajorVersion;
	soIDStr += ".";
	soIDStr += smajorv.str();
	sminorv << osver.dwMinorVersion;
	soIDStr += ".";
	soIDStr += sminorv.str();

	int major;
	smajorv >> major;
	int minor;
	sminorv >> minor;
	if (major <= 4)
	{//         Win95          Win98         WinME
		if (minor == 0 || minor == 10 || minor == 90)
		{
			if (osver.szCSDVersion != NULL)
			{
				csd << osver.szCSDVersion;
				soIDStr += ".";
				soIDStr += csd.str();
			}
		}
	}
	else
	{// Win2K acima
		OSVERSIONINFOEX osverex;
		ZeroMemory(&osverex, sizeof(OSVERSIONINFOEX));
		osverex.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
		GetVersionEx((LPOSVERSIONINFOA) &osverex);

		soIDStr += ".";
		switch (osverex.wProductType)
		{
			case VER_NT_WORKSTATION: soIDStr += "1"; break;
			case VER_NT_DOMAIN_CONTROLLER: soIDStr += "2"; break;
			case VER_NT_SERVER: soIDStr += "3"; break;
		}

		std::stringstream scsd;
		scsd << osverex.wSuiteMask;
		soIDStr += ".";
		soIDStr += scsd.str();
	}

	return soIDStr;
}
