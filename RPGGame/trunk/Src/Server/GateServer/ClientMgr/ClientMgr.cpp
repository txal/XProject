#include "Server/GateServer/ClientMgr/ClientMgr.h"
#include "Include/Logger/Logger.hpp"
	
ClientMgr::ClientMgr()
{

}

ClientMgr::~ClientMgr()
{
	ClientIter iter = m_oClientMap.begin();
	ClientIter iter_end = m_oClientMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
}
	
CLIENT* ClientMgr::CreateClient(int nSessionID, uint32_t uRemoteIP)
{
	if (GetClient(nSessionID) != NULL)
	{
		XLog(LEVEL_ERROR, "CreateClient: key duplicated!\n");
		return NULL;
	}
	CLIENT* poClient = XNEW(CLIENT);
	poClient->uRemoteIP = uRemoteIP;
	m_oClientMap[nSessionID] = poClient;
	return poClient;
}

void ClientMgr::RemoveClient(int nSessionID)
{
	ClientIter iter = m_oClientMap.find(nSessionID);
	if (iter != m_oClientMap.end())
	{
		SAFE_DELETE(iter->second);
		m_oClientMap.erase(iter);
	}
}

CLIENT* ClientMgr::GetClient(int nSessionID)
{
	ClientIter iter = m_oClientMap.find(nSessionID);
	if (iter != m_oClientMap.end())
	{
		return iter->second;
	}
	return NULL;
}

int ClientMgr::GetClientLogicService(int nSessionID)
{
	CLIENT* poClient = GetClient(nSessionID);
	if (poClient == NULL)
	{
		return 0;
	}
	return poClient->nLogicService;
}
