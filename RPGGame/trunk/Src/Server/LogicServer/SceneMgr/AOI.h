#ifndef __AOI_H__
#define __AOI_H__

#include "Common/DataStruct/Array.h"
#include "Server/LogicServer/SceneMgr/Tower.h"

class Scene;
class AOI
{
public:
	typedef std::unordered_map<int, AOIOBJ*> AOIObjMap;
	typedef AOIObjMap::iterator AOIObjIter;
	friend class Scene;

public:
	AOI();
	~AOI();

	bool Init(Scene *pScene, int nMapWidth, int nMapHeight, int nLineObjNum=MAX_OBJ_PERLINE);

	int AddObj(int nPosX, int nPosY, int8_t nAOIMode, int nAOIArea[], Object* poGameObj, int8_t nAOIType = AOI_TYPE_RECT, int8_t nLine = -1);
	void MoveObj(int nID, int nPosX, int nPosY);
	void RemoveObj(int nID, bool bLeaveScene=false);

	void AddObserved(int nID);
	void AddObserver(int nID);
	void RemoveObserved(int nID);
	void RemoveObserver(int nID, bool bLeaveScene = false);
	void GetAreaObservers(int nID, Array<AOIOBJ*>& oObjCache, int nGameObjType); //nGameObjType:0表示所有
	void GetAreaObserveds(int nID, Array<AOIOBJ*>& oObjCache, int nGameObjType);

	AOIOBJ* GetObj(int nID) ;
	int GetObjCount() { return (int)m_oObjMap.size(); }
	AOIObjIter GetObjIterBegin() { return m_oObjMap.begin(); }
	AOIObjIter GetObjIterEnd() { return m_oObjMap.end(); }

	void ChangeLine(int nID, int8_t nNewLine);

public:
	void PrintTower();
	void ClearDropObj(int64_t nNowMS);

	int16_t* GetLineArray() { return m_tLineObj; }
	int16_t GetLineObjNum() { return m_nLineObjNum; }

private:
	int GenAOIID();
	void MoveObserver(AOIOBJ* pObj, int nOldPos[2], int nNewPos[2]);
	void MoveObserved(AOIOBJ* pObj, int nOldPos[2], int nNewPos[2]);

	void CalcTowerPos(int nPosX, int nPosY, int& nTowerX, int& nTowerY);
	void CalcRectTowerArea(int nPosX, int nPosY, int nWidth, int nHeight, int nLTTower[], int nRBTower[]);
	void CalcCircleTowerArea(int nPosX, int nPosY, int nRadius, int nLTTower[], int nRBTower[]);

private:
	int8_t AddLineObj(int8_t nLine=-1);
	int16_t SubLineObj(int8_t nLine);
	
private:
	Scene* m_poScene;		// 场景对象
	int m_nMapPixelWidth;	// 地图宽(像素)
	int m_nMapPixelHeight;	// 地图高(像素)
	int m_nMapWidthUnit;	// 地图宽(格子)
	int m_nMapHeightUnit;	// 地图高(格子)
	int m_nXTowerNum;		// X轴塔数量
	int m_nYTowerNum;		// Y轴塔数量
	int m_nTowerWidthPixel;
	int m_nTowerHeightPixel;


	AOIObjMap m_oObjMap;			//游戏对象映射
	Tower** m_pTowerArray;			//灯塔数组
	int64_t m_nLastClearMSTime;		//上次清理时间(毫秒)

	int16_t m_nLineObjNum;			//每条线人数
	int16_t m_tLineObj[MAX_LINE];	//分线(0表示公共线)

	Array<AOIOBJ*> m_oObjCache; //AOI对象缓存
	Array<AOIOBJ*> m_oObjCache2; //AOI对象缓存2
	DISALLOW_COPY_AND_ASSIGN(AOI);
};

#endif
