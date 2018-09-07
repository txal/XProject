#ifndef __GATEWAY_H__
#define __GATEWAY_H__

#include "Include/Network/Network.hpp"
#include "Server/Base/Service.h"
#include "Server/Base/ServerConfig.h"
#include "Server/GateServer/ClientMgr/ClientMgr.h"

class Gateway : public Service
{
public:
	Gateway();
	virtual ~Gateway();
	bool Init(ServerNode* poConf);
	bool Start();

public:
	virtual INet* GetInnerNet() { return m_poInnerNet;  }
	virtual INet* GetExterNet() { return m_poExterNet;  }
	ClientMgr* GetClientMgr() { return &m_oClientMgr;  }

private:
	// Connect and reg to router
	bool RegToRouter(int nRouterServiceID);

	// For client
	void DecodeMask(Packet* poPacket); //Websocket masking decode
	void OnExterNetAccept(int nSessionID, uint32_t uRemoteIP);
	void OnExterNetClose(int nSessionID);
	void OnExterNetMsg(int nSessionID, Packet* poPacket);

	// For internal
	void OnInnerNetAccept(int nListenPort, int nSessionID);
	void OnInnerNetConnect(int nSessionID, int nRemoteIP, uint16_t nRemotePort);
	void OnInnerNetClose(int nSessionID);
	void OnInnerNetMsg(int nSessionID, Packet* poPacket);

	//
	void ProcessNetEvent(int64_t nWaitMSTime);
	void ProcessTimer(int64_t nNowMSTime);

private:
	uint16_t m_uListenPort;

	INet* m_poExterNet;
	INet* m_poInnerNet;
	NetEventHandler m_oNetEventHandler;

	uint32_t m_uInPackets;
	uint32_t m_uOutPackets;

	ClientMgr m_oClientMgr;

	DISALLOW_COPY_AND_ASSIGN(Gateway);
};

#endif
