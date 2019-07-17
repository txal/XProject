//给非RouterServer使用

#ifndef __NETADAPTER_H__
#define __NETADAPTER_H__

#include "Include/Network/Network.hpp"

#include "Common/Platform.h"
#include "Common/DataStruct/Array.h"


class NetAdapter
{
public:
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
	//按服务器和网关分组
	struct BROADCAST_HEADER
	{
		INNER_HEADER oInnerHeader;
		Array<int> oSessionList;
	};


	typedef std::unordered_map<int, BROADCAST_HEADER*> BCHeaderMap;
	typedef BCHeaderMap::iterator BCHeaderIter;

public:
	static void Release();
	static bool SendExter(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi, uint32_t uPacketIdx = 0);
	static bool SendInner(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi);

	static bool BroadcastExter(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList);
	static bool BroadcastInner(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList);

private:
	static BCHeaderMap m_oBCHeaderMap;

};

#endif 