#ifndef __NETEVENT_H__
#define __NETEVENT_H__

#include <stdlib.h>
#include <stdint.h>

class INet;
class Packet;

namespace NSNetEvent
{
	enum EVENT_TYPE
	{
		eEVT_INVALID = 0,
		eEVT_ON_RECV = 1,
		eEVT_ON_ACCEPT = 2,
		eEVT_ON_CLOSE = 3,
		eEVT_ON_CONNECT = 4,
		eEVT_ON_LISTEN = 5,
		eEVT_ADD_DATASOCK = 6,
		eEVT_HANDSHAKE = 7,
		eEVT_REMAINPACKETS = 8,
	};

	struct EVENT_LISTEN
	{
		int nSessionID;
		uint16_t uListenPort;
	};

	struct EVENT_ACCEPT
	{
		HSOCKET hSock;
		int nSessionID;
		uint32_t uRemoteIP;
		uint16_t uRemotePort;
	};

	struct EVENT_CONNECT
	{
		int nSessionID;
		uint32_t uRemoteIP;
		uint16_t uRemotePort;
	};

	struct EVENT_DATASOCK
	{
		HSOCKET hSock;
		int nSessionID;
	};

	struct EVENT_CLOSE
	{
		int nSessionID;
	};

	struct EVENT_RECV
	{
		int nSessionID;
		Packet* poPacket;
	};

	struct EVENT_HANDSHAKE_RET
	{
		int nSessionID;
	};

	struct EVENT_REMAINPACKETS
	{
		int nPackets;
	};

	struct EVENT
	{
		INet* pNet;
		uint8_t uEventType;
		union
		{
			EVENT_RECV oRecv;
			EVENT_CLOSE oClose;
			EVENT_LISTEN oListen;
			EVENT_ACCEPT oAccept;
			EVENT_CONNECT oConnect;
			EVENT_DATASOCK oDataSock;
			EVENT_HANDSHAKE_RET oHandShake;
			EVENT_REMAINPACKETS oRemainPackets;
		} U;

		EVENT()
		{ 
			pNet = NULL;
			uEventType = (uint8_t)eEVT_INVALID;
			U.oRecv.poPacket = NULL;
		}
	};

}

#endif
