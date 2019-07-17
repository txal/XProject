#include "Server/LogicServer//SceneMgr/SceneMgr.h"

#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XUUID.h"
#include "Common/CDebug.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/GameObject/Role/RoleMgr.h"
#include "Server/LogicServer/GameObject/Monster/MonsterMgr.h"
#include "Server/LogicServer/LogicServer.h"


LUNAR_IMPLEMENT_CLASS(SceneMgr)
{
	LUNAR_DECLARE_METHOD(SceneMgr, CreateScene),
	LUNAR_DECLARE_METHOD(SceneMgr, RemoveScene),
	LUNAR_DECLARE_METHOD(SceneMgr, GetScene),
	LUNAR_DECLARE_METHOD(SceneMgr, GetSceneList),
	LUNAR_DECLARE_METHOD(SceneMgr, DumpSceneInfo),
	{0, 0}
};

SceneMgr::SceneMgr()
{
}


SceneMgr::~SceneMgr()
{
	SceneIter iter = m_oSceneMap.begin();
	for (iter; iter != m_oSceneMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

SceneBase* SceneMgr::GetScene(int64_t nSceneID)
{
	SceneIter iter = m_oSceneMap.find(nSceneID);
	if (iter != m_oSceneMap.end() && !iter->second->IsDeleted())
	{
		return iter->second;
	}
	return NULL;
}

void SceneMgr::RemoveScene(int64_t nSceneID)
{
	SceneBase* poScene = GetScene(nSceneID);
	if (poScene != NULL)
	{
		poScene->MarkDeleted();
	}
}

void SceneMgr::Update(int64_t nNowMS)
{
	static int64_t nLastUpdateTime = 0;
	if (nNowMS - nLastUpdateTime < 1000)
	{
		return;
	}
	nLastUpdateTime = nNowMS;

	int nSceneCount = 0;
	SceneIter iter = m_oSceneMap.begin();
	SceneIter iter_end = m_oSceneMap.end();
	for (; iter != iter_end; )
	{
		SceneBase* poScene = iter->second;
		if (poScene->IsDeleted())
		{
			iter = m_oSceneMap.erase(iter);
			SAFE_DELETE(poScene);
			continue;
		}
		else
		{
			poScene->Update(nNowMS);
		}
		nSceneCount++;
		iter++;
	}

	static int64_t nLastDumpTime = 0;
	if (nNowMS-nLastDumpTime >= 60000)
	{
		nLastDumpTime = nNowMS;
		XLog(LEVEL_INFO, "CPP current scene count=%d\n", nSceneCount);
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
	REG_CLASS(SceneBase, false, NULL); 
}

int SceneMgr::CreateScene(lua_State* pState)
{
	int nSceneType = (int)luaL_checkinteger(pState, 1); 
	int64_t nSceneID = (int64_t)luaL_checkinteger(pState, 2); 
	uint16_t uConfID = (uint16_t)luaL_checkinteger(pState, 3); 
	int nMaxLineObjs = (int)lua_tointeger(pState, 4);
	nMaxLineObjs = nMaxLineObjs == 0 ? MAX_OBJ_PERLINE : nMaxLineObjs;

	MAPCONF* poMapConf = ConfMgr::Instance()->GetMapMgr()->GetConf(uConfID);
	if (poMapConf == NULL)
	{
		return LuaWrapper::luaM_error(pState, "Scene:%lld mapid:%d not found!\n", nSceneID, uConfID);
	}

	if (GetScene(nSceneID) != NULL)
	{
		char sBuff[1024] = "";
		snprintf(sBuff, sizeof(sBuff)-1, "Scene:%lld confid:%d conflict!!!\n", nSceneID, uConfID);
		return LuaWrapper::luaM_error(pState, sBuff);
	}

	SceneBase* poScene = XNEW(SceneBase)();
	if (!poScene->Init(this, nSceneID, uConfID, poMapConf, (SCENETYPE)nSceneType, nMaxLineObjs))
	{
		SAFE_DELETE(poScene);  
		return LuaWrapper::luaM_error(pState, "Scene:%lld confid:%d init aoi error\n", nSceneID, uConfID);
	}

	m_oSceneMap[nSceneID] = poScene;
	Lunar<SceneBase>::push(pState, poScene);
	return 1;
}

int SceneMgr::RemoveScene(lua_State* pState)
{
	int64_t nSceneID = (int64_t)luaL_checkinteger(pState, 1);
	RemoveScene(nSceneID);
	return 0;
}

int SceneMgr::GetScene(lua_State* pState)
{
	int64_t nSceneID = (int64_t)luaL_checkinteger(pState, 1);
	SceneBase* poScene = GetScene(nSceneID);
	if (poScene != NULL)
	{
		Lunar<SceneBase>::push(pState, poScene);
	}
	else
	{
		lua_pushnil(pState);
	}
	return 1;
}

int SceneMgr::DumpSceneInfo(lua_State* pState)
{
	int64_t nSceneID = (int64_t)lua_tointeger(pState, -1);
	if (nSceneID == 0)
	{
		SceneIter iter = m_oSceneMap.begin();
		SceneIter iter_end = m_oSceneMap.end();
		for (; iter != iter_end; iter++)
		{
			SceneBase* poScene = iter->second;
			if (poScene->GetSceneType() >= SCENETYPE::eST_Dup)
			{
				poScene->DumpSceneInfo(pState);
			}
		}
	}
	else
	{
		SceneBase* poScene = GetScene(nSceneID);
		if (poScene == NULL)
		{
			XLog(LEVEL_INFO, "Scene not exist or deleted sceneid=%d\n", nSceneID);
			return 0;
		}
		poScene->DumpSceneInfo(pState);
	}
	return 0;
}

int SceneMgr::GetSceneList(lua_State* pState)
{
	lua_newtable(pState);
	SceneIter iter = m_oSceneMap.begin();
	SceneIter iter_end = m_oSceneMap.end();
	for (int n = 1; iter != iter_end; iter++)
	{
		if (iter->second->IsDeleted())
		{
			continue;
		}
		lua_pushinteger(pState, iter->second->GetSceneID());
		lua_rawseti(pState, -2, n++);
	}
	return 1;
}
