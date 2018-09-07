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
	void OnClientClose(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	void OnServiceClose(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);

	//玩家跑动
	void OnPlayerRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//玩家停止跑动
	void OnPlayerStopRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//玩家开始攻击
	void OnActorStartAttack(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//玩家停止攻击
	void OnActorStopAttack(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//角色受伤
	void OnActorHurted(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//角色伤害
	void OnActorDamage(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	//EVE伤害
	void OnEveHurted(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
}

#endif