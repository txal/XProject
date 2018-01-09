#ifndef __WEBSOCKET_H__
#define __WEBSOCKET_H__

#include "LibNetwork/ExterNet.h"
#include "LibNetwork/Session.h"


class WebSocket : public ExterNet
{
public:
	typedef std::map<std::string, std::string> HEADER_MAP;

public:
	WebSocket() {};
	bool Init(int nServiceId, int nMaxConns, int nSecureCPM, int nSecureQPM, int nSecureBlock, int nDeadLinkTime, bool bLinger, bool bClient);

public:
	// Interface 
	virtual bool SendPacket(int nSessionID, Packet* poPacket);

public:
	//Server websocket handshake
	int ServerHandShakeReq(void* pUD, RECVBUF& oRecvBuf);
	int ServerHandShakeRet(void* pUD, RECVBUF& oRecvBuf);

	//Client websocket handshake
	virtual bool ClientHandShakeReq(int nSessionID);

	//Websocket mask decode
	void DecodeMask(uint8_t* pData, int nLen);

	//Websocket split packet function
	static int SplitPacket(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet);

    //Packet income
	virtual void OnRecvPacket(void* pUD, Packet* poPacket);

private:
	virtual void ReadData(SESSION* pSession);

private:
	bool m_bClient;
	HEADER_MAP m_oHeaderMap;

private:
	virtual ~WebSocket() {};
	DISALLOW_COPY_AND_ASSIGN(WebSocket);

};

#endif
