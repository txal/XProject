//给非RouterServer使用

#ifndef __NETADAPTER_H__
#define __NETADAPTER_H__

#include "Common/Platform.h"
#include "Include/Network/Network.hpp"

namespace NetAdapter
{
	bool SendExter(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession, uint32_t uPacketIdx = 0, int nToServer = 0);
	bool SendInner(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession = 0, int nToServer = 0);
	bool BroadcastExter(uint16_t uCmd, Packet* poPacket, int tSessionList[], int nSessionNum);
	bool BroadcastInner(uint16_t uCmd, Packet* poPacket, int tServiceList[], int nServiceNum, int tServerList[] = NULL);
};

#endif 