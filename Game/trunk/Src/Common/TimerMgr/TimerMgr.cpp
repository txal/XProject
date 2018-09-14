#include "Common/TimerMgr/TimerMgr.h"
#include "Include/Script/Script.hpp"
#include "Common/DataStruct/XTime.h"

int TimerCmpFunc(void* poObj1, void* poObj2)
{
	TimerBase* poTimer1 = (TimerBase*)poObj1;
	TimerBase* poTimer2 = (TimerBase*)poObj2;
	int64_t nExpireTime1 = poTimer1->GetExpireTime();
	int64_t nExpireTime2 = poTimer2->GetExpireTime();
	if (nExpireTime1 == nExpireTime2)
	{
		return 0;
	}
	if (nExpireTime1 > nExpireTime2)
	{
		return 1;
	}
	return -1;
}

TimerMgr* TimerMgr::Instance()
{
	static TimerMgr oSingleton;
	return &oSingleton;
}

TimerMgr::TimerMgr() : m_oTimerHeap(TimerCmpFunc)
{
}

TimerMgr::~TimerMgr()
{
	int nCount = m_oTimerHeap.Size();
	for (int i = 0; i < nCount; i++)
	{
		SAFE_DELETE(m_oTimerHeap[i]);
	}
}

uint32_t TimerMgr::GenTimerID()
{
	static uint32_t uTimerIndex = 0;
	uTimerIndex = uTimerIndex % 0xFFFFFFFF + 1;
	return uTimerIndex;
}

uint32_t TimerMgr::RegisterTimer(uint32_t uMSTime, int nLuaRef, const char* pWhere)
{
	assert(uMSTime >= 0);
	uint32_t uTimerID = GenTimerID();
	assert(m_oTimerMap.find(uTimerID) == m_oTimerMap.end());
	LuaTimer* poTimer = XNEW(LuaTimer)(uTimerID, uMSTime, nLuaRef, pWhere);
	m_oTimerHeap.Push(poTimer);
	m_oTimerMap[uTimerID] = poTimer;
	XLog(LEVEL_DEBUG, "timer count: %d (%s)\n", m_oTimerMap.size(), pWhere);
	if (m_oTimerMap.size() >= 100000)
	{
		XLog(LEVEL_ERROR, "Too many timer count:%d where:%s\n", m_oTimerMap.size(), pWhere);
	}
	return uTimerID;
}

uint32_t TimerMgr::RegisterTimer(uint32_t uMSTime, TimerCallback fnCallback, void* pParam)
{
	assert(uMSTime >= 0);
	uint32_t uTimerID = GenTimerID();
	assert(m_oTimerMap.find(uTimerID) == m_oTimerMap.end());
	CTimer* poTimer = XNEW(CTimer)(uTimerID, uMSTime, fnCallback, pParam);
	m_oTimerHeap.Push(poTimer);
	m_oTimerMap[uTimerID] = poTimer;
	return uTimerID;
}

void TimerMgr::ExecuteTimer(int64_t nNowMS)
{
	for (;;)
	{
		TimerBase* poTimer = m_oTimerHeap.Min();
		if (poTimer == NULL)
		{
			break;
		}
		if (poTimer->GetExpireTime() > nNowMS)
		{
			break;
		}
		if (!poTimer->IsCancel())
		{
			poTimer->Execute();
		}
		m_oTimerCache.PushBack(poTimer);
		bool bRes = m_oTimerHeap.Remove(poTimer);
		assert(bRes);
	}
	//处理过期的计时器(销毁或更新回去)
	for (int i = m_oTimerCache.Size() - 1; i >= 0; --i)
	{
		TimerBase* poTimer = m_oTimerCache[i];
		if (poTimer->IsCancel())
		{
			SAFE_DELETE(poTimer);
		}
		else
		{
			poTimer->UpdateTime(nNowMS);
			m_oTimerHeap.Push(poTimer);
			assert(m_oTimerMap.find(poTimer->GetID()) != m_oTimerMap.end());
		}
	}
	m_oTimerCache.Clear();
}

void TimerMgr::RemoveTimer(uint32_t uTimerID)
{
	TimerIter iter = m_oTimerMap.find(uTimerID);
	if (iter != m_oTimerMap.end())
	{
		TimerBase* poTimer = iter->second;
		m_oTimerMap.erase(iter);
		poTimer->Cancel();
		poTimer->MarkExpire(XTime::MSTime());
		m_oTimerHeap.Update(poTimer);
	}
	else
	{
		XLog(LEVEL_ERROR, "can not found timer:%u\n", uTimerID);
	}
}



////////////Export to lua////////////
static int RegisterTimer(lua_State* pState)
{
	lua_settop(pState, 2);
	int nMSTime = (int)luaL_checkinteger(pState, 1);
	if (nMSTime <= 0)
	{
		return LuaWrapper::luaM_error(pState, "Timer val must > 0: %d", nMSTime);
	}
	luaL_checktype(pState, 2, LUA_TFUNCTION);
	int nLuaRef = luaL_ref(pState, LUA_REGISTRYINDEX);
	luaL_where(pState, 1);
	const char* pWhere = lua_tostring(pState, -1);
	uint32_t uTimerID = TimerMgr::Instance()->RegisterTimer(nMSTime, nLuaRef, pWhere);
	lua_pushinteger(pState, uTimerID);
	return 1;
}

static int CancelTimer(lua_State* pState)
{
	uint32_t uTimerID = (uint32_t)luaL_checkinteger(pState, 1);
	if (uTimerID <= 0)
	{
		return LuaWrapper::luaM_error(pState, "Timer id error");
	}
	TimerMgr::Instance()->RemoveTimer(uTimerID);
	return 0;
}

void RegTimerMgr(const char* psTable)
{
	luaL_Reg _timermgr_func[] =
	{
		{ "RegisterTimer", RegisterTimer },
		{ "CancelTimer", CancelTimer },
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(_timermgr_func, psTable);
}