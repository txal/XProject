#ifndef __ROUTER_H__
#define __ROUTER_H__

#include "Include/Network/Network.hpp"
#include "Server/Base/Service.h"
#include "Server/Base/ServerContext.h"
#include "Server/RouterServer/NetPool.h"
#include "Server/RouterServer/ServiceNode.h"
#include "Server/RouterServer/ServerCloseProgress.h"

class Router : public Service
{
public:
	//<socket, ServiceNode*>
	typedef std::unordered_map<HSOCKET, ServiceNode*> SockMap;
	typedef SockMap::iterator SockIter;

	//<session, ServiceNode*>
	typedef std::unordered_map<int, ServiceNode*> SessionMap;
	typedef SessionMap::iterator SessionIter;

	//<mixid, ServiceNode*>
	typedef std::unordered_map<int, ServiceNode*> ServiceMap;
	typedef ServiceMap::iterator ServiceIter;

public:
	Router();
	virtual ~Router();
	bool Init(int nServiceID, const char* psListenIP, uint16_t uListenPort);
	bool Start();

public:
	bool RegService(int nServerID, int nServiceID, int nSessionID, int nServiceType);
	ServiceNode* GetService(int nServerID, int nServiceID);
	int GetServiceNum() { return (int)m_oServiceMap.size(); }
	NetPool* GetNetPool() {return &m_oNetPool;}

	int GetServerList(int tServerList[], int nMaxNum);
	int GetServiceListByServer(int nServerID, ServiceNode* tServiceList[], int nMaxNum, int nServiceType=0);
	ServerCloseProgress& GetServerClose() { return m_oServerClose; }

public:
	virtual INet* GetInnerNet() { return m_poListener; }

private:
    void ProcessNetEvent(int nWaitMSTime);
	void ProcessServerClose();

	void OnRouterAccept(HSOCKET hSock, uint32_t uRemoteIP, uint16_t uRemotePort);
	void OnRouterDisconnect(int nSessionID);
    void OnAddDataSock(HSOCKET hSock, int nSessionID);
	void OnRouterMsg(int nSessionID, Packet* poPacket);

	void BroadcastService(int nServerID, Packet* poPacket);

private:
	// Server
	int m_nListenSession;
	char m_sListenIP[256];
	uint16_t m_uListenPort;

	INet* m_poListener;
	NetEventHandler m_oNetEventHandler;
	
	ServiceMap m_oServiceMap;
	SessionMap m_oSessionMap;
	SockMap m_oSockMap;

	NetPool m_oNetPool;
	ServerCloseProgress m_oServerClose;
	DISALLOW_COPY_AND_ASSIGN(Router);
};

extern ServerContext* g_poContext;

#endif
