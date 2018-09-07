#include "Server/LogicServer/Object/Object.h"
#include "Include/Network/Packet.h"
#include "Common/DataStruct/XTime.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/Scene.h"

const int nOBJECT_COLLECT_MSTIME = 3*60*1000; //非玩家对象收集时间

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
	m_nCamp = eBC_FreeLand;

	m_nLeaveSceneTime = m_nLastUpdateTime = XTime::MSTime();
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

bool Object::IsTimeToCollected(int64_t nNowMS)
{
	if (m_nObjType == eOT_Player)
	{//角色不会被收集
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

void Object::OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID)
{
	assert(poScene != NULL && nAOIID > 0);
	m_poScene = poScene;
	m_oPos = oPos;
	m_nAOIID = nAOIID;
	m_nLeaveSceneTime = 0;
}

void Object::AfterEnterScene()
{
}

void Object::OnLeaveScene()
{
	m_poScene = NULL;
	m_oPos = Point(-1, -1);
	m_nAOIID = 0;
	m_nLeaveSceneTime = XTime::MSTime();
}

bool Object::CheckCamp(Object* poTar)
{
	assert(poTar != NULL);
	int nTarCamp = poTar->m_nCamp;
	if (m_nCamp == eBC_Neutral || nTarCamp == eBC_Neutral)
	{
		return false;
	}
	if (m_nCamp == eBC_FreeLand)
	{
		return true;
	}
	return (m_nCamp != nTarCamp);
}

void Object::CachePlayerSessionList(int nSelfSession)
{
	g_oSessionCache.Clear();
	if (m_poScene == NULL || m_nAOIID <= 0)
	{
		return;
	}
	if (nSelfSession > 0)
	{
		g_oSessionCache.PushBack(nSelfSession);
	}
	Array<AOI_OBJ*>& oAOIObjList = m_poScene->GetAreaObservers(m_nAOIID, GAME_OBJ_TYPE::eOT_Player);
	if (oAOIObjList.Size() <= 0)
	{
		return;
	}
	for (int i = oAOIObjList.Size() - 1; i >= 0; --i)
	{
		int nSession = ((Actor*)oAOIObjList[i]->poGameObj)->GetSession();
		g_oSessionCache.PushBack(nSession);
	}
}




/////////////////////////lua export///////////////////////
void RegClassObject()
{
	REG_CLASS(Object, false, NULL); 
}

int Object::GetObjID(lua_State* pState)
{
	lua_pushinteger(pState, m_oObjID.llID);
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

int Object::GetSceneIndex(lua_State* pState)
{
	if (m_poScene != NULL)
	{
		lua_pushinteger(pState, m_poScene->GetSceneIndex());
		return 1;
	}
	return 0;
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

int Object::GetCamp(lua_State* pState)
{
	lua_pushinteger(pState, m_nCamp);
	return 1;
}

int Object::SetCamp(lua_State* pState)
{
	int8_t nCamp = (int8_t)luaL_checkinteger(pState, 1);
	m_nCamp = nCamp;
	return 0;
}