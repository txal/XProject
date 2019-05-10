﻿#ifndef __ClientMGR_H__
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
	int GetClientLogic(int nSessionID);
	void OnClientClose(int nSessionID);

	ClientIter GetClientIterBegin() { return m_oClientSessionMap.begin(); }
	ClientIter GetClientIterEnd()	{ return m_oClientSessionMap.end(); }

public:
	void Update(int64_t nNowMS);

private:
	ClientMap m_oClientSessionMap;
	int m_nLastUpdateTime;
	DISALLOW_COPY_AND_ASSIGN(ClientMgr);
};

#endif