#include "Server/LogicServer/SceneMgr/Tower.h"
#include "Server/LogicServer/SceneMgr/AOI.h"

Tower::Tower(int nX, int nY, uint16_t nTowerWidth, uint16_t nTowerHeight)
{
	assert(nX >= 0 && nX <= 0x7FFF && nY >= 0 && nY <= 0x7FFF);
	m_nLeftTop[0] = nX;
	m_nLeftTop[1] = nY;
	m_nTowerWidth = nTowerWidth;
	m_nTowerHeight = nTowerHeight;
}

void Tower::AddObserver(AOI_OBJ* pObj)
{
	m_ObserverSet.PushBack(pObj);
	pObj->nRef++;
}

void Tower::AddObserved(AOI_OBJ* pObj)
{
	m_ObservedSet.PushBack(pObj);
	pObj->nRef++;
}

bool Tower::RemoveObserver(AOI_OBJ* pObj)
{
	int nSize = m_ObserverSet.Size();
	for (int i = 0; i < nSize; i++)
	{
		if (m_ObserverSet[i] == pObj)
		{
			m_ObserverSet.Ptr()[i] = m_ObserverSet.Ptr()[--nSize];
			m_ObserverSet.SetSize(nSize);
			pObj->nRef--;
			return true;
		}
	}
	return false;
}

bool Tower::RemoveObserved(AOI_OBJ* pObj)
{
	int nSize = m_ObservedSet.Size();
	for (int i = 0; i < nSize; i++)
	{
		if (m_ObservedSet[i] == pObj)
		{
			m_ObservedSet.Ptr()[i] = m_ObservedSet.Ptr()[--nSize];
			m_ObservedSet.SetSize(nSize);
			pObj->nRef--;
			return true;
		}
	}
	return false;
}

Array<AOI_OBJ*>& Tower::GetObserverSet()
{
	return m_ObserverSet;
}

Array<AOI_OBJ*>& Tower::GetObservedSet()
{
	return m_ObservedSet;
}