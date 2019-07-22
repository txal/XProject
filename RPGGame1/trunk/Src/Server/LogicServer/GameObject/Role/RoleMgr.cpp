#include "RoleMgr.h"
#include "Server/LogicServer/LogicServer.h"

LUNAR_IMPLEMENT_CLASS(RoleMgr)
{
	LUNAR_DECLARE_METHOD(RoleMgr, CreateRole),
	LUNAR_DECLARE_METHOD(RoleMgr, RemoveRole),
	LUNAR_DECLARE_METHOD(RoleMgr, GetRole),
	{0, 0}
};


RoleMgr::RoleMgr()
{
}

RoleMgr::~RoleMgr()
{
	RoleIter iter = m_oRoleIDMap.begin();
	for (iter; iter != m_oRoleIDMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
	m_oRoleSSMap.clear();
}

Role* RoleMgr::CreateRole(int64_t nObjID, int nConfID, const char* psName)
{
	Role* poRole = GetRoleByID(nObjID);
	if (poRole != NULL)
	{
		XLog(LEVEL_ERROR, "CreateRole error for role id:%lld exist\n", nObjID);
		return poRole;
	}

	poRole = XNEW(Role);
	poRole->Init(nObjID, nConfID, psName);
	m_oRoleIDMap[nObjID] = poRole;
	return poRole;
}

void RoleMgr::RemoveRole(int64_t nObjID)
{
	Role* poRole = GetRoleByID(nObjID);
	if (poRole == NULL)
	{
		return;
	}
	if (poRole->GetScene() != NULL)
	{
		poRole->GetScene()->LeaveScene(poRole->GetAOIID(), false);
	}

	BindSession(nObjID, 0);
	poRole->MarkDeleted();
}

Role* RoleMgr::GetRoleByID(int64_t nObjID)
{
	RoleIter iter = m_oRoleIDMap.find(nObjID);
	if (iter != m_oRoleIDMap.end() && !iter->second->IsDeleted())
	{
		return iter->second;
	}
	return NULL;
}

Role* RoleMgr::GetRoleBySS(uint16_t uServer, int nSession)
{
	int64_t nSSKey = GenSSKey(uServer, nSession);
	RoleIter iter = m_oRoleSSMap.find(nSSKey);
	if (iter != m_oRoleSSMap.end() && iter->second->IsDeleted())
	{
		return iter->second;
	}
	return NULL;
}

void RoleMgr::BindSession(int64_t nObjID, int nSession)
{
	Role* poRole = GetRoleByID(nObjID);
	if (poRole == NULL)
	{
		return;
	}

	int nOldSession = poRole->GetSession();
	if (nOldSession == nSession)
	{
		return;
	}
	poRole->SetSession(nSession);

	if (nOldSession > 0)
	{
		int64_t nOldSSKey = GenSSKey(poRole->GetServer(), nOldSession);
		m_oRoleSSMap.erase(nOldSSKey);

		LogicServer* poLogic = (LogicServer*)(gpoContext->GetService());
		poLogic->OnClientClose(poRole->GetServer(), nOldSession>>SERVICE_SHIFT, nOldSession);
	}

	if (nSession > 0)
	{
		int64_t nNewSSKey = GenSSKey(poRole->GetServer(), nSession);
		m_oRoleSSMap[nNewSSKey] = poRole;
	}
}

void RoleMgr::Update(int64_t nNowMS)
{
	static int64_t nLastUpdateTime = 0;
	if (nNowMS - nLastUpdateTime < 30)
	{
		return;
	}
	nLastUpdateTime = nNowMS;

	int nRoleCount = 0;
	RoleIter iter = m_oRoleIDMap.begin();
	RoleIter iter_end = m_oRoleIDMap.end();
	for (; iter != iter_end; iter++)
	{
		Role* poRole = iter->second;
		if (poRole->IsDeleted())
		{
			iter = m_oRoleIDMap.erase(iter);
			SAFE_DELETE(poRole);
			continue;
		}
		if (poRole->GetScene() != NULL)
		{
			poRole->Update(nNowMS);
		}
		nRoleCount++;
	}	

	static int64_t nLastDumpTime = 0;
	if (nNowMS-nLastDumpTime >= 60000)
	{
		nLastDumpTime = nNowMS;
		XLog(LEVEL_INFO, "CPP current role count=%d\n", nRoleCount);
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
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	Role* poRole = CreateRole(nObjID, nConfID, psName);
	if (poRole != NULL)
	{
		Lunar<Role>::push(pState, poRole);
		return 1;
	}
	return 0;
}

int RoleMgr::GetRole(lua_State* pState)
{
	int64_t nRoleID = (int64_t)luaL_checkinteger(pState, 1);
	Role* poRole = GetRoleByID(nRoleID);
	if (poRole != NULL)
	{
		Lunar<Role>::push(pState, poRole);
		return 1;
	}
	return 0;
}


int RoleMgr::RemoveRole(lua_State* pState)
{
	int64_t nRoleID = (int64_t)luaL_checkinteger(pState, 1);
	RemoveRole(nRoleID);
	return 0;
}
