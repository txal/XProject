#include "DropItemMgr.h"

LUNAR_IMPLEMENT_CLASS(DropItemMgr)
{
	LUNAR_DECLARE_METHOD(DropItemMgr, CreateDropItem),
	LUNAR_DECLARE_METHOD(DropItemMgr, GetDropItem),
	{0, 0}
};


DropItemMgr::DropItemMgr()
{
}

DropItemMgr::~DropItemMgr()
{
	DropItemIter iter = m_oDropItemMap.begin();
	for (iter; iter != m_oDropItemMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

DropItem* DropItemMgr::CreateDropItem(int nID, int nConfID, const char* psName, int nAliveTime, int nCamp)
{
	DropItem* poDropItem = GetDropItemByID(nID);
	if (poDropItem != NULL)
	{
		XLog(LEVEL_ERROR, "CreateDropItem: %lld exist\n", nID);
		return NULL;
	}
	poDropItem = XNEW(DropItem);
	poDropItem->Init(nID, nConfID, psName, nAliveTime, nCamp);
	m_oDropItemMap[nID] = poDropItem;
	return poDropItem;
}

DropItem* DropItemMgr::GetDropItemByID(int nID)
{
	DropItemIter iter = m_oDropItemMap.find(nID);
	if (iter != m_oDropItemMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void DropItemMgr::Update(int64_t nNowMS)
{
	static int nLastUpdateTime = 0;
	int nNowSec = (int)time(0);
	if (nLastUpdateTime == nNowSec)
		return;
	nLastUpdateTime = nNowSec;

	DropItemIter iter = m_oDropItemMap.begin();
	DropItemIter iter_end = m_oDropItemMap.end();
	for (; iter != iter_end; )
	{
		DropItem* poDropItem = iter->second;
		if (poDropItem->IsTime2Collect(nNowMS))
		{
			iter = m_oDropItemMap.erase(iter);
			 LuaWrapper::Instance()->FastCallLuaRef<void>("OnObjCollected", 0, "ii", poDropItem->GetID(), poDropItem->GetType());
			SAFE_DELETE(poDropItem);
			continue;
		}
		if (poDropItem->GetScene() != NULL)
		{
			poDropItem->Update(nNowMS);
		}
		iter++;
	}	
}




////////////////////////lua export///////////////////////
void RegClassDropItem()
{
	REG_CLASS(DropItem, false, NULL); 
	REG_CLASS(DropItemMgr, false, NULL); 
}

int DropItemMgr::CreateDropItem(lua_State* pState)
{
	int nObjID = (int)luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	int nAliveTime  = (int)luaL_checkinteger(pState, 4);
	int nCamp = (int)luaL_checkinteger(pState, 5);
	DropItem* poDropItem = CreateDropItem(nObjID, nConfID, psName, nAliveTime, nCamp);
	if (poDropItem != NULL)
	{
		Lunar<DropItem>::push(pState, poDropItem);
		return 1;
	}
	return 0;
}

int DropItemMgr::GetDropItem(lua_State* pState)
{
	int nObjID = (int)luaL_checkinteger(pState, 1);
	DropItem* poDropItem = GetDropItemByID(nObjID);
	if (poDropItem != NULL)
	{
		Lunar<DropItem>::push(pState, poDropItem);
		return 1;
	}
	return 0;
}