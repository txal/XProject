#ifndef __PACKETPROC_H__
#define __PACKETPROC_H__

#include "Include/Network/Network.hpp"

namespace NSPacketProc
{
	void RegisterPacketProc();
	///////////////////////外部消息///////////////////////////
	void OnLuaCmdMsg(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	///////////////////////内部消息///////////////////////////
	//注册Router返回
	void OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//Rpc处理函数
	void OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnLuaCmdMsgInner(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);

}

#endif