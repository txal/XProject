#ifndef __ROLEMGR_H__
#define __ROLEMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/Role/Role.h"

class RoleMgr
{
public:
	LUNAR_DECLARE_CLASS(RoleMgr);

	typedef std::unordered_map<int, Role*> RoleMap;
	typedef RoleMap::iterator RoleIter;

	typedef std::unordered_map<int64_t, Role*> RoleSSMap;
	typedef RoleSSMap::iterator RoleSSIter;

	typedef std::vector<int> FollowVec;
	typedef FollowVec::iterator FollowIter;

public:
	RoleMgr();
	~RoleMgr();

	Role* CreateRole(int nID, int nConfID, const char* psName, uint16_t uServer, int nSession);
	void RemoveRole(int nID);

	Role* GetRoleByID(int nID);
	Role* GetRoleBySS(uint16_t uServer, int nSession);

	void BindSession(int nID, int nSession);

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
	RoleSSMap m_oRoleSSMap;
};


//Register to lua
void RegClassRole();

#endif