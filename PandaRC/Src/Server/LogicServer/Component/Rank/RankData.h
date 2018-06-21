#ifndef __RANKDATA_H__
#define __RANKDATA_H__

#include "Common/Platform.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/LogicServer/Component/Battle/WeaponList.h"

//伤害排行
struct DmgData
{
	int64_t llID;
	char sName[64];
	int nValue;
};

inline int DmgRankCompare(void* pData1, void* pData2)
{
	DmgData* pVal1 = (DmgData*)pData1;
	DmgData* pVal2 = (DmgData*)pData2;
	if (pVal1->nValue== pVal2->nValue)
	{
		return 0;
	}
	if (pVal1->nValue > pVal2->nValue)
	{
		return 1;
	}
	return -1;
}

inline void DefaultRankTraverse(int nRank, void* pData, void* pContext)
{
	DmgData* poRank = (DmgData*)pData;
	PacketWriter& g_oPKWriter = *(PacketWriter*)pContext;
	g_oPKWriter << poRank->sName << poRank->nValue;
}

#endif