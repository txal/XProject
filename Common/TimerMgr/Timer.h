#ifndef __TIMER_H__
#define __TIMER_H__

#include "Common/DataStruct/XTime.h"
#include "Common/Platform.h"

typedef void(*TimerCallback)(uint32_t uTimerID, void* pParam);

class TimerBase
{
public:
	TimerBase(uint32_t uTimerID, uint32_t uMSTime);
	virtual ~TimerBase();

	uint32_t GetID() { return m_uTimerID; }
	int64_t GetExpireTime() { return m_nExpireTime; }
	uint32_t GetTimerTime() { return m_uTimerTime;  }
	void UpdateTime(int64_t nNowMS) { m_nExpireTime = nNowMS + m_uTimerTime; }
	void MarkExpire(int64_t nNowMS) { m_nExpireTime = nNowMS - 1000; }

	int IsCancel() { return m_bCancel; }
	virtual void Cancel() = 0;
	virtual void Execute() = 0;

protected:
	uint32_t m_uTimerID;
	int64_t m_nExpireTime; //MS
	uint32_t m_uTimerTime; //MS
	int8_t m_bCancel; 

	DISALLOW_COPY_AND_ASSIGN(TimerBase);
};

//Cpp timer
class CTimer : public TimerBase
{
public:
	CTimer(uint32_t uTimerID, uint32_t uMSTime, TimerCallback fnCallback, void* pParam);

	virtual void Cancel();
	virtual void Execute();

private:
	TimerCallback m_fnCallback;
	void* m_pParam;
};

//Lua timer
class LuaTimer : public TimerBase
{
public:
	LuaTimer(uint32_t uTimerID, uint32_t uMSTime, int nLuaRef, const char* pWhere = NULL);
	virtual ~LuaTimer();

	virtual void Cancel();
	virtual void Execute();

protected:
	void UnRef();

private:
	int m_nLuaRef;
	//char m_sWhere[32];
};

#endif