#include "Server/LogicServer/SceneMgr/Scene.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/Object/Player/Player.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"


//场景回收时间
const int nSCENE_COLLECT_MSTIME = 3*60*1000;
//AOI 废弃对象回收时间
const int nAOIDROP_COLLECT_MSTIME = 1*60*1000;
//排行榜广播时间
const int nDAMAGE_BROADCAST_MSTIME = 2*1000;

char Scene::className[] = "Scene";
Lunar<Scene>::RegType Scene::methods[] =
{
	LUNAR_DECLARE_METHOD(Scene, GetSceneIndex),
	LUNAR_DECLARE_METHOD(Scene, GetObj),
	LUNAR_DECLARE_METHOD(Scene, AddObj),
	LUNAR_DECLARE_METHOD(Scene, MoveObj),
	LUNAR_DECLARE_METHOD(Scene, RemoveObj),
	LUNAR_DECLARE_METHOD(Scene, RemoveObserver),
	LUNAR_DECLARE_METHOD(Scene, RemoveObserved),
	LUNAR_DECLARE_METHOD(Scene, AddObserver),
	LUNAR_DECLARE_METHOD(Scene, AddObserved),
	LUNAR_DECLARE_METHOD(Scene, GetAreaObservers),
	LUNAR_DECLARE_METHOD(Scene, GetAreaObserveds),
	LUNAR_DECLARE_METHOD(Scene, GetSceneObjList),
	LUNAR_DECLARE_METHOD(Scene, KickAllPlayer),
	LUNAR_DECLARE_METHOD(Scene, BattleResult),
	LUNAR_DECLARE_METHOD(Scene, StartAI),
	LUNAR_DECLARE_METHOD(Scene, StopAI),
	LUNAR_DECLARE_METHOD(Scene, GetActorDmg),
	{0, 0}
};

Scene::Scene(lua_State* pState)
{
	XLog(LEVEL_ERROR, "Scene should not new in lua!\n");
}

Scene::Scene(SceneMgr* poSceneMgr, uint32_t uSceneIndex, MapConf* poMapConf, uint8_t uBattleType, bool bCanCollected)
: m_oDmgRanking(DmgRankCompare)
{
	m_uSceneIndex = uSceneIndex;
	m_poSceneMgr = poSceneMgr;
	m_bCanCollected = bCanCollected;

	m_nPlayerCount = 0;

	int64_t nNowMS = XTime::MSTime();
	m_nLastUpdateTime = nNowMS;
	m_nLastPlayerLeaveTime = nNowMS;

	m_uBattleType = uBattleType;
	m_nLastDmgRankSyncTime = nNowMS;

	m_poMapConf = poMapConf;
}

Scene::~Scene()
{
	AOI::AOIObjIter iter = m_oAOI.GetObjIterBegin();
	AOI::AOIObjIter iter_end = m_oAOI.GetObjIterEnd();
	for (; iter != iter_end; iter++)
	{
		if (iter->second->nAOIMode & AOI_MODE_DROP)
		{
			continue;
		}
		Object* poGameObj = iter->second->poGameObj;
		RemoveObj(poGameObj->GetAOIID());
	}
	m_oObjMap.clear();
	XLog(LEVEL_INFO, "Scene:%d destructed!\n", m_uSceneIndex);
}

void Scene::Update(int64_t nNowMS)
{
	if (nNowMS - m_oAOI.m_nLastClearMSTime >= nAOIDROP_COLLECT_MSTIME)
	{
		m_oAOI.ClearDropObj(nNowMS);
	}
}

Array<AOI_OBJ*>& Scene::GetAreaObservers(int nAOIObjID, int nGameObjType)
{
	m_oObjCache.Clear();
	m_oAOI.GetAreaObservers(nAOIObjID, m_oObjCache, nGameObjType);
	return m_oObjCache;
}

Array<AOI_OBJ*>& Scene::GetAreaObserveds(int nAOIObjID, int nGameObjType)
{
	m_oObjCache.Clear();
	m_oAOI.GetAreaObserveds(nAOIObjID, m_oObjCache, nGameObjType);
	return m_oObjCache;
}

Object* Scene::GetGameObj(int nAOIID)
{
	AOI_OBJ* poObj = m_oAOI.GetObj(nAOIID);
	return (poObj == NULL ? NULL : poObj->poGameObj);
}

bool Scene::IsTimeToCollected(int64_t nNowMS)
{
	if (!m_bCanCollected)
	{
		return false;
	}
	if (nNowMS - m_nLastPlayerLeaveTime >= nSCENE_COLLECT_MSTIME && m_nPlayerCount <= 0)
	{
		return true;
	}
	return false;
}


int Scene::AddObj(Object* poObject, int nPosX, int nPosY, int8_t nAOIMode, int8_t nAOIType, int nAOIArea[])
{
	int64_t nObjID = poObject->GetID().llID;
	int nObjType = poObject->GetType();
	if (m_oObjMap.find(nObjID) != m_oObjMap.end())
	{
		XLog(LEVEL_ERROR, "AddObj error id:%lld type:%d already in scene:%d\n", nObjID, nObjType, m_uSceneIndex);
		return -1;
	}
	int nAOIID = m_oAOI.AddObj(nPosX, nPosY, nAOIMode, nAOIType, nAOIArea, poObject);
	if (nAOIID <= 0)
	{
		XLog(LEVEL_ERROR, "AOI add obj error id:%lld type:%d\n", nObjID, nObjType);
		return -1;
	}
	return nAOIID;
}

void Scene::RemoveObj(int nAOIObjID)
{
	m_oAOI.RemoveObj(nAOIObjID);
}

void Scene::KickAllPlayer()
{
	Array<Object*> oPlayerArray;
	ObjIter iter = m_oObjMap.begin();
	ObjIter iter_end = m_oObjMap.end();
	for (; iter != iter_end; iter++)
	{
		if (iter->second->GetType() == eOT_Player)
		{
			oPlayerArray.PushBack(iter->second);
		}
	}

	for (int i = 0; i < oPlayerArray.Size(); i++)
	{
		Object* poObj = oPlayerArray[i];
		RemoveObj(poObj->GetAOIID());
	}
}

void Scene::OnObjEnterScene(AOI_OBJ* pObj)
{
	Object* poGameObj = pObj->poGameObj;
	m_oObjMap.insert(std::make_pair(poGameObj->GetID().llID, poGameObj));
	poGameObj->OnEnterScene(this, Point(pObj->nPos[0], pObj->nPos[1]), pObj->nAOIObjID);
	if (poGameObj->GetType() == eOT_Player)
	{
		m_nPlayerCount++;
	}

	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	Lunar<Object>::push(pState, pObj->poGameObj);
	pEngine->CallLuaRef("OnObjEnterScene", 2, 0);
}


void Scene::AfterObjEnterScene(AOI_OBJ* pObj)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	Lunar<Object>::push(pState, pObj->poGameObj);
	pEngine->CallLuaRef("AfterObjEnterScene", 2, 0);

	Object* poGameObj = pObj->poGameObj;
	poGameObj->AfterEnterScene();

}

void Scene::OnObjLeaveScene(AOI_OBJ* pObj)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	Lunar<Object>::push(pState, pObj->poGameObj);
	pEngine->CallLuaRef("OnObjLeaveScene", 2, 0);

	Object* poGameObj = pObj->poGameObj;
	m_oObjMap.erase(poGameObj->GetID().llID);
	poGameObj->OnLeaveScene();
	if (poGameObj->GetType() == eOT_Player)
	{
		m_nPlayerCount--;
		m_nLastPlayerLeaveTime = XTime::MSTime();
	}
}

void Scene::OnObjEnterObj(Array<AOI_OBJ*>& oObserverCache, AOI_OBJ* pObserved)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	lua_newtable(pState);
	for (int i = 0; i < oObserverCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObserverCache[i]->poGameObj);
		lua_rawseti(pState, -2, i + 1);
	}
	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserved->poGameObj);
	lua_rawseti(pState, -2, 1);
	pEngine->CallLuaRef("OnObjEnterObj", 3, 0);
}

void Scene::OnObjEnterObj(AOI_OBJ* pObserver, Array<AOI_OBJ*>& oObservedCache)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserver->poGameObj);
	lua_rawseti(pState, -2, 1);
	lua_newtable(pState);
	for (int i = 0; i < oObservedCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObservedCache[i]->poGameObj);
		lua_rawseti(pState, -2, i + 1);
	}
	pEngine->CallLuaRef("OnObjEnterObj", 3, 0);
}

void Scene::OnObjLeaveObj(Array<AOI_OBJ*>& oObserverCache, AOI_OBJ* pObserved)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	lua_newtable(pState);
	for (int i = 0; i < oObserverCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObserverCache[i]->poGameObj);
		lua_rawseti(pState, -2, i + 1);
	}
	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserved->poGameObj);
	lua_rawseti(pState, -2, 1);
	pEngine->CallLuaRef("OnObjLeaveObj", 3, 0);
}

void Scene::OnObjLeaveObj(AOI_OBJ* pObserver, Array<AOI_OBJ*>& oObservedCache)
{
	LuaWrapper* pEngine = LuaWrapper::Instance();
	lua_State* pState = pEngine->GetLuaState();
	lua_pushinteger(pState, m_uSceneIndex);
	lua_newtable(pState);
	Lunar<Object>::push(pState, pObserver->poGameObj);
	lua_rawseti(pState, -2, 1);
	lua_newtable(pState);
	for (int i = 0; i < oObservedCache.Size(); i++)
	{
		Lunar<Object>::push(pState, oObservedCache[i]->poGameObj);
		lua_rawseti(pState, -2, i + 1);
	}
	pEngine->CallLuaRef("OnObjLeaveObj", 3, 0);
}

void Scene::UpdateDamage(Actor* poAtker, Actor* poDefer, int nHP, int nAtkID, int nAtkType, bool bDead /*=false*/)
{
	if (poAtker == NULL || poDefer == NULL || nHP <= 0)
	{
		return;
	}
	if (m_uBattleType  == eBT_BugStorm || m_uBattleType == eBT_BugHole || m_uBattleType == eBT_BugHole1 || m_uBattleType == eBT_BugHole2)
	{
		GAME_OBJID& oID = poAtker->GetID();
		DmgData* poData = m_oDmgRanking.GetDataByID(oID.llID);
		if (poData == NULL)
		{
			DmgData oData;
			oData.llID = oID.llID;
			strcpy(oData.sName, poAtker->GetName());
			oData.nValue = nHP;
			m_oDmgRanking.InsertData(oID.llID, oData);
		}
		else
		{
			poData->nValue += nHP;
			m_oDmgRanking.UpdateData(oID.llID);
		}
		int& nTotalDmg = m_oDmgRanking.GetTotalDmg();
		nTotalDmg += nHP;

		////广播(客户端自己做)
		//int64_t nNowMS = XTime::MSTime();
		//if (nNowMS - m_nLastDmgRankSyncTime >= nDAMAGE_BROADCAST_MSTIME || bDead)
		//{
		//	m_nLastDmgRankSyncTime = nNowMS;

		//	Array<int> g_oSessionCache;
		//	ObjIter iter = m_oObjMap.begin();
		//	ObjIter iter_end = m_oObjMap.end();
		//	for (; iter != iter_end; iter++)
		//	{
		//		Actor* poActor = (Actor*)iter->second;
		//		if (poActor->GetType() == eOT_Player)
		//		{
		//			int nSession = poActor->GetSession();
		//			g_oSessionCache.PushBack(nSession);
		//		}
		//	}
		//	if (g_oSessionCache.Size() <= 0)
		//	{
		//		return;
		//	}
		//	Packet* poPacket = Packet::Create();
		//	PacketWriter g_oPKWriter(poPacket);
		//	uint16_t uCount = (uint16_t)m_oDmgRanking.Size();
		//	g_oPKWriter << nTotalDmg << uCount;
		//	m_oDmgRanking.Traverse(1, uCount, DefaultRankTraverse, &g_oPKWriter);
		//	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastRanking, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
		//}
	}
}




///////////////////lua export///////////////
int Scene::GetSceneIndex(lua_State* pState)
{
	lua_pushinteger(pState, m_uSceneIndex);
	return 1;
}

int Scene::GetObj(lua_State* pState)
{
	int nAOIObjID= (int)luaL_checkinteger(pState, 1);
	Object* poGameObj = GetGameObj(nAOIObjID);
	if (poGameObj == NULL)
	{
		return 0;
	}
	switch (poGameObj->GetType())
	{
		case eOT_Player:
		case eOT_Robot:
		case eOT_Monster:
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

int Scene::AddObj(lua_State* pState)
{
	luaL_checktype(pState, 1, LUA_TUSERDATA);
	Lunar<Object>::userdataType *ud = static_cast<Lunar<Object>::userdataType*>(lua_touserdata(pState, 1));
	Object* poObject = ud->pT;
	int nPosX = (int)luaL_checkinteger(pState, 2);
	int nPosY = (int)luaL_checkinteger(pState, 3);
	int8_t nAOIMode = (int8_t)luaL_checkinteger(pState, 4);
	int8_t nAOIType = (int8_t)luaL_checkinteger(pState, 5);
	int tAOIArea[2];
	tAOIArea[0] = (int)luaL_checkinteger(pState, 6);
	tAOIArea[1] = (int)luaL_checkinteger(pState, 7);
	assert(tAOIArea[0] >= 0 && tAOIArea[1] >= 0);

	int nAOIObjID = AddObj(poObject, nPosX, nPosY, nAOIMode, nAOIType, tAOIArea);
	if (nAOIObjID <= 0)
	{
		return LuaWrapper::luaM_error(pState, "AddObj to scene fail!");
	}
	lua_pushinteger(pState, nAOIObjID);
	return 1;
};

int Scene::MoveObj(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	int nPosX = (int)luaL_checkinteger(pState, 2);
	int nPosY = (int)luaL_checkinteger(pState, 3);
	MoveObj(nAOIObjID, nPosX, nPosY);
	return 0;
}

int Scene::RemoveObj(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	RemoveObj(nAOIObjID);
	return 0;
}

int Scene::RemoveObserver(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	m_oAOI.RemoveObserver(nAOIObjID);
	return 0;
}

int Scene::RemoveObserved(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	m_oAOI.RemoveObserved(nAOIObjID);
	return 0;
}

int Scene::AddObserver(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	m_oAOI.AddObserver(nAOIObjID);
	return 0;
}

int Scene::AddObserved(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	m_oAOI.AddObserved(nAOIObjID);
	return 0;
}

int Scene::GetAreaObservers(lua_State* pState)
{
	int nAOIObjID= (int)luaL_checkinteger(pState, 1);
	int nGameObjType = (int)luaL_checkinteger(pState, 2);
	GetAreaObservers(nAOIObjID, nGameObjType);
	lua_newtable(pState);
	int nTop = lua_gettop(pState);
	for (int i = 0; i < m_oObjCache.Size(); i++)
	{
		Lunar<Object>::push(pState, m_oObjCache[i]->poGameObj);
		lua_rawseti(pState, nTop, i + 1);
	}
	return 1; 
}

int Scene::GetAreaObserveds(lua_State* pState)
{
	int nAOIObjID = (int)luaL_checkinteger(pState, 1);
	int nGameObjType = (int)luaL_checkinteger(pState, 2);
	GetAreaObservers(nAOIObjID, nGameObjType);
	lua_newtable(pState);
	int nTop = lua_gettop(pState);
	for (int i = 0; i < m_oObjCache.Size(); i++)
	{
		Lunar<Object>::push(pState, m_oObjCache[i]->poGameObj);
		lua_rawseti(pState, nTop, i + 1);
	}
	return 1;
}

int Scene::GetSceneObjList(lua_State* pState)
{
	int nObjType = (int)lua_tonumber(pState, 1);
	AOI::AOIObjIter iter = m_oAOI.GetObjIterBegin();
	AOI::AOIObjIter iter_end = m_oAOI.GetObjIterEnd();

	lua_newtable(pState);
	for (int n = 1; iter != iter_end; iter++)
	{
		Object* poObj = iter->second->poGameObj;
		if (nObjType == 0 || nObjType == poObj->GetType())
		{
			Lunar<Object>::push(pState, poObj);
			lua_rawseti(pState, -2, n++);
		}
	}
	return 1;
}

int Scene::KickAllPlayer(lua_State* pState)
{
	KickAllPlayer();
	return 0;
}

int Scene::BattleResult(lua_State* pState)
{
	ObjIter iter = m_oObjMap.begin();
	ObjIter iter_end  = m_oObjMap.end();
	for (; iter != iter_end; iter++)
	{
		iter->second->OnBattleResult();
	}
	return 0;
}

int Scene::StartAI(lua_State* pState)
{
	ObjIter iter = m_oObjMap.begin();
	ObjIter iter_end = m_oObjMap.end();
	for (; iter != iter_end; iter++)
	{
		AI* poAI = NULL;
		Object* poObj = iter->second;
		int nObjType = poObj->GetType();
		if (nObjType  == eOT_Robot)
		{
			poAI = ((Robot*)poObj)->GetAI();
		}
		else if (nObjType == eOT_Monster)
		{
			poAI = ((Monster*)poObj)->GetAI();
		}
		if (poAI != NULL)
		{
			poAI->Start();
		}
	}
	return 0;
}

int Scene::StopAI(lua_State* pState)
{
	ObjIter iter = m_oObjMap.begin();
	ObjIter iter_end = m_oObjMap.end();
	for (; iter != iter_end; iter++)
	{
		Object* poObj = iter->second;
		if (poObj->GetType() == eOT_Robot)
		{
			AI* poAI = ((Robot*)poObj)->GetAI();
			if (poAI != NULL)
			{
				poAI->Stop();
			}
		}
	}
	return 0;
}

int Scene::GetActorDmg(lua_State* pState)
{
	int64_t nObjID = luaL_checkinteger(pState, 1);
	DmgData* poData = m_oDmgRanking.GetDataByID(nObjID);
	if (poData == NULL)
	{
		lua_pushinteger(pState, 0);
	}
	else
	{
		lua_pushinteger(pState, poData->nValue);
	}
	return 1;
}