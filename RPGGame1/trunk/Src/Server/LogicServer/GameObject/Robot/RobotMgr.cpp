#include "Server/LogicServer/GameObject/Robot/RobotMgr.h"

LUNAR_IMPLEMENT_CLASS(RobotMgr)
{
	LUNAR_DECLARE_METHOD(RobotMgr, CreateRobot),
	LUNAR_DECLARE_METHOD(RobotMgr, GetRobot),
	LUNAR_DECLARE_METHOD(RobotMgr, RemoveRobot),
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
	m_oRobotIDMap.clear();
}

Robot* RobotMgr::CreateRobot(int64_t nObjID, int nRobotID, const char* psName, int nAIID, int8_t nCamp, uint16_t uSyncHPTime)
{
	
	Robot* poRobot = GetRobotByID(nObjID);
	if (poRobot != NULL)
	{
		XLog(LEVEL_ERROR, "CreateRobot %lld exist\n", nObjID);
		return NULL;
	}
	poRobot = XNEW(Robot);
	poRobot->Init(nObjID, nRobotID, psName, nAIID, nCamp, uSyncHPTime);
	m_oRobotIDMap[nObjID] = poRobot;
	return poRobot;
}

Robot* RobotMgr::GetRobotByID(int64_t nObjID)
{
	RobotIDIter iter = m_oRobotIDMap.find(nObjID);
	if (iter != m_oRobotIDMap.end() && !iter->second->IsDeleted())
	{
		return iter->second;
	}
	return NULL;
}

void RobotMgr::RemoveRobot(int64_t nObjID)
{
	Robot* poRobot= GetRobotByID(nObjID);
	if (poRobot == NULL)
	{
		return;
	}
	if (poRobot->GetScene() != NULL)
	{
		XLog(LEVEL_ERROR, "需要先离开场景才能删除对象");
		return;
	}
	poRobot->MarkDeleted();
}

void RobotMgr::Update(int64_t nNowMS)
{
	static int64_t nLastUpdateTime = 0;
	if (nNowMS - nLastUpdateTime < 30)
	{
		return;
	}
	nLastUpdateTime = nNowMS;

	RobotIDIter iter = m_oRobotIDMap.begin();
	RobotIDIter iter_end = m_oRobotIDMap.end();
	for (; iter != iter_end; )
	{
		Robot* poRobot = iter->second;
		if (poRobot->IsDeleted())
		{
			iter = m_oRobotIDMap.erase(iter);
			SAFE_DELETE(poRobot);
			continue;
		}
		if (poRobot->GetScene() != NULL)
		{
			poRobot->Update(nNowMS);
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
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
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
	int64_t nRobotID = (int64_t)luaL_checkinteger(pState, 1);
	Robot* poRobot = GetRobotByID(nRobotID);
	if (poRobot != NULL)
	{
		Lunar<Robot>::push(pState, poRobot);
		return 1;
	}
	return 0;
}

int RobotMgr::RemoveRobot(lua_State* pState)
{
	int64_t nRobotID = (int64_t)luaL_checkinteger(pState, 1);
	RemoveRobot(nRobotID);
	return 0;
}