#include "Server/LogicServer/GameObject/DropItem/DropItemMgr.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"

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
	m_oDropItemMap.clear();
}

DropItem* DropItemMgr::CreateDropItem(int64_t nObjID, int nConfID, const char* psName, int nAliveTime, int nCamp)
{
	DropItem* poDropItem = GetDropItemByID(nObjID);
	if (poDropItem != NULL)
	{
		XLog(LEVEL_ERROR, "CreateDropItem: %lld exist\n", nObjID);
		return NULL;
	}
	poDropItem = XNEW(DropItem);
	poDropItem->Init(nObjID, nConfID, psName, nAliveTime, nCamp);
	m_oDropItemMap[nObjID] = poDropItem;
	return poDropItem;
}

DropItem* DropItemMgr::GetDropItemByID(int64_t nObjID)
{
	DropItemIter iter = m_oDropItemMap.find(nObjID);
	if (iter != m_oDropItemMap.end() && !iter->second->IsDeleted())
	{
		return iter->second;
	}
	return NULL;
}

void DropItemMgr::RemoveDropItemByID(int64_t nObjID)
{
	DropItem* poDropItem = GetDropItemByID(nObjID);
	if (poDropItem == NULL)
	{
		return;
	}
	if (poDropItem->GetScene() != NULL)
	{
		poDropItem->GetScene()->LeaveScene(poDropItem->GetAOIID(), false);
	}
	poDropItem->MarkDeleted();
}

void DropItemMgr::Update(int64_t nNowMS)
{
	static int64_t nLastUpdateTime = 0;
	if (nNowMS - nLastUpdateTime < 1000)
	{
		return;
	}
	nLastUpdateTime = nNowMS;

	DropItemIter iter = m_oDropItemMap.begin();
	DropItemIter iter_end = m_oDropItemMap.end();
	for (; iter != iter_end; )
	{
		DropItem* poDropItem = iter->second;
		if (poDropItem->IsDeleted())
		{
			iter = m_oDropItemMap.erase(iter);
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
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
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
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	DropItem* poDropItem = GetDropItemByID(nObjID);
	if (poDropItem != NULL)
	{
		Lunar<DropItem>::push(pState, poDropItem);
		return 1;
	}
	return 0;
}

int DropItemMgr::RemoveDropItem(lua_State* pState)
{
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	RemoveDropItemByID(nObjID);
	return 0;
}
