#include "Server/LogicServer/GameObject/Object.h"

#include "Include/Network/Packet.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"

LUNAR_IMPLEMENT_CLASS(Object)
{
	DECLEAR_OBJECT_METHOD(Object),
	{0, 0}
};

Object::Object()
{
	m_nLuaObjRef = LUA_NOREF;
	m_nConfID = 0;
	m_nObjType = OBJTYPE::eOT_None;
	memset(m_sName, 0, sizeof(m_sName));
	m_nFace = 0;

	m_nAOIID = 0;
	m_poScene = NULL;

	m_nLeaveSceneTime = 0;
	m_nLastRunUpdateTime = 0;
	m_nLastViewUpdateTime = 0;
	m_bIsDeleted = false;
}

Object::~Object()
{
	if (m_nLuaObjRef != LUA_NOREF)
	{
		luaL_unref(LuaWrapper::Instance()->GetLuaState(), LUA_REGISTRYINDEX, m_nLuaObjRef);
	}
	Lunar<Object>::cthunk_once(LuaWrapper::Instance()->GetLuaState(), this);
}

void Object::Init(OBJTYPE nObjType, int64_t nObjID, int nConfID, const char* psName)
{
	m_nObjType = nObjType;
    m_nConfID = nConfID;
	memset(m_sName, 0, sizeof(m_sName));
	strncpy(m_sName, psName, sizeof(m_sName)-1);
}

void Object::SetPos(const Point& oPos)
{
	if (m_poScene == NULL || m_oPos == oPos)
	{
		return;
	}
	m_oPos = oPos;
}

void Object::Update(int64_t nNowMS)
{
	//更新走路
	if (nNowMS - m_nLastRunUpdateTime >= 200)
	{
		m_nLastRunUpdateTime = nNowMS;
		UpdateRunState(nNowMS);
	}
	//更新视野
	if (nNowMS - m_nLastViewUpdateTime >= 400)
	{
		m_nLastViewUpdateTime = nNowMS;
		UpdateViewList(nNowMS);
	}
}

void Object::UpdateViewList(int64_t nNowMS)
{
	SceneBase* poScene = GetScene();
	if (poScene == NULL)
	{
		return;
	}
	poScene->MoveGameObj(GetAOIID(), m_oPos.x, m_oPos.y);
}

void Object::OnEnterScene(SceneBase* poScene, int nAOIID, Point& oPos)
{
	assert(poScene != NULL && nAOIID > 0);
	m_poScene = poScene;
	m_nAOIID = nAOIID;
	m_oPos = oPos;
	m_nLeaveSceneTime = 0;
}

void Object::OnLeaveScene()
{
	m_poScene = NULL;
	m_nAOIID = 0;
	m_oPos = Point(-1, -1);
	m_nLeaveSceneTime = XTime::MSTime();
}

void Object::CacheObjNavi(uint16_t uSelfServer, int nSelfSession)
{
	goNaviCache.Clear();
	if (m_poScene == NULL || m_nAOIID <= 0)
	{
		return;
	}

	if (uSelfServer> 0 && nSelfSession > 0)
	{
		NetAdapter::SERVICE_NAVI oNavi;
		oNavi.uSrcServer = gpoContext->GetServerConfig().GetServerID();
		oNavi.nSrcService = gpoContext->GetService()->GetServiceID();
		oNavi.uTarServer = uSelfServer;
		oNavi.nTarService = nSelfSession >> SERVICE_SHIFT;
		oNavi.nTarSession = nSelfSession;
		goNaviCache.PushBack(oNavi);
	}

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = gpoContext->GetServerConfig().GetServerID();
	oNavi.nSrcService = gpoContext->GetService()->GetServiceID();

	Array<AOIOBJ*>& oAOIObjList = m_poScene->GetAreaObservers(m_nAOIID, OBJTYPE::eOT_Role);
	for (int i = oAOIObjList.Size() - 1; i >= 0; --i)
	{
		Object* poObj = (Object*)(oAOIObjList[i]->poGameObj);
		if (poObj->GetSession() > 0)
		{
			oNavi.uTarServer = poObj->GetServer();
			oNavi.nTarService = poObj->GetSession() >> SERVICE_SHIFT;
			oNavi.nTarSession = poObj->GetSession();
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

int Object::GetSceneID(lua_State* pState)
{
	if (m_poScene != NULL) {
		lua_pushinteger(pState, m_poScene->GetSceneID());
	}
	else
	{
		lua_pushinteger(pState, 0);
	}
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
	SetPos(Point(nPosX, nPosY));
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
	if (m_poScene == NULL) {
		return 0;
	}
	int16_t nLine = m_poScene->GetAOI()->GetAOIObj(m_nAOIID)->nLine;
	lua_pushinteger(pState, nLine);
	return 1;
}

int Object::SetLine(lua_State* pState)
{
	if (m_poScene == NULL)
	{
		return 0;
	}
	int16_t nLine = (int16_t)luaL_checkinteger(pState, 1);
	m_poScene->SetGameObjLine(m_nAOIID, nLine);
	return 0;
}

int Object::GetLuaObj(lua_State* pState)
{
	if (m_nLuaObjRef == LUA_NOREF)
	{
		return LuaWrapper::luaM_error(pState, "GetLuaObj: lua obj id not binded!");
	}
	lua_rawgeti(pState, LUA_REGISTRYINDEX, m_nLuaObjRef);
	return 1;
}

int Object::BindLuaObj(lua_State* pState)
{
	luaL_checktype(pState, 1, LUA_TTABLE);
	if (m_nLuaObjRef != LUA_NOREF) 
	{
		luaL_unref(pState, LUA_REGISTRYINDEX, m_nLuaObjRef);
	}
	m_nLuaObjRef = luaL_ref(pState, LUA_REGISTRYINDEX);
	return 0;
}
