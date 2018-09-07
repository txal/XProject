#ifndef __LOGICSERVER_H__
#define __LOGICSERVER_H__

#include "Include/Network/Network.hpp"

#include "Server/Base/NetAdapter.h"
#include "Server/Base/Service.h"
#include "Server/Base/MsgBalancer.h"
#include "Server/LogicServer/BattleLog.h"
#include "Server/LogicServer/Object/DropItem/DropItemMgr.h"
#include "Server/LogicServer/Object/Monster/MonsterMgr.h"
#include "Server/LogicServer/Object/Role/RoleMgr.h"
#include "Server/LogicServer/Object/Robot/RobotMgr.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"


class LogicServer : public Service
{
public:
	LogicServer();
	virtual ~LogicServer();

	bool Init(int8_t nServiceID);
	bool Start();
	INet* GetInnerNet()						{ return m_pInnerNet;  }
	NetEventHandler* GetNetEventHandler()	{ return &m_oNetEventHandler; }

public:
	SceneMgr* GetSceneMgr()					{ return &m_oSceneMgr; }
	RoleMgr* GetRoleMgr()					{ return &m_oRoleMgr; }
	MonsterMgr* GetMonsterMgr()				{ return &m_oMonsterMgr; }
	RobotMgr* GetRobotMgr()					{ return &m_oRobotMgr; }
	DropItemMgr* GetDropItemMgr()			{ return &m_oDropItemMgr; }

public:
	void OnClientClose(uint16_t uServer, int8_t nService, int nSession);

private:
	// Connect and reg to router
	bool RegToRouter(int8_t nRouterServiceID);

	void ProcessTimer(int64_t nNowMSTime);
	void ProcessNetEvent(int64_t nWaitMSTime);
	void ProcessLoopCount(int64_t nWaitMSTime);

	void OnConnected(int nSessionID, int nRemoteIP, uint16_t nRemotePort);
	void OnDisconnect(int nSessionID);
	void OnRevcMsg(int nSessionID, Packet* poPacket);

private:
	// Net
	INet* m_pInnerNet;
	MsgBalancer m_oMsgBalancer;
	NetEventHandler m_oNetEventHandler;

	// Record
	uint32_t m_uInPackets;
	uint32_t m_uOutPackets;

	SceneMgr m_oSceneMgr;
	RoleMgr m_oRoleMgr;
	MonsterMgr m_oMonsterMgr;

	RobotMgr m_oRobotMgr;
	DropItemMgr m_oDropItemMgr;

	DISALLOW_COPY_AND_ASSIGN(LogicServer);
};

extern PacketReader goPKReader;
extern PacketWriter goPKWriter;
extern Packet* gpoPacketCache;
extern Array<NetAdapter::SERVICE_NAVI> goNaviCache;
extern BattleLog goBattleLog;

#endif
