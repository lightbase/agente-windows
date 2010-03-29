//  Copyright (C) 2002 RealVNC Ltd. All Rights Reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
// If the source code for the program is not available from the place from
// which you received this file, check http://www.realvnc.com/ or contact
// the authors on info@realvnc.com for information on obtaining it.

// Log.cpp: implementation of the VNCLog class.
//
//////////////////////////////////////////////////////////////////////

#include "stdhdrs.h"
#include <io.h>
#include "VNCLog.h"

#include "CACIC_Con.h"
#include "CACIC_Auth.h"

using namespace std;

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

const int VNCLog::ToDebug   =  1;
const int VNCLog::ToFile    =  2;
const int VNCLog::ToConsole =  4;
// modo de envio para o script que tratara o log 
// o enviando para o banco de dados
const int VNCLog::ToScript =  8;

static const int LINE_BUFFER_SIZE = 1024;



//static const string srVersion = "2.6.0.0";

VNCLog::VNCLog()
    : m_tofile(false)
    , m_todebug(false)
    , m_toconsole(false)
	, m_toscript(false) // ADICIONADO
    , m_mode(0)
    , m_level(0)
    , hlogfile(NULL)
    , m_filename(NULL)
    , m_append(false)
    , m_lastLogTime(0)
{
}

void VNCLog::SetMode(int mode)
{
	m_mode = mode;

	// ---> modo de log adicionado
	if (mode & ToScript)  {
		m_toscript = true;
	} else {
		m_toscript = false;
    }

    if (mode & ToDebug)
        m_todebug = true;
    else
        m_todebug = false;

    if (mode & ToFile)  {
		if (!m_tofile)
			OpenFile();
	} else {
		CloseFile();
        m_tofile = false;
    }
  
    if (mode & ToConsole) {
        if (!m_toconsole) {
            AllocConsole(); //lint !e534
            fclose(stdout);
            fclose(stderr);
#ifdef _MSC_VER
            int fh = _open_osfhandle((long)GetStdHandle(STD_OUTPUT_HANDLE), 0);
            _dup2(fh, 1);
            _dup2(fh, 2);
            _fdopen(1, "wt");
            _fdopen(2, "wt");
            printf("fh is %d\n",fh);
            fflush(stdout);
#endif
        }

        m_toconsole = true;

    } else {
        m_toconsole = false;
    }
}


void VNCLog::SetLevel(int level) {
    m_level = level;
}

void VNCLog::SetFile(const char* filename, bool append) 
{
	//SetMode(2);
	//SetLevel(10);
	if (m_filename != NULL)
		free(m_filename);
	m_filename = _strdup(filename);
	m_append = append;
	if (m_tofile)
		OpenFile();
}

void VNCLog::OpenFile()
{
	// Is there a file-name?
	if (m_filename == NULL)
	{
        m_todebug = true;
        m_tofile = false;
        Print(0, "Error opening log file");
		return;
	}

    m_tofile  = true;
    
	// If there's an existing log and we're not appending then move it
	if (!m_append)
	{
		// Build the backup filename
		char *backupfilename = new char[strlen(m_filename)+5];
		if (backupfilename)
		{
			strcpy(backupfilename, m_filename);
			strcat(backupfilename, ".bak");
			// Attempt the move and replace any existing backup
			// Note that failure is silent - where would we log a message to? ;)
			MoveFileEx(m_filename, backupfilename, MOVEFILE_REPLACE_EXISTING);
			delete [] backupfilename;
		}
	}

	CloseFile();

    // If filename is NULL or invalid we should throw an exception here
    hlogfile = CreateFile(
        m_filename,  GENERIC_WRITE, FILE_SHARE_READ, NULL,
        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL  );
    
    if (hlogfile == INVALID_HANDLE_VALUE) {
        // We should throw an exception here
        m_todebug = true;
        m_tofile = false;
        Print(0, "Error opening log file %s", m_filename);
    }
    if (m_append) {
        SetFilePointer( hlogfile, 0, NULL, FILE_END );
    } else {
        SetEndOfFile( hlogfile );
    }
}

// if a log file is open, close it now.
void VNCLog::CloseFile() {
    if (hlogfile != NULL) {
        CloseHandle(hlogfile);
        hlogfile = NULL;
    }
}

inline void VNCLog::ReallyPrintLine(const char* line) 
{
	// pega a data e hora local
	time_t now = time(0);
    struct tm ts;
    char data_buf[20];

    ts = *localtime(&now);
	strftime(data_buf, sizeof(data_buf), "%d/%m %X", &ts);
	
	if (m_toscript) enviaLog(data_buf, (char*)line, SCRIPT); // ADICIONADO
    if (m_todebug) OutputDebugString(line);
    if (m_toconsole) {
        DWORD byteswritten;
        WriteConsole(GetStdHandle(STD_OUTPUT_HANDLE), line, strlen(line), &byteswritten, NULL); 
    };
    if (m_tofile && (hlogfile != NULL)) {
		string strLine;
		strLine.append(data_buf);
		strLine.append(" : ");
		strLine.append("[Suporte Remoto]");
		
		//if (/*Verificar modo DEBUG!*/){
		//	strLine.append(" (");
		//	strLine.append(/*Funcao de retorno da Versao: v.2.6.0.0*/);
		//	strLine.append(")");
		//	strLine.append(" DEBUG -");
		//}

		if (IsDebugModeON()) {
			strLine.append(" (v.");
			strLine.append(SRVersion());
			strLine.append(")");
			strLine.append(" DEBUG -");
		}

		strLine.append(" ");
		strLine.append(line);
        DWORD byteswritten;
		WriteFile(hlogfile, strLine.c_str(), strLine.length(), &byteswritten, NULL);
	}
}

void VNCLog::ReallyPrint(const char* format, va_list ap) 
{
	//time_t current = time(0);
	//if (current != m_lastLogTime) {
	//	m_lastLogTime = current;
	//	ReallyPrintLine(ctime(&m_lastLogTime));
	//}

	// - Write the log message, safely, limiting the output buffer size
	TCHAR line[(LINE_BUFFER_SIZE * 2) + 1]; // sf@2006 - Prevents buffer overflow
	TCHAR szErrorMsg[LINE_BUFFER_SIZE];
	DWORD  dwErrorCode = GetLastError();
    _vsnprintf(line, LINE_BUFFER_SIZE, format, ap);
	SetLastError(0);
    if (dwErrorCode != 0) {
	    FormatMessage( 
             FORMAT_MESSAGE_FROM_SYSTEM, NULL, dwErrorCode,
			 //FORMAT_MESSAGE_IGNORE_INSERTS, NULL, dwErrorCode,
			 //FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, dwErrorCode,
             MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),(char *)&szErrorMsg,
             LINE_BUFFER_SIZE, NULL);
	strcat(line," -- ");
	strcat(line,szErrorMsg);
    }
	else strcat(line,"\r\n");
	ReallyPrintLine(line);
}


VNCLog::~VNCLog()
{
	if (m_filename != NULL)
		free(m_filename);
    try
    {
        CloseFile();
    }
    catch(...)
    {
    }
}

bool VNCLog::IsDebugModeON(){
//	LPCTSTR diretorio_debugs;

/**	Trecho especifico para teste com o Path fixo do Cacic.
	string caminho = "C:\\Cacic\\Temp\\debugs";
	diretorio_debugs = caminho.c_str();
*/

//	LPTSTR diretorio_corrente;
//	string diretorio;
//	string diretorio = "Temp\\debugs";
//	SetCurrentDirectory("..");
//	GetCurrentDirectory(MAX_PATH,diretorio_corrente);
//	diretorio.append(diretorio_corrente);
//	diretorio.replace(diretorio.begin(),diretorio.end(),'\',"\\");
//	diretorio.append ("Temp\\debugs");
/*
	diretorio_corrente = (LPTSTR)diretorio.c_str();
	MessageBox (NULL,diretorio_corrente,"Warning! Nussa!!! o.O", MB_OKCANCEL| MB_ICONASTERISK);
*/
//	diretorio_debugs = diretorio.c_str();

	HANDLE hDir = CreateFile("Temp\\debugs",
		GENERIC_ALL,
		FILE_SHARE_READ,
		NULL,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS,
		NULL);
	if (hDir == INVALID_HANDLE_VALUE){
		CloseHandle(hDir);
		return false;
	}

	FILETIME dirCreationTime;
	SYSTEMTIME dirCreationTimeSystem, currentSystemTime;

	if (GetFileTime(hDir, &dirCreationTime, NULL, NULL)) {
        FileTimeToSystemTime (&dirCreationTime,&dirCreationTimeSystem);
        GetSystemTime(&currentSystemTime);
		CloseHandle(hDir);
		if (CACIC_Utils::DateCompare (currentSystemTime,dirCreationTimeSystem) == 0){
            return true;
		}
		else {
            return false;
		}
    }
	CloseHandle(hDir);
    return false;
}

void VNCLog::GetLastErrorMsg(LPSTR szErrorMsg) const {

   DWORD  dwErrorCode = GetLastError();

   // Format the error message.
   FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER 
         | FORMAT_MESSAGE_FROM_SYSTEM, NULL, dwErrorCode,
         MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPSTR) &szErrorMsg,
         0, NULL);
}

// Envia o log passado para o servidor.
void VNCLog::enviaLog(char data[], char log[], char script[])
{
	string servidor = CACIC_Auth::getInstance()->getServidorWeb();
	if (servidor.empty()) return;

	string post = CACIC_Auth::getInstance()->getPostComum();
	post = "te_data_log=";
	post += data;
	post += "&te_log=";
	post += log;

	CACIC_Con m_con;
	m_con.setServer(servidor.c_str());
	try
	{
		m_con.conecta();
		m_con.sendRequest(HTTP_POST, script, (char*)post.data());
	}
	catch(SRCException ex)
	{
		MessageBox(NULL, ex.getMessage().c_str(), "Erro!", MB_OK | MB_ICONERROR);
		return;
	}
}
