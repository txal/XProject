#ifndef __LOG_SERVER_H__
#define __LOG_SERVER_H__

#include "Include/Network/Network.hpp"
#include "Server/Base/Service.h"
#include "Common/HttpRequest/HttpRequest.h"

class LogServer: public Service
{
public:
	LogServer();
	virtual ~LogServer();
	bool Init(int8_t nServiceID);
	bool Start();
	int GetMsgCount() { return m_oNetEventHandler.GetMailBox().Size(); }
	virtual INet* GetInnerNet() { return m_poInnerNet;  }

private:
	// Connect and reg to router
	bool RegToRouter(int nRouterServiceID);

	// For internal
	void OnInnerNetAccept(int nListenPort, int nSessionID);
	void OnInnerNetConnect(int nSessionID, int nRemoteIP, uint16_t nRemotePort);
	void OnInnerNetClose(int nSessionID);
	void OnInnerNetMsg(int nSessionID, Packet* poPacket);

	//
	void ProcessNetEvent(int64_t nWaitMSTime);
	void ProcessTimer(int64_t nNowMSTime);

private:
	INet* m_poInnerNet;
	NetEventHandler m_oNetEventHandler;
	DISALLOW_COPY_AND_ASSIGN(LogServer);
};

extern HttpRequest goHttpRequest;

#endif