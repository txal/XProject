#ifndef __TOWER_H__
#define __TOWER_H__

#include "Include/Logger/Logger.hpp"
#include "Common/DataStruct/Array.h"
#include "Common/Platform.h"

#define DEF_AMSIZE 8;
//Array map
template<class T>
struct AM
{
	T* TArray;
	uint16_t* AFreeSlot;
	uint16_t nCap;

	AM()
	{
		nCap = DEF_AMSIZE;
		TArray = (T*)XALLOC(NULL, sizeof(T)*nCap);
		AFreeSlot = (uint16_t*)XALLOC(NULL, sizeof(uint16_t)*nCap);
		for (int i = 0; i < nCap; i++)
		{
			AFreeSlot[i] = i;
		}
	}

	bool Expand()
	{
		uint16_t nCapNew = nCap * 2;
		T* TArrayNew = XALLOC(TArray, sizoef(T)*nCapNew)
	}

	bool AddObj()
	{
		if (freeslot[0] == 0)
		{
			if (!Expand())
			{
				return false;
			}
		}
	}
};

struct AOIOBJ;
class Tower
{
public:
	typedef std::unordered_map<int, AOIOBJ*> AOIObjMap;
	typedef AOIObjMap::iterator AOIObjIter;

public:
	Tower(int nUnitX, int nUnitY, uint16_t nTowerWidth, uint16_t nTowerHeight);
	void AddObserver(AOIOBJ* pObj);
	void AddObserved(AOIOBJ* pObj);
	bool RemoveObserver(AOIOBJ* pObj);
	bool RemoveObserved(AOIOBJ* pObj);
	AOIObjMap& GetObserverMap();
	AOIObjMap& GetObservedMap();

private:
	AOIObjMap m_oObserverMap;
	AOIObjMap m_oObservedMap;

	int16_t m_nLeftTop[2];		//灯塔坐标(格子)
	uint16_t m_nTowerWidth;		//灯塔高(格子)
	uint16_t m_nTowerHeight;	//灯塔宽(格子)

	DISALLOW_COPY_AND_ASSIGN(Tower);
};


#endif
