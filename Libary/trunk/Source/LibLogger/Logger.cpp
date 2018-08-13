#include "Include/Logger/Logger.h"
#include "Common/DataStruct/Encoding.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/Thread.h"
#include "Common/DataStruct/TimeMonitor.h"

#ifdef __linux
    #define _pipe pipe2
    #define _fdopen fdopen
    #define _fileno fileno
    #define _dup dup
    #define _dup2 dup2
    #define _close close
#endif

static const
char* psErrLv[LEVEL_COUNT] =
{
	"INFO",
	"ERROR",
	"DEBUG",
	"WARNING",
};

// Max log length
const int nMaxLogLen = 1040;

Logger* Logger::Instance()
{
    static Logger oSingleton;
    Logger* pLogger = &oSingleton;
    return pLogger;
}

Logger::Logger()
{
	m_bTerminate = false;
    memset(m_sLogName, 0, sizeof(m_sLogName));
	memset(m_nPipeFds, -1, sizeof(m_nPipeFds));
}

void Logger::Terminate()
{
	m_bTerminate = true;
	uint8_t uNotify = 1;
	write(m_nPipeFds[1], &uNotify, sizeof(uNotify));
	m_oLogThread.Join();
}

void Logger::Init()
{
#ifdef _WIN32
	mkdir("Log");
#else
	mkdir("Log", 0777);
#endif

#ifdef __linux
    if (_pipe(m_nPipeFds, O_CLOEXEC) == -1)
    {
        return;
    }
#else
    if (_pipe(m_nPipeFds, 0, _O_TEXT) == -1)
    {
       return;
    }
#endif
	//FILE* poStdOutCopy = _fdopen(_dup(STDOUT_FILENO), "w");
	//FILE* m_poStdErrCopy = _fdopen(_dup(STDERR_FILENO), "w");
	//_dup2(m_nPipeFds[1], STDOUT_FILENO);
	//_dup2(m_nPipeFds[1], STDERR_FILENO);
	//_close(m_nPipeFds[1]);
	setvbuf(stdout, NULL, _IONBF, 0);
	setvbuf(stderr, NULL, _IONBF, 0);
	FILE* poPipeWrite = _fdopen(m_nPipeFds[1], "w");
	setvbuf(poPipeWrite, NULL, _IONBF, 0);
    m_oLogThread.Create(Logger::LogThread, this);
}

void Logger::SetLogName(const char* psLogName)
{
    strcpy(m_sLogName, psLogName);
}

void Logger::Print(int nLevel, const char* pFmt, ...)
{
	if (m_bTerminate)
	{
		printf("Logger is closed!\n");
		return;
	}
	if (m_nPipeFds[0] == -1)
	{
		printf("Logger is not initial!\n");
		return;
	}
    nLevel = XMath::Max(0, XMath::Min(nLevel, LEVEL_COUNT - 1));
	if (nLevel == LEVEL_DEBUG)
	{
#ifndef _DEBUG
		return;
#endif
	}

    char sMsg[nMaxLogLen] = { 0 };
    va_list Ap;
    va_start(Ap, pFmt);
    // Will add '\0' auto in linux but not in windows, the same with sprintf
    vsnprintf(sMsg, sizeof(sMsg) - 1, pFmt, Ap);
    va_end(Ap);

	const char* psTarMsg = sMsg;
#ifdef _WIN32
	char sGBKMsg[nMaxLogLen];
	Encoding::UTF8ToGBK(sMsg, sGBKMsg, sizeof(sGBKMsg));
	psTarMsg = sGBKMsg;
#endif

	std::string* poStr = XNEW(std::string)(psTarMsg);
	if (nLevel != LEVEL_DEBUG)
	{
	    time_t nNowSec = time(0);
	    tm* ptm = localtime(&nNowSec);
		char sHeader[256] = { 0 };
		snprintf(sHeader, sizeof(sHeader)-1, "[%s %04d-%02d-%02d %02d:%02d:%02d]: ", psErrLv[nLevel], ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec);
		*poStr = sHeader + *poStr;
	}

    m_oPrintLock.Lock();

	m_oLogList.PushBack(poStr);
	if (m_oLogList.Size() % 8000 == 0)
	{
		std::string* poNotice = XNEW(std::string)("Too many log!\n");
		m_oLogList.PushFront(poNotice);
	}
	if (m_oLogList.Size() == 1)
	{
		uint8_t uNotify = 1;
		int nWrited = write(m_nPipeFds[1], &uNotify, sizeof(uNotify));
		if (nWrited != sizeof(uNotify))
		{
			fprintf(stdout, "write log pipe error: %s\n", strerror(errno));
		}
	}

    m_oPrintLock.Unlock();
}

void Logger::LogThread(void* pParam)
{
    Logger* poLogger = (Logger*)pParam;
    int hReadHandle= poLogger->m_nPipeFds[0];
	for (;;)
	{
		for (;;)
		{
			std::string* poStr = NULL;
			poLogger->m_oPrintLock.Lock();
			if (poLogger->m_oLogList.Size() > 0)
			{
				poStr = poLogger->m_oLogList.Front();
				poLogger->m_oLogList.PopFront();
			}
			poLogger->m_oPrintLock.Unlock();
			if (poStr == NULL)
			{
				break;
			}
			if (poLogger->m_sLogName[0] != 0)
			{
				struct tm oTm;
				time_t nTime = time(NULL);
#ifdef __linux
				localtime_r(&nTime, &oTm);
#else
				localtime_s(&oTm, &nTime);
#endif
				char sDateLogFile[256] = { 0 };
				sprintf(sDateLogFile, "Log/%s_%d%02d%02d", poLogger->m_sLogName, oTm.tm_year + 1900, oTm.tm_mon + 1, oTm.tm_mday);

				FILE* poFile = fopen(sDateLogFile, "a+");
				if (poFile == NULL)
				{
					fprintf(stderr, "Open log file '%s' fail!\n", sDateLogFile);
				}
				else
				{
					fwrite(poStr->c_str(), 1, poStr->size(), poFile);
					fclose(poFile);
				}
				SAFE_DELETE(poStr);
				continue;
			}
			fprintf(stdout, "%s", poStr->c_str());
			SAFE_DELETE(poStr);
		}

		if (poLogger->m_bTerminate)
			break;

		uint8_t uNotify = 0;
		int nReadByte = read(hReadHandle, &uNotify, sizeof(uNotify));
		if (nReadByte != sizeof(uNotify))
			fprintf(stderr, "%s\n", strerror(errno));
    }
}
