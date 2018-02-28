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
	m_nLeaveSceneTime = 0;
	m_nLastUpdateTime = 0;
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
	m_poScene->MoveObj(m_nAOIID, m_oPos.x, m_oPos.y);
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
	m_nLastUpdateTime = nNowMS;
}

void Object::OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos)
{
	assert(poScene != NULL && nAOIID > 0);
	m_poScene = poScene;
	m_nAOIID = nAOIID;
	m_oPos = oPos;
	m_nLeaveSceneTime = 0;
}

void Object::AfterEnterScene()
{
}

void Object::OnLeaveScene()
{
	m_poScene = NULL;
	m_nAOIID = 0;
	m_oPos = Point(-1, -1);
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
		oNavi.uSrcServer = g_poContext->GetServerID();
		oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
		oNavi.uTarServer = uTarServer;
		oNavi.nTarSession = nTarSession;
		goNaviCache.PushBack(oNavi);
	}

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = g_poContext->GetServerID();
	oNavi.nSrcService = g_poContext->GetService()->GetServiceID();

	Array<AOIOBJ*>& oAOIObjList = m_poScene->GetAreaObservers(m_nAOIID, GAMEOBJ_TYPE::eOT_Role);
	for (int i = oAOIObjList.Size() - 1; i >= 0; --i)
	{
		Actor* poActor = (Actor*)(oAOIObjList[i]->poGameObj);
		oNavi.uTarServer = poActor->GetServer();
		oNavi.nTarSession = poActor->GetSession();
		goNaviCache.PushBack(oNavi);
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

int Object::GetSessionID(lua_State* pState)
{
	lua_pushinteger(pState, GetSession());
	return 1;
}
