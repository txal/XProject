#ifndef __LOGICPACKETPROC_H__
#define __LOGICPACKETPROC_H__

#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketReader.h"

namespace NSPacketProc
{
	void RegisterPacketProc();

	//////////////////// 只有外部消息///////////////////
	void OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	void OnLuaCmdMsg(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);

	//位置同步
	void OnSyncActorPos(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	//跑动广播
	void OnBroadcastActorRun(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	//停止跑动广播
	void OnBroadcastActorStopRun(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	//角色攻击广播
	void OnBroadcastActorAttack(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	//角色伤害广播
	void OnBroadcastActorHurt(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	//角色死亡广播
	void OnBroadcastActorDead(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
	//同步/广播角色血量
	void OnSyncActorHP(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
}

#endif