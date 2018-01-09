#ifndef __NET_H__
#define __NET_H__

#include "Include/Network/INet.h"
#include "Include/Network/MailBox.h"
#include "Include/Logger/Logger.h"
#include "LibNetwork/Ctrl.h"
#include "LibNetwork/NetDef.h"

#ifdef __linux
#include "LibNetwork/Ae/Epoll.h"
#else
#include "LibNetwork/Ae/Iocp.h"
#endif

class Packet;
class MsgHandler;
struct SESSION;

class Net : public INet
{
public:
	Net();

	bool Init(const char* psNetName, int nServiceID, int nMaxConns, int nRecvBufSize, bool bLinger = true);
	void SetEventHandler(NetEventHandler* pNetEventHandler) { m_poNetEventHandler = pNetEventHandler; }
	NetEventHandler* GetEventHandler() { return m_poNetEventHandler;  }
	const char* GetName() { return m_sNetName; }

public:
	// Interface
	virtual void Release();
	virtual bool Listen(const char* psIP, uint16_t uListenPort, bool bNotCreateSession);
	virtual bool Connect(const char* psRemoteIP, uint16_t uRemotePort);
	virtual bool Close(int nSessionID);

	virtual bool SetSentClose(int nSessionID);
	virtual bool SendPacket(int nSessionID, Packet* poPacket) = 0;
	virtual bool AddDataSock(HSOCKET hSock, uint32_t uRemoteIP, uint16_t uRemotePort);
	virtual bool ClientHandShakeReq(int nSessionID) { return false; }

protected:
	// Event call back
	virtual void OnListen(uint16_t uListenPort, int nSessionID);
	virtual void OnAccept(HSOCKET hSock, int nSessionID, uint32_t uRemoteIP, uint16_t uRemotePort);
	virtual void OnConnect(int nSessionID, uint32_t uRemoteIP, uint16_t uRemotePort);
	virtual void OnClose(int nSessionID);
	virtual void OnAddDataSock(HSOCKET hSock, int nSessionID);

public:
	virtual void OnRecvPacket(void* pUD, Packet* poPacket) = 0;

protected:
	// For child class
	SESSION* GetSession(int nSessionID);
	void CloseSession(int nSessionID);

	// Member var
	int GetCurSessions()		{ return m_nCurSessions; }
	int GetMaxSessions()		{ return m_nMaxSessions; }
	SESSION** GetSessionArray() { return m_poSessionArray; }

    // Sys
	Ae* GetAe()					{ return m_pNetAe; }
	int GetServiceID()			{ return m_nServiceID; }
	MailBox<REQUEST_PACKET>* GetMailBox() { return &m_oMailBox; }
	void CheckAndModifyEvent(SESSION* poSession, int nPreEvent); //检查需要注册的事件

	uint32_t& GetInPackets()	{ return m_uInPackets; }
	uint32_t& GetOutPackets()	{ return m_uOutPackets; }

private:
	// Session
	int GenSessionIndex();
	void AcceptTcpConnect(SESSION* pListener);
	SESSION* CreateSession(HSOCKET nSock, uint32_t uSessionIP, uint16_t nSessionPort, int nSessionType);

	// Net event proc
	static void EventProc(void* pParam, const EVENT &Event);
	virtual void Timer(long nInterval) = 0;
	virtual void ReadData(SESSION* pSession) = 0;
	virtual void WriteData(SESSION* pSession) = 0;
	virtual bool CheckBlockDataSize(SESSION* pSession) = 0;
	virtual bool CheckCPM(uint32_t uIP, const char* psIP) { return true; };

	// Ctrl
	void CtrlProc(SESSION* pSession);
	void DoListen(REQUEST_LISTEN* pRequest);
	void DoConnect(REQUEST_CONNECT* pRequest);
	void DoClose(REQUEST_CLOSE* pRequest);
	void DoSend(REQUEST_SEND* pRequest);
	void DoSentClose(REQUEST_SENTCLOSE* pRequest);
	void DoAddDataSock(REQUEST_ADD_DATASOCK* pRequest);

private:
	char m_sNetName[32];
	int m_nServiceID;

	bool m_bLinger;
	bool m_bNoSession; //只负责监听不创建SESSION

	int m_nMaxSessions;
	int m_nCurSessions;
	SESSION** m_poSessionArray;

	Ae* m_pNetAe;
	int m_nRecvBufSize;

	MailBox<REQUEST_PACKET> m_oMailBox;
    NetEventHandler* m_poNetEventHandler;

	uint32_t m_uInPackets;
	uint32_t m_uOutPackets;

protected:
	int m_nNetType;
	bool m_bDebugNet;

	virtual ~Net();
    DISALLOW_COPY_AND_ASSIGN(Net);
};

#endif
