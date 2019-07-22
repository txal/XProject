#ifndef __ROLEMGR_H__
#define __ROLEMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/GameObject/Role/Role.h"

class RoleMgr
{
public:
	LUNAR_DECLARE_CLASS(RoleMgr);

	typedef std::unordered_map<int64_t, Role*> RoleMap;
	typedef RoleMap::iterator RoleIter;

public:
	RoleMgr();
	~RoleMgr();

	Role* CreateRole(int64_t nObjID, int nConfID, const char* psName);
	void RemoveRole(int64_t nObjID);

	Role* GetRoleByID(int64_t nObjID);
	Role* GetRoleBySS(uint16_t uServer, int nSession);

	void BindSession(int64_t nObjID, int nSession);

public:
	void Update(int64_t nNowMS);

protected:
	int64_t GenSSKey(uint16_t uServer, int nSession) { return (int64_t)uServer << 32 | nSession; }


////////////////Lua export///////////////////
public:
	int CreateRole(lua_State* pState);
	int RemoveRole(lua_State* pState);
	int GetRole(lua_State* pState);

private:
	RoleMap m_oRoleIDMap;
	RoleMap m_oRoleSSMap;
};


//Register to lua
void RegClassRole();

#endif