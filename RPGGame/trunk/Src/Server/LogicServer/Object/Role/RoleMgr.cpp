#include "RoleMgr.h"

LUNAR_IMPLEMENT_CLASS(RoleMgr)
{
	LUNAR_DECLARE_METHOD(RoleMgr, CreateRole),
	LUNAR_DECLARE_METHOD(RoleMgr, RemoveRole),
	LUNAR_DECLARE_METHOD(RoleMgr, GetRole),
	LUNAR_DECLARE_METHOD(RoleMgr, SetFollow),
	{0, 0}
};


RoleMgr::RoleMgr()
{
}

Role* RoleMgr::CreateRole(int nID, int nConfID, const char* psName, uint16_t uServer, int nSession)
{
	Role* poRole = GetRoleByID(nID);
	if (poRole != NULL)
	{
		XLog(LEVEL_ERROR, "CreateRole error for role id:%d exist\n", nID);
		return poRole;
	}

	if (nSession > 0)
	{
		poRole = GetRoleBySS(uServer, nSession);
		if (poRole != NULL)
		{
			XLog(LEVEL_ERROR, "CreateRole error for role server:%d session:%d exist\n", uServer, nSession);
			return NULL;
		}
	}

	poRole = XNEW(Role);
	poRole->Init(nID, nConfID, psName);
	poRole->SetServer(uServer);
	poRole->SetSession(nSession);

	m_oRoleIDMap[nID] = poRole;
	m_oRoleSSMap[GenSSKey(uServer,nSession)] = poRole;
	return poRole;
}

void RoleMgr::RemoveRole(int nID)
{
	RoleIter iter = m_oRoleIDMap.find(nID);
	if (iter == m_oRoleIDMap.end())
	{
		return;
	}

	Role* poRole = iter->second;
	if (poRole->GetScene() != NULL)
	{
		XLog(LEVEL_ERROR, "Remove role must leave scene first\n");
		return;
	}

	m_oRoleIDMap.erase(iter);

	int nSession = poRole->GetSession();
	if (nSession > 0)
	{
		uint16_t uServer = poRole->GetServer();
		m_oRoleSSMap.erase(GenSSKey(uServer, nSession));
	}

	SAFE_DELETE(poRole);
}

Role* RoleMgr::GetRoleByID(int nID)
{
	RoleIter iter = m_oRoleIDMap.find(nID);
	if (iter != m_oRoleIDMap.end())
	{
		return iter->second;
	}
	return NULL;
}

Role* RoleMgr::GetRoleBySS(uint16_t uServer, int nSession)
{
	int nSSKey = GenSSKey(uServer, nSession);
	RoleIter iter = m_oRoleSSMap.find(nSSKey);
	if (iter != m_oRoleSSMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void RoleMgr::BindSession(int nID, int nSession)
{
	Role* poRole = GetRoleByID(nID);
	if (poRole == NULL)
		return;

	int nOldSession = poRole->GetSession();
	if (nOldSession == nSession)
		return;

	poRole->SetSession(nSession);

	if (nOldSession > 0)
	{
		int nOldSSKey = GenSSKey(poRole->GetServer(), nOldSession);
		m_oRoleSSMap.erase(nOldSSKey);
	}

	if (nSession > 0)
	{
		int nNewSSKey = GenSSKey(poRole->GetServer(), nSession);
		m_oRoleSSMap[nNewSSKey] = poRole;
	}
}

void RoleMgr::Update(int64_t nNowMS)
{
	static float nFRAME_MSTIME = 1000.0f / 30.0f;
	RoleIter iter = m_oRoleIDMap.begin();
	RoleIter iter_end = m_oRoleIDMap.end();
	for (; iter != iter_end; iter++)
	{
		Role* poRole = iter->second;
		if (nNowMS - poRole->GetLastUpdateTime() >= nFRAME_MSTIME)
		{
			if (poRole->GetScene() != NULL)
			{
				poRole->Update(nNowMS);
			}
		}
	}	
}




//////////////////////lua export//////////////////
void RegClassRole()
{
	REG_CLASS(Actor, false, NULL); 
	REG_CLASS(Role, false, NULL); 
	REG_CLASS(RoleMgr, false, NULL); 
}

int RoleMgr::CreateRole(lua_State* pState)
{
	int nRoleID = (int)luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	uint16_t uServer = (int16_t)luaL_checkinteger(pState, 4);
	int nSession = (int)luaL_checkinteger(pState, 5);
	Role* poRole = CreateRole(nRoleID, nConfID, psName, uServer, nSession);
	if (poRole != NULL)
	{
		Lunar<Role>::push(pState, poRole);
		return 1;
	}
	return 0;
}

int RoleMgr::RemoveRole(lua_State* pState)
{
	int nRoleID = (int)luaL_checkinteger(pState, 1);
	RemoveRole(nRoleID);
	return 0;
}

int RoleMgr::GetRole(lua_State* pState)
{
	int nRoleID = (int)luaL_checkinteger(pState, 1);
	Role* poRole = GetRoleByID(nRoleID);
	if (poRole != NULL)
	{
		Lunar<Role>::push(pState, poRole);
		return 1;
	}
	return 0;
}

int RoleMgr::SetFollow(lua_State* pState)
{
	int nTarObjID = (int)luaL_checkinteger(pState, 1);
	if (!lua_istable(pState, 2))
		return LuaWrapper::luaM_error(pState, "跟随参数2必须是表");

	RoleMgr* poRoleMgr = this;
	Object* poTarObj = poRoleMgr->GetRoleByID(nTarObjID);
	if (poTarObj == NULL)
		XLog(LEVEL_INFO, "跟随目标角色不存在 %d\n", nTarObjID);

	std::unordered_map<int, int> oClearFollowMap;

	//清理旧的跟随者
	for (int i = 0; i < m_oFollowVec.size(); i++)
	{
		int nObjID = m_oFollowVec[i];
		Object* poFollowObj = poRoleMgr->GetRoleByID(nObjID);
		if (poFollowObj == NULL) continue;
		poFollowObj->SetFollowTarget(0);
		oClearFollowMap[nObjID] = 1;
	}

	m_oFollowVec.clear();
	if (poTarObj != NULL)
		poTarObj->SetFollowTarget(0);

	//设置新的跟随者
	int nTableLen = (int)lua_rawlen(pState, 2);
	if (nTableLen > 0)
	{
		for (int i = 0; i < nTableLen; i++)
		{
			lua_rawgeti(pState, 2, i+1);
			int nObjID = (int)lua_tointeger(pState, -1);
			if (nObjID != nTarObjID)
			{
				Object* poFollowObj = poRoleMgr->GetRoleByID(nObjID);
				if (poFollowObj == NULL) continue;

				m_oFollowVec.push_back(nObjID);
				poFollowObj->SetFollowTarget(nTarObjID);
				oClearFollowMap.erase(nObjID);
			}
			else
			{
				XLog(LEVEL_ERROR, "自己不能跟随自己 %d\n", nTarObjID);
			}
		}
	}

	//脱离跟随的角色同步坐标
	while (oClearFollowMap.size() > 0)
	{
		std::unordered_map<int, int>::iterator iter = oClearFollowMap.begin();
		Object* poFollowObj = poRoleMgr->GetRoleByID(iter->second);
		oClearFollowMap.erase(iter);
		if (poFollowObj == NULL) continue;
		poFollowObj->BroadcastPos(true);
	}
	return 0;
}
