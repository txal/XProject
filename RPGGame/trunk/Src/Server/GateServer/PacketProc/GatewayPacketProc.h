#ifndef __PACKETPROC_H__
#define __PACKETPROC_H__

#include "Include/Network/Network.hpp"

namespace NSPacketProc
{
	void RegisterPacketProc();

	/********************************外部处理函数***********************************/
	void OnPing(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	void OnKeepAlive(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);


	/********************************内部处理函数***********************************/
	//注册到Router返回
	void OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//角色逻辑服同步
	void OnSyncRoleLogic(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//踢玩家下线
	void OnKickClient(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//请求玩家IP
	void OnClientIPReq(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//广播网关指令
	void OnBroadcastGate(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);

}

#endif