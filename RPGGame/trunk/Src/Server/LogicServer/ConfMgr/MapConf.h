#ifndef __MAPCONF_H__
#define __MAPCONF_H__

#include "Include/Logger/Logger.hpp"
#include "Common/CSVDocument/CSVDocument.h"
#include "Common/Platform.h"

static const int gnUnitWidth = 40;	//格子宽(像素)
static const int gnUnitHeight = 40;	//格子高(像素)
static const int gnTowerWidth = 9;	//灯塔宽(格子)
static const int gnTowerHeight = 9;	//灯塔高(格子)

struct MapConf
{
	uint16_t nMapID;
	int16_t nUnitNumX;		//行格子数
	int16_t nUnitNumY;		//列格子数
	int16_t nPixelWidth;	//地图像素宽
	int16_t nPixelHeight;	//地图像素高
	int16_t* pMapGrid;

	inline bool IsBlockUnit(int nUnitX, int nUnitY)
	{
		int nIndex = nUnitY * nUnitNumX + nUnitX;
		if (nIndex < 0 || nIndex >= nUnitNumY * nUnitNumX)
		{
			XLog(LEVEL_ERROR, "IsBlockUnit: unit out of map:%d range:(%d,%d) map:(%d,%d)\n", nMapID, nUnitX, nUnitY, nUnitNumX, nUnitNumY);
			return true;
		}
		return (pMapGrid[nIndex] >= 0);
	}
};

class MapConfMgr
{
public:
	typedef std::unordered_map<int, MapConf> ConfMap;
	typedef ConfMap::iterator ConfIter;

public:
	MapConf* GetConf(int nID);
	bool Init(CSVDocument* poCSVDoc);

private:
	ConfMap m_oConfMap;

};

#endif