#ifndef __RANKDATA_H__
#define __RANKDATA_H__

#include "Common/Platform.h"

struct RankData
{
	int64_t llID;
	char sName[64];
	int nValue;
};

static int RankCompare(void* pData1, void* pData2)
{
	RankData* pVal1 = (RankData*)pData1;
	RankData* pVal2 = (RankData*)pData2;
	if (pVal1->nValue == pVal2->nValue)
	{
		return 0;
	}
	if (pVal1->nValue > pVal2->nValue)
	{
		return 1;
	}
	return -1;
}

static void RankTraverse(int nRank, void* pData, void* pContext)
{

}

#endif