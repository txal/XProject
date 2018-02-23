#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Include/Logger/Logger.hpp"

std::string gsMapDir = "../../Data/ServerMap/";

MapConf* MapConfMgr::GetConf(int nID)
{
	ConfIter iter = m_oConfMap.find(nID);
	if (iter != m_oConfMap.end())
	{
		return &(iter->second);
	}
	return NULL;
}

bool MapConfMgr::Init(CSVDocument* poCSVDoc)
{
	int nRows = (int)poCSVDoc->numRows();
	int nCols = (int)poCSVDoc->numColumns();
	assert(nCols >= 2);

	CSVDocument oDoc;
	for (int i = 2; i < nRows; i++)
	{
		int nID = (int)poCSVDoc->getValue(i, "nID");
		std::string sFile = (const char*)poCSVDoc->getValue(i, "sFile");
		assert(sFile != "");
		sFile = gsMapDir + sFile;
		int nErrRow = 0, nErrCol = 0;
		oDoc.load(sFile, false, &nErrRow, &nErrCol);
		if (nErrRow != 0 || nErrCol != 0)
		{
			 XLog(LEVEL_ERROR, "Conf '%s' Row:%d Col:%d error!\n", sFile.c_str());
			 return false;
		}
		int nUnitNumY = (int)oDoc.numRows();
		int nUnitNumX = (int)oDoc.numColumns();
		assert(nUnitNumY > 0 && nUnitNumX > 0);
		int nGridNum = nUnitNumY * nUnitNumX;
		MapConf oConf;
		oConf.nMapID = nID;
		oConf.nUnitNumX = nUnitNumX;
		oConf.nUnitNumY = nUnitNumY;
		oConf.nPixelWidth = nUnitNumX * gnUnitWidth;
		oConf.nPixelHeight = nUnitNumY * gnUnitHeight;
		oConf.pMapGrid = (int16_t*)XALLOC(NULL, nGridNum * sizeof(int16_t));
		
		for (int r = nUnitNumY - 1; r >= 0; r--)
		{
			for (int c = 0; c < nUnitNumX; c++)
			{
				int nGridVal = (int)oDoc.getValue(r, c);
				int nGridIdx = (nUnitNumY - 1 - r) * nUnitNumX + c;
				oConf.pMapGrid[nGridIdx] = (int16_t)nGridVal;
			}
		}
		m_oConfMap[nID] = oConf;
	}
	return true;
}