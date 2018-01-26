//给非RouterServer使用

#ifndef __NETADAPTER_H__
#define __NETADAPTER_H__

#include "Include/Network/Network.hpp"

#include "Common/Platform.h"
#include "Common/DataStruct/Array.h"

namespace NetAdapter
{
	//服务导航
	struct SERVICE_NAVI
	{
		SERVICE_NAVI(int _nServerID, int _nServiceID, int _nSessionID)
		{
			nServerID = _nServerID;
			nServiceID = _nServiceID; 
			nSessionID = _nSessionID;
		}
		int nServerID;
		int nServiceID; //Exter可不填
		int nSessionID; //Inner可不填
	};

	bool SendExter(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi, uint32_t uPacketIdx = 0);
	bool SendInner(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi);

	bool BroadcastExter(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList);
	bool BroadcastInner(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList);
};

#endif 