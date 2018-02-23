#ifndef __TOWER_H__
#define __TOWER_H__

#include "Include/Logger/Logger.hpp"
#include "Common/DataStruct/Array.h"
#include "Common/Platform.h"

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
