#include "Server/GateServer/ClientMgr/ClientMgr.h"
#include "Include/Logger/Logger.hpp"
	
ClientMgr::ClientMgr()
{
	m_nLastUpdateTime = 0;
}

ClientMgr::~ClientMgr()
{
	ClientIter iter = m_oClientSessionMap.begin();
	ClientIter iter_end = m_oClientSessionMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
	m_oClientSessionMap.clear();
}
	
Client* ClientMgr::CreateClient(int nSessionID, uint32_t uRemoteIP)
{
	if (GetClientBySession(nSessionID) != NULL)
	{
		XLog(LEVEL_ERROR, "CreateClient: session:%d client allready exist!\n", nSessionID);
		return NULL;
	}
	Client* poClient = XNEW(Client);
	poClient->m_nSession = nSessionID;
	poClient->m_uRemoteIP = uRemoteIP;
	m_oClientSessionMap[nSessionID] = poClient;
	return poClient;
}

void ClientMgr::OnClientClose(int nSessionID)
{
	ClientIter iter = m_oClientSessionMap.find(nSessionID);
	if (iter != m_oClientSessionMap.end())
	{
		Client* poClient = iter->second;
		poClient->m_nSession = 0;
		poClient->m_uRemoteIP = 0;
		poClient->m_uCmdIndex = 0;
		m_oClientSessionMap.erase(iter);
		SAFE_DELETE(poClient);
	}
}

Client* ClientMgr::GetClientBySession(int nSessionID)
{
	ClientIter iter = m_oClientSessionMap.find(nSessionID);
	if (iter != m_oClientSessionMap.end())
	{
		return iter->second;
	}
	return NULL;
}

int ClientMgr::GetClientLogic(int nSessionID)
{
	Client* poClient = GetClientBySession(nSessionID);
	if (poClient == NULL)
	{
		return 0;
	}
	return poClient->m_nLogicService;
}

void ClientMgr::Update(int64_t nNowMS)
{
	int nTimeNow = (int)time(0);
	if (m_nLastUpdateTime == nTimeNow)
	{
		return;
	}
	m_nLastUpdateTime = nTimeNow;

	ClientIter iter = m_oClientSessionMap.begin();
	for (iter; iter != m_oClientSessionMap.end(); iter++)
	{
		iter->second->Update(nNowMS);
	}
}
