#ifndef __AOI_H__
#define __AOI_H__

#include "Common/DataStruct/Array.h"
#include "Server/LogicServer/SceneMgr/Tower.h"

class SceneBase;

class AOI
{
public:
	typedef std::unordered_map<int, AOIOBJ*> AOIObjMap; //[aoiid,aoiobj]
	typedef AOIObjMap::iterator AOIObjIter;
	friend class SceneBase;

public:
	AOI();
	~AOI();

	bool Init(SceneBase *pScene, int nMaxLineObjs);
	int AddAOIObj(Object* poGameObj, int nPosX, int nPosY, int8_t nAOIMode, int8_t nAOIType, int nAOIArea[], int16_t nLine);
	void MoveAOIObj(int nAOIID, int nPosX, int nPosY);
	void RemoveAOIObj(int nAOIID, bool bLeaveScene=false, bool bKicked=false);

	bool AddObserved(int nAOIID);
	bool AddObserver(int nAOIID);
	bool RemoveObserved(int nAOIID);
	bool RemoveObserver(int nAOIID, bool bLeaveScene = false);
	void GetAreaObservers(int nAOIID, Array<AOIOBJ*>& oObjCache, int nGameObjType); //nGameObjType:0表示所有
	void GetAreaObserveds(int nAOIID, Array<AOIOBJ*>& oObjCache, int nGameObjType);

	AOIOBJ* GetAOIObj(int nAOIID) ;
	int GetAOIObjCount() { return (int)m_oAOIObjMap.size(); }
	AOIObjIter GetAOIObjIterBegin() { return m_oAOIObjMap.begin(); }
	AOIObjIter GetAOIObjIterEnd() { return m_oAOIObjMap.end(); }

	int16_t* GetLineArray() { return m_tLineObjs; }
	int16_t GetMaxLineObjs() { return m_nMaxLineObjs; }
	void ChangeAOIObjLine(int nAOIID, int16_t nNewLine);

public:
	void PrintTower();
	void Update(int64_t nNowMS);
	void ClearDropedAOIObj(int64_t nNowMS);

private:
	int GenAOIID();
	void MoveObserver(AOIOBJ* pObj, int nOldPos[2], int nNewPos[2]);
	void MoveObserved(AOIOBJ* pObj, int nOldPos[2], int nNewPos[2]);

	void CalcTowerPos(int nPosX, int nPosY, int& nTowerX, int& nTowerY);
	void CalcRectTowerArea(int nPosX, int nPosY, int nWidth, int nHeight, int nLTTower[], int nRBTower[]);
	void CalcCircleTowerArea(int nPosX, int nPosY, int nRadius, int nLTTower[], int nRBTower[]);

private:
	int16_t AddLineObj(int16_t nLine=-1);
	int16_t SubLineObj(int16_t nLine);
	
private:
	SceneBase* m_poScene;	// 场景对象
	int m_nMapWidthUnit;	// 地图宽(格子)
	int m_nMapHeightUnit;	// 地图高(格子)
	int m_nXTowerNum;		// X轴塔数量
	int m_nYTowerNum;		// Y轴塔数量
	int m_nTowerWidthPixel;
	int m_nTowerHeightPixel;


	AOIObjMap m_oAOIObjMap;			//AOI对象映射
	Tower** m_pTowerArray;			//灯塔数组
	int64_t m_nLastClearAOITime;	//上次清理AOI时间(毫秒)

	int16_t m_nMaxLineObjs;			//每条线游戏对象上线
	int16_t m_tLineObjs[MAX_LINE];	//分线(0表示公共线)

	Array<AOIOBJ*> m_oAOIObjCache; //AOI对象缓存
	Array<AOIOBJ*> m_oAOIObjCache2; //AOI对象缓存2

private:
	DISALLOW_COPY_AND_ASSIGN(AOI);
};

#endif
