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

	CLIENT* CreateClient(int nClientID, uint32_t uRemoteIP);
	CLIENT* GetClient(int nClientID);
	void RemoveClient(int nClientID);
	int GetClientLogicService(int nClientID);

	ClientIter GetClientIterBegin() { return m_oClientMap.begin(); }
	ClientIter GetClientIterEnd()	{ return m_oClientMap.end(); }

private:
	ClientMap m_oClientMap;
	DISALLOW_COPY_AND_ASSIGN(ClientMgr);
};

#endif