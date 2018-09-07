#ifndef __PACKETPROC_H__
#define __PACKETPROC_H__

#include "Include/Network/Network.hpp"

namespace NSPacketProc
{
	void RegisterPacketProc();
	////////////////RouterServer 只有内部消息 //////////////////
	void OnRegisterService(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnCloseServerReq(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnPrepCloseServer(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
}

#endif