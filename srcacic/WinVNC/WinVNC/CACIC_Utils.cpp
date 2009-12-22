/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns métodos utilitários.
 */

#include "CACIC_Utils.h"

#include <Iphlpapi.h>
#pragma comment(lib, "iphlpapi.lib")

#include <math.h>

#include <sstream>
#include <iostream>

#include "CACIC_Exception.h"

const string CACIC_Utils::F_SANS_SERIF = "Microsoft Sans Serif";

void CACIC_Utils::leTag(char xml[], char tagname[],  string &conteudo)
{
	// 1 posição maior por causa do null character
	const int xmlLen = strlen(xml) + 1;
	char* a_xml = new char[xmlLen];
	strcpy(a_xml, xml);
	char* tag;

	// pega o conteudo da tag de resposta tagname
	tag = strtok(a_xml, "<>");
	while (tag != NULL && strcmp(tag, tagname))
	{
		tag = strtok(NULL, "<>");
	}

	string errorMsg = "Falha na comunicação com o módulo Gerente WEB.";
	//string errorMsg = "Tag ";
	//errorMsg.append(tagname);
	//errorMsg.append(" não encontrada!");
	if (tag == NULL) throw SRCException(errorMsg);

	tag = strtok(NULL, "<>");
	
	conteudo = string(tag);
	delete a_xml;
}

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

void CACIC_Utils::urlEncode(string &decoded)
{
	string unsafe = "<>.#{}|\^~[]`+/?& ";
	stringstream buff;
	size_t found;
	char temp[8];

	for(int i = 0; i < decoded.length(); i++)
	{
		found = unsafe.find(decoded.at(i));
		if (found != string::npos)
		{
			sprintf_s(temp, "%%%X", decoded.at(i));
			buff << temp;
		}
		else
		{
			buff << decoded.at(i);
		}
	}

	decoded.swap(buff.str());
}

void CACIC_Utils::urlDecode(string &encoded)
{
	string unsafe = "%3C%3E%2E%23%7B%7D%7C%5E%7E%5B%5D%60%2B%2F%3F%26%20";
	stringstream buff;
	size_t found;
	string hexCode;

	stringstream teste;

	for(int i = 0; i < encoded.length(); i++)
	{
		if (encoded.at(i) == '%')
		{
			hexCode = encoded.substr(i + 1, 2);
			found = unsafe.find(hexCode);
			if (found != string::npos)
			{
				buff << hexToAscii(hexCode.at(0), hexCode.at(1));
				i += 2;

				continue;
			}

		}
		buff << encoded.at(i);
	}

	encoded.swap(buff.str());
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

char CACIC_Utils::hexToAscii(char first, char second)
{
	char hex[5], *stop;
	hex[0] = '0';
	hex[1] = 'x';
	hex[2] = first;
	hex[3] = second;
	hex[4] = 0;

	return strtol(hex, &stop, 16);
}

void CACIC_Utils::trim(string &str)
{
  string::size_type pos = str.find_last_not_of(" \t\n\r");
  if(pos != string::npos)
  {
    str.erase(pos + 1);
    pos = str.find_first_not_of(" \t\n\r");
    if(pos != string::npos) str.erase(0, pos);
  }
  else str.erase(str.begin(), str.end());
}


void CACIC_Utils::changeFont(HWND dlgHandle, int dlgItem, int fontSize, string fontName, bool fontIsBold)
{
	HFONT hFont ;
	LOGFONT lfFont;

	memset(&lfFont, 0x00, sizeof(lfFont));
	memcpy(lfFont.lfFaceName, fontName.c_str(), fontName.size());

	lfFont.lfHeight   = fontSize;
	lfFont.lfWeight   = (fontIsBold == true) ? FW_BOLD : FW_NORMAL;
	lfFont.lfCharSet  = ANSI_CHARSET;
	lfFont.lfOutPrecision = OUT_DEFAULT_PRECIS;
	lfFont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
	lfFont.lfQuality  = DEFAULT_QUALITY;

	// Create the font from the LOGFONT structure passed.
	hFont = CreateFontIndirect (&lfFont);

	SendMessage(GetDlgItem(dlgHandle, dlgItem), WM_SETFONT, (int)hFont, MAKELONG(TRUE, 0));
}

//void tokenize(const string &str, vector<string> &tokens, const string &delimiters)
//{
//    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
//    string::size_type pos = str.find_first_of(delimiters, lastPos);
//
//    while (string::npos != pos || string::npos != lastPos)
//    {
//        tokens.push_back(str.substr(lastPos, pos - lastPos));
//
//		lastPos = str.find_first_not_of(delimiters, pos);
//        pos = str.find_first_of(delimiters, lastPos);
//    }
//}

string CACIC_Utils::getMACAddress() {

	IP_ADAPTER_INFO AdapterInfo[16];			// Allocate information for up to 16 NICs
	DWORD dwBufLen = sizeof(AdapterInfo);		// Save the memory size of buffer

	DWORD dwStatus = GetAdaptersInfo(			// Call GetAdapterInfo
		AdapterInfo,							// [out] buffer to receive data
		&dwBufLen);								// [in] size of receive data buffer
	//assert(dwStatus == ERROR_SUCCESS);			// Verify return value is valid, no buffer overflow

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
