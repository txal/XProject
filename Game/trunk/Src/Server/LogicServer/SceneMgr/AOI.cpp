#include "Server/LogicServer/SceneMgr/AOI.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/Object/Object.h"
#include "Server/LogicServer/SceneMgr/Scene.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

AOI::AOI()
{
	m_poScene = NULL;	
	m_nMapPixelWidth = 0;
	m_nMapPixelHeight = 0;
	m_nXTowerNum = 0;
	m_nYTowerNum = 0;
	m_pTowerArray = NULL;
	m_nLastClearMSTime = XTime::MSTime();
}

AOI::~AOI()
{
	int nTotalTowerNum = m_nXTowerNum * m_nYTowerNum;
	for (int i = 0; i < nTotalTowerNum; i++)
	{
		Tower* poTower = m_pTowerArray[i];
		SAFE_DELETE(poTower);
	}
	SAFE_FREE(m_pTowerArray);

	AOIObjIter iter = m_oObjMap.begin();
	AOIObjIter iter_end = m_oObjMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

bool AOI::Init(Scene* pScene, int nMapWidth, int nMapHeight)
{
	assert(nMapWidth <= 0x7FFF && nMapHeight <= 0x7FFF);
	if (pScene == NULL || nMapWidth <= 0 || nMapHeight <= 0)
	{
		return false;
	}
	m_poScene = pScene;
	m_nMapPixelWidth = nMapWidth;
	m_nMapPixelHeight = nMapHeight;
	m_nMapWidthUnit = (int)ceil((double)m_nMapPixelWidth / gnUnitWidth);
	m_nMapHeightUnit = (int)ceil((double)m_nMapPixelHeight / gnUnitHeight);
	m_nXTowerNum = (int)ceil((double)m_nMapWidthUnit / gnTowerWidth);
	m_nYTowerNum = (int)ceil((double)m_nMapHeightUnit / gnTowerHeight);
	int nEdgeTowerWidth = XMath::Max(0, m_nMapWidthUnit - (m_nXTowerNum - 1) * gnTowerWidth);
	int nEdgeTowerHeight = XMath::Max(0, m_nMapHeightUnit - (m_nYTowerNum - 1) * gnTowerHeight);

	int nTotalTowerNum = m_nXTowerNum * m_nYTowerNum;
	m_pTowerArray = (Tower**)XALLOC(NULL, nTotalTowerNum * sizeof(Tower*));

	int nRealTowerWidth = gnTowerWidth;
	int nRealTowerHeight = gnTowerHeight; 
	for (int y = 0 ; y < m_nYTowerNum; y++)
	{
		int nRealY = y * gnTowerHeight;
		if (y == m_nYTowerNum - 1)
		{
			nRealTowerHeight = nEdgeTowerHeight;
		}
		for (int x = 0; x < m_nXTowerNum; x++)
		{
			int nRealX = x * gnTowerWidth;
			if (x == m_nXTowerNum - 1)
			{
				nRealTowerWidth = nEdgeTowerWidth;
			}
			else
			{
				nRealTowerWidth = gnTowerWidth;
			}
			Tower* pTower = XNEW(Tower)(nRealX, nRealY, nRealTowerWidth, nRealTowerHeight);	
			m_pTowerArray[y * m_nXTowerNum + x] = pTower;
		}
	}
	return true;
}

int AOI::AddObj(int nPosX, int nPosY, int8_t nAOIMode, int8_t nAOIType, int nAOIArea[], Object* poGameObj)
{
	if (nAOIMode & AOI_MODE_DROP)
	{
		return -1;
	}
	if (!(nAOIType == AOI_TYPE_RECT || nAOIType == AOI_TYPE_CIRCLE))
	{
		return -1;
	}
	nPosX = XMath::Min(m_nMapPixelWidth-1, XMath::Max(0, nPosX));
	nPosY = XMath::Min(m_nMapPixelWidth-1, XMath::Max(0, nPosY));
	nAOIArea[0] = XMath::Max(nAOIArea[0], 0);
	nAOIArea[1] = XMath::Max(nAOIArea[1], 0);

	AOI_OBJ* pObj = XNEW(AOI_OBJ);	
	pObj->nRef = 0;
	pObj->nAOIObjID = GenObjID();
	pObj->nAOIMode = AOI_MODE_NONE;
	pObj->nAOIType = nAOIType;
	pObj->nPos[0] = (int16_t)nPosX;
	pObj->nPos[1] = (int16_t)nPosY;
	pObj->nArea[0] = (int16_t)nAOIArea[0];
	pObj->nArea[1] = (int16_t)nAOIArea[1];
	pObj->poGameObj = poGameObj;
	m_oObjMap.insert(std::make_pair(pObj->nAOIObjID, pObj));
	m_poScene->OnObjEnterScene(pObj);

	if (nAOIMode & AOI_MODE_OBSERVER)
	{
		assert(pObj->nArea[0] > 0 && pObj->nArea[1] > 0);
		AddObserver(pObj->nAOIObjID);
	} 

	if (nAOIMode & AOI_MODE_OBSERVED)
	{
		AddObserved(pObj->nAOIObjID);
	}

	m_poScene->AfterObjEnterScene(pObj);
	return pObj->nAOIObjID;
}

void AOI::MoveObj(int nID, int nPosX, int nPosY)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP))
	{
		return;
	}
	nPosX = XMath::Max(0, XMath::Min(nPosX, m_nMapPixelWidth - 1));
	nPosY = XMath::Max(0, XMath::Min(nPosY, m_nMapPixelHeight - 1));
	int nOldPos[2] = {pObj->nPos[0], pObj->nPos[1]};
	int nNewPos[2] = {nPosX, nPosY};
	int nUnitXOld = nOldPos[0] / gnUnitWidth;
	int nUnitYOld = nOldPos[1] / gnUnitHeight;
	int nUnitXNew = nNewPos[0] / gnUnitWidth;
	int nUnitYNew = nNewPos[1] / gnUnitHeight;
	if (nUnitXOld == nUnitXNew && nUnitYOld == nUnitYNew)
	{
		return;
	}
	pObj->nPos[0] = (int16_t)nNewPos[0];
	pObj->nPos[1] = (int16_t)nNewPos[1];
	if (pObj->nAOIMode & AOI_MODE_OBSERVER)
	{
		MoveObserver(pObj, nOldPos, nNewPos);
	}
	if (pObj->nAOIMode & AOI_MODE_OBSERVED)
	{
		MoveObserved(pObj, nOldPos, nNewPos);
	}
}

void AOI::MoveObserver(AOI_OBJ* pObj, int nOldPos[2], int nNewPos[2])
{
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return;
	}
	int nOldLeftTopTower[2] = {-1, -1};
	int nOldRightBottomTower[2] = {-1, -1};

	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalRectTowerArea(nOldPos[0], nOldPos[1], pObj->nArea[0], pObj->nArea[1], nOldLeftTopTower, nOldRightBottomTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalCircleTowerArea(nOldPos[0], nOldPos[1], pObj->nArea[0], nOldLeftTopTower, nOldRightBottomTower);
	}
	int nNewLeftTopTower[2] = {-1, -1};
	int nNewRightBottomTower[2] = {-1, -1};
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalRectTowerArea(nNewPos[0], nNewPos[1], pObj->nArea[0], pObj->nArea[1], nNewLeftTopTower, nNewRightBottomTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalCircleTowerArea(nNewPos[0], nNewPos[1], pObj->nArea[0], nNewLeftTopTower, nNewRightBottomTower);
	}
	// Check if the observer arena equal
	if (nOldLeftTopTower[0] == nNewLeftTopTower[0] && nOldLeftTopTower[1] == nNewLeftTopTower[1]
		&& nOldRightBottomTower[0] == nNewRightBottomTower[0] && nOldRightBottomTower[1] == nNewRightBottomTower[1])
	{
		return;
	}

	m_oObjCache.Clear();
	for (int oy = nOldLeftTopTower[1]; oy <= nOldRightBottomTower[1]; oy++)
	{
		for (int ox = nOldLeftTopTower[0]; ox <= nOldRightBottomTower[0]; ox++)
		{
			if (ox < nNewLeftTopTower[0] || ox > nNewRightBottomTower[0] || oy < nNewLeftTopTower[1] || oy > nNewRightBottomTower[1])
			{
				Tower* pTower = m_pTowerArray[oy * m_nXTowerNum + ox];
				Array<AOI_OBJ*>& ObservedSet = pTower->GetObservedSet();
				for (int i = 0; i < ObservedSet.Size(); i++)
				{
					if (ObservedSet[i] == pObj)
					{
						continue;
					}
					m_oObjCache.PushBack(ObservedSet[i]);
				}
				if (!pTower->RemoveObserver(pObj))
				{
					XLog(LEVEL_ERROR, "MoveObserver: remove observer:%d fail\n", pObj->nAOIObjID);
				}
			}
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(pObj, m_oObjCache);
	}

	m_oObjCache.Clear();
	for (int ny = nNewLeftTopTower[1]; ny <= nNewRightBottomTower[1]; ny++)
	{
		for (int nx = nNewLeftTopTower[0]; nx <= nNewRightBottomTower[0]; nx++)
		{
			if (nx < nOldLeftTopTower[0] || nx > nOldRightBottomTower[0] || ny < nOldLeftTopTower[1] || ny > nOldRightBottomTower[1])
			{
				Tower* pTower = m_pTowerArray[ny * m_nXTowerNum + nx];
				Array<AOI_OBJ*>& ObservedSet = pTower->GetObservedSet();
				for (int i = 0; i < ObservedSet.Size(); i++)
				{
					if (pObj == ObservedSet[i])
					{
						continue;
					}
					m_oObjCache.PushBack(ObservedSet[i]);
				}
				pTower->AddObserver(pObj);
			}
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(pObj, m_oObjCache);
	}
}

void AOI::MoveObserved(AOI_OBJ* pObj, int nOldPos[2], int nNewPos[2])
{
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return;
	}
	int nOldTowerX = -1;
	int nOldTowerY = -1;
	CalTowerPos(nOldPos[0], nOldPos[1], nOldTowerX, nOldTowerY);

	int nNewTowerX = -1;
	int nNewTowerY = -1;
	CalTowerPos(nNewPos[0], nNewPos[1], nNewTowerX, nNewTowerY);

	// Check if the observed tower equal
	if (nOldTowerX == nNewTowerX && nOldTowerY == nNewTowerY)
	{
		return;
	}

	m_oObjCache.Clear();
	Tower* pOldTower = m_pTowerArray[nOldTowerY * m_nXTowerNum + nOldTowerX];
	Array<AOI_OBJ*>& oOldObserverSet = pOldTower->GetObserverSet();
	for (int i = 0; i < oOldObserverSet.Size(); i++)
	{
		AOI_OBJ* pObserver = oOldObserverSet[i];
		if (pObserver == pObj)
		{
			continue;
		}
		int nLeftTopTower[2] = {-1, -1};
		int nRightBottomTower[2] = {-1, -1};
		if (pObserver->nAOIType == AOI_TYPE_RECT)
		{
			CalRectTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], pObserver->nArea[1], nLeftTopTower, nRightBottomTower);
		}
		else if (pObserver->nAOIType == AOI_TYPE_CIRCLE)
		{
			CalCircleTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], nLeftTopTower, nRightBottomTower);
		}

		if (nNewTowerX < nLeftTopTower[0] || nNewTowerX > nRightBottomTower[0] || nNewTowerY < nLeftTopTower[1] || nNewTowerY > nRightBottomTower[1])
		{
			m_oObjCache.PushBack(pObserver);
		}
	}
	if (!pOldTower->RemoveObserved(pObj))
	{
		XLog(LEVEL_ERROR, "Remove observed:%d fail\n", pObj->nAOIObjID);
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(m_oObjCache, pObj);
	}

	m_oObjCache.Clear();
	Tower* pNewTower = m_pTowerArray[nNewTowerY * m_nXTowerNum + nNewTowerX];
	Array<AOI_OBJ*>& oNewObserverSet = pNewTower->GetObserverSet();
	for (int i = 0; i < oNewObserverSet.Size(); i++)
	{
		AOI_OBJ* pObserver = oNewObserverSet[i];
		if (pObserver == pObj)
		{
			continue;
		}
		int nLeftTopTower[2] = {-1, -1};
		int nRightBottomTower[2] = {-1, -1};
		if (pObserver->nAOIType == AOI_TYPE_RECT)
		{
			CalRectTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], pObserver->nArea[1], nLeftTopTower, nRightBottomTower);
		}
		else if (pObserver->nAOIType == AOI_TYPE_CIRCLE)
		{
			CalCircleTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], nLeftTopTower, nRightBottomTower);
		}
		if (nOldTowerX < nLeftTopTower[0] || nOldTowerX > nRightBottomTower[0] || nOldTowerY < nLeftTopTower[1] || nOldTowerY > nRightBottomTower[1])
		{
			m_oObjCache.PushBack(pObserver);
		}
	}
	pNewTower->AddObserved(pObj);
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(m_oObjCache, pObj);
	}
}

void AOI::RemoveObj(int nID)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP))
	{
		return;
	}
	RemoveObserver(nID, true);
	RemoveObserved(nID);
	if (pObj->nAOIMode == 0)
	{
		if (pObj->nRef != 0)
		{
			XLog(LEVEL_ERROR, "RemoverObj:%d ref error:%d/%d\n", pObj->nAOIObjID, pObj->nAOIMode, pObj->nRef);
		}
		m_poScene->OnObjLeaveScene(pObj);
		pObj->nAOIMode = AOI_MODE_DROP;
		pObj->poGameObj = NULL;
	}
}

void AOI::AddObserver(int nID)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP) || (pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return;
	}
	pObj->nAOIMode |= AOI_MODE_OBSERVER;
	int nLeftTopTower[2] = { -1, -1 };
	int nRightBottomTower[2] = { -1, -1 };
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalRectTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], pObj->nArea[1], nLeftTopTower, nRightBottomTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalCircleTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], nLeftTopTower, nRightBottomTower);
	}

	m_oObjCache.Clear();
	for (int y = nLeftTopTower[1]; y <= nRightBottomTower[1]; y++)
	{
		for (int x = nLeftTopTower[0]; x <= nRightBottomTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			Array<AOI_OBJ*>& ObservedSet = pTower->GetObservedSet();
			for (int i = 0; i < ObservedSet.Size(); i++)
			{
				if (ObservedSet[i] == pObj)
				{
					continue;
				}
				m_oObjCache.PushBack(ObservedSet[i]);
			}
			pTower->AddObserver(pObj);
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(pObj, m_oObjCache);
	}
}

void AOI::RemoveObserver(int nID, bool bLeaveScene)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return;
	}

	int nLeftTopTower[2] = {-1, -1};
	int nRightBottomTower[2] = {-1, -1};
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalRectTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], pObj->nArea[1], nLeftTopTower, nRightBottomTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalCircleTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], nLeftTopTower, nRightBottomTower);
	}
	m_oObjCache.Clear();
	for (int y = nLeftTopTower[1]; y <= nRightBottomTower[1]; y++)
	{
		for (int x = nLeftTopTower[0]; x <= nRightBottomTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			Array<AOI_OBJ*>& ObservedSet = pTower->GetObservedSet();
			for (int i = 0; i < ObservedSet.Size(); i++)
			{
				if (ObservedSet[i] == pObj)
				{
					continue;
				}
				m_oObjCache.PushBack(ObservedSet[i]);
			}
			pTower->RemoveObserver(pObj);
		}
	}
	if (!bLeaveScene && m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(pObj, m_oObjCache);
	}

	pObj->nAOIMode &= ~AOI_MODE_OBSERVER;
	if (pObj->nAOIMode == 0 && pObj->nRef != 0)
	{
		XLog(LEVEL_ERROR, "RemoverObserver:%d ref error:%d/%d\n", pObj->nAOIObjID, pObj->nAOIMode, pObj->nRef);
	}
}

void AOI::AddObserved(int nID)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP) || (pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return;
	}
	pObj->nAOIMode |= AOI_MODE_OBSERVED;
	int nTowerX = -1;
	int nTowerY = -1;
	CalTowerPos(pObj->nPos[0], pObj->nPos[1], nTowerX, nTowerY);

	m_oObjCache.Clear();
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	Array<AOI_OBJ*>& ObserverSet = pTower->GetObserverSet();
	for (int i = 0; i < ObserverSet.Size(); i++)
	{
		if (ObserverSet[i] == pObj)
		{
			continue;
		}
		m_oObjCache.PushBack(ObserverSet[i]);
	}
	pTower->AddObserved(pObj);
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(m_oObjCache, pObj);
	}
}

void AOI::RemoveObserved(int nID)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return;
	}
	int nTowerX = -1;
	int nTowerY = -1;
	CalTowerPos(pObj->nPos[0], pObj->nPos[1], nTowerX, nTowerY);

	m_oObjCache.Clear();
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	Array<AOI_OBJ*>& oObserverSet = pTower->GetObserverSet();
	for (int i = 0; i < oObserverSet.Size(); i++)
	{
		if (oObserverSet[i] == pObj)
		{
			continue;
		}
		m_oObjCache.PushBack(oObserverSet[i]);
	}
	pTower->RemoveObserved(pObj);
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(m_oObjCache, pObj);
	}

	pObj->nAOIMode &= ~AOI_MODE_OBSERVED;
	if (pObj->nAOIMode == 0 && pObj->nRef != 0)
	{
		XLog(LEVEL_ERROR, "RemoveObserved:%d ref error:%d/%d\n", pObj->nAOIObjID, pObj->nAOIMode, pObj->nRef);
	}
}

void AOI::GetAreaObservers(int nID, Array<AOI_OBJ*>& oObjCache, int nGameObjType)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return;
	}
	int nTowerX = -1;
	int nTowerY = -1;
	CalTowerPos(pObj->nPos[0], pObj->nPos[1], nTowerX, nTowerY);
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	Array<AOI_OBJ*>& oObserverSet = pTower->GetObserverSet();
	for (int i = 0; i < oObserverSet.Size(); i++)
	{
		if (oObserverSet[i] == pObj)
		{
			continue;
		}
		if (nGameObjType == 0 || oObserverSet[i]->poGameObj->GetType() == nGameObjType)
		{
			oObjCache.PushBack(oObserverSet[i]);
		}
	}
}

void AOI::GetAreaObserveds(int nID, Array<AOI_OBJ*>& oObjCache, int nGameObjType)
{
	AOI_OBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return;
	}
	int nLeftTopTower[2] = {-1, -1};
	int nRightBottomTower[2] = {-1, -1};
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalRectTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], pObj->nArea[1], nLeftTopTower, nRightBottomTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalCircleTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], nLeftTopTower, nRightBottomTower);
	}
	for (int y = nLeftTopTower[1]; y <= nRightBottomTower[1]; y++)
	{
		for (int x = nLeftTopTower[0]; x <= nRightBottomTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			Array<AOI_OBJ*>& oObservedSet = pTower->GetObservedSet();
			for (int i = 0; i < oObservedSet.Size(); i++)
			{
				if (oObservedSet[i] == pObj)
				{
					continue;
				}
				if (nGameObjType == 0 || oObservedSet[i]->poGameObj->GetType() == nGameObjType)
				{
					oObjCache.PushBack(oObservedSet[i]);
				}
			}
		}
	}
}

void AOI::PrintTower()
{
	for (int y = 0; y < m_nYTowerNum; y++)
	{
		bool bPrint = false;
		for (int x = 0; x < m_nXTowerNum; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			Array<AOI_OBJ*>& ObserverSet = pTower->GetObserverSet();
			Array<AOI_OBJ*>& ObservedSet = pTower->GetObservedSet();
			if (ObserverSet.Size() > 0 || ObservedSet.Size() > 0)
			{
				XLog(LEVEL_DEBUG, "[%d,%d](%d,%d) ", y, x, ObserverSet.Size(), ObservedSet.Size());
				bPrint = true;
			}
		}
		if (bPrint)
		{
			XLog(LEVEL_DEBUG, "\n");
		}
	}
	XLog(LEVEL_DEBUG, "\n");
}

int AOI::GenObjID()
{
	static int nIndex = 0;
	nIndex = nIndex % 0x7FFFFFFF + 1;
	return nIndex;
}

AOI_OBJ* AOI::GetObj(int nID)
{
	AOIObjIter iter = m_oObjMap.find(nID);
	if (iter != m_oObjMap.end())
	{
		if (!(iter->second->nAOIMode & AOI_MODE_DROP))
		{
			return iter->second;
		}
	}
	return NULL;
}

void AOI::ClearDropObj(int64_t nNowMS)
{
	m_nLastClearMSTime = nNowMS;
	AOIObjIter iter = m_oObjMap.begin();
	for (; iter != m_oObjMap.end(); )
	{
		if (iter->second->nAOIMode & AOI_MODE_DROP)
		{
			AOI_OBJ* poObj = iter->second;
			iter = m_oObjMap.erase(iter);
			SAFE_DELETE(poObj);
			continue;
		}
		iter++;
	}
}

void AOI::CalTowerPos(int nPosX, int nPosY, int& nTowerX, int& nTowerY)
{
	nPosX = XMath::Max(0, XMath::Min(nPosX, m_nMapPixelWidth - 1));
	nPosY = XMath::Max(0, XMath::Min(nPosY, m_nMapPixelHeight - 1));
	nTowerX = nPosX / gnUnitWidth / gnTowerWidth;
	nTowerY = nPosY / gnUnitHeight / gnTowerHeight;
}

void AOI::CalCircleTowerArea(int nPosX, int nPosY, int nRadius, int nLeftTopTower[2], int nRightBottomTower[2])
{
	int nLeftTopX = XMath::Max(0, nPosX - nRadius);
	int nRightBottomX = XMath::Min(m_nMapPixelWidth - 1, nPosX + nRadius);
	int nLeftTopY = XMath::Max(0, nPosY - nRadius);
	int nRightBottomY = XMath::Min(m_nMapPixelHeight - 1, nPosY + nRadius);

	// fix pz (Edge deal)

	int nTowerWidthPixel = gnUnitWidth * gnTowerWidth;
	int nTowerHeightPixel = gnUnitHeight * gnTowerHeight;

	int nLeftTopTowerX = nLeftTopX / nTowerWidthPixel;
	int nLeftTopTowerY = nLeftTopY / nTowerHeightPixel;
	assert(nLeftTopTowerX < m_nXTowerNum && nLeftTopTowerY < m_nYTowerNum);

	int nRightBottomTowerX = nRightBottomX / nTowerWidthPixel;
	int nRightBottomTowerY = nRightBottomY / nTowerHeightPixel;
	assert(nRightBottomTowerX < m_nXTowerNum && nRightBottomTowerY < m_nYTowerNum);

	nLeftTopTower[0] = nLeftTopTowerX;
	nLeftTopTower[1] = nLeftTopTowerY;
	nRightBottomTower[0] = nRightBottomTowerX;
	nRightBottomTower[1] = nRightBottomTowerY;
}

void AOI::CalRectTowerArea(int nPosX, int nPosY, int nWidth, int nHeight, int nLeftTopTower[2], int nRightBottomTower[2])
{
	if (nWidth == 0 && nHeight == 0)
	{
		nLeftTopTower[0] = 0;
		nLeftTopTower[1] = 0;
		nRightBottomTower[0] = -1;
		nRightBottomTower[0] = -1;
		return;
	}
	int nLeftTopX = XMath::Max(0, nPosX - nWidth / 2);
	int nLeftTopY = XMath::Max(0, nPosY - nHeight / 2);
	int nRightBottomX = XMath::Min(m_nMapPixelWidth - 1, nPosX + nWidth / 2);
	int nRightBottomY = XMath::Min(m_nMapPixelHeight - 1, nPosY + nHeight / 2);

	// Edge deal
	if (nRightBottomX - nLeftTopX + 1 < nWidth)
	{
		(nLeftTopX == 0) ? (nRightBottomX = XMath::Min(nWidth - 1, m_nMapPixelWidth - 1)) : 0;
		(nRightBottomX == m_nMapPixelWidth - 1) ? (nLeftTopX = XMath::Max(0, m_nMapPixelWidth - nWidth + 1)) : 0;
	}
	if (nRightBottomY - nLeftTopY + 1 < nHeight)
	{
		(nLeftTopY == 0) ? (nRightBottomY = XMath::Min(nHeight - 1, m_nMapPixelHeight - 1)) : 0;
		(nRightBottomY == m_nMapPixelHeight - 1) ? (nLeftTopY = XMath::Max(0, m_nMapPixelHeight - nHeight + 1)) : 0;
	}

	int nTowerWidthPixel = gnUnitWidth * gnTowerWidth;
	int nTowerHeightPixel = gnUnitHeight * gnTowerHeight;

	int nLeftTopTowerX = nLeftTopX / nTowerWidthPixel;
	int nLeftTopTowerY = nLeftTopY / nTowerHeightPixel;
	assert(nLeftTopTowerX < m_nXTowerNum && nLeftTopTowerY < m_nYTowerNum);

	int nRightBottomTowerX = nRightBottomX / nTowerWidthPixel;
	int nRightBottomTowerY = nRightBottomY / nTowerHeightPixel;
	assert(nRightBottomTowerX < m_nXTowerNum && nRightBottomTowerY < m_nYTowerNum);

	nLeftTopTower[0] = nLeftTopTowerX;
	nLeftTopTower[1] = nLeftTopTowerY;
	nRightBottomTower[0] = nRightBottomTowerX;
	nRightBottomTower[1] = nRightBottomTowerY;
}

