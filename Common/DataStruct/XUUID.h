#ifndef __XUUID_H__
#define __XUUID_H__

#include "Common/Platform.h"
#include "Common/DataStruct/XMath.h"

namespace XUUID
{
	//参照时间 2019.6.1 0:0:0
	static int32_t nStandTime = 1559318400;

	static union
	{
		struct
		{//地址低到高
			uint16_t uSeriID;	//序列ID
			uint16_t uCustomID;	//服务器ID
			int nTime;			//本地时间
		} oID;
		int64_t llID;
	} unID;

	//@uCustomID: groupid+serverid+serviceid
	static inline int64_t GenID(int _nCustomID)
	{
		assert(_nCustomID <= 0xFFFF);
		static uint16_t uSeriID = 0;
		unID.oID.uSeriID = uSeriID++;
		unID.oID.uCustomID = (uint16_t)_nCustomID;
		unID.oID.nTime = (int)time(NULL) - nStandTime;
		return unID.llID;
	}
};

#endif