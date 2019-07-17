#include "Server/LogicServer/SceneMgr/SceneBase.h"

#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Common/CDebug.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/GameObject/Role/Role.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"


//场景回收时间
const int nSCENE_COLLECT_MSTIME = 10 * 60 * 1000;

LUNAR_IMPLEMENT_CLASS(SceneBase)
{
	LUNAR_DECLARE_METHOD(SceneBase, GetID),
	LUNAR_DECLARE_METHOD(SceneBase, GetConfID),
	LUNAR_DECLARE_METHOD(SceneBase, EnterScene),
	LUNAR_DECLARE_METHOD(SceneBase, LeaveScene),
	LUNAR_DECLARE_METHOD(SceneBase, GetSceneType),
	LUNAR_DECLARE_METHOD(SceneBase, GetCreateTime),
	LUNAR_DECLARE_METHOD(SceneBase, GetGameObj),
	LUNAR_DECLARE_METHOD(SceneBase, GetGameObjList),
	LUNAR_DECLARE_METHOD(SceneBase, GetGameObjCount),
	LUNAR_DECLARE_METHOD(SceneBase, AddObserver),
	LUNAR_DECLARE_METHOD(SceneBase, AddObserved),
	LUNAR_DECLARE_METHOD(SceneBase, RemoveObserver),
	LUNAR_DECLARE_METHOD(SceneBase, RemoveObserved),
	LUNAR_DECLARE_METHOD(SceneBase, GetAreaObservers),
	LUNAR_DECLARE_METHOD(SceneBase, GetAreaObserveds),
	LUNAR_DECLARE_METHOD(SceneBase, KickAllGameObjs),
	LUNAR_DECLARE_METHOD(SceneBase, DumpSceneInfo),
	LUNAR_DECLARE_METHOD(SceneBase, GetLuaObj),
	LUNAR_DECLARE_METHOD(SceneBase, BindLuaObj),
	{0, 0}
};

SceneBase:: SceneBase()
{
	m_nLuaObjRef = LUA_NOREF;
	m_poSceneMgr = NULL;
	m_nSceneID = 0;
	m_uConfID = 0;
	m_nSceneType = SCENETYPE::eST_None;
	m_bIsDeleted = false;

	m_poMapConf = NULL;
	m_nCreateTime = (int)time(0);
	m_nLastUpdateTime = XTime::MSTime();
}

SceneBase::~SceneBase()
{
	XLog(LEVEL_INFO, "SceneBase:%lld destructed!\n", m_nSceneID);
	KickAllGameObjs(0);

	if (m_nLuaObjRef != LUA_NOREF) 
	{
		luaL_unref(LuaWrapper::Instance()->GetLuaState(), LUA_REGISTRYINDEX, m_nLuaObjRef);
	}
	Lunar<SceneBase>::cthunk_once(LuaWrapper::Instance()->GetLuaState(), this);
}

bool SceneBase::Init(SceneMgr* poSceneMgr, int64_t nSceneID, uint16_t uConfID, MAPCONF* poMapConf, SCENETYPE nSceneType, int nMaxLineObjs)
{
	m_poSceneMgr = NULL;
	m_nSceneID = nSceneID;
	m_uConfID = uConfID;
	m_nSceneType = nSceneType;
	m_poMapConf = poMapConf;
	return m_oAOI.Init(this, nMaxLineObjs);
}

void SceneBase::Update(int64_t nNowMS)
{
	m_oAOI.Update(nNowMS);
}

Array<AOIOBJ*>& SceneBase::GetAreaObservers(int nAOIID, OBJTYPE nObjType)
{
	m_oObjCache.Clear();
	m_oAOI.GetAreaObservers(nAOIID, m_oObjCache, nObjType);
	return m_oObjCache;
}

Array<AOIOBJ*>& SceneBase::GetAreaObserveds(int nAOIID, OBJTYPE nObjType)
{
	m_oObjCache.Clear();
	m_oAOI.GetAreaObserveds(nAOIID, m_oObjCache, nObjType);
	return m_oObjCache;
}

Object* SceneBase::GetGameObjByAOIID(int nAOIID)
{
	AOIOBJ* poAOIObj = m_oAOI.GetAOIObj(nAOIID);
	return (poAOIObj == NULL ? NULL : poAOIObj->poGameObj);
}

Object* SceneBase::GetGameObjByObjID(int64_t nObjID)
{
	GameObjIter iter = m_oGameObjMap.find(nObjID);
	if (iter != m_oGameObjMap.end())
	{
		return iter->second;
	}
	return NULL;
}

int SceneBase::EnterScene(Object* poGameObj, int nPosX, int nPosY, int8_t nAOIMode, int nAOIArea[], int8_t nAOIType, int16_t nLine)
{
	int64_t nObjID = poGameObj->GetID();
	int nObjType = poGameObj->GetType();
	
	if (GetGameObjByObjID(nObjID) != NULL)
	{
		XLog(LEVEL_ERROR, "AddObj objid:%lld type:%d already in scene:%d\n", nObjID, nObjType, m_uConfID);
		NSCDebug::TraceBack();
		return -1;
	}
	if (m_oGameObjMap.size() >= 10000)
	{
		XLog(LEVEL_ERROR, "AddObj too many obj:%d in scene:%ld\n", m_oGameObjMap.size(), m_uConfID);
		NSCDebug::TraceBack();
		return -1;
	}
	int nAOIID = m_oAOI.AddAOIObj(poGameObj, nPosX, nPosY, nAOIMode, nAOIType, nAOIArea, nLine);
	if (nAOIID <= 0)
	{
		XLog(LEVEL_ERROR, "AOI add obj error id:%lld type:%d\n", nObjID, nObjType);
		NSCDebug::TraceBack();
		return -1;
	}
	return nAOIID;
}

void SceneBase::KickAllGameObjs(int nObjType)
{
	Array<Object*> oObjArray;
	GameObjIter iter = m_oGameObjMap.begin();
	GameObjIter iter_end = m_oGameObjMap.end();

	for (; iter != iter_end; iter++)
	{
		if (nObjType == 0 || iter->second->GetType() == nObjType)
		{
			oObjArray.PushBack(iter->second);
		}
	}

	for (int i = 0; i < oObjArray.Size(); i++)
	{
		Object* poGameObj = oObjArray[i];
		LeaveScene(poGameObj->GetAOIID(), true);
	}
}

void SceneBase::OnObjEnterScene(AOIOBJ* poAOIObj)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	Lunar<SceneBase>::push(pState, this);
	Lunar<Object>::push(pState, poAOIObj->poGameObj);
	pEngine->CallLuaRef("OnObjEnterScene", 2, 0);

	//调用ObjEnterScene中可能又退出了场景
	if (poAOIObj->poGameObj != NULL)
	{
		m_oGameObjMap[poAOIObj->poGameObj->GetID()] = poAOIObj->poGameObj;
		poAOIObj->poGameObj->OnEnterScene(this, poAOIObj->nAOIID, Point(poAOIObj->nPos[0], poAOIObj->nPos[1]));
	}
}

void SceneBase::OnObjLeaveScene(AOIOBJ* poAOIObj, bool bKicked)
{
	Object* poGameObj = poAOIObj->poGameObj;
	m_oGameObjMap.erase(poGameObj->GetID());

	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();

	Lunar<SceneBase>::push(pState, this);
	Lunar<Object>::push(pState, poGameObj);
	lua_pushboolean(pState, bKicked ? 1 : 0);

	pEngine->CallLuaRef("OnObjLeaveScene", 3, 0);
	poGameObj->OnLeaveScene();
}

void SceneBase::OnObjEnterObj(Array<AOIOBJ*>& oObserverCache, AOIOBJ* pObserved)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();

	Lunar<SceneBase>::push(pState, this);

	lua_newtable(pState);
	for (int i = 0; i < oObserverCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObserverCache[i]->poGameObj);
		lua_rawseti(pState, -2, i+1);
	}

	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserved->poGameObj);
	lua_rawseti(pState, -2, 1);

	pEngine->CallLuaRef("OnObjEnterObj", 3, 0);
}

void SceneBase::OnObjEnterObj(AOIOBJ* pObserver, Array<AOIOBJ*>& oObservedCache)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();

	Lunar<SceneBase>::push(pState, this);

	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserver->poGameObj);
	lua_rawseti(pState, -2, 1);

	lua_newtable(pState);
	for (int i = 0; i < oObservedCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObservedCache[i]->poGameObj);
		lua_rawseti(pState, -2, i+1);
	}

	pEngine->CallLuaRef("OnObjEnterObj", 3, 0);
}

void SceneBase::OnObjLeaveObj(Array<AOIOBJ*>& oObserverCache, AOIOBJ* pObserved)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();

	Lunar<SceneBase>::push(pState, this);

	lua_newtable(pState);
	for (int i = 0; i < oObserverCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObserverCache[i]->poGameObj);
		lua_rawseti(pState, -2, i+1);
	}

	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserved->poGameObj);
	lua_rawseti(pState, -2, 1);

	pEngine->CallLuaRef("OnObjLeaveObj", 3, 0);
}

void SceneBase::OnObjLeaveObj(AOIOBJ* pObserver, Array<AOIOBJ*>& oObservedCache)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();

	Lunar<SceneBase>::push(pState, this);

	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserver->poGameObj);
	lua_rawseti(pState, -2, 1);

	lua_newtable(pState);
	for (int i = 0; i < oObservedCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObservedCache[i]->poGameObj);
		lua_rawseti(pState, -2, i+1);
	}
	pEngine->CallLuaRef("OnObjLeaveObj", 3, 0);
}




///////////////////lua export///////////////
int SceneBase::GetID(lua_State* pState)
{
	lua_pushinteger(pState, m_nSceneID);
	return 1;
}

int SceneBase::GetConfID(lua_State* pState)
{
	lua_pushinteger(pState, m_uConfID);
	return 1;
}
int SceneBase::GetGameObj(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	Object* poGameObj = GetGameObjByAOIID(nAOIID);
	if (poGameObj == NULL)
	{
		return 0;
	}

	switch (poGameObj->GetType())
	{
		case OBJTYPE::eOT_Role:
		case OBJTYPE::eOT_Robot:
		case OBJTYPE::eOT_Monster:
		case OBJTYPE::eOT_Pet:
		{
			Actor* poActor = (Actor*)poGameObj;
			Lunar<Actor>::push(pState, poActor);
		}
		break;
		default:
		{
			Lunar<Object>::push(pState, poGameObj);
		}
		break;
	}
	return 1;
}

int SceneBase::EnterScene(lua_State* pState)
{
	LogicServer *poService = (LogicServer*)(gpoContext->GetService());

	int64_t nSceneID = (int64_t)luaL_checkinteger(pState, 1);
	if (poService->GetSceneMgr()->GetScene(nSceneID) == NULL)
	{
		return LuaWrapper::luaM_error(pState, "SceneBase::EnterScene scene:%lld not exist!!!\n", nSceneID);
	}

	luaL_checktype(pState, 2, LUA_TUSERDATA);
	Lunar<Object>::userdataType *ud = static_cast<Lunar<Object>::userdataType*>(lua_touserdata(pState, 2));
	Object* poGameObj = ud->pT;
	
	int nPosX = (int)luaL_checkinteger(pState, 3);
	int nPosY = (int)luaL_checkinteger(pState, 4);
	int8_t nAOIMode = (int8_t)luaL_checkinteger(pState, 5);

	int tAOIArea[2];
	tAOIArea[0] = (int)luaL_checkinteger(pState, 6);
	tAOIArea[1] = (int)luaL_checkinteger(pState, 7);
	assert(tAOIArea[0] >= 0 && tAOIArea[1] >= 0);

	int16_t nLine = (int16_t)luaL_checkinteger(pState, 8);	//0公共线,-1自动
	int nAOIID = EnterScene(poGameObj, nPosX, nPosY, nAOIMode, tAOIArea, AOI_TYPE_RECT, nLine);
	if (nAOIID <= 0)
	{
		return LuaWrapper::luaM_error(pState, "AddObj to scene fail!");
	}
	lua_pushinteger(pState, nAOIID);
	return 1;
};

int SceneBase::LeaveScene(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	LeaveScene(nAOIID, false);
	return 0;
}

int SceneBase::RemoveObserver(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	bool bLeaveScene = lua_toboolean(pState, 2) != 0;
	m_oAOI.RemoveObserver(nAOIID, bLeaveScene);
	return 0;
}

int SceneBase::RemoveObserved(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	m_oAOI.RemoveObserved(nAOIID);
	return 0;
}

int SceneBase::AddObserver(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	if (!m_oAOI.AddObserver(nAOIID))
	{
		luaL_where(pState, 1);
		XLog(LEVEL_ERROR, "%s\n", lua_tostring(pState, -1));
	}
	lua_pushinteger(pState, nAOIID);
	return 1;
}

int SceneBase::AddObserved(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	m_oAOI.AddObserved(nAOIID);
	lua_pushinteger(pState, nAOIID);
	return 1;
}

int SceneBase::GetAreaObservers(lua_State* pState)
{
	int nAOIID= (int)luaL_checkinteger(pState, 1);
	int nGameObjType = (int)luaL_checkinteger(pState, 2);
	GetAreaObservers(nAOIID, (OBJTYPE)nGameObjType);

	lua_newtable(pState);
	int nTop = lua_gettop(pState);
	for (int i = 0; i < m_oObjCache.Size(); i++)
	{
		Lunar<Object>::push(pState, m_oObjCache[i]->poGameObj);
		lua_rawseti(pState, nTop, i + 1);
	}
	return 1; 
}

int SceneBase::GetAreaObserveds(lua_State* pState)
{
	int nAOIID = (int)luaL_checkinteger(pState, 1);
	int nGameObjType = (int)luaL_checkinteger(pState, 2);
	GetAreaObserveds(nAOIID, (OBJTYPE)nGameObjType);

	lua_newtable(pState);
	int nTop = lua_gettop(pState);
	for (int i = 0; i < m_oObjCache.Size(); i++)
	{
		Lunar<Object>::push(pState, m_oObjCache[i]->poGameObj);
		lua_rawseti(pState, nTop, i + 1);
	}
	return 1;
}

int SceneBase::GetGameObjList(lua_State* pState)
{
	int nObjType = (int)luaL_checkinteger(pState, 1);
	int16_t nTarLine = (int16_t)luaL_checkinteger(pState, 2);

	GameObjIter iter = m_oGameObjMap.begin();
	GameObjIter iter_end = m_oGameObjMap.end();

	lua_newtable(pState);
	for (int n = 1; iter != iter_end; iter++)
	{
		Object* poGameObj = iter->second;
		if (poGameObj != NULL
			&& (nObjType == 0 || nObjType == poGameObj->GetType())
			&& (nTarLine == -1 || m_oAOI.GetAOIObj(poGameObj->GetAOIID())->nLine == nTarLine))
		{
			Lunar<Object>::push(pState, poGameObj);
			lua_rawseti(pState, -2, n++);
		}
	}
	return 1;
}

int SceneBase::GetGameObjCount(lua_State* pState)
{
	lua_pushinteger(pState, m_oGameObjMap.size());
	return 1;
}

int SceneBase::KickAllGameObjs(lua_State* pState)
{
	int nObjType = (int)lua_tointeger(pState, -1);
	KickAllGameObjs(nObjType);
	return 0;
}

int SceneBase::DumpSceneInfo(lua_State* pState)
{
	XLog(LEVEL_INFO, "dump scene Info-------\n");
	XLog(LEVEL_INFO, "scenetype:%d sceneid:%lld confid:%d isdeleted:%d\n", m_nSceneType, m_nSceneID, m_uConfID, m_bIsDeleted);
	int16_t *pLineArray = m_oAOI.GetLineArray();
	for (int i = 0; i < MAX_LINE; i++)
	{
		if (pLineArray[i] > 0)
		{
			XLog(LEVEL_INFO, "line:%d objs:%d\n", i, pLineArray[i]);
		}
	}
	return 0;
}

int SceneBase::GetSceneType(lua_State* pState)
{
	lua_pushinteger(pState, m_nSceneType);
	return 1;
}

int SceneBase::GetCreateTime(lua_State* pState)
{
	lua_pushinteger(pState, m_nCreateTime);
	return 1;
}

int SceneBase::GetLuaObj(lua_State* pState)
{
	if (m_nLuaObjRef == LUA_NOREF)
	{
		return LuaWrapper::luaM_error(pState, "GetLuaObj: lua obj id not binded!");
	}
	lua_rawgeti(pState, LUA_REGISTRYINDEX, m_nLuaObjRef);
	return 1;
}

int SceneBase::BindLuaObj(lua_State* pState)
{
	luaL_checktype(pState, 1, LUA_TTABLE);
	if (m_nLuaObjRef != LUA_NOREF) 
	{
		luaL_unref(pState, LUA_REGISTRYINDEX, m_nLuaObjRef);
	}
	m_nLuaObjRef = luaL_ref(pState, LUA_REGISTRYINDEX);
	return 0;
}
