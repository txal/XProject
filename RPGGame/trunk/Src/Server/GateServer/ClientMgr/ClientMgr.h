#ifndef __CLIENTMGR_H__
#define __CLIENTMGR_H__

#include "Common/Platform.h"
#include "Server/GateServer/ClientMgr/Client.h"

class ClientMgr
{
public:
	typedef std::unordered_map<int, CLIENT*> ClientMap;
	typedef ClientMap::iterator ClientIter;

public:
	ClientMgr();
	~ClientMgr();

	CLIENT* CreateClient(int nSessionID, uint32_t uRemoteIP);
	CLIENT* GetClient(int nSessionID);
	void RemoveClient(int nSessionID);
	int GetClientLogicService(int nSessionID);

	ClientIter GetClientIterBegin() { return m_oClientMap.begin(); }
	ClientIter GetClientIterEnd()	{ return m_oClientMap.end(); }

private:
	ClientMap m_oClientMap;
	DISALLOW_COPY_AND_ASSIGN(ClientMgr);
};

#endif