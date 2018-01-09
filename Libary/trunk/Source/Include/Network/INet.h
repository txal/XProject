#ifndef __INET_H__
#define __INET_H__

#include "Common/Platform.h"

enum
{
	NET_TYPE_INTERNAL = 1,
	NET_TYPE_EXTERNAL = 2,
	NET_TYPE_WEBSOCKET = 3,
};

class Packet;
class NetEventHandler;

class INet
{
public:
	INet() {}
	DLL_API static INet* CreateNet(int nNetType, int nServiceID, int nMaxConns, NetEventHandler* pNetEventHandler
		, int nSecureCPM = 0, int nSecureQPM = 0, int nSecureBlock = 0, int nDeadLinkTime = 180, bool bClient = false);

public:
	DLL_API virtual void Release() = 0;
	// @bNotCreateSession: only listen and accept connection, but not create data session for connection
	DLL_API virtual bool Listen(const char* psIP, uint16_t uPort, bool bNotCreateSession = false) = 0;
	DLL_API virtual bool Connect(const char* pRemoteIP, uint16_t nRemotePort) = 0;
	DLL_API virtual bool Close(int nSessionID) = 0;

	DLL_API virtual bool SetSentClose(int nSessionID) = 0;
	DLL_API virtual bool SendPacket(int nSessionID, Packet *poPacket) = 0;
	DLL_API virtual bool AddDataSock(HSOCKET hSock, uint32_t uRemoteIP, uint16_t uRemotePort) = 0;
	DLL_API virtual bool ClientHandShakeReq(int nSessionID) = 0;

protected:
	virtual ~INet() {}

private:
	DISALLOW_COPY_AND_ASSIGN(INet);
};

#endif
