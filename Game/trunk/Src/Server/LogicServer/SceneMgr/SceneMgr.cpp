#include "SceneMgr.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/ObjID.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"

char SceneMgr::className[] = "SceneMgr";
Lunar<SceneMgr>::RegType SceneMgr::methods[] =
{
	LUNAR_DECLARE_METHOD(SceneMgr, CreateScene),
	LUNAR_DECLARE_METHOD(SceneMgr, RemoveScene),
	LUNAR_DECLARE_METHOD(SceneMgr, GetScene),
	{0, 0}
};

SceneMgr::SceneMgr()
{
}


SceneMgr::~SceneMgr()
{
}


uint32_t SceneMgr::GenSceneIndex(uint16_t uConfID)
{
	static uint16_t uIndex = 0;
	uIndex = uIndex % 0xFFFF + 1;
	uint32_t nSceneIndex = (int)uIndex << 16 | uConfID;
	return nSceneIndex;
}

Scene* SceneMgr::GetScene(uint32_t uSceneIndex)
{
	SceneIter iter = m_oSceneMap.find(uSceneIndex);
	if (iter != m_oSceneMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void SceneMgr::RemoveScene(uint32_t uSceneIndex)
{
	SceneIter iter = m_oSceneMap.find(uSceneIndex);
	if (iter != m_oSceneMap.end())
	{
		SAFE_DELETE(iter->second);
		m_oSceneMap.erase(iter);
	}
}

void SceneMgr::UpdateScenes(int64_t nNowMS)
{
	static int nLastUpdateTime = 0;
	if (nLastUpdateTime == (int)time(0))
	{
		return;
	}
	nLastUpdateTime = (int)time(0);

	SceneIter iter = m_oSceneMap.begin();
	SceneIter iter_end = m_oSceneMap.end();
	for (; iter != iter_end; )
	{
		Scene* poScene = iter->second;
		if (poScene->IsTimeToCollected(nNowMS))
		{
			iter = m_oSceneMap.erase(iter);
			uint32_t uSceneIndex = poScene->GetSceneIndex();
			LuaWrapper::Instance()->FastCallLuaRef<void>("OnSceneCollected", 0, "I", uSceneIndex);
			SAFE_DELETE(poScene);
			continue;
		}
		else
		{
			poScene->Update(nNowMS);
		}
		iter++;
	}
}

void SceneMgr::LogicToScreen(int nLogicX, int nLogicY, int &nScreenX, int &nSreenY)
{
	nScreenX = nLogicX * gnUnitWidth + (nLogicY & 1) * (gnUnitWidth / 2);
	nSreenY = nLogicY * (gnUnitHeight / 2);
}

void SceneMgr::ScreenToLogic(int nScreenX, int nSreenY, int &nLogicX, int &nLogicY)
{
	nLogicY = nSreenY * 2 / gnUnitHeight;
	nLogicX = (nScreenX - (nLogicY & 1) * (gnUnitWidth / 2)) / gnUnitWidth;
}




/////////////////lua export/////////////////
void RegClassScene()
{
	REG_CLASS(SceneMgr, false, NULL); 
	REG_CLASS(Scene, false, NULL); 
}

SceneMgr::SceneMgr(lua_State* pState)
{
	XLog(LEVEL_ERROR, "Should not create in lua!\n");
}

int SceneMgr::CreateScene(lua_State* pState)
{
	int nSysSceneID = (int)luaL_checkinteger(pState, 1); 
	lua_assert(nSysSceneID > 0 && nSysSceneID <= 0xFFFF);
	int nMapID = (int)luaL_checkinteger(pState, 2);
	int nMapPixelWidth = (int)luaL_checkinteger(pState, 3);
	int nMapPixelHeight = (int)luaL_checkinteger(pState, 4);
	bool bCanCollected = lua_toboolean(pState, 5) != 0;
	int nBattleType = (int)luaL_checkinteger(pState, 6);
	MapConf* poMapConf = ConfMgr::Instance()->GetMapMgr()->GetConf(nMapID);
	if (poMapConf == NULL)
	{
		return LuaWrapper::luaM_error(pState, "Scene:%d map:%d not found!\n", nSysSceneID, nMapID);
	}
	if (poMapConf->nPixelWidth != nMapPixelWidth || poMapConf->nPixelHeight != nMapPixelHeight)
	{
		return LuaWrapper::luaM_error(pState, "Scene:%d map:%d pixel size error!\n", nSysSceneID, nMapID);
	}
	uint32_t nSceneIndex = GenSceneIndex(nSysSceneID);
	Scene* poScene = XNEW(Scene)(this, nSceneIndex, poMapConf, (uint8_t)nBattleType, bCanCollected);
	if (!poScene->InitAOI(nMapPixelWidth, nMapPixelHeight))
	{
		SAFE_DELETE(poScene);  
		return LuaWrapper::luaM_error(pState, "System scene:%d init AOI error\n", nSysSceneID);
	}
	m_oSceneMap.insert(std::make_pair(nSceneIndex, poScene));
	lua_pushinteger(pState, nSceneIndex);
	Lunar<Scene>::push(pState, poScene);
	return 2;
}

int SceneMgr::RemoveScene(lua_State* pState)
{
	uint32_t uSceneIndex = (uint32_t)luaL_checkinteger(pState, 1);
	RemoveScene(uSceneIndex);
	return 0;
}

int SceneMgr::GetScene(lua_State* pState)
{
	uint32_t uSceneIndex = (uint32_t)luaL_checkinteger(pState, 1);
	Scene* pScene = GetScene(uSceneIndex);
	if (pScene != NULL)
	{
		Lunar<Scene>::push(pState, pScene);
	}
	else
	{
		lua_pushnil(pState);
	}
	return 1;
}