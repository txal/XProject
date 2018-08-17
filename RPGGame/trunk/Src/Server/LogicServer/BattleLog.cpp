#include "BattleLog.h"
#include "Include/Logger/Logger.hpp"
#include "Common/DataStruct/XTime.h"

BattleLog::BattleLog()
{
	m_bTerminate = false;
	m_oThread.Create(BattleLog::LogThread, this);
}

BattleLog::~BattleLog()
{
	Terminate();
	m_oLock.Lock();
	while (m_oLogList.size() > 0)
	{
		BATTLELOG* pLog = m_oLogList.front();
		m_oLogList.pop_front();
		SAFE_DELETE(pLog);
	}
	m_oLock.Unlock();
}

void BattleLog::AddLog(BATTLELOG* pLog)
{
	m_oLock.Lock();
	m_oLogList.push_back(pLog);
	m_oLock.Unlock();
}

void BattleLog::LogThread(void* param)
{
	BattleLog* pCls = (BattleLog*)param;
	while (!pCls->m_bTerminate)
	{
		BATTLELOG* pLog = NULL;

		pCls->m_oLock.Lock();
		if (pCls->m_oLogList.size() > 0)
		{
			pLog = pCls->m_oLogList.front();
			pCls->m_oLogList.pop_front();
		}
		pCls->m_oLock.Unlock();

		if (pLog != NULL)
		{
			FILE* file = fopen(pLog->oFile.c_str(), "a");
			if (file != NULL)
			{
				fwrite(pLog->oCont.c_str(), 1, pLog->oCont.size(), file);
				fclose(file);
			}
			else
			{
				XLog(LEVEL_ERROR, "Open file %s error!\n", pLog->oFile.c_str());
			}

			SAFE_DELETE(pLog);
		}
		else
		{
			XTime::MSSleep(1);
		}

	}
}
