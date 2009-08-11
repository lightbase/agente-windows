/**
 * Copyright (C) 2009 DATAPREV-ES
 * @author Vinicius Avellar Moreira
 * Classe com alguns métodos utilitários.
 */

#include "CACIC_Utils.h"

const string CACIC_Utils::F_SANS_SERIF = "Microsoft Sans Serif";

string CACIC_Utils::leTag(char xml[], char tagname[])
{
	char* tag;
	char* a_xml = new char[strlen(xml)];
	strcpy(a_xml, xml);

	// pega o conteudo da tag de resposta tagname
	tag = strtok(a_xml, "<>");
	while (tag != NULL && strcmp(tag, tagname))
	{
		tag = strtok(NULL, "<>");
	}

	string errorMsg = "Falha ao ler arquivo xml.";
	//string errorMsg = "Tag ";
	//errorMsg.append(tagname);
	//errorMsg.append(" não encontrada!");
	if (tag == NULL) throw SRCException(errorMsg);

	tag = strtok(NULL, "<>");
	string content;
	content = tag;

	return content;
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
