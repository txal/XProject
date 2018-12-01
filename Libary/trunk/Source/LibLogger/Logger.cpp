#include "Include/Logger/Logger.h"
#include "Common/DataStruct/Encoding.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XThread.h"
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

//日志
struct LOGTITLE 
{
	int8_t level;
	std::string* log;
	LOGTITLE(int8_t _level, const char* _log)
	{
		level = _level;
		log = XNEW(std::string)(_log);
	}
	~LOGTITLE()
	{
		SAFE_DELETE(log);
	}
};

Logger* Logger::Instance()
{
    static Logger oSingleton;
    Logger* pLogger = &oSingleton;
    return pLogger;
}

Logger::Logger()
{
	m_bSync = false;
	m_bTerminate = false;
	strcpy(m_sLogPath, "./Log");
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

void Logger::SetLogFile(const char* psPath, const char* psName)
{
	if (psPath != NULL)
	{
		strcpy(m_sLogPath, psPath);
	}
	if (psName != NULL)
	{
		strcpy(m_sLogName, psName);
	}

	if (m_sLogPath[0] != '\0')
	{
#ifdef _WIN32
		mkdir(m_sLogPath);
#else
		mkdir(m_sLogPath, 0777);
#endif
	}

}

void Logger::Print(int nLevel, const char* pFmt, ...)
{
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

	// 同步打印
	if (m_bSync)
	{
		char sHeader[256] = { 0 };
		if (nLevel != LEVEL_DEBUG)
		{
			struct tm oTm;
			time_t nTime = time(NULL);
#ifdef __linux
			localtime_r(&nTime, &oTm);
#else
			localtime_s(&oTm, &nTime);
#endif
			snprintf(sHeader, sizeof(sHeader) - 1, "(sync)[%s %04d-%02d-%02d %02d:%02d:%02d]: ", psErrLv[nLevel], oTm.tm_year + 1900, oTm.tm_mon + 1, oTm.tm_mday, oTm.tm_hour, oTm.tm_min, oTm.tm_sec);
		}
		fprintf(stdout, "%s%s", sHeader, psTarMsg);
		return;
	}

	LOGTITLE* poLog = XNEW(LOGTITLE)((int8_t)nLevel, psTarMsg);
	if (m_bTerminate)
	{
		fprintf(stdout, "Logger is closed!---%s\n", poLog->log->c_str());
		SAFE_DELETE(poLog);
		return;
	}

    m_oPrintLock.Lock();

	m_oLogList.PushBack(poLog);
	if (m_oLogList.Size() % 1024 == 0)
	{
		LOGTITLE* poLog = XNEW(LOGTITLE)((int8_t)LEVEL_WARNING, "Too many logs!\n");
		m_oLogList.PushFront(poLog);
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
			LOGTITLE* poLog = NULL;
			poLogger->m_oPrintLock.Lock();
			if (poLogger->m_oLogList.Size() > 0)
			{
				poLog = poLogger->m_oLogList.Front();
				poLogger->m_oLogList.PopFront();
			}
			poLogger->m_oPrintLock.Unlock();

			if (poLog == NULL)
			{
				break;
			}

			struct tm oTm;
			time_t nTime = time(NULL);
#ifdef __linux
			localtime_r(&nTime, &oTm);
#else
			localtime_s(&oTm, &nTime);
#endif

			if (poLog->level != LEVEL_DEBUG)
			{
				char sHeader[256] = { 0 };
				snprintf(sHeader, sizeof(sHeader)-1, "[%s %04d-%02d-%02d %02d:%02d:%02d]: ", psErrLv[poLog->level], oTm.tm_year + 1900, oTm.tm_mon + 1,oTm.tm_mday, oTm.tm_hour, oTm.tm_min, oTm.tm_sec);
				*poLog->log  = sHeader + *poLog->log;
			}

			if (poLogger->m_sLogName[0] != 0)
			{
				char sDateLogFile[256] = { 0 };
				sprintf(sDateLogFile, "%s/%s_%d%02d%02d.log", poLogger->m_sLogPath, poLogger->m_sLogName, oTm.tm_year + 1900, oTm.tm_mon + 1, oTm.tm_mday);

				FILE* poFile = fopen(sDateLogFile, "a+");
				if (poFile == NULL)
				{
					fprintf(stderr, "Open log file '%s' fail!\n", sDateLogFile);
				}
				else
				{
					fwrite(poLog->log->c_str(), 1, poLog->log->size(), poFile);
					fclose(poFile);
				}
				SAFE_DELETE(poLog);
				continue;
			}
			fprintf(stdout, "%s", poLog->log->c_str());
			SAFE_DELETE(poLog);
		}

		if (poLogger->m_bTerminate && poLogger->m_oLogList.Size() <= 0)
		{
			break;
		}

		uint8_t uNotify = 0;
		int nReadByte = read(hReadHandle, &uNotify, sizeof(uNotify));
		if (nReadByte != sizeof(uNotify))
		{
			fprintf(stderr, "%s\n", strerror(errno));
		}
    }
}
