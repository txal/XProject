#include "Server/LogicServer/SceneMgr/Tower.h"
#include "Server/LogicServer/Object/Object.h"
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

Tower::~Tower()
{
	LineIter iter = m_oObserverLine.begin();
	for (iter; iter != m_oObserverLine.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
	iter = m_oObservedLine.begin();
	for (iter; iter != m_oObservedLine.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

Tower::AOIObjMap* Tower::GetLineObserverMap(int nLine)
{
	LineIter iter = m_oObserverLine.find(nLine);
	if (iter != m_oObserverLine.end())
	{
		return iter->second;
	}
	AOIObjMap* pObjMap = XNEW(Tower::AOIObjMap)();
	m_oObserverLine[nLine] = pObjMap;
	return pObjMap;
}

void Tower::RemoveLineObserverMap(int nLine)
{
	LineIter iter = m_oObserverLine.find(nLine);
	if (iter != m_oObserverLine.end())
	{
		SAFE_DELETE(iter->second);
		m_oObserverLine.erase(iter);
	}
}

Tower::AOIObjMap* Tower::GetLineObservedMap(int nLine)
{
	LineIter iter = m_oObservedLine.find(nLine);
	if (iter != m_oObservedLine.end())
	{
		return iter->second;
	}
	AOIObjMap* pObjMap = XNEW(Tower::AOIObjMap)();;
	m_oObservedLine[nLine] = pObjMap;
	return pObjMap;
}

void Tower::RemoveLineObservedMap(int nLine)
{
	LineIter iter = m_oObservedLine.find(nLine);
	if (iter != m_oObservedLine.end())
	{
		SAFE_DELETE(iter->second);
		m_oObservedLine.erase(iter);
	}
}

void Tower::AddObserver(AOIOBJ* pObj)
{
	Tower::AOIObjMap* pObjMap = GetLineObserverMap(pObj->nLine);
	(*pObjMap)[pObj->nAOIID] = pObj;
	pObj->nRef++;
}

void Tower::AddObserved(AOIOBJ* pObj)
{
	Tower::AOIObjMap* pObjMap = GetLineObservedMap(pObj->nLine);;
	(*pObjMap)[pObj->nAOIID] = pObj;;
	pObj->nRef++;
}

bool Tower::RemoveObserver(AOIOBJ* pObj)
{
	Tower::AOIObjMap* pObjMap = GetLineObserverMap(pObj->nLine);;
	Tower::AOIObjIter iter = pObjMap->find(pObj->nAOIID);
	if (iter != pObjMap->end())
	{
		pObjMap->erase(iter);
		pObj->nRef--;
		assert(pObj->nRef >= 0);
		if (pObjMap->size() <= 0)
		{
			RemoveLineObserverMap(pObj->nLine);
		}
		return true;
	}
	return false;
}

bool Tower::RemoveObserved(AOIOBJ* pObj)
{
	Tower::AOIObjMap* pObjMap = GetLineObservedMap(pObj->nLine);;
	Tower::AOIObjIter iter = pObjMap->find(pObj->nAOIID);
	if (iter != pObjMap->end())
	{
		pObjMap->erase(iter);
		pObj->nRef--;
		assert(pObj->nRef >= 0);
		if (pObjMap->size() <= 0)
		{
			RemoveLineObservedMap(pObj->nLine);
		}
		return true;
	}
	return false;
}

void Tower::CacheAOIObj(AOIObjMap* pObjMap, AOIOBJ* pObj, Array<AOIOBJ*>& oObjCache, int nObjType)
{
	for (AOIObjIter objiter = pObjMap->begin(); objiter != pObjMap->end(); objiter++)
	{
		AOIOBJ* pTmpObj = objiter->second;
		if (pTmpObj == pObj)
			continue;
		if (nObjType != 0 && nObjType != pTmpObj->poGameObj->GetType())
			continue;
		oObjCache.PushBack(pTmpObj);
	}
}

void Tower::GetObserverList(AOIOBJ* pObj, Array<AOIOBJ*>& oObjCache, int nObjType)
{
	if (pObj->nLine == 0)
	{
		LineIter iter = m_oObserverLine.begin();
		for (iter; iter != m_oObserverLine.end(); iter++)
		{
			AOIObjMap* pObjMap= iter->second;
			if (pObjMap->size() > 0)
			{
				CacheAOIObj(pObjMap, pObj, oObjCache, nObjType);
			}
		}
	}
	else
	{
		LineIter iter = m_oObserverLine.find(0);
		if (iter != m_oObserverLine.end())
		{
			AOIObjMap* pObjMap= iter->second;
			if (pObjMap->size() > 0)
			{
				CacheAOIObj(pObjMap, pObj, oObjCache, nObjType);
			}
		}
		iter = m_oObserverLine.find(pObj->nLine);
		if (iter != m_oObserverLine.end())
		{
			AOIObjMap* pObjMap= iter->second;
			if (pObjMap->size() > 0)
			{
				CacheAOIObj(pObjMap, pObj, oObjCache, nObjType);
			}
		}
	}
}

void Tower::GetObservedList(AOIOBJ* pObj, Array<AOIOBJ*>& oObjCache, int nObjType)
{
	if (pObj->nLine == 0)
	{
		LineIter iter = m_oObservedLine.begin();
		for (iter; iter != m_oObservedLine.end(); iter++)
		{
			AOIObjMap* pObjMap = iter->second;
			if (pObjMap->size() > 0)
			{
				CacheAOIObj(pObjMap, pObj, oObjCache, nObjType);
			}
		}
	}
	else
	{
		LineIter iter = m_oObservedLine.find(0);
		if (iter != m_oObservedLine.end())
		{
			AOIObjMap* pObjMap = iter->second;
			if (pObjMap->size() > 0)
			{
				CacheAOIObj(pObjMap, pObj, oObjCache, nObjType);
			}
		}
		iter = m_oObservedLine.find(pObj->nLine);
		if (iter != m_oObservedLine.end())
		{
			AOIObjMap* pObjMap = iter->second;
			if (pObjMap->size() > 0)
			{
				CacheAOIObj(pObjMap, pObj, oObjCache, nObjType);
			}
		}
	}
}
