#ifndef __ClientMGR_H__
#define __ClientMGR_H__

#include "Common/Platform.h"
#include "Server/GateServer/ClientMgr/Client.h"

class ClientMgr
{
public:
	typedef std::unordered_map<int, Client*> ClientMap;
	typedef ClientMap::iterator ClientIter;

public:
	ClientMgr();
	~ClientMgr();

	Client* CreateClient(int nSessionID, uint32_t uRemoteIP);
	Client* GetClientBySession(int nSessionID);
	Client* GetClientByRoleID(int nRoleID);

	void OnClientClose(int nSessionID);
	int GetClientLogic(int nSessionID);

	ClientIter GetClientIterBegin() { return m_oClientSessionMap.begin(); }
	ClientIter GetClientIterEnd()	{ return m_oClientSessionMap.end(); }

	void AddRoleIDMap(int nRoleID, Client* poClient);
	void OnRoleRelease(int nRoleID);

public:
	void Update(int64_t nNowMS);

private:
	ClientMap m_oClientSessionMap;
	ClientMap m_oClientRoleIDMap;
	int m_nLastUpdateTime;
	DISALLOW_COPY_AND_ASSIGN(ClientMgr);
};

#endif