#ifndef __BATTLELOG_H__
#define __BATTLELOG_H__

#include "Common/Platform.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/Thread.h"

struct BATTLELOG
{
	std::string oFile;
	std::string oCont;
};

class BattleLog
{
public:
	BattleLog();
	virtual ~BattleLog();

public:
	void AddLog(BATTLELOG* pLog);
	void Terminate() { m_bTerminate = true; }

protected:
	static void LogThread(void* param);

private:
	std::list<BATTLELOG*> m_oLogList;
	MutexLock m_oLock;
	Thread m_oThread;
	bool m_bTerminate;

	DISALLOW_COPY_AND_ASSIGN(BattleLog);
};

#endif
