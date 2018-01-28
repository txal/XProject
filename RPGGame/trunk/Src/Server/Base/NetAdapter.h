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
		SERVICE_NAVI(uint16_t _uSrcServer=0, int8_t _nSrcService=0, uint16_t _uTarServer=0, int8_t _nTarService=0, int _nTarSession=0)
		{
			uSrcServer = _uSrcServer;
			nSrcService = _nSrcService;
			uTarServer = _uTarServer; 
			nTarService = _nTarService; 
			nTarSession = _nTarSession;
		}
		uint16_t uSrcServer;
		int8_t nSrcService;
		uint16_t uTarServer;
		int8_t nTarService;
		int nTarSession;
	};

	bool SendExter(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi, uint32_t uPacketIdx = 0);
	bool SendInner(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi);

	bool BroadcastExter(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList);
	bool BroadcastInner(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList);
};

#endif 