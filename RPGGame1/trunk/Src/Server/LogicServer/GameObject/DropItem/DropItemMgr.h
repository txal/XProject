#ifndef __DROPITEMMGR_H__
#define __DROPITEMMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/GameObject/DropItem/DropItem.h"

class DropItemMgr
{
public:
	LUNAR_DECLARE_CLASS(DropItemMgr);

	typedef std::unordered_map<int64_t, DropItem*> DropItemMap;
	typedef DropItemMap::iterator DropItemIter;

public:
	DropItemMgr();
	~DropItemMgr();

	DropItem* CreateDropItem(int64_t nObjID, int nConfID, const char* psName, int nAliveTime, int nCamp);
	DropItem* GetDropItemByID(int64_t nObjID);
	void RemoveDropItemByID(int64_t nObjID);

public:
	void Update(int64_t nNowMS);

private:
	DISALLOW_COPY_AND_ASSIGN(DropItemMgr);



////////////////lua export///////////////////
public:
	int CreateDropItem(lua_State* pState);
	int RemoveDropItem(lua_State* pState);
	int GetDropItem(lua_State* pState);

private:
	DropItemMap m_oDropItemMap;
};




//Register to lua
void RegClassDropItem();

#endif