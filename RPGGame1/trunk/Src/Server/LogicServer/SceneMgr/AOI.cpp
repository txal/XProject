#include "Server/LogicServer/SceneMgr/AOI.h"

#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/CDebug.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/GameObject/Object.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

//AOI 废弃对象回收时间
const int nAOIDROP_COLLECT_MSTIME = 3*60*1000;

AOI::AOI()
{
	m_poScene = NULL;
	m_nMapWidthUnit = 0;
	m_nMapHeightUnit = 0;
	m_nXTowerNum = 0;
	m_nYTowerNum = 0;
	m_nTowerWidthPixel = gnUnitWidth * gnTowerWidth;
	m_nTowerHeightPixel = gnUnitWidth * gnTowerWidth;
	m_pTowerArray = NULL;
	m_nLastClearAOITime = XTime::MSTime();
	m_nMaxLineObjs = 0;
	memset(m_tLineObjs, 0, sizeof(m_tLineObjs));
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

	AOIObjIter iter = m_oAOIObjMap.begin();
	AOIObjIter iter_end = m_oAOIObjMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
	m_oAOIObjMap.clear();
}

bool AOI::Init(SceneBase* pScene, int nMaxLineObjs)
{
	if (pScene == NULL)
	{
		return false;
	}
	
	m_poScene = pScene;
	m_nMaxLineObjs = (int16_t)XMath::Max(MIN_OBJ_PERLINE, XMath::Min(nMaxLineObjs, MAX_OBJ_PERLINE));

	int nMapPixelWidth = m_poScene->GetMapConf()->nPixelWidth;
	int nMapPixelHeight = m_poScene->GetMapConf()->nPixelHeight;

	m_nMapWidthUnit = (int)ceil((double)nMapPixelWidth / gnUnitWidth);
	m_nMapHeightUnit = (int)ceil((double)nMapPixelHeight / gnUnitHeight);

	m_nXTowerNum = (int)ceil((double)m_nMapWidthUnit / gnTowerWidth);
	m_nYTowerNum = (int)ceil((double)m_nMapHeightUnit / gnTowerHeight);

	//边缘塔大小
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

int AOI::AddAOIObj(Object* poGameObj, int nPosX, int nPosY, int8_t nAOIMode, int8_t nAOIType, int nAOIArea[], int16_t nLine)
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

	int nMapPixelWidth = m_poScene->GetMapConf()->nPixelWidth;
	int nMapPixelHeight = m_poScene->GetMapConf()->nPixelHeight;

	nPosX = XMath::Min(nMapPixelWidth-1, XMath::Max(0, nPosX));
	nPosY = XMath::Min(nMapPixelHeight-1, XMath::Max(0, nPosY));
	nAOIArea[0] = XMath::Min(nMapPixelWidth, XMath::Max(nAOIArea[0], 0));
	nAOIArea[1] = XMath::Min(nMapPixelHeight, XMath::Max(nAOIArea[1], 0));

	AOIOBJ* poAOIObj = XNEW(AOIOBJ);	
	poAOIObj->nRef = 0;
	poAOIObj->nAOIID = GenAOIID();
	poAOIObj->nAOIMode = AOI_MODE_NONE;
	poAOIObj->nAOIType = nAOIType;
	poAOIObj->nPos[0] = (int16_t)nPosX;
	poAOIObj->nPos[1] = (int16_t)nPosY;
	poAOIObj->nArea[0] = (int16_t)nAOIArea[0];
	poAOIObj->nArea[1] = (int16_t)nAOIArea[1];
	poAOIObj->poGameObj = poGameObj;

	int16_t nTarLine = AddLineObj(nLine);
	assert(nTarLine >= 0 && nTarLine < MAX_LINE);
	poAOIObj->nLine = nTarLine;

	m_oAOIObjMap[poAOIObj->nAOIID] =  poAOIObj;
	m_poScene->OnObjEnterScene(poAOIObj);

	//进入场景的过程中可能又离开了场景
	if (poAOIObj->poGameObj != NULL)
	{
		if (nAOIMode & AOI_MODE_OBSERVER)
		{
			assert(poAOIObj->nArea[0] >= 0 && poAOIObj->nArea[1] >= 0);
			AddObserver(poAOIObj->nAOIID);
		}
		if (nAOIMode & AOI_MODE_OBSERVED)
		{
			AddObserved(poAOIObj->nAOIID);
		}
	}
	return poAOIObj->nAOIID;
}

void AOI::MoveAOIObj(int nAOIID, int nPosX, int nPosY)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || poAOIObj->nAOIMode&AOI_MODE_DROP)
	{
		return;
	}

	int nMapPixelWidth = m_poScene->GetMapConf()->nPixelWidth;
	int nMapPixelHeight = m_poScene->GetMapConf()->nPixelHeight;

	nPosX = XMath::Max(0, XMath::Min(nPosX, nMapPixelWidth - 1));
	nPosY = XMath::Max(0, XMath::Min(nPosY, nMapPixelHeight - 1));

	int nOldPos[2] = {poAOIObj->nPos[0], poAOIObj->nPos[1]};
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

	if (poAOIObj->nAOIMode&AOI_MODE_OBSERVER)
	{
		MoveObserver(poAOIObj, nOldPos, nNewPos);
	}
	if (poAOIObj->nAOIMode&AOI_MODE_OBSERVED)
	{
		MoveObserved(poAOIObj, nOldPos, nNewPos);
	}

	poAOIObj->nPos[0] = (int16_t)nNewPos[0];
	poAOIObj->nPos[1] = (int16_t)nNewPos[1];
}

void AOI::MoveObserver(AOIOBJ* poAOIObj, int nOldPos[2], int nNewPos[2])
{
	if (poAOIObj == NULL || !(poAOIObj->nAOIMode&AOI_MODE_OBSERVER))
	{
		return;
	}

	int nOldLTTower[2] = {-1, -1}; 
	int nOldRBTower[2] = {-1, -1};

	if (poAOIObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(nOldPos[0], nOldPos[1], poAOIObj->nArea[0], poAOIObj->nArea[1], nOldLTTower, nOldRBTower);
	}
	else if (poAOIObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(nOldPos[0], nOldPos[1], poAOIObj->nArea[0], nOldLTTower, nOldRBTower);
	}

	int nNewLTTower[2] = {-1, -1};
	int nNewRBTower[2] = {-1, -1};
	if (poAOIObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(nNewPos[0], nNewPos[1], poAOIObj->nArea[0], poAOIObj->nArea[1], nNewLTTower, nNewRBTower);
	}
	else if (poAOIObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(nNewPos[0], nNewPos[1], poAOIObj->nArea[0], nNewLTTower, nNewRBTower);
	}

	//XLog(LEVEL_DEBUG, "moveobserver: nOldPos[%d,%d] nNewPos[%d,%d], oldlt[%d,%d],oldrb[%d,%d],newlt[%d,%d],newrb[%d,%d]\n"
	//	, nOldPos[0], nOldPos[1], nNewPos[0], nNewPos[1]
	//	, nOldLTTower[0], nOldLTTower[1], nOldRBTower[0], nOldRBTower[1]
	//	, nNewLTTower[0], nNewLTTower[1], nNewRBTower[0], nNewRBTower[1]);

	// 检查观察者区域是否相等
	if (nOldLTTower[0] == nNewLTTower[0]
		&& nOldLTTower[1] == nNewLTTower[1]
		&& nOldRBTower[0] == nNewRBTower[0]
		&& nOldRBTower[1] == nNewRBTower[1])
	{
		return;
	}

	m_oAOIObjCache.Clear();
	for (int oy = nOldLTTower[1]; oy <= nOldRBTower[1]; oy++)
	{
		for (int ox = nOldLTTower[0]; ox <= nOldRBTower[0]; ox++)
		{
			if (ox < nNewLTTower[0] || ox > nNewRBTower[0] || oy < nNewLTTower[1] || oy > nNewRBTower[1])
			{
				Tower* pTower = m_pTowerArray[oy * m_nXTowerNum + ox];
				pTower->GetObservedList(poAOIObj, m_oAOIObjCache);
				if (!pTower->RemoveObserver(poAOIObj))
				{
					XLog(LEVEL_ERROR, "MoveObserver: tower:[%d,%d] remove observer:%d fail\n", ox, oy, poAOIObj->nAOIID);
					NSCDebug::TraceBack();
				}
			}
		}
	}
	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(poAOIObj, m_oAOIObjCache);
	}

	m_oAOIObjCache.Clear();
	for (int ny = nNewLTTower[1]; ny <= nNewRBTower[1]; ny++)
	{
		for (int nx = nNewLTTower[0]; nx <= nNewRBTower[0]; nx++)
		{
			if (nx < nOldLTTower[0] || nx > nOldRBTower[0] || ny < nOldLTTower[1] || ny > nOldRBTower[1])
			{
				Tower* pTower = m_pTowerArray[ny * m_nXTowerNum + nx];
				pTower->GetObservedList(poAOIObj, m_oAOIObjCache);
				pTower->AddObserver(poAOIObj);
			}
		}
	}
	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(poAOIObj, m_oAOIObjCache);
	}
}

void AOI::MoveObserved(AOIOBJ* poAOIObj, int nOldPos[2], int nNewPos[2])
{
	if (poAOIObj == NULL || !(poAOIObj->nAOIMode&AOI_MODE_OBSERVED))
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

	m_oAOIObjCache.Clear();
	m_oAOIObjCache2.Clear();
	Tower* pOldTower = m_pTowerArray[nOldTowerY * m_nXTowerNum + nOldTowerX];
	pOldTower->GetObserverList(poAOIObj, m_oAOIObjCache2);
	for (int i = 0; i < m_oAOIObjCache2.Size(); i++) 
	{
		AOIOBJ* pObserver = m_oAOIObjCache2[i];

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
			m_oAOIObjCache.PushBack(pObserver);
		}
	}
	if (!pOldTower->RemoveObserved(poAOIObj))
	{
		XLog(LEVEL_ERROR, "MoveObserved: remove observed:%d fail\n", poAOIObj->nAOIID);
		NSCDebug::TraceBack();
	}
	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(m_oAOIObjCache, poAOIObj);
	}

	m_oAOIObjCache.Clear();
	m_oAOIObjCache2.Clear();
	Tower* pNewTower = m_pTowerArray[nNewTowerY * m_nXTowerNum + nNewTowerX];
	pNewTower->GetObserverList(poAOIObj, m_oAOIObjCache2);
	for (int i = 0; i < m_oAOIObjCache2.Size(); i++)
	{
		AOIOBJ* pObserver = m_oAOIObjCache2[i];

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
			m_oAOIObjCache.PushBack(pObserver);
		}
	}
	pNewTower->AddObserved(poAOIObj);

	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(m_oAOIObjCache, poAOIObj);
	}
}

void AOI::RemoveAOIObj(int nAOIID, bool bLeaveScene, bool bKicked)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || poAOIObj->nAOIMode&AOI_MODE_DROP)
	{
		return;
	}
	RemoveObserver(nAOIID, bLeaveScene);
	RemoveObserved(nAOIID);
	if (poAOIObj->nAOIMode == 0)
	{
		if (poAOIObj->nRef != 0)
		{
			XLog(LEVEL_ERROR, "RemoverObj: id:%d reference error mode:%d ref:%d\n", poAOIObj->nAOIID, poAOIObj->nAOIMode, poAOIObj->nRef);
			NSCDebug::TraceBack();
		}
		poAOIObj->nAOIMode = AOI_MODE_DROP;
		SubLineObj(poAOIObj->nLine);

		m_poScene->OnObjLeaveScene(poAOIObj, bKicked);
		poAOIObj->poGameObj = NULL;
	}
}

bool AOI::AddObserver(int nAOIID)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || (poAOIObj->nAOIMode&AOI_MODE_DROP || poAOIObj->nAOIMode&AOI_MODE_OBSERVER))
	{
		XLog(LEVEL_ERROR, "AddObserver: id:%d addr:0x%x mode:%d name:%s aoi obj not exist or mode error!\n", nAOIID, (void*)poAOIObj, (poAOIObj?poAOIObj->nAOIMode:0), (poAOIObj?(poAOIObj->poGameObj?poAOIObj->poGameObj->GetName():""):""));
		NSCDebug::TraceBack();
		return false;
	}
	poAOIObj->nAOIMode |= AOI_MODE_OBSERVER;
	int nLTTower[2] = { -1, -1 };
	int nRBTower[2] = { -1, -1 };
	if (poAOIObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(poAOIObj->nPos[0], poAOIObj->nPos[1], poAOIObj->nArea[0], poAOIObj->nArea[1], nLTTower, nRBTower);
	}
	else if (poAOIObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(poAOIObj->nPos[0], poAOIObj->nPos[1], poAOIObj->nArea[0], nLTTower, nRBTower);
	}
	//XLog(LEVEL_DEBUG, "addobserver: lt[%d,%d],rb[%d,%d]\n", nLTTower[0], nLTTower[1], nRBTower[0], nRBTower[1]);

	m_oAOIObjCache.Clear();
	for (int y = nLTTower[1]; y <= nRBTower[1]; y++)
	{
		for (int x = nLTTower[0]; x <= nRBTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			pTower->GetObservedList(poAOIObj, m_oAOIObjCache);
			pTower->AddObserver(poAOIObj);
		}
	}
	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(poAOIObj, m_oAOIObjCache);
	}
	return true;
}

bool AOI::RemoveObserver(int nAOIID, bool bLeaveScene)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || !(poAOIObj->nAOIMode&AOI_MODE_OBSERVER))
	{
		return false;
	}

	int nLTTower[2] = { -1, -1 };
	int nRBTower[2] = { -1, -1 };
	if (poAOIObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(poAOIObj->nPos[0], poAOIObj->nPos[1], poAOIObj->nArea[0], poAOIObj->nArea[1], nLTTower, nRBTower);
	}
	else if (poAOIObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(poAOIObj->nPos[0], poAOIObj->nPos[1], poAOIObj->nArea[0], nLTTower, nRBTower);
	}

	m_oAOIObjCache.Clear();
	for (int y = nLTTower[1]; y <= nRBTower[1]; y++)
	{
		for (int x = nLTTower[0]; x <= nRBTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			if (!bLeaveScene) //离开场景不需要管理视野
			{
				pTower->GetObservedList(poAOIObj, m_oAOIObjCache);
			}
			pTower->RemoveObserver(poAOIObj);
		}
	}
	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(poAOIObj, m_oAOIObjCache);
	}

	poAOIObj->nAOIMode &= ~AOI_MODE_OBSERVER;
	if (poAOIObj->nAOIMode == 0 && poAOIObj->nRef != 0)
	{
		XLog(LEVEL_ERROR, "RemoverObserver: id:%d reference error mode:%d ref:%d\n", poAOIObj->nAOIID, poAOIObj->nAOIMode, poAOIObj->nRef);
		NSCDebug::TraceBack();
	}
	return true;
}

bool AOI::AddObserved(int nAOIID)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || poAOIObj->nAOIMode&AOI_MODE_DROP || poAOIObj->nAOIMode&AOI_MODE_OBSERVED)
	{
		XLog(LEVEL_ERROR, "AddObserved: id:%d addr:0x%x mode:%d name:%s aoi obj not exist or mode error!\n"
			, nAOIID, (void*)poAOIObj, (poAOIObj?poAOIObj->nAOIMode:0), (poAOIObj?(poAOIObj->poGameObj?poAOIObj->poGameObj->GetName():""):""));
		NSCDebug::TraceBack();
		return false;
	}
	
	poAOIObj->nAOIMode |= AOI_MODE_OBSERVED;
	int nTowerX = -1;
	int nTowerY = -1;
	CalcTowerPos(poAOIObj->nPos[0], poAOIObj->nPos[1], nTowerX, nTowerY);
	//XLog(LEVEL_DEBUG, "addobserved: [%d,%d]\n", nTowerX, nTowerY);

	m_oAOIObjCache.Clear();
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	pTower->GetObserverList(poAOIObj, m_oAOIObjCache);
	pTower->AddObserved(poAOIObj);

	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjEnterObj(m_oAOIObjCache, poAOIObj);
	}
	return true;
}

bool AOI::RemoveObserved(int nAOIID)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || !(poAOIObj->nAOIMode&AOI_MODE_OBSERVED))
	{
		return false;
	}

	int nTowerX = -1;
	int nTowerY = -1;
	CalcTowerPos(poAOIObj->nPos[0], poAOIObj->nPos[1], nTowerX, nTowerY);

	m_oAOIObjCache.Clear();
	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	pTower->GetObserverList(poAOIObj, m_oAOIObjCache);
	pTower->RemoveObserved(poAOIObj);

	if (m_oAOIObjCache.Size() > 0)
	{
		m_poScene->OnObjLeaveObj(m_oAOIObjCache, poAOIObj);
	}

	poAOIObj->nAOIMode &= ~AOI_MODE_OBSERVED;
	if (poAOIObj->nAOIMode == 0 && poAOIObj->nRef != 0)
	{
		XLog(LEVEL_ERROR, "RemoveObserved: id:%d reference error mode:%d ref:%d\n", poAOIObj->nAOIID, poAOIObj->nAOIMode, poAOIObj->nRef);
		NSCDebug::TraceBack();
	}
	return true;
}

void AOI::GetAreaObservers(int nAOIID, Array<AOIOBJ*>& oObjCache, int nGameObjType)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || !(poAOIObj->nAOIMode&AOI_MODE_OBSERVED))
	{
		return;
	}

	int nTowerX = -1;
	int nTowerY = -1;
	CalcTowerPos(poAOIObj->nPos[0], poAOIObj->nPos[1], nTowerX, nTowerY);

	Tower* pTower = m_pTowerArray[nTowerY * m_nXTowerNum + nTowerX];
	pTower->GetObserverList(poAOIObj, oObjCache, nGameObjType);
}

void AOI::GetAreaObserveds(int nAOIID, Array<AOIOBJ*>& oObjCache, int nGameObjType)
{
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);
	if (poAOIObj == NULL || !(poAOIObj->nAOIMode&AOI_MODE_OBSERVER))
	{
		return;
	}

	int nLTTower[2] = {-1, -1};
	int nRBTower[2] = {-1, -1};
	if (poAOIObj->nAOIType == AOI_TYPE_RECT)
	{
		CalcRectTowerArea(poAOIObj->nPos[0], poAOIObj->nPos[1], poAOIObj->nArea[0], poAOIObj->nArea[1], nLTTower, nRBTower);
	}
	else if (poAOIObj->nAOIType == AOI_TYPE_CIRCLE)
	{
		CalcCircleTowerArea(poAOIObj->nPos[0], poAOIObj->nPos[1], poAOIObj->nArea[0], nLTTower, nRBTower);
	}

	for (int y = nLTTower[1]; y <= nRBTower[1]; y++)
	{
		for (int x = nLTTower[0]; x <= nRBTower[0]; x++)
		{
			Tower* pTower = m_pTowerArray[y * m_nXTowerNum + x];
			pTower->GetObservedList(poAOIObj, oObjCache, nGameObjType);
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

AOIOBJ* AOI::GetAOIObj(int nAOIID)
{
	AOIObjIter iter = m_oAOIObjMap.find(nAOIID);
	if (iter != m_oAOIObjMap.end())
	{
		if (!(iter->second->nAOIMode & AOI_MODE_DROP))
		{
			return iter->second;
		}
	}
	return NULL;
}

void AOI::ClearDropedAOIObj(int64_t nNowMS)
{
	AOIObjIter iter = m_oAOIObjMap.begin();
	for (; iter != m_oAOIObjMap.end(); )
	{
		if (iter->second->IsDroped())
		{
			AOIOBJ* poAOIObj = iter->second;
			iter = m_oAOIObjMap.erase(iter);
			SAFE_DELETE(poAOIObj);
			continue;
		}
		iter++;
	}
}

inline void AOI::CalcTowerPos(int nPosX, int nPosY, int& nTowerX, int& nTowerY)
{
	int nMapPixelWidth = m_poScene->GetMapConf()->nPixelWidth;
	int nMapPixelHeight = m_poScene->GetMapConf()->nPixelHeight;
	nPosX = XMath::Max(0, XMath::Min(nPosX, nMapPixelWidth - 1));
	nPosY = XMath::Max(0, XMath::Min(nPosY, nMapPixelHeight - 1));
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

	int nMapPixelWidth = m_poScene->GetMapConf()->nPixelWidth;
	int nMapPixelHeight = m_poScene->GetMapConf()->nPixelHeight;

	int nLTX = XMath::Max(0, nPosX - nRadius);
	int nRBX = XMath::Min(nMapPixelWidth - 1, nPosX + nRadius);
	int nLTY = XMath::Max(0, nPosY - nRadius);
	int nRBY = XMath::Min(nMapPixelHeight - 1, nPosY + nRadius);

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

	int nMapPixelWidth = m_poScene->GetMapConf()->nPixelWidth;
	int nMapPixelHeight = m_poScene->GetMapConf()->nPixelHeight;

	if (nLeftX < 0)
	{
		nRightX = XMath::Min(nMapPixelWidth-1, nRightX+abs(nLeftX));
		nLeftX = 0;
	}
	if (nRightX >= nMapPixelWidth)
	{
		nLeftX = XMath::Max(0, nLeftX-(nRightX-nMapPixelWidth+1));
		nRightX = nMapPixelWidth - 1;
	}

	if (nBottomY < 0)
	{
		nTopY = XMath::Min(nMapPixelHeight-1, nTopY+abs(nBottomY));
		nBottomY = 0;
	}
	if (nTopY >= nMapPixelHeight)
	{
		nBottomY = XMath::Max(0, nBottomY-(nTopY-nMapPixelHeight+1));
		nTopY = nMapPixelHeight - 1;
	}

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
		m_tLineObjs[nLine]++;
		XLog(LEVEL_DEBUG, "AddLineObj:%d Scene:%lld objs:%d\n", nLine, m_poScene->GetSceneID(), m_tLineObjs[nLine]);
		return 0;
	}

	//自动
	if (nLine == -1)
	{
		int nMinLine = 1;
		int nMinObjs = 0;
		for (int i = 1; i < MAX_LINE; i++)
		{
			if (m_tLineObjs[i] < m_nMaxLineObjs)
			{
				m_tLineObjs[i]++;
				XLog(LEVEL_DEBUG, "AddLineObj:%d scene:%lld objs:%d\n", i, m_poScene->GetSceneID(), m_tLineObjs[i]);
				return i;
			}
			else
			{
				if (nMinObjs == 0 || m_tLineObjs[i] < nMinObjs)
				{
					nMinObjs = m_tLineObjs[i];
					nMinLine = i;
				}
			}
		}
		m_tLineObjs[nMinLine]++;
		XLog(LEVEL_DEBUG, "AddLineObj:%d scene:%lld objs:%d\n", nMinLine, m_poScene->GetSceneID(), m_tLineObjs[nMinLine]);
		return nMinLine;
	} 
	else
	{
		m_tLineObjs[nLine]++;
		XLog(LEVEL_DEBUG, "AddLineObj:%d scene:%lld objs:%d\n", nLine, m_poScene->GetSceneID(), m_tLineObjs[nLine]);
		return nLine;
	}
	return -1;
}

inline int16_t AOI::SubLineObj(int16_t nLine)
{
	assert(nLine >= 0 && nLine < MAX_LINE);
	m_tLineObjs[nLine]--;
	assert(m_tLineObjs[nLine] >= 0);
	return m_tLineObjs[nLine];
}

void AOI::ChangeAOIObjLine(int nAOIID, int16_t nNewLine)
{
	assert(nNewLine >= 0 && nNewLine < MAX_LINE);
	AOIOBJ* poAOIObj = GetAOIObj(nAOIID);

	if (poAOIObj == NULL || (poAOIObj->nAOIMode & AOI_MODE_DROP))
	{
		return;
	}
	if (poAOIObj->nLine == nNewLine)
	{
		return;
	}

	RemoveObserver(nAOIID);
	RemoveObserved(nAOIID);
	SubLineObj(poAOIObj->nLine);

	poAOIObj->nLine = nNewLine;
	AddObserver(nAOIID);
	AddObserved(nAOIID);
	AddLineObj(poAOIObj->nLine);
}

void AOI::Update(int64_t nNowMS)
{
	if (nNowMS - m_nLastClearAOITime >= nAOIDROP_COLLECT_MSTIME)
	{
		m_nLastClearAOITime = nNowMS;
		ClearDropedAOIObj(nNowMS);
	}
}
