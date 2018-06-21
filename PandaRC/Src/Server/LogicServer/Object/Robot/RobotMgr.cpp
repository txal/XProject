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

Robot* RobotMgr::CreateRobot(const GAME_OBJID& oID, int nRobotID, const char* psName, int nAIID, int8_t nCamp, uint16_t uSyncHPTime)
{
	
	Robot* poRobot = GetRobotByID(oID);
	if (poRobot != NULL)
	{
		XLog(LEVEL_ERROR, "CreateRobot %lld exist\n", oID.llID);
		return NULL;
	}
	poRobot = XNEW(Robot);
	poRobot->Init(oID, nRobotID, psName, nAIID, nCamp, uSyncHPTime);
	m_oRobotIDMap[oID.llID] = poRobot;
	return poRobot;
}

Robot* RobotMgr::GetRobotByID(const GAME_OBJID& oID)
{
	RobotIDIter iter = m_oRobotIDMap.find(oID.llID);
	if (iter != m_oRobotIDMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void RobotMgr::UpdateRobots(int64_t nNowMS)
{
	RobotIDIter iter = m_oRobotIDMap.begin();
	RobotIDIter iter_end = m_oRobotIDMap.end();
	for (; iter != iter_end; )
	{
		Robot* poRobot = iter->second;
		if (nNowMS - poRobot->GetLastUpdateTime() >= FRAME_MSTIME)
		{
			if (poRobot->IsTimeToCollected(nNowMS))
			{
				iter = m_oRobotIDMap.erase(iter);
				LuaWrapper::Instance()->FastCallLuaRef<void>("OnObjCollected", 0, "ii", poRobot->GetID().llID, poRobot->GetType());
				SAFE_DELETE(poRobot);
				continue;
			}
			if (!poRobot->IsDead() && poRobot->GetScene() != NULL)
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
	int64_t nObjID = luaL_checkinteger(pState, 1);
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
	int64_t nCharID = luaL_checkinteger(pState, 1);
	Robot* poRobot = GetRobotByID(nCharID);
	if (poRobot != NULL)
	{
		Lunar<Robot>::push(pState, poRobot);
		return 1;
	}
	return 0;
}