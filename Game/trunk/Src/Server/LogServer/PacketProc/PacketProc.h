#ifndef __PACKETPROC_H__
#define __PACKETPROC_H__

#include "Include/Network/Network.hpp"

namespace NSPacketProc
{
	void RegisterPacketProc();
	///////////////////////LogServer 只有内部消息///////////////////////////
	//注册到Router返回
	void OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//Rpc处理
	void OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);

}

#endif