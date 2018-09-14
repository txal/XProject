#ifndef __TOWER_H__
#define __TOWER_H__

#include "Include/Logger/Logger.hpp"
#include "Common/DataStruct/Array.h"
#include "Common/Platform.h"

#define DEFAULT_CAP 16

struct AOI_OBJ;
class Tower
{
public:
	Tower(int nX, int nY, uint16_t nTowerWidth, uint16_t nTowerHeight);
	void AddObserver(AOI_OBJ* pObj);
	void AddObserved(AOI_OBJ* pObj);
	bool RemoveObserver(AOI_OBJ* pObj);
	bool RemoveObserved(AOI_OBJ* pObj);
	Array<AOI_OBJ*>& GetObserverSet();
	Array<AOI_OBJ*>& GetObservedSet();

private:
	Array<AOI_OBJ*> m_ObserverSet;
	Array<AOI_OBJ*> m_ObservedSet;

	int16_t m_nLeftTop[2];		// 0:x 1:y
	uint16_t m_nTowerWidth;		//Grid nNum
	uint16_t m_nTowerHeight;

	DISALLOW_COPY_AND_ASSIGN(Tower);
};


#endif
