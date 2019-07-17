#ifndef __TOWER_H__
#define __TOWER_H__

#include "Include/Logger/Logger.hpp"
#include "Common/DataStruct/Array.h"
#include "Common/DataStruct/XMath.h"
#include "Common/Platform.h"

#define AOI_MODE_NONE 0
#define AOI_MODE_OBSERVER 1
#define AOI_MODE_OBSERVED 2
#define AOI_MODE_DROP 4

#define AOI_TYPE_RECT 1
#define AOI_TYPE_CIRCLE 2

#define MAX_LINE 1001		//分线上限
#define MIN_OBJ_PERLINE 1   //每条线最小对象数
#define MAX_OBJ_PERLINE 200 //每条线最大对象数

class Object;

struct AOIOBJ
{
	uint8_t nRef;
	int nAOIID;
	int8_t nAOIMode;
	int8_t nAOIType;	//矩形或者圆形
	int16_t nPos[2];	//坐标(像素)
	int16_t nArea[2];	//矩形(像素):[宽,高]; 圆形(像素):[半径,0]
	int16_t nLine;		//所在分线
	Object* poGameObj;	//游戏对象

	bool IsDroped()
	{
		return ((nAOIMode & AOI_MODE_DROP) ? true : false);
	}
};

class Tower
{
public:
	typedef std::unordered_map<int, AOIOBJ*> AOIObjMap;
	typedef AOIObjMap::iterator AOIObjIter;

	typedef std::unordered_map<int, AOIObjMap*> LineMap;
	typedef LineMap::iterator LineIter;

public:
	Tower(int nUnitX, int nUnitY, uint16_t nTowerWidth, uint16_t nTowerHeight);
	~Tower();

public:
	void AddObserver(AOIOBJ* pObj);
	void AddObserved(AOIOBJ* pObj);
	bool RemoveObserver(AOIOBJ* pObj);
	bool RemoveObserved(AOIOBJ* pObj);
	void GetObserverList(AOIOBJ* pObj, Array<AOIOBJ*>& oObjCache, int nObjType=0);
	void GetObservedList(AOIOBJ* pObj, Array<AOIOBJ*>& oObjCache, int nObjType=0);

protected:
	AOIObjMap* GetLineObserverMap(int nLine);
	void RemoveLineObserverMap(int nLine);
	AOIObjMap* GetLineObservedMap(int nLine);
	void RemoveLineObservedMap(int nLine);
	void CacheAOIObj(AOIObjMap* pObjMap, AOIOBJ* pObj, Array<AOIOBJ*>& oObjCache, int nObjType);

private:
	LineMap m_oObserverLine;
	LineMap m_oObservedLine;

	int16_t m_nLeftTop[2];		//塔坐标(格子)
	uint16_t m_nTowerWidth;		//塔高(格子)
	uint16_t m_nTowerHeight;	//塔宽(格子)

	DISALLOW_COPY_AND_ASSIGN(Tower);
};


#endif
