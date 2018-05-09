#include "Server/GateServer/ClientMgr/ClientMgr.h"
#include "Include/Logger/Logger.hpp"
	
ClientMgr::ClientMgr()
{
	m_nLastUpdateTime = 0;
}

ClientMgr::~ClientMgr()
{
	ClientIter iter = m_oClientRoleIDMap.begin();
	ClientIter iter_end = m_oClientRoleIDMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
	m_oClientRoleIDMap.clear();
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
	poClient->m_uRemoteIP = uRemoteIP;
	poClient->m_nSession = nSessionID;
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

		if (m_oClientRoleIDMap.find(poClient->m_nRoleID) == m_oClientRoleIDMap.end())
		{
			SAFE_DELETE(poClient);
		}
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

Client* ClientMgr::GetClientByRoleID(int nRoleID)
{
	ClientIter iter = m_oClientRoleIDMap.find(nRoleID);
	if (iter != m_oClientRoleIDMap.end())
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

void ClientMgr::AddRoleIDMap(int nRoleID, Client* poClient)
{
	ClientIter iter = m_oClientRoleIDMap.find(nRoleID);
	if (iter != m_oClientRoleIDMap.end())
	{
		if (GetClientBySession(iter->second->m_nSession) == NULL)
		{
			SAFE_DELETE(iter->second);
		}
		else
		{
			XLog(LEVEL_ERROR, "AddRoleIDMap------session:%d\n", iter->second->m_nSession);
		}
		m_oClientRoleIDMap.erase(iter);
	}
	m_oClientRoleIDMap[nRoleID] = poClient; 
}

void ClientMgr::OnRoleRelease(int nRoleID)
{
	ClientIter iter = m_oClientRoleIDMap.find(nRoleID);
	if (iter != m_oClientRoleIDMap.end())
	{
		SAFE_DELETE(iter->second);
		m_oClientRoleIDMap.erase(iter);
	}
}

void ClientMgr::Update(int64_t nNowMS)
{
	int nTimeNow = (int)time(0);
	if (m_nLastUpdateTime == nTimeNow)
		return;
	m_nLastUpdateTime = nTimeNow;

	ClientIter iter = m_oClientRoleIDMap.begin();
	for (iter; iter != m_oClientRoleIDMap.end(); iter++)
	{
		iter->second->Update(nNowMS);
	}
}
