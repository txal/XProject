#include "Server/LogicServer/SceneMgr/Tower.h"
#include "Server/LogicServer/SceneMgr/AOI.h"

//nUnitX,nUnitY¸ñ×Ó
Tower::Tower(int nUnitX, int nUnitY, uint16_t nTowerWidth, uint16_t nTowerHeight)
{
	assert(nUnitX >= 0 && nUnitX <= 0x7FFF && nUnitY >= 0 && nUnitY <= 0x7FFF);
	m_nLeftTop[0] = nUnitX;
	m_nLeftTop[1] = nUnitY;
	m_nTowerWidth = nTowerWidth;
	m_nTowerHeight = nTowerHeight;
}

void Tower::AddObserver(AOIOBJ* pObj)
{
	m_oObserverMap[pObj->nAOIID] = pObj;
	pObj->nRef++;
}

void Tower::AddObserved(AOIOBJ* pObj)
{
	m_oObservedMap[pObj->nAOIID] = pObj;
	pObj->nRef++;
}

bool Tower::RemoveObserver(AOIOBJ* pObj)
{
	AOIObjIter iter = m_oObserverMap.find(pObj->nAOIID);
	if (iter != m_oObserverMap.end())
	{
		m_oObserverMap.erase(iter);
		pObj->nRef--;
		assert(pObj->nRef >= 0);
		return true;
	}
	return false;
}

bool Tower::RemoveObserved(AOIOBJ* pObj)
{
	AOIObjIter iter = m_oObservedMap.find(pObj->nAOIID);
	if (iter != m_oObservedMap.end())
	{
		m_oObservedMap.erase(iter);
		pObj->nRef--;
		assert(pObj->nRef >= 0);
		return true;
	}
	return false;
}

Tower::AOIObjMap& Tower::GetObserverMap()
{
	return m_oObserverMap;
}

Tower::AOIObjMap& Tower::GetObservedMap()
{
	return m_oObservedMap;
}