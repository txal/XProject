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
	
CLIENT* ClientMgr::CreateClient(int nClientID, uint32_t uRemoteIP)
{
	if (GetClient(nClientID) != NULL)
	{
		XLog(LEVEL_ERROR, "CreateClient: key duplicated!\n");
		return NULL;
	}
	CLIENT* poClient = XNEW(CLIENT);
	poClient->uRemoteIP = uRemoteIP;
	m_oClientMap[nClientID] = poClient;
	return poClient;
}

void ClientMgr::RemoveClient(int nClientID)
{
	ClientIter iter = m_oClientMap.find(nClientID);
	if (iter != m_oClientMap.end())
	{
		SAFE_DELETE(iter->second);
		m_oClientMap.erase(iter);
	}
}

CLIENT* ClientMgr::GetClient(int nClientID)
{
	ClientIter iter = m_oClientMap.find(nClientID);
	if (iter != m_oClientMap.end())
	{
		return iter->second;
	}
	return NULL;
}

int ClientMgr::GetClientLogicService(int nClientID)
{
	CLIENT* poClient = GetClient(nClientID);
	if (poClient == NULL)
	{
		return 0;
	}
	return poClient->nLogicService;
}
