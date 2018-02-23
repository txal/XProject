#ifndef __DROPITEMMGR_H__
#define __DROPITEMMGR_H__

#include "Include/Script/Script.hpp"
#include "DropItem.h"
#include "Server/Base/ServerContext.h"

class DropItemMgr
{
public:
	LUNAR_DECLARE_CLASS(DropItemMgr);

	typedef std::unordered_map<int64_t, DropItem*> DropItemMap;
	typedef DropItemMap::iterator DropItemIter;

public:
	DropItemMgr();
	DropItem* CreateDropItem(int nID, int nConfID, const char* psName, int nAliveTime, int nCamp);
	DropItem* GetDropItemByID(int nID);

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