#include "Server/LogicServer/SceneMgr/AOI.h"

#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/CDebug.h"
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
	memset(m_tLineObj, 0, sizeof(m_tLineObj));

	m_nTowerWidthPixel = gnUnitWidth * gnTowerWidth;
	m_nTowerHeightPixel = gnUnitHeight * gnTowerHeight;

	m_nLineObjNum = 0;
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

bool AOI::Init(Scene* pScene, int nMapWidth, int nMapHeight, int nLineObjNum)
{
	assert(nMapWidth > 0 && nMapWidth <= 0x7FFF && nMapHeight > 0 && nMapHeight <= 0x7FFF);
	if (pScene == NULL)
		return false;
	
	m_poScene = pScene;
	m_nLineObjNum = (int16_t)XMath::Max(MIN_OBJ_PERLINE, XMath::Min(nLineObjNum, MAX_OBJ_PERLINE));

	m_nMapPixelWidth = nMapWidth;
	m_nMapPixelHeight = nMapHeight;

	m_nMapWidthUnit = (int)ceil((double)m_nMapPixelWidth / gnUnitWidth);
	m_nMapHeightUnit = (int)ceil((double)m_nMapPixelHeight / gnUnitHeight);

	m_nXTowerNum = (int)ceil((double)m_nMapWidthUnit / gnTowerWidth);
	m_nYTowerNum = (int)ceil((double)m_nMapHeightUnit / gnTowerHeight);

	int nEdgeTowerWidth = XMath::Max(0, m_nMapWidthUnit - (m_nXTowerNum-1)*gnTowerWidth);
	int nEdgeTowerHeight = XMath::Max(0, m_nMapHeightUnit - (m_nYTowerNum-1)*gnTowerHeight);

	int nTotalTowerNum = m_nXTowerNum * m_nYTowerNum;
	m_pTowerArray = (Tower**)XALLOC(NULL, nTotalTowerNum*sizeof(Tower*));

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

int AOI::AddObj(int nPosX, int nPosY, int8_t nAOIMode, int nAOIArea[], Object* poGameObj, int8_t nAOIType, int16_t nLine)
{
	assert(nLine >= -1 && nLine < MAX_LINE);

	if (nAOIMode & AOI_MODE_DROP)
	{
		return -1;
	}
	if (!(nAOIType == AOI_TYPE_RECT || nAOIType == AOI_TYPE_CIRCLE))
	{
		return -1;
	}

	nPosX = XMath::Min(m_nMapPixelWidth-1, XMath::Max(0, nPosX));
	nPosY = XMath::Min(m_nMapPixelHeight-1, XMath::Max(0, nPosY));
	nAOIArea[0] = XMath::Min(m_nMapPixelWidth, XMath::Max(nAOIArea[0], 0));
	nAOIArea[1] = XMath::Min(m_nMapPixelHeight, XMath::Max(nAOIArea[1], 0));

	AOIOBJ* pObj = XNEW(AOIOBJ);	
	pObj->nRef = 0;
	pObj->nAOIID = GenAOIID();
	pObj->nAOIMode = AOI_MODE_NONE;
	pObj->nAOIType = nAOIType;
	pObj->nPos[0] = (int16_t)nPosX;
	pObj->nPos[1] = (int16_t)nPosY;
	pObj->nArea[0] = (int16_t)nAOIArea[0];
	pObj->nArea[1] = (int16_t)nAOIArea[1];
	pObj->poGameObj = poGameObj;

	int16_t nTarLine = AddLineObj(nLine);
	assert(nTarLine >= 0 && nTarLine < MAX_LINE);
	pObj->nLine = nTarLine;

	m_oObjMap[pObj->nAOIID] =  pObj;

	m_poScene->OnObjEnterScene(pObj);
	if (nAOIMode & AOI_MODE_OBSERVER)
	{
		assert(pObj->nArea[0] >= 0 && pObj->nArea[1] >= 0);
		AddObserver(pObj->nAOIID);
	} 
	if (nAOIMode & AOI_MODE_OBSERVED)
	{
		AddObserved(pObj->nAOIID);
	}
	PrintTower(); //fix pd
	
	//在OnObjEnterScene里面可能又会跳到别的场景，所以加个判断
	if (pObj->poGameObj != NULL)
	{
		m_poScene->AfterObjEnterScene(pObj);
	}

	return pObj->nAOIID;
}

void AOI::MoveObj(int nID, int nPosX, int nPosY)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP))
	{
		return;
	}

	nPosX = XMath::Max(0, XMath::Min(nPosX, m_nMapPixelWidth - 1));
	nPosY = XMath::Max(0, XMath::Min(nPosY, m_nMapPixelHeight - 1));

	int nOldPos[2] = {pObj->nPos[0], pObj->nPos[1]};
	int nNewPos[2] = {nPosX, nPosY};

	if (nOldPos[0] == nNewPos[0] && nOldPos[1] == nNewPos[1])
	{
		return;
	}

	int nOldTowerX = 0;
	int nOldTowerY = 0;
	int nNewTowerX = 0;
	int nNewTowerY = 0;

	CalcTowerPos(nOldPos[0], nOldPos[1], nOldTowerX, nOldTowerY);
	CalcTowerPos(nNewPos[0], nNewPos[1], nNewTowerX, nNewTowerY);

	if (nOldTowerX == nNewTowerX && nOldTowerY == nNewTowerY)
	{
		return;
	}

	if (pObj->nAOIMode & AOI_MODE_OBSERVER)
	{
		MoveObserver(pObj, nOldPos, nNewPos);
	}
	if (pObj->nAOIMode & AOI_MODE_OBSERVED)
	{
		MoveObserved(pObj, nOldPos, nNewPos);
	}

	pObj->nPos[0] = (int16_t)nNewPos[0];
	pObj->nPos[1] = (int16_t)nNewPos[1];
}

void AOI::MoveObserver(AOIOBJ* pObj, int nOldPos[2], int nNewPos[2])
{
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return;
	}

	int nOldLTTower[2] = {-1, -1}; 
	int nOldRBTower[2] = {-1, -1};

	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(nOldPos[0], nOldPos[1], pObj->nArea[0], pObj->nArea[1], nOldLTTower, nOldRBTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(nOldPos[0], nOldPos[1], pObj->nArea[0], nOldLTTower, nOldRBTower);
	}

	int nNewLTTower[2] = {-1, -1};
	int nNewRBTower[2] = {-1, -1};
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(nNewPos[0], nNewPos[1], pObj->nArea[0], pObj->nArea[1], nNewLTTower, nNewRBTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(nNewPos[0], nNewPos[1], pObj->nArea[0], nNewLTTower, nNewRBTower);
	}

	//XLog(LEVEL_DEBUG, "moveobserver: nOldPos[%d,%d] nNewPos[%d,%d], oldlt[%d,%d],oldrb[%d,%d],newlt[%d,%d],newrb[%d,%d]\n"
	//	, nOldPos[0], nOldPos[1], nNewPos[0], nNewPos[1]
	//	, nOldLTTower[0], nOldLTTower[1], nOldRBTower[0], nOldRBTower[1], nNewLTTower[0], nNewLTTower[1], nNewRBTower[0], nNewRBTower[1]);

	// 检查观察者区域是否相等
	if (nOldLTTower[0] == nNewLTTower[0] && nOldLTTower[1] == nNewLTTower[1] && nOldRBTower[0] == nNewRBTower[0] && nOldRBTower[1] == nNewRBTower[1])
	{
		return;
	}

	m_oObjCache.Clear();
	for (int oy = nOldLTTower[1]; oy <= nOldRBTower[1]; oy++)
	{
		for (int ox = nOldLTTower[0]; ox <= nOldRBTower[0]; ox++)
		{
			if (ox < nNewLTTower[0] || ox > nNewRBTower[0] || oy < nNewLTTower[1] || oy > nNewRBTower[1])
			{
				Tower* pTower = m_pTowerArray[oy * m_nXTowerNum + ox];
				pTower->GetObservedList(pObj, m_oObjCache);
				if (!pTower->RemoveObserver(pObj))
				{
					XLog(LEVEL_ERROR, "MoveObserver: tower:[%d,%d] remove observer:%d fail\n", ox, oy, pObj->nAOIID);
					NSCDebug::TraceBack();
				}
			}
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(pObj, m_oObjCache);
	}

	m_oObjCache.Clear();
	for (int ny = nNewLTTower[1]; ny <= nNewRBTower[1]; ny++)
	{
		for (int nx = nNewLTTower[0]; nx <= nNewRBTower[0]; nx++)
		{
			if (nx < nOldLTTower[0] || nx > nOldRBTower[0] || ny < nOldLTTower[1] || ny > nOldRBTower[1])
			{
				Tower* pTower = m_pTowerArray[ny * m_nXTowerNum + nx];
				pTower->GetObservedList(pObj, m_oObjCache);
				pTower->AddObserver(pObj);
			}
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(pObj, m_oObjCache);
	}
	PrintTower(); //fix pd
}

void AOI::MoveObserved(AOIOBJ* pObj, int nOldPos[2], int nNewPos[2])
{
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return;
	}

	int nOldTowerX = -1;
	int nOldTowerY = -1;
	CalcTowerPos(nOldPos[0], nOldPos[1], nOldTowerX, nOldTowerY);

	int nNewTowerX = -1;
	int nNewTowerY = -1;
	CalcTowerPos(nNewPos[0], nNewPos[1], nNewTowerX, nNewTowerY);

	// 检查被观察者坐标是否相等
	if (nOldTowerX == nNewTowerX && nOldTowerY == nNewTowerY)
	{
		return;
	}

	m_oObjCache.Clear();
	m_oObjCache2.Clear();
	Tower* pOldTower = m_pTowerArray[nOldTowerY * m_nXTowerNum + nOldTowerX];
	pOldTower->GetObserverList(pObj, m_oObjCache2);
	for (int i = 0; i < m_oObjCache2.Size(); i++) 
	{
		AOIOBJ* pObserver = m_oObjCache2[i];

		int nLTTower[2] = {-1, -1};
		int nRBTower[2] = {-1, -1};

		if (pObserver->nAOIType == AOI_TYPE_RECT)
		{
			CalcRectTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], pObserver->nArea[1], nLTTower, nRBTower);
		}
		else if (pObserver->nAOIType == AOI_TYPE_CIRCLE)
		{
			CalcCircleTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], nLTTower, nRBTower);
		}

		if (nNewTowerX < nLTTower[0] || nNewTowerX > nRBTower[0] || nNewTowerY < nLTTower[1] || nNewTowerY > nRBTower[1])
		{
			m_oObjCache.PushBack(pObserver);
		}
	}
	if (!pOldTower->RemoveObserved(pObj))
	{
		XLog(LEVEL_ERROR, "MoveObserved: remove observed:%d fail\n", pObj->nAOIID);
		NSCDebug::TraceBack();
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(m_oObjCache, pObj);
	}

	m_oObjCache.Clear();
	m_oObjCache2.Clear();
	Tower* pNewTower = m_pTowerArray[nNewTowerY * m_nXTowerNum + nNewTowerX];
	pNewTower->GetObserverList(pObj, m_oObjCache2);
	for (int i = 0; i < m_oObjCache2.Size(); i++)
	{
		AOIOBJ* pObserver = m_oObjCache2[i];

		int nLTTower[2] = {-1, -1};
		int nRBTower[2] = {-1, -1};
		if (pObserver->nAOIType == AOI_TYPE_RECT)
		{
			CalcRectTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], pObserver->nArea[1], nLTTower, nRBTower);
		}
		else if (pObserver->nAOIType == AOI_TYPE_CIRCLE)
		{
			CalcCircleTowerArea(pObserver->nPos[0], pObserver->nPos[1], pObserver->nArea[0], nLTTower, nRBTower);
		}
		if (nOldTowerX < nLTTower[0] || nOldTowerX > nRBTower[0] || nOldTowerY < nLTTower[1] || nOldTowerY > nRBTower[1])
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

void AOI::RemoveObj(int nID, bool bLeaveScene)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP))
	{
		return;
	}
	RemoveObserver(nID, bLeaveScene);
	RemoveObserved(nID);
	if (pObj->nAOIMode == 0)
	{
		if (pObj->nRef != 0)
		{
			XLog(LEVEL_ERROR, "RemoverObj: id:%d reference error mode:%d ref:%d\n", pObj->nAOIID, pObj->nAOIMode, pObj->nRef);
			NSCDebug::TraceBack();
		}
		pObj->nAOIMode = AOI_MODE_DROP;
		SubLineObj(pObj->nLine);

		m_poScene->OnObjLeaveScene(pObj);
		pObj->poGameObj = NULL;
	}
}

bool AOI::AddObserver(int nID)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP) || (pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		XLog(LEVEL_ERROR, "AddObserver: id:%d addr:0x%x mode:%d name:%s aoi obj not exist or mode error!\n", nID, (void*)pObj, (pObj?pObj->nAOIMode:0), (pObj?(pObj->poGameObj?pObj->poGameObj->GetName():""):""));
		NSCDebug::TraceBack();
		return false;
	}
	pObj->nAOIMode |= AOI_MODE_OBSERVER;
	int nLTTower[2] = { -1, -1 };
	int nRBTower[2] = { -1, -1 };
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], pObj->nArea[1], nLTTower, nRBTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], nLTTower, nRBTower);
	}
	//XLog(LEVEL_DEBUG, "addobserver: lt[%d,%d],rb[%d,%d]\n", nLTTower[0], nLTTower[1], nRBTower[0], nRBTower[1]);

	m_oObjCache.Clear();
	for (int y = nLTTower[1]; y <= nRBTower[1]; y++)
	{
		for (int x = nLTTower[0]; x <= nRBTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			pTower->GetObservedList(pObj, m_oObjCache);
			pTower->AddObserver(pObj);
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(pObj, m_oObjCache);
	}
	return true;
}

bool AOI::RemoveObserver(int nID, bool bLeaveScene)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return false;
	}

	int nLTTower[2] = { -1, -1 };
	int nRBTower[2] = { -1, -1 };
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], pObj->nArea[1], nLTTower, nRBTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], nLTTower, nRBTower);
	}

	m_oObjCache.Clear();
	for (int y = nLTTower[1]; y <= nRBTower[1]; y++)
	{
		for (int x = nLTTower[0]; x <= nRBTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			if (!bLeaveScene) //离开场景不需要管理视野
			{
				pTower->GetObservedList(pObj, m_oObjCache);
			}
			pTower->RemoveObserver(pObj);
		}
	}
	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(pObj, m_oObjCache);
	}

	pObj->nAOIMode &= ~AOI_MODE_OBSERVER;
	if (pObj->nAOIMode == 0 && pObj->nRef != 0)
	{
		XLog(LEVEL_ERROR, "RemoverObserver: id:%d reference error mode:%d ref:%d\n", pObj->nAOIID, pObj->nAOIMode, pObj->nRef);
		NSCDebug::TraceBack();
	}
	return true;
}

bool AOI::AddObserved(int nID)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP) || (pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		XLog(LEVEL_ERROR, "AddObserved: id:%d addr:0x%x mode:%d name:%s aoi obj not exist or mode error!\n", nID, (void*)pObj, (pObj?pObj->nAOIMode:0), (pObj ? (pObj->poGameObj ? pObj->poGameObj->GetName() : "") : ""));
		NSCDebug::TraceBack();
		return false;
	}
	
	pObj->nAOIMode |= AOI_MODE_OBSERVED;
	int nTowerX = -1;
	int nTowerY = -1;
	CalcTowerPos(pObj->nPos[0], pObj->nPos[1], nTowerX, nTowerY);
	//XLog(LEVEL_DEBUG, "addobserved: [%d,%d]\n", nTowerX, nTowerY);

	m_oObjCache.Clear();
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	pTower->GetObserverList(pObj, m_oObjCache);
	pTower->AddObserved(pObj);

	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(m_oObjCache, pObj);
	}
	return true;
}

bool AOI::RemoveObserved(int nID)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return false;
	}

	int nTowerX = -1;
	int nTowerY = -1;
	CalcTowerPos(pObj->nPos[0], pObj->nPos[1], nTowerX, nTowerY);

	m_oObjCache.Clear();
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	pTower->GetObserverList(pObj, m_oObjCache);
	pTower->RemoveObserved(pObj);

	if (m_oObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(m_oObjCache, pObj);
	}

	pObj->nAOIMode &= ~AOI_MODE_OBSERVED;
	if (pObj->nAOIMode == 0 && pObj->nRef != 0)
	{
		XLog(LEVEL_ERROR, "RemoveObserved: id:%d reference error mode:%d ref:%d\n", pObj->nAOIID, pObj->nAOIMode, pObj->nRef);
		NSCDebug::TraceBack();
	}
	return true;
}

void AOI::GetAreaObservers(int nID, Array<AOIOBJ*>& oObjCache, int nGameObjType)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVED))
	{
		return;
	}

	int nTowerX = -1;
	int nTowerY = -1;
	CalcTowerPos(pObj->nPos[0], pObj->nPos[1], nTowerX, nTowerY);

	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	pTower->GetObserverList(pObj, oObjCache, nGameObjType);
}

void AOI::GetAreaObserveds(int nID, Array<AOIOBJ*>& oObjCache, int nGameObjType)
{
	AOIOBJ* pObj = GetObj(nID);
	if (pObj == NULL || !(pObj->nAOIMode & AOI_MODE_OBSERVER))
	{
		return;
	}

	int nLTTower[2] = {-1, -1};
	int nRBTower[2] = {-1, -1};
	if (pObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], pObj->nArea[1], nLTTower, nRBTower);
	}
	else if (pObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(pObj->nPos[0], pObj->nPos[1], pObj->nArea[0], nLTTower, nRBTower);
	}

	for (int y = nLTTower[1]; y <= nRBTower[1]; y++)
	{
		for (int x = nLTTower[0]; x <= nRBTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			pTower->GetObservedList(pObj, oObjCache, nGameObjType);
		}
	}
}

void AOI::PrintTower()
{
	return;

	//for (int y = 0; y < m_nYTowerNum; y++)
	//{
	//	bool bPrint = false;
	//	for (int x = 0; x < m_nXTowerNum; x++)
	//	{
	//		Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
	//		Tower::AOIObjMap& oObserverMap = pTower->GetObserverMap();
	//		Tower::AOIObjMap& oObservedMap = pTower->GetObservedMap();
	//		if (oObserverMap.size() > 0 || oObservedMap.size() > 0)
	//		{
	//			XLog(LEVEL_DEBUG, "Tower:[%d,%d][%d,%d] ", x, y, oObserverMap.size(), oObservedMap.size());
	//			bPrint = true;
	//		}
	//	}
	//	if (bPrint)
	//	{
	//		XLog(LEVEL_DEBUG, "\n");
	//	}
	//}
	//XLog(LEVEL_DEBUG, "\n");
}

int AOI::GenAOIID()
{
	static int nIndex = 0;
	nIndex = nIndex % 0x7FFFFFFF + 1;
	return nIndex;
}

AOIOBJ* AOI::GetObj(int nID)
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
			AOIOBJ* poObj = iter->second;
			iter = m_oObjMap.erase(iter);
			SAFE_DELETE(poObj);
			continue;
		}
		iter++;
	}
}

inline void AOI::CalcTowerPos(int nPosX, int nPosY, int& nTowerX, int& nTowerY)
{
	nPosX = XMath::Max(0, XMath::Min(nPosX, m_nMapPixelWidth - 1));
	nPosY = XMath::Max(0, XMath::Min(nPosY, m_nMapPixelHeight - 1));
	nTowerX = nPosX / m_nTowerWidthPixel;
	nTowerY = nPosY / m_nTowerHeightPixel;
}

inline void AOI::CalcCircleTowerArea(int nPosX, int nPosY, int nRadius, int nLTTower[], int nRBTower[])
{
	assert(false); //屏蔽

	if (nRadius == 0)
	{
		nLTTower[0] = 0;
		nLTTower[1] = 0;
		nRBTower[0] = -1;
		nRBTower[1] = -1;
		return;
	}
	int nLTX = XMath::Max(0, nPosX - nRadius);
	int nRBX = XMath::Min(m_nMapPixelWidth - 1, nPosX + nRadius);
	int nLTY = XMath::Max(0, nPosY - nRadius);
	int nRBY = XMath::Min(m_nMapPixelHeight - 1, nPosY + nRadius);

	// 边界处理 fix pd

	int nTowerWidthPixel = gnUnitWidth * gnTowerWidth;
	int nTowerHeightPixel = gnUnitHeight * gnTowerHeight;

	int nLTTowerX = nLTX / nTowerWidthPixel;
	int nLTTowerY = nLTY / nTowerHeightPixel;
	assert(nLTTowerX < m_nXTowerNum && nLTTowerY < m_nYTowerNum);

	int nRBTowerX = nRBX / nTowerWidthPixel;
	int nRBTowerY = nRBY / nTowerHeightPixel;
	assert(nRBTowerX < m_nXTowerNum && nRBTowerY < m_nYTowerNum);

	nLTTower[0] = nLTTowerX;
	nLTTower[1] = nLTTowerY;
	nRBTower[0] = nRBTowerX;
	nRBTower[1] = nRBTowerY;
}

inline void AOI::CalcRectTowerArea(int nPosX, int nPosY, int nWidth, int nHeight, int nLTTower[], int nRBTower[])
{
	if (nWidth == 0 && nHeight == 0)
	{
		nLTTower[0] = 0;
		nLTTower[1] = 0;
		nRBTower[0] = -1;
		nRBTower[1] = -1;
		return;
	}
	int nMidW = nWidth / 2;
	int nMidH = nHeight / 2;

	int nLeftX = nPosX - nMidW;
	int nRightX = nPosX + nMidW;
	int nBottomY = nPosY - nMidH;
	int nTopY = nPosY + nMidH;

	if (nLeftX < 0)
	{
		nRightX = XMath::Min(m_nMapPixelWidth-1, nRightX+abs(nLeftX));
		nLeftX = 0;
	}
	if (nRightX >= m_nMapPixelWidth)
	{
		nLeftX = XMath::Max(0, nLeftX-(nRightX-m_nMapPixelWidth+1));
		nRightX = m_nMapPixelWidth - 1;
	}

	if (nBottomY < 0)
	{
		nTopY = XMath::Min(m_nMapPixelHeight-1, nTopY+abs(nBottomY));
		nBottomY = 0;
	}
	if (nTopY >= m_nMapPixelHeight)
	{
		nBottomY = XMath::Max(0, nBottomY-(nTopY-m_nMapPixelHeight+1));
		nTopY = m_nMapPixelHeight - 1;
	}

	//int nLTX = XMath::Max(0, nPosX - );
	//int nLTY = XMath::Max(0, nPosY - nHeight/2);
	//int nRBX = XMath::Min(m_nMapPixelWidth - 1, nPosX + nWidth/2);
	//int nRBY = XMath::Min(m_nMapPixelHeight - 1, nPosY + nHeight/2);

	//// 边界处理
	//if (nRBX - nLTX + 1 < nWidth)
	//{
	//	(nLTX == 0) ? (nRBX = XMath::Min(nWidth - 1, m_nMapPixelWidth - 1)) : 0;
	//	(nRBX == m_nMapPixelWidth - 1) ? (nLTX = XMath::Max(0, m_nMapPixelWidth - nWidth + 1)) : 0;
	//}
	//if (nRBY - nLTY + 1 < nHeight)
	//{
	//	(nLTY == 0) ? (nRBY = XMath::Min(nHeight - 1, m_nMapPixelHeight - 1)) : 0;
	//	(nRBY == m_nMapPixelHeight - 1) ? (nLTY = XMath::Max(0, m_nMapPixelHeight - nHeight + 1)) : 0;
	//}

	int nLTTowerX = nLeftX / m_nTowerWidthPixel;
	int nLTTowerY = nBottomY / m_nTowerHeightPixel;
	assert(nLTTowerX < m_nXTowerNum && nLTTowerY < m_nYTowerNum);

	int nRBTowerX = nRightX / m_nTowerWidthPixel;
	int nRBTowerY = nTopY / m_nTowerHeightPixel;
	assert(nRBTowerX < m_nXTowerNum && nRBTowerY < m_nYTowerNum);

	nLTTower[0] = nLTTowerX;
	nLTTower[1] = nLTTowerY;
	nRBTower[0] = nRBTowerX;
	nRBTower[1] = nRBTowerY;
}

inline int16_t AOI::AddLineObj(int16_t nLine)
{
	assert(nLine >= -1 && nLine < MAX_LINE);

	//公共
	if (nLine == 0)
	{
		m_tLineObj[nLine]++;
		XLog(LEVEL_DEBUG, "Addtoline:%d Scene:%lld objs:%d\n", 0, m_poScene->GetSceneMixID(), m_tLineObj[nLine]);
		return 0;
	}

	//自动
	if (nLine == -1)
	{
		int nMinLine = 1;
		int nMinObjs = 0;
		for (int i = 1; i < MAX_LINE; i++)
		{
			if (m_tLineObj[i] < m_nLineObjNum)
			{
				m_tLineObj[i]++;
				XLog(LEVEL_DEBUG, "AddToLine:%d scene:%lld objs:%d\n", i, m_poScene->GetSceneMixID(), m_tLineObj[i]);
				return i;
			}
			else
			{
				if (nMinObjs == 0 || m_tLineObj[i] < nMinObjs)
				{
					nMinObjs = m_tLineObj[i];
					nMinLine = i;
				}
			}
		}
		m_tLineObj[nMinLine]++;
		XLog(LEVEL_DEBUG, "AddToLine:%d scene:%lld objs:%d\n", nMinLine, m_poScene->GetSceneMixID(), m_tLineObj[nMinLine]);
		return nMinLine;
	} 
	else
	{
		m_tLineObj[nLine]++;
		XLog(LEVEL_DEBUG, "AddToLine:%d objs:%d\n", nLine, m_tLineObj[nLine]);
		return nLine;
	}
	return -1;
}

inline int16_t AOI::SubLineObj(int16_t nLine)
{
	assert(nLine >= 0 && nLine < MAX_LINE);
	m_tLineObj[nLine]--;
	assert(m_tLineObj[nLine] >= 0);
	return m_tLineObj[nLine];
}

void AOI::ChangeLine(int nID, int16_t nNewLine)
{
	assert(nNewLine >= 0 && nNewLine < MAX_LINE);
	AOIOBJ* pObj = GetObj(nID);

	if (pObj == NULL || (pObj->nAOIMode & AOI_MODE_DROP))
		return;
	if (pObj->nLine == nNewLine)
		return;

	RemoveObserver(nID);
	RemoveObserved(nID);
	SubLineObj(pObj->nLine);

	pObj->nLine = nNewLine;
	AddObserver(nID);
	AddObserved(nID);
	AddLineObj(pObj->nLine);
}
