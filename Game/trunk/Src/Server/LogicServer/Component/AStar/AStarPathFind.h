#ifndef __ASTAR_PATH_FIND_H__
#define __ASTAR_PATH_FIND_H__

#include "Common/DataStruct/MinHeap.h"
#include "Common/DataStruct/Point.h"

struct ASTAR_POINT 
{
    int nX;
    int nY;

    ASTAR_POINT(int _nX = 0, int _nY = 0)
    {
        nX = _nX;
        nY = _nY;
    }

    ASTAR_POINT operator-(const ASTAR_POINT& oPoint) const
    {
        return ASTAR_POINT(nX - oPoint.nX, nY - oPoint.nY);
    }
};

struct ASTAR_NODE 
{
    int nX;
    int nY;

    int nG;
    int nH;
    int nKey;
    bool bClosed;
    bool bOpened;
    uint32_t uVersion;
    ASTAR_NODE* pParent;

    ASTAR_NODE()
    {
        nX = 0;
        nY = 0;
        Reset();
    }

    void Reset()
    {
        nG = 0;
        nH = 0;
        nKey = 0; 
        bClosed = false;
        bOpened = false;
        pParent = NULL;
        uVersion = 0;
    }
};


struct MapConf;
class AStarPathFind
{
public:
    typedef std::list<ASTAR_POINT>::iterator ASLITER;
    typedef std::list<ASTAR_POINT>::reverse_iterator ASLRITER;

public:
    AStarPathFind();
    virtual ~AStarPathFind();
    void InitMapData(int nMapID);	//初始化地图块(地图变化时)调用
    int PathFind(int nStartX, int nStartY, int nEndX, int nEndY, std::list<Point>& oListPath);

protected:
    void Floyd(std::list<ASTAR_POINT>& oListPath);
    bool FloydCrossAble(const ASTAR_POINT& oPos1, const ASTAR_POINT& oPos2);
    inline ASTAR_NODE* GetNode(int nX, int nY);
	inline int GetNodesUnderPoint(float fX, float fY, ASTAR_NODE* tNodeList[]);
    inline int GetH(int nStartX, int nStartY, int nEndX, int nEndY);
    inline int GetG(int nStartX, int nStartY, int nEndX, int nEndY);
    inline bool CanDiagonalWalk(const ASTAR_NODE* pNode1, const ASTAR_NODE* pNode2);
    inline bool CanWalk(int nX, int nY);

private:
	MapConf* m_poMapConf;

	ASTAR_NODE* m_pMapData;
    MinHeap<ASTAR_NODE*> m_OpenedList;
    std::list<ASTAR_POINT> m_oTmpListPath;
    uint32_t m_uSearchVersion;
};

#endif