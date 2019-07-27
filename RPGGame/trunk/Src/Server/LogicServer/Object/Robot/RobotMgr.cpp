#include "RobotMgr.h"

LUNAR_IMPLEMENT_CLASS(RobotMgr)
{
	LUNAR_DECLARE_METHOD(RobotMgr, CreateRobot),
	LUNAR_DECLARE_METHOD(RobotMgr, GetRobot),
	{0, 0}
};


RobotMgr::RobotMgr()
{
}

RobotMgr::~RobotMgr()
{
	RobotIDIter iter = m_oRobotIDMap.begin();
	for (iter; iter != m_oRobotIDMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

Robot* RobotMgr::CreateRobot(int nID, int nRobotID, const char* psName, int nAIID, int8_t nCamp, uint16_t uSyncHPTime)
{
	
	Robot* poRobot = GetRobotByID(nID);
	if (poRobot != NULL)
	{
		XLog(LEVEL_ERROR, "CreateRobot %lld exist\n", nID);
		return NULL;
	}
	poRobot = XNEW(Robot);
	poRobot->Init(nID, nRobotID, psName, nAIID, nCamp, uSyncHPTime);
	m_oRobotIDMap[nID] = poRobot;
	return poRobot;
}

Robot* RobotMgr::GetRobotByID(int nID)
{
	RobotIDIter iter = m_oRobotIDMap.find(nID);
	if (iter != m_oRobotIDMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void RobotMgr::Update(int64_t nNowMS)
{
	static float nFRAME_MSTIME = 1000.0f / 30.0f;
	RobotIDIter iter = m_oRobotIDMap.begin();
	RobotIDIter iter_end = m_oRobotIDMap.end();
	for (; iter != iter_end; )
	{
		Robot* poRobot = iter->second;
		if (nNowMS - poRobot->GetLastUpdateTime() >= nFRAME_MSTIME)
		{
			if (poRobot->IsTime2Collect(nNowMS))
			{
				iter = m_oRobotIDMap.erase(iter);
				LuaWrapper::Instance()->FastCallLuaRef<void, CNOTUSE>("OnObjCollected", 0, "ii", poRobot->GetID(), poRobot->GetType());
				SAFE_DELETE(poRobot);
				continue;
			}
			if (poRobot->GetScene() != NULL)
			{
				poRobot->Update(nNowMS);
			}
		}
		iter++;
	}	
}




//////////////////////lua export//////////////////
void RegClassRobot()
{
	REG_CLASS(Robot, false, NULL); 
	REG_CLASS(RobotMgr, false, NULL); 
}

int RobotMgr::CreateRobot(lua_State* pState)
{
	int nObjID = (int)luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	int nAIID = (int)luaL_checkinteger(pState, 4);
	int8_t nCamp = (int8_t)luaL_checkinteger(pState, 5);
	uint16_t uSyncHPTime = (uint16_t)lua_tointeger(pState, 6); //MS time
	uSyncHPTime = uSyncHPTime == 0 ? 333 : uSyncHPTime;
	Robot* poRobot = CreateRobot(nObjID, nConfID, psName, nAIID, nCamp, uSyncHPTime);
	if (poRobot != NULL)
	{
		Lunar<Robot>::push(pState, poRobot);
		return 1;
	}
	return 0;
}

int RobotMgr::GetRobot(lua_State* pState)
{
	int nCharID = (int)luaL_checkinteger(pState, 1);
	Robot* poRobot = GetRobotByID(nCharID);
	if (poRobot != NULL)
	{
		Lunar<Robot>::push(pState, poRobot);
		return 1;
	}
	return 0;
}