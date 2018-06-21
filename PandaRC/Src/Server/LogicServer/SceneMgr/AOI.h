#ifndef __AOI_H__
#define __AOI_H__

#include "Common/DataStruct/Array.h"
#include "Server/LogicServer/SceneMgr/Tower.h"

#define AOI_MODE_NONE 0
#define AOI_MODE_OBSERVER 1
#define AOI_MODE_OBSERVED 2
#define AOI_MODE_DROP 4

#define AOI_TYPE_RECT 1
#define AOI_TYPE_CIRCLE 2

class Object;
struct AOI_OBJ
{
	uint32_t nRef;
	int nAOIObjID;
	int8_t nAOIMode;
	int8_t nAOIType;	//AOI_(RECT|CIRCLE)
	int16_t nPos[2];	//Pixel pos
	int16_t nArea[2];	//(Width, Height) or Radius(Pixel)
	Object* poGameObj;	//游戏对象
};

class Scene;
class AOI
{
public:
	typedef std::unordered_map<int, AOI_OBJ*> AOIObjMap;
	typedef AOIObjMap::iterator AOIObjIter;
	friend class Scene;

public:
	AOI();
	~AOI();

	bool Init(Scene *pScene, int nMapWidth, int nMapHeight);
	int AddObj(int nPosX, int nPosY, int8_t nAOIMode, int8_t nAOIType, int nAOIArea[], Object* poGameObj);
	void MoveObj(int nID, int nX, int nY);
	void RemoveObj(int nID);
	void RemoveObserver(int nID, bool bLeaveScene = false);
	void RemoveObserved(int nID);
	void AddObserver(int nID);
	void AddObserved(int nID);
	void GetAreaObservers(int nID, Array<AOI_OBJ*>& oObjCache, int nGameObjType);
	void GetAreaObserveds(int nID, Array<AOI_OBJ*>& oObjCache, int nGameObjType);
	AOI_OBJ* GetObj(int nID) ;
	int GetObjCount()				{ return (int)m_oObjMap.size(); }
	AOIObjIter GetObjIterBegin()	{ return m_oObjMap.begin(); }
	AOIObjIter GetObjIterEnd()		{ return m_oObjMap.end(); }
	void ClearDropObj(int64_t nNowMS);

public:
	void PrintTower();

private:
	int GenObjID();
	void MoveObserver(AOI_OBJ* pObj, int nOldPos[2], int nNewPos[2]);
	void MoveObserved(AOI_OBJ* pObj, int nOldPos[2], int nNewPos[2]);

	void CalTowerPos(int nPosX, int nPosY, int& nTowerX, int& nTowerY);
	void CalCircleTowerArea(int nPosX, int nPosY, int nRadius, int nLeftTopTower[], int nRightBottomTower[]);
	void CalRectTowerArea(int nPosX, int nPosY, int nWidth, int nHeight, int nLeftTopTower[], int nRightBottomTower[]);
	
private:
	Scene* m_poScene;		// scene
	int m_nMapPixelWidth;	// Map pixel width 
	int m_nMapPixelHeight;	// Map pixel heiht
	int m_nMapWidthUnit;	// Map width unit num
	int m_nMapHeightUnit;	// Map heiht unit num
	int m_nXTowerNum;		// X tower num
	int m_nYTowerNum;		// Y tower num

	Tower** m_pTowerArray;
	AOIObjMap m_oObjMap;
	int64_t m_nLastClearMSTime; 

	Array<AOI_OBJ*> m_oObjCache; // Cache
	DISALLOW_COPY_AND_ASSIGN(AOI);
};

#endif
