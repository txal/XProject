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
	AM& oLineAM = m_tObserverAM[pObj->nLine];
	bool bRes = oLineAM.AddObserver(pObj);
	assert(bRes);
	pObj->nRef++;
}

void Tower::AddObserved(AOIOBJ* pObj)
{
	AM& oLineAM = m_tObserverAM[pObj->nLine];
	bool bRes = oLineAM.AddObserved(pObj);
	assert(bRes);
	pObj->nRef++;
}

bool Tower::RemoveObserver(AOIOBJ* pObj)
{
	AM& oLineAM = m_tObserverAM[pObj->nLine];
	bool bRes = oLineAM.RemoveObserver(pObj);
	assert(bRes);
	pObj->nRef--;
	assert(pObj->nRef >= 0);
	return true;
}

bool Tower::RemoveObserved(AOIOBJ* pObj)
{
	AM& oLineAM = m_tObservedAM[pObj->nLine];
	bool bRes = oLineAM.RemoveObserved(pObj);
	assert(bRes);
	pObj->nRef--;
	assert(pObj->nRef >= 0);
	return true;
}

Array<AOIOBJ*>& Tower::GetObserverList(int nLine)
{
	
}

Array<AOIOBJ*>& Tower::GetObservedList(int nLine)
{

}
