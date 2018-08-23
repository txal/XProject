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

#define MAX_LINE 101		//分线上限
#define MIN_OBJ_PERLINE 10  //每条线最低数对象
#define MAX_OBJ_PERLINE 100 //每条线默认对象上限

#define DEF_AMSIZE 2
#define MAX_AMSIZE 0x7FFF

class Object;
struct AOIOBJ
{
	uint8_t nRef;
	int nAOIID;
	int8_t nAOIMode;
	int8_t nAOIType;	//矩形或者圆形
	int16_t nPos[2];	//坐标(像素)
	int16_t nArea[2];	//矩形(像素):(宽,高); 圆形(像素):(半径,0)
	Object* poGameObj;	//游戏对象
	int8_t nLine;		//所在分线
};


//Array map
struct AM
{
	int16_t nCap;
	AOIOBJ** pTArray;
	int16_t nFreeIndex;

	AM()
	{
		nCap = DEF_AMSIZE;
		pTArray = (AOIOBJ**)XALLOC(NULL, sizeof(AOIOBJ*)*nCap);
		nFreeIndex = 0;
	}
	~AM()
	{
		SAFE_FREE(pTArray);
	}

	int Size()
	{
		return nFreeIndex;
	}

	bool Expand()
	{
		int16_t nNewCap = XMath::Min(nCap*2, MAX_AMSIZE);
		if (nCap == nNewCap)
		{
			return false;
		}
		AOIOBJ** pNewTArray= (AOIOBJ**)XALLOC(pTArray, sizeof(AOIOBJ*)*nNewCap);
		if (pNewTArray == NULL)
		{
			SAFE_FREE(pNewTArray);
			XLog(LEVEL_ERROR, "Memory out!\n");
			return false;
		}
		nCap = nNewCap;
		pTArray = pNewTArray;
		return true;
	}

	bool AddObj(AOIOBJ* pObj, int16_t& nIndex)
	{
		if (nIndex != -1)
		{
			assert(nIndex < MAX_AMSIZE);
			assert(pTArray[nIndex] == pObj);
			return true;
		}
		if (nFreeIndex >= nCap)
		{
			if (!Expand())
			{
				return false;
			}
		}
		nIndex = nFreeIndex;
		pTArray[nFreeIndex++] = pObj;
		return true;
	}
	bool RemoveObj(AOIOBJ* pObj, int16_t& nIndex)
	{
		if (nIndex == -1)
		{
			return false;
		}
		assert(nIndex < MAX_AMSIZE);
		assert(pTArray[nIndex] == pObj);
		pTArray[nIndex] = pTArray[--nFreeIndex];
		pTArray[nFreeIndex] = NULL;
		nIndex = -1;
		return true;
	}

	//bool AddObserver(AOIOBJ* pObj)
	//{
	//	return AddObj(pObj, pObj->nObserverIndex);
	//}
	//bool RemoveObserver(AOIOBJ* pObj)
	//{
	//	return RemoveObj(pObj, pObj->nObserverIndex);
	//}
	//bool AddObserved(AOIOBJ* pObj)
	//{
	//	return AddObj(pObj, pObj->nObservedIndex);
	//}
	//bool RemoveObserved(AOIOBJ* pObj)
	//{
	//	return RemoveObj(pObj, pObj->nObservedIndex);
	//}

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

	int16_t m_nLeftTop[2];		//灯塔坐标(格子)
	uint16_t m_nTowerWidth;		//灯塔高(格子)
	uint16_t m_nTowerHeight;	//灯塔宽(格子)

	DISALLOW_COPY_AND_ASSIGN(Tower);
};


#endif
