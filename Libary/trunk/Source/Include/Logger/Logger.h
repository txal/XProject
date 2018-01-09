#ifndef __LOGGER_H__
#define __LOGGER_H__

#include "Common/Platform.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/PureList.h"
#include "Common/DataStruct/Thread.h"

// stdin
// stdout
// stderr
// STDOUT_FILENO
// STDERR_FILENO

// It is needed, or the "__LINE__" preprocessor
// directive itself has become a part of the output!
#define LOG_STRINGIFY(x) #x 
#define LOG_TOSTRING(x) LOG_STRINGIFY(x)	
#define LOG_ADDR "[" __FILE__":" LOG_TOSTRING(__LINE__)"]: "

// Log level
enum
{
	LEVEL_INFO,
	LEVEL_ERROR,
	LEVEL_DEBUG,
	LEVEL_WARNING,
	LEVEL_COUNT,
};

class Logger 
{
public:
	static Logger* Instance();
	void Init();

	void SetAndWaitClose();
	void SetLogName(const char* pLogName);
	void Print(int nLevel, const char* pFmt, ...);

private:
	Logger();
    static void LogThread(void* pParam);

private:
	bool m_bClose;
	char m_sLogName[256]; //log name
	int m_nPipeFds[2];
	PureList<std::string*> m_oLogList;
	Thread m_oLogThread;
    MutexLock m_oPrintLock;
	DISALLOW_COPY_AND_ASSIGN(Logger);
};

#define XLog Logger::Instance()->Print

#endif
