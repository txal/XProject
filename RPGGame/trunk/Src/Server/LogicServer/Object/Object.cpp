#include "Server/LogicServer/Object/Object.h"

#include "Include/Network/Packet.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/Scene.h"

const int nOBJECT_COLLECT_MSTIME = 3*60*1000; //非玩家对象回收时间

LUNAR_IMPLEMENT_CLASS(Object)
{
	DECLEAR_OBJECT_METHOD(Object),
	{0, 0}
};

Object::Object()
{
    m_nConfID = 0;
    m_sName[0] = '\0';
	m_nObjType = eOT_None;
	m_poScene = NULL;
	m_nAOIID = 0;
	m_nFace = 0;
	m_nLine = 0;
	m_nFollowTarget = 0;
	m_nLeaveSceneTime = 0;
	m_nLastUpdateTime = 0;
	m_nLastViewListTime = 0;
}

Object::~Object()
{
}

void Object::SetPos(const Point& oPos, const char* pFile, int nLine)
{
	if (m_poScene == NULL || m_oPos == oPos)
	{
		return;
	}

	m_oPos = oPos;
	//m_poScene->MoveObj(m_nAOIID, m_oPos.x, m_oPos.y);
}

bool Object::IsTime2Collect(int64_t nNowMS)
{
	//角色不会被回收
	if (m_nObjType == eOT_Role)
	{
		return false;
	}

	if (m_poScene == NULL && m_nLeaveSceneTime > 0 && nNowMS - m_nLeaveSceneTime >= nOBJECT_COLLECT_MSTIME)
	{
		return true;
	}
	return false;
}

void Object::Update(int64_t nNowMS)
{
	//更新玩家跑步
	if (nNowMS - m_nLastUpdateTime >= 200)
	{
		m_nLastUpdateTime = nNowMS;
		UpdateRunState(nNowMS);
	}
	//更新玩家视野
	if (nNowMS - m_nLastViewListTime >= 400)
	{
		m_nLastViewListTime = nNowMS;
		UpdateViewList(nNowMS);
	}
}

void Object::OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos, int16_t nLine)
{
	assert(poScene != NULL && nAOIID > 0);
	m_poScene = poScene;
	m_nAOIID = nAOIID;
	m_oPos = oPos;
	m_nLeaveSceneTime = 0;
	m_nLine = nLine;
}

void Object::AfterEnterScene()
{
}

void Object::OnLeaveScene()
{
	m_poScene = NULL;
	m_nAOIID = 0;
	m_oPos = Point(-1, -1);
	m_nLine = 0;
	m_nLeaveSceneTime = XTime::MSTime();
}

void Object::CacheActorNavi(uint16_t uTarServer, int nTarSession)
{
	goNaviCache.Clear();
	if (m_poScene == NULL || m_nAOIID <= 0)
	{
		return;
	}

	if (uTarServer> 0 && nTarSession > 0)
	{
		NetAdapter::SERVICE_NAVI oNavi;
		oNavi.uSrcServer = gpoContext->GetServerID();
		oNavi.nSrcService = gpoContext->GetService()->GetServiceID();
		oNavi.uTarServer = uTarServer;
		oNavi.nTarService = nTarSession >> SERVICE_SHIFT;
		oNavi.nTarSession = nTarSession;
		goNaviCache.PushBack(oNavi);
	}

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = gpoContext->GetServerID();
	oNavi.nSrcService = gpoContext->GetService()->GetServiceID();

	Array<AOIOBJ*>& oAOIObjList = m_poScene->GetAreaObservers(m_nAOIID, GAMEOBJ_TYPE::eOT_Role);
	for (int i = oAOIObjList.Size() - 1; i >= 0; --i)
	{
		Actor* poActor = (Actor*)(oAOIObjList[i]->poGameObj);
		if (poActor->GetSession() > 0)
		{
			oNavi.uTarServer = poActor->GetServer();
			oNavi.nTarService = poActor->GetSession() >> SERVICE_SHIFT;
			oNavi.nTarSession = poActor->GetSession();
			goNaviCache.PushBack(oNavi);
		}
	}
}


/////////////////////////lua export///////////////////////
void RegClassObject()
{
	REG_CLASS(Object, false, NULL); 
}

int Object::GetObjID(lua_State* pState)
{
	lua_pushinteger(pState, m_nObjID);
	return 1;
}

int Object::GetConfID(lua_State* pState)
{
	lua_pushinteger(pState, m_nConfID);
	return 1;
}

int Object::GetObjType(lua_State* pState)
{
	lua_pushinteger(pState, m_nObjType);
	return 1;
}

int Object::GetName(lua_State* pState)
{
	lua_pushstring(pState, m_sName);
	return 1;
}

int Object::GetDupMixID(lua_State* pState)
{
	if (m_poScene != NULL)
		lua_pushinteger(pState, m_poScene->GetSceneMixID());
	else
		lua_pushinteger(pState, 0);
	return 1;
}

int Object::GetAOIID(lua_State* pState)
{
	lua_pushinteger(pState, m_nAOIID);
	return 1;
}

int Object::GetPos(lua_State* pState)
{
	lua_pushinteger(pState, m_oPos.x);
	lua_pushinteger(pState, m_oPos.y);
	return 2;
}

int Object::SetPos(lua_State* pState)
{
	int nPosX = (int)luaL_checkinteger(pState, 1);
	int nPosY = (int)luaL_checkinteger(pState, 2);

	int8_t nFace = -1;
	if (!lua_isnoneornil(pState,3))
		nFace = (int8_t)luaL_checkinteger(pState, 3);

	SetPos(Point(nPosX, nPosY));
	nFace = nFace == -1 ? m_nFace : nFace;
	SetFace(nFace);

	BroadcastPos(true);
	return 0;
}

int Object::GetSessionID(lua_State* pState)
{
	lua_pushinteger(pState, GetSession());
	return 1;
}

int Object::GetServerID(lua_State* pState)
{
	lua_pushinteger(pState, GetServer());
	return 1;
}

int Object::GetFace(lua_State* pState)
{
	lua_pushinteger(pState, m_nFace);
	return 1;
}

int Object::GetLine(lua_State* pState)
{
	lua_pushinteger(pState, m_nLine);
	return 1;
}

int Object::SetLine(lua_State* pState)
{
	int16_t nLine = (int16_t)luaL_checkinteger(pState, 1);
	if (m_poScene == NULL)
		return 0;
	m_poScene->SetLine(m_nAOIID, nLine);
	return 0;
}
