#include "AIConf.h"
#include "MapConf.h"

//t{ii}
void ParseTable(std::string& sTable, int& nVal1, int& nVal2)
{
	nVal1 = nVal2 = 0;
	int nPosDot = (int)sTable.find(',');
	int nPosSemi = (int)sTable.find(';');
	assert(nPosDot >= 0 && nPosSemi >= 0);
	std::string sVal1 = sTable.substr(0, nPosDot);
	std::string sVal2 = sTable.substr(nPosDot + 1, nPosSemi - nPosDot - 1);
	nVal1 = atoi(sVal1.c_str());
	nVal2 = atoi(sVal2.c_str());
}

AIConf* AIConfMgr::GetConf(int nID)
{
	ConfIter iter = m_oConfMap.find(nID);
	if (iter != m_oConfMap.end())
	{
		return &(iter->second);
	}
	return NULL;
}

bool AIConfMgr::Init(CSVDocument* poCSVDoc)
{
	int nRows = (int)poCSVDoc->numRows();
	int nCols = (int)poCSVDoc->numColumns();
	assert(nCols >= 2);

	CSVDocument oDoc;
	for (int i = 2; i < nRows; i++)
	{
		AIConf oConf;
		oConf.uID = (uint16_t)poCSVDoc->getValue(i, "nID");
		std::string sActRandom = (const char*)poCSVDoc->getValue(i, "tActRandom");
		std::string sR1 = (const char*)poCSVDoc->getValue(i, "tR1");
		std::string sR2 = (const char*)poCSVDoc->getValue(i, "tR2");
		std::string sR3 = (const char*)poCSVDoc->getValue(i, "tR3");
		std::string sAtkTime = (const char*)poCSVDoc->getValue(i, "tAtkTime");
		std::string sDefTime = (const char*)poCSVDoc->getValue(i, "tDefTime");

		int nVal1;
		int nVal2;
		ParseTable(sActRandom, nVal1, nVal2);
		oConf.tActRandom[0] = (int16_t)nVal1;
		oConf.tActRandom[1] = (int16_t)nVal2;
		assert(oConf.tActRandom[0] + oConf.tActRandom[1] > 0);

		ParseTable(sR1, nVal1, nVal2);
		oConf.tR1[0] = (int16_t)nVal1;
		oConf.tR1[1] = (int16_t)nVal2;
		assert((oConf.tR1[0] == 0 && oConf.tR1[1] == 0) || oConf.tR1[1] >= gnUnitWidth);

		ParseTable(sR2, nVal1, nVal2);
		oConf.tR2[0] = (int16_t)nVal1;
		oConf.tR2[1] = (int16_t)nVal2;
		assert((oConf.tR2[0] == 0 && oConf.tR2[1] == 0) || oConf.tR2[1] >= gnUnitWidth);

		ParseTable(sR3, nVal1, nVal2);
		oConf.tR3[0] = (int16_t)nVal1;
		oConf.tR3[1] = (int16_t)nVal2;
		assert((oConf.tR3[0] == 0 && oConf.tR3[1] == 0) || (oConf.tR3[1] >= gnUnitWidth && oConf.tR3[1] >= gnUnitWidth));

		ParseTable(sAtkTime, nVal1, nVal2);
		oConf.tAtkTime[0] = (int16_t)nVal1;
		oConf.tAtkTime[1] = (int16_t)nVal2;

		ParseTable(sDefTime, nVal1, nVal2);
		oConf.tDefTime[0] = (int16_t)nVal1;
		oConf.tDefTime[1] = (int16_t)nVal2;

		oConf.nAtkCD = (int16_t)poCSVDoc->getValue(i, "nAtkCD");
		oConf.nSwitchWeaponRate = (int8_t)((int16_t)poCSVDoc->getValue(i, "nSwitchWeaponRate"));
		oConf.nDropBombRate = (int8_t)((int16_t)poCSVDoc->getValue(i, "nDropBombRate"));

		m_oConfMap[oConf.uID] = oConf;
	}
	return true;
}