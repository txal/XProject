#ifndef __TIMERMGR_H__
#define __TIMERMGR_H__

#include "Common/DataStruct/Array.h"
#include "Common/DataStruct/MinHeap.h"
#include "Common/TimerMgr/Timer.h"

class TimerMgr
{
public:
	typedef std::unordered_map<uint32_t, TimerBase*> TimerMap;
	typedef TimerMap::iterator TimerIter;

public:
	static TimerMgr* Instance();
	~TimerMgr();

	uint32_t RegisterTimer(uint32_t uMSTime, int nLuaRef, const char* pWhere = NULL);
	uint32_t RegisterTimer(uint32_t uMSTime, TimerCallback fnCallback, void* pParam);

	void ExecuteTimer(int64_t nNowMS);
	void RemoveTimer(uint32_t uTimerID);

protected:
	uint32_t GenTimerID();

private:
	TimerMgr();
	TimerMap m_oTimerMap;
	MinHeap<TimerBase*> m_oTimerHeap;
	Array<TimerBase*> m_oTimerCache;
    DISALLOW_COPY_AND_ASSIGN(TimerMgr);
};


/////////////export to lua/////////////
void RegTimerMgr(const char* psTable);

#endif