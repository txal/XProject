//给非RouterServer使用

#ifndef __NETADAPTER_H__
#define __NETADAPTER_H__

#include "Include/Network/Network.hpp"

#include "Common/Platform.h"
#include "Common/DataStruct/Array.h"

namespace NetAdapter
{
	//内部服务路由节点
	struct INNER_NAVI
	{
		int nServer;
		union {
			int nSession;
			int nService;
		} u;
	};
	bool SendExter(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession, uint32_t uPacketIdx = 0, int nToServer = 0);
	bool SendInner(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession = 0, int nToServer = 0);
	bool BroadcastExter(uint16_t uCmd, Packet* poPacket, Array<INNER_NAVI>& oNaviList);
	bool BroadcastInner(uint16_t uCmd, Packet* poPacket, int tServiceList[], int nServiceNum, int tServerList[] = NULL);
};

#endif 