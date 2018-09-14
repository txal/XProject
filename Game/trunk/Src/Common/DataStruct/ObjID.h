#ifndef __OBJID_H__
#define __OBJID_H__

#include "Common/Platform.h"
#include "Common/DataStruct/XMath.h"

union GAME_OBJID
{
	struct
	{//地址低到高
		uint16_t uSeriID;	//序列ID
		uint16_t uSrvID;	//服务ID
		int nTime;			//本地时间
	};
	int64_t llID;
	GAME_OBJID(int64_t nID = 0) { llID = nID; }
};

//不支持负数
static inline const char* objid_str(int64_t llID)
{
	assert(llID >= 0);
	size_t uSize = 0;
	return XMath::Int2Str(llID, uSize);
}

static inline int64_t str_objid(const char* psID)
{
	int64_t llID = 0;
	int nLen = (int)strlen(psID);
	for (int i = 0; i < nLen; i++)
	{
		if (isdigit(psID[i]))
		{
			llID = llID * 10 + psID[i] - '0';
		}
	}
	return llID;
}

static inline GAME_OBJID MakeGameObjID(int nServiceID)
{
	static uint16_t nAutoIncrement = 0;
	nAutoIncrement++;
	GAME_OBJID oObjID;
	oObjID.uSeriID = nAutoIncrement;
	oObjID.uSrvID = (uint16_t)nServiceID;
	oObjID.nTime = (int)time(NULL);
	return oObjID;
}


#endif