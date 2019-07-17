#ifndef __LOGICPACKETPROC_H__
#define __LOGICPACKETPROC_H__

#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketReader.h"

namespace NSPacketProc
{
	void RegisterPacketProc();

	////////////////////LogicServer 只有内部消息///////////////////
	void OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnLuaCmdMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//void OnClientClose(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);

	//角色开始跑动
	void OnRoleStartRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//角色停止跑动
	void OnRoleStopRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
}

#endif