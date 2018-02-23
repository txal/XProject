#include "SceneMgr.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/ObjID.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"


LUNAR_IMPLEMENT_CLASS(SceneMgr)
{
	LUNAR_DECLARE_METHOD(SceneMgr, CreateDup),
	LUNAR_DECLARE_METHOD(SceneMgr, RemoveDup),
	LUNAR_DECLARE_METHOD(SceneMgr, GetDup),
	{0, 0}
};

SceneMgr::SceneMgr()
{
}


SceneMgr::~SceneMgr()
{
}


uint32_t SceneMgr::GenSceneMixID(uint16_t uConfID)
{
	static uint16_t uIndex = 0;
	uIndex = uIndex % 0xFFFF + 1;
	uint32_t nSceneIndex = (uint32_t)uIndex << 16 | uConfID;
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

void SceneMgr::Update(int64_t nNowMS)
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
		if (poScene->IsTime2Collect(nNowMS))
		{
			iter = m_oSceneMap.erase(iter);
			uint32_t uSceneIndex = poScene->GetSceneMixID();
			LuaWrapper::Instance()->FastCallLuaRef<void>("OnDupCollected", 0, "I", uSceneIndex);
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

int SceneMgr::CreateDup(lua_State* pState)
{
	int nDupID = (int)luaL_checkinteger(pState, 1); 
	lua_assert(nDupID > 0 && nDupID <= 0xFFFF);
	int nMapID = (int)luaL_checkinteger(pState, 2);
	bool bCanCollected = lua_toboolean(pState, 3) != 0;
	MapConf* poMapConf = ConfMgr::Instance()->GetMapMgr()->GetConf(nMapID);
	if (poMapConf == NULL)
	{
		return LuaWrapper::luaM_error(pState, "Dup:%d map:%d not found!\n", nDupID, nMapID);
	}
	uint32_t uSceneMixID = nDupID;
	if (nDupID >= 1000) //[1-999]:城镇; [1000-]:副本
	{
		uSceneMixID = GenSceneMixID(nDupID);
	}
	Scene* poScene = XNEW(Scene)(this, uSceneMixID, poMapConf, bCanCollected);
	if (!poScene->InitAOI(poMapConf->nPixelWidth, poMapConf->nPixelHeight))
	{
		SAFE_DELETE(poScene);  
		return LuaWrapper::luaM_error(pState, "Dup:%d init AOI error\n", nDupID);
	}
	m_oSceneMap[uSceneMixID] = poScene;
	lua_pushinteger(pState, uSceneMixID);
	Lunar<Scene>::push(pState, poScene);
	return 2;
}

int SceneMgr::RemoveDup(lua_State* pState)
{
	uint32_t uSceneIndex = (uint32_t)luaL_checkinteger(pState, 1);
	RemoveScene(uSceneIndex);
	return 0;
}

int SceneMgr::GetDup(lua_State* pState)
{
	uint32_t uSceneMixID = (uint32_t)luaL_checkinteger(pState, 1);
	Scene* poScene = GetScene(uSceneMixID);
	if (poScene != NULL)
	{
		Lunar<Scene>::push(pState, poScene);
	}
	else
	{
		lua_pushnil(pState);
	}
	return 1;
}