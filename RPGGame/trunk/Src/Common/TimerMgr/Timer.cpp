#include "Common/TimerMgr/Timer.h"
#include "Common/DataStruct/XMath.h"
#include "Include/Script/Script.hpp"

TimerBase::TimerBase(uint32_t uTimerID, uint32_t uMSTime)
{
	assert(uMSTime > 0);
	m_uTimerTime = uMSTime;
	m_nExpireTime = XTime::MSTime() + m_uTimerTime;
	m_uTimerID = uTimerID;
	m_bCancel = 0;
}

TimerBase::~TimerBase()
{
}


////////////////////////////Cpp timer//////////////////////////////
CTimer::CTimer(uint32_t uTimerID, uint32_t nMSTime, TimerCallback fnCallback, void* pParam) : TimerBase(uTimerID, nMSTime)
{
	m_fnCallback = fnCallback;
	m_pParam = pParam;
}

void CTimer::Execute()
{
	if (m_fnCallback != NULL)
	{
		(*m_fnCallback)(m_uTimerID, m_pParam);
	}
}

void CTimer::Cancel()
{
	m_fnCallback = NULL;
	m_bCancel = 1;
}


//////////////////////////Lua timer//////////////////////////////
LuaTimer::LuaTimer(uint32_t uTimerID, uint32_t nMSTime, int nLuaRef, const char* pWhere) : TimerBase(uTimerID, nMSTime)
{
	m_nLuaRef = nLuaRef;
	//memset(m_sWhere, 0, sizeof(m_sWhere));
	//if (pWhere != NULL)
	//{
	//	int nLen = (int)strlen(pWhere);
	//	const char* pPos = pWhere + XMath::Max(0, nLen - (int)sizeof(m_sWhere) + 1);
	//	strncpy(m_sWhere, pPos, sizeof(m_sWhere)-1);
	//}
}

LuaTimer::~LuaTimer()
{
	UnRef();
	m_bCancel = 1;
	//XLog(LEVEL_DEBUG, "timer destroy: %u (%s)\n", m_uTimerID, m_sWhere);
}

void LuaTimer::Execute()
{
	if (m_nLuaRef == LUA_NOREF)
	{
		return;
	}
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_pushinteger(poLuaWrapper->GetLuaState(), m_uTimerID);
	poLuaWrapper->CallLuaRef(m_nLuaRef, 1);
}

void LuaTimer::Cancel()
{
	UnRef();
	m_bCancel = 1;
}

void LuaTimer::UnRef()
{
	if (m_nLuaRef == LUA_NOREF)
	{
		return;
	}
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	luaL_unref(poLuaWrapper->GetLuaState(), LUA_REGISTRYINDEX, m_nLuaRef);
	m_nLuaRef = LUA_NOREF;
}
