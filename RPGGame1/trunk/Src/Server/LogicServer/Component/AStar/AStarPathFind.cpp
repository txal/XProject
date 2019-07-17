#include "AStarPathFind.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/TimeMonitor.h"
#include "Common/Platform.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

int NodeCmpFunc(void* poObj1, void* poObj2)
{
	ASTAR_NODE* poNode1 = (ASTAR_NODE*)poObj1;
	ASTAR_NODE* poNode2 = (ASTAR_NODE*)poObj2;
	if (poNode1->nKey == poNode2->nKey)
	{
		return 0;
	}
	if (poNode1->nKey > poNode2->nKey)
	{
		return 1;
	}
	return -1;
}

AStarPathFind::AStarPathFind()
	: m_OpenedList(NodeCmpFunc)
{
	m_pMapData = NULL;
	m_poMapConf = NULL;
    m_uSearchVersion = 0;
}

AStarPathFind::~AStarPathFind()
{
	SAFE_FREE(m_pMapData);
	m_poMapConf = NULL;
    m_OpenedList.Clear();
}

void AStarPathFind::InitMapData(int nMapID)
{
	m_poMapConf = ConfMgr::Instance()->GetMapMgr()->GetConf(nMapID);
    if (m_poMapConf == NULL)
    {
        return;
    }
	int nGridNum = m_poMapConf->nUnitNumX * m_poMapConf->nUnitNumY;
	m_pMapData = (ASTAR_NODE*)XALLOC(m_pMapData, nGridNum * sizeof(ASTAR_NODE));
    for (int i = 0; i < m_poMapConf->nUnitNumY; i++)
    {
        for (int j = 0; j < m_poMapConf->nUnitNumX; j++)
        {
            int32_t nIdx = i * m_poMapConf->nUnitNumX + j;
            m_pMapData[nIdx].nX = j;
            m_pMapData[nIdx].nY = i;
            m_pMapData[nIdx].Reset();
        }
    }
    m_uSearchVersion = 0;
}

int AStarPathFind::GetH(int nStartX, int nStartY, int nEndX, int nEndY)
{
	int nH = 10 * (abs(nStartX - nEndX) + abs(nStartY - nEndY));
    return nH;
}

int AStarPathFind::GetG(int nStartX, int nStartY, int nEndX, int nEndY)
{
    int nG = 0;
    if (nStartX != nEndX && nStartY != nEndY)
    {
        nG = 14;
    }
    else
    {
        nG = 10;
    }
    return nG;
}

bool AStarPathFind::CanWalk(int nX, int nY)
{
    if (nX < 0 || nX >= m_poMapConf->nUnitNumX || nY < 0 || nY >= m_poMapConf->nUnitNumY)
    {
        return false;
    }
    if (m_poMapConf == NULL)
    {
        return false;
    }
	return !m_poMapConf->IsBlockUnit(nX, nY);
}

bool AStarPathFind::CanDiagonalWalk(const ASTAR_NODE* pNode1, const ASTAR_NODE* pNode2)
{
	ASTAR_NODE* pNodeNear1 = GetNode(pNode1->nX, pNode2->nY);
	ASTAR_NODE* pNodeNear2 = GetNode(pNode2->nX, pNode1->nY);
	if (CanWalk(pNodeNear1->nX, pNodeNear1->nY) && CanWalk(pNodeNear2->nX, pNodeNear2->nY))
	{
		return true;
	}
	return false;
}

ASTAR_NODE* AStarPathFind::GetNode(int nX, int nY)
{
	if (nX < 0 || nX >= m_poMapConf->nUnitNumX || nY < 0 || nY >= m_poMapConf->nUnitNumY)
    {
        return NULL;
    }
	ASTAR_NODE* pNode = &m_pMapData[nX + nY * m_poMapConf->nUnitNumX];
    if (pNode->uVersion != m_uSearchVersion)
    {
        pNode->Reset();
        pNode->uVersion = m_uSearchVersion;
    }
    return pNode;
}

int AStarPathFind::PathFind(int nStartX, int nStartY, int nEndX, int nEndY, std::list<Point>& oListPath)
{
    if (m_poMapConf == NULL)
    {
        return -1;
    }
    nStartX = XMath::Max(0, XMath::Min(nStartX, (int)m_poMapConf->nPixelWidth - 1));
    nStartY = XMath::Max(0, XMath::Min(nStartY, (int)m_poMapConf->nPixelHeight - 1));
    nEndX = XMath::Max(0, XMath::Min(nEndX, (int)m_poMapConf->nPixelWidth - 1));
    nEndY = XMath::Max(0, XMath::Min(nEndY , (int)m_poMapConf->nPixelHeight - 1));
    int nSX = nStartX / gnUnitWidth;
    int nSY = nStartY / gnUnitHeight;
    int nEX = nEndX / gnUnitWidth;
    int nEY = nEndY / gnUnitHeight;
    if (nSX == nEX && nSY == nEY)
    {
        return -2;
    }
    if (!CanWalk(nSX, nSY) || !CanWalk(nEX, nEY))
    {
        return -3;
    }
    m_uSearchVersion++;
    ASTAR_NODE* pNode = GetNode(nSX, nSY);
    ASTAR_NODE* pEnd = GetNode(nEX, nEY);
    if (pNode == NULL || pEnd == NULL)
    {
        return -4;
    }
    m_OpenedList.Clear();
    pNode->bOpened = true;
    m_OpenedList.Push(pNode);
    static int tDir[8][2] = { { -1, 1 }, { -1, 0 }, { -1, -1 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, 0 }, { 1, -1 } };
    while (!pEnd->bClosed && m_OpenedList.Size() > 0)
    {
        pNode = m_OpenedList.Min();
        m_OpenedList.Remove(pNode);
        pNode->bOpened = false;
        pNode->bClosed = true;
        ASTAR_NODE* pTmpNode = NULL;
        for (int i = 0; i < 8; i++)
        {
            int nX = pNode->nX + tDir[i][0];
            int nY = pNode->nY + tDir[i][1];
            pTmpNode = GetNode(nX, nY);
            if (pTmpNode == NULL || !CanWalk(nX, nY)) 
            {
                continue;
            }
            if (!CanDiagonalWalk(pNode, pTmpNode))
            {
                continue;
            }
            int nG = pNode->nG + GetG(pNode->nX, pNode->nY, pTmpNode->nX, pTmpNode->nY);
            int nH = GetH(pTmpNode->nX, pTmpNode->nY, pEnd->nX, pEnd->nY);
			int nF = nG + nH;
            if (pTmpNode->bOpened || pTmpNode->bClosed)
            {
                if (pTmpNode->nKey > nF)
                {
                    pTmpNode->nG = nG;
                    pTmpNode->nH = nH;
					pTmpNode->nKey = nF;
                    pTmpNode->pParent = pNode;
					if (pTmpNode->bOpened)
					{
						m_OpenedList.Update(pTmpNode);
					}
                }
            }
            else
            {
				pTmpNode->nG = nG;
                pTmpNode->nH = nH;
				pTmpNode->nKey = nF;
                pTmpNode->pParent = pNode;
                m_OpenedList.Push(pTmpNode);
                pTmpNode->bOpened = true;
            }
        }
    }
    if (!pEnd->bClosed)
    {
        return -5;
    }
    m_oTmpListPath.clear();
    ASTAR_NODE* pTarNode = pNode;
	//XLog(LEVEL_DEBUG,"Robot path0:");
    while (pTarNode != NULL)
    {
        ASTAR_POINT oASPos;
        oASPos.nX = pTarNode->nX;
        oASPos.nY = pTarNode->nY;
		//XLog(LEVEL_DEBUG, "[%d,%d] ", oASPos.nX, 35 - oASPos.nY);
        m_oTmpListPath.push_front(oASPos);
        pTarNode = pTarNode->pParent;
    }
	//XLog(LEVEL_DEBUG,"\n");

    if (m_oTmpListPath.size() > 2)
    {
        Floyd(m_oTmpListPath);
    }
    ASLITER iter = m_oTmpListPath.begin();
    ASLITER iter_end = m_oTmpListPath.end();
	//XLog(LEVEL_DEBUG,"Robot path1:");
    for (; iter != iter_end; iter++)
    {
        ASTAR_POINT& oPos = *iter;
		int nPosX = (int)((oPos.nX + 0.5f) * gnUnitWidth);
		int nPosY = (int)((oPos.nY + 0.5f) * gnUnitHeight);
		oListPath.push_back(Point(nPosX, nPosY));
		//XLog(LEVEL_DEBUG,"[%d,%d](%d,%d) ", nPosX, nPosY, oPos.nX, 35-oPos.nY);
    }
	//XLog(LEVEL_DEBUG,"\n");
    return 0;
}

void AStarPathFind::Floyd(std::list<ASTAR_POINT>& oListPath)
{
    ASLITER iter1 = oListPath.begin();
    ASTAR_POINT oPos1 = *(++iter1) - *iter1;
    for (ASLITER iter2 = ++iter1; iter2 != oListPath.end(); ++iter2)
    {
        ASLITER iter_tmp = iter2;
        iter_tmp--;
        ASTAR_POINT oPos2 = *iter2 - *(iter_tmp);
        if (oPos1.nX == oPos2.nX && oPos1.nY == oPos2.nY)
        {
            oListPath.erase(iter_tmp);
        }
        else
        {
            oPos1 = oPos2;
        }
    }
    ASLRITER riter = oListPath.rbegin();
    ASLRITER riter_end = oListPath.rend();
    for (; riter != riter_end; ) 
    {
        ASLRITER riter_tmp = riter;
        if (++riter_tmp == riter_end)
        {
            break;
        }
        bool bDelPoint = false;
        ASLITER iter_end = (++riter_tmp).base();
        for (ASLITER  iter = oListPath.begin(); iter != iter_end; iter++)
        {
            if (FloydCrossAble(*riter, *iter))
            {
                ASLITER iter1 = iter;
                ASLITER iter_end1 = (++riter).base();
                for (iter1++; iter1 != iter_end1; )
                {
                    oListPath.erase(iter1++);
                }
                riter = ASLRITER(++iter);
                bDelPoint = true;
                break;
            }
        }
        if (!bDelPoint)
        {
            riter++;
        }
    }
}

int AStarPathFind::GetNodesUnderPoint(float fX, float fY, ASTAR_NODE* tNodeList[])
{
	int nCount = 0;
	bool bIsIntX = fX == (int)fX ? true : false;
	bool bIsIntY = fY == (int)fY ? true : false;
	if (bIsIntX && bIsIntY)
	{
		tNodeList[0] = GetNode((int)(fX - 1), (int)(fY - 1));
		tNodeList[1] = GetNode((int)fX, (int)(fY - 1));
		tNodeList[2] = GetNode((int)(fX - 1), (int)fY);
		tNodeList[3] = GetNode ((int)fX, (int)fY);
		nCount = 4;
	}
	else if (bIsIntX && !bIsIntY)
	{
		tNodeList[0] = GetNode((int)(fX - 1), (int)fY);
		tNodeList[1] = GetNode((int)fX, (int)fY);
		nCount = 2;
	}
	else if (!bIsIntX && bIsIntY)
	{
		tNodeList[0] = GetNode((int)fX, (int)(fY - 1));
		tNodeList[1] = GetNode((int)fX, (int)fY);
		nCount = 2;
	}
	else
	{
		tNodeList[0] = GetNode((int)fX, (int)fY);
		nCount = 1;
	}
	return nCount;
}

bool AStarPathFind::FloydCrossAble(const ASTAR_POINT& oPos1, const ASTAR_POINT& oPos2)
{
	int nPosX1 = oPos1.nX;
	int nPosY1 = oPos1.nY;
	int nPosX2 = oPos2.nX;
	int nPosY2 = oPos2.nY;
	if (nPosX1 == nPosX2 && nPosY1 == nPosY2)
	{
		return false;
	}
	float fPosCenterX1 = nPosX1 + 0.5f;
	float fPosCenterY1 = nPosY1 + 0.5f;
	float fPosCenterX2 = nPosX2 + 0.5f;
	float fPosCenterY2 = nPosY2 + 0.5f;
	int nLoopDir = 1;
	if (abs((int)(nPosX2 - nPosX1)) <= abs((int)(nPosY2 - nPosY1)))
	{
		nLoopDir = 2;
	}
	float fDistX = fPosCenterX1 - fPosCenterX2;
	fDistX = fDistX == 0 ? 1 : fDistX;
	float fA = (fPosCenterY1 - fPosCenterY2) / fDistX;
	float fB = fPosCenterY1 - fA * fPosCenterX1;
	if (nLoopDir == 1)
	{
		ASTAR_NODE* tNodeList[4];
		float fLoopStart = (float)XMath::Min(nPosX1, nPosX2);
		float fLoopStartCenter = fLoopStart + 0.5f;
		float fLoopEnd = (float)XMath::Max(nPosX1, nPosX2);
		for (float i = fLoopStart; i <= fLoopEnd; i++)
		{
			if (i == fLoopStart)
			{
				i += 0.5f;
			}
			float fPosY = 0;
			if (fPosCenterX1 == fPosCenterX2)
			{
				assert(false);
                return false;
			}
			else if (fPosCenterY1 == fPosCenterY2)
			{
				fPosY = fPosCenterY1;
			}
			else
			{
				fPosY = fA * i + fB;
			}
			int nCount = GetNodesUnderPoint(i, fPosY, tNodeList);
			for (int n = nCount - 1; n >= 0; n--)
			{
				if (!CanWalk(tNodeList[n]->nX, tNodeList[n]->nY))
				{
					return false;
				}
			}
			if (i == fLoopStartCenter)
			{
				i -= 0.5f;
			}
		}
	}
	else
	{
		ASTAR_NODE* tNodeList[4];
		float fLoopStart = (float)XMath::Min(nPosY1, nPosY2);
		float fLoopStartCenter = fLoopStart + 0.5f;
		float fLoopEnd = (float)XMath::Max(nPosY1, nPosY2);
		for (float i = fLoopStart; i <= fLoopEnd; i++)
		{
			if (i == fLoopStart)
			{
				i += 0.5f;
			}
			float fPosX = 0;
			if (fPosCenterX1 == fPosCenterX2)
			{
				fPosX = fPosCenterX1;
			}
			else if (fPosCenterY1 == fPosCenterY2)
			{
				assert(false);
                return false;
			}
			else
			{
				fPosX = (i - fB) / fA;
			}
			int nCount = GetNodesUnderPoint(fPosX, i, tNodeList);
			for (int n = nCount - 1; n >= 0; n--)
			{
				if (!CanWalk(tNodeList[n]->nX, tNodeList[n]->nY))
				{
					return false;
				}
			}
			if (i == fLoopStartCenter)
			{
				i -= 0.5f;
			}
		}
	}
	return true;
}