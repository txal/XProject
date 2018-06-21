#include "Server/RouterServer/Router.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/ServerContext.h"

Router::Router()
{
	m_sListenIP[0] = 0;
	m_nListenSession = 0;
	m_uListenPort = 0;
	m_poListener = NULL;
}

Router::~Router()
{
	m_poListener->Release();
	ServiceIter iter = m_oServiceMap.begin();
	ServiceIter iter_end = m_oServiceMap.end();
	for (; iter != iter_end; iter++)
	{
        SAFE_DELETE(iter->second);
	}
}

bool Router::Init(int nServiceID, const char* psListenIP, uint16_t uListenPort)
{
	char sServiceName[32];
	sprintf(sServiceName, "Router:%d", nServiceID);
	m_oNetEventHandler.GetMailBox().SetName(sServiceName);

	if (!Service::Init(nServiceID, sServiceName))
	{
		return false;
	}
	if (psListenIP != NULL)
	{
		strcpy(m_sListenIP, psListenIP);
	}
	m_uListenPort = uListenPort;
	m_poListener = INet::CreateNet(NET_TYPE_INTERNAL, nServiceID, 1024, &m_oNetEventHandler);
	if (m_poListener == NULL)
	{
		return false;
	}
	return true;
}

bool Router::Start()
{
	if (!m_poListener->Listen(m_sListenIP[0]?m_sListenIP:NULL, m_uListenPort, true))
	{
		return false;
	}

	for (;;)
	{
        ProcessNetEvent(1);
	}
	return true;
}

void Router::ProcessNetEvent(int nWaitMSTime)
{
    NSNetEvent::EVENT oEvent;
    if (!m_oNetEventHandler.RecvEvent(oEvent, nWaitMSTime))
    {
        return;
    }
    switch (oEvent.uEventType)
    {
        case NSNetEvent::eEVT_ON_RECV:
        {
            OnRouterMsg(oEvent.U.oRecv.nSessionID, oEvent.U.oRecv.poPacket);
            break;
        }
        case NSNetEvent::eEVT_ON_ACCEPT:
        {
            OnRouterAccept(oEvent.U.oAccept.hSock, oEvent.U.oAccept.uRemoteIP, oEvent.U.oAccept.uRemotePort);
            break;
        }
        case NSNetEvent::eEVT_ON_CLOSE:
        {
            OnRouterDisconnect(oEvent.U.oClose.nSessionID);
            break;
        }
        case NSNetEvent::eEVT_ON_LISTEN:
        {
            break;
        }
        case NSNetEvent::eEVT_ADD_DATASOCK:
        {
            OnAddDataSock(oEvent.U.oDataSock.hSock, oEvent.U.oDataSock.nSessionID);
            break;
        }
        default:
        {
            XLog(LEVEL_ERROR, "Msg type error:%d\n", oEvent.uEventType);
            break;
        }
    }
}

void Router::OnRouterAccept(HSOCKET hSock, uint32_t uRemoteIP, uint16_t uRemotePort)
{
	SockIter iter = m_oSockMap.find(hSock);
	if (iter != m_oSockMap.end())
	{
		SAFE_DELETE(iter->second);
		m_oSockMap.erase(iter);
		XLog(LEVEL_ERROR, "OnRouterAccept: Socket:%d conflict\n", hSock);
	}

    ServiceNode* poService = XNEW(ServiceNode);
	if (!poService->Init(GetServiceID(), &m_oNetEventHandler))
	{
		SAFE_DELETE(poService);
		XLog(LEVEL_ERROR, "OnRouterAccept: Socket:%u init service node fail\n", hSock);
		return;
	}

	poService->GetInnerNet()->AddDataSock(hSock, uRemoteIP, uRemotePort);
	m_oSockMap[hSock] = poService;
	XLog(LEVEL_INFO, "OnRouterAccept: OnRouterAccept socket:%u \n", hSock);
}

void Router::OnRouterDisconnect(int nSessionID)
{
	SessionIter iter = m_oSessionMap.find(nSessionID);
	if (iter == m_oSessionMap.end())
	{
		XLog(LEVEL_ERROR, "OnRouterDisconnect: Session:%d not found on disconnect!\n", nSessionID);
		return;
	}
	ServiceNode* poService = iter->second;
	m_oSessionMap.erase(nSessionID);

    int nServerID = poService->GetServerID();
	int nServiceID = poService->GetServiceID();

	int nKey = ServiceNode::Key(nServerID, nServiceID);
	m_oServiceMap.erase(nKey);
    SAFE_DELETE(poService);

	//通知本地全服服务断开
	Packet* poPacket = Packet::Create();
	if (poPacket == NULL)
	{
		return;
	}
	PacketWriter oPacketWriter(poPacket);
	oPacketWriter<<nServerID<<nServiceID;
	BroadcastService(nServerID, poPacket);
	XLog(LEVEL_ERROR, "OnRouterDisconnect: server:%d service:%d disconnect\n", nServerID, nServiceID);
}

void Router::OnAddDataSock(HSOCKET hSock, int nSessionID)
{
	SockIter iter = m_oSockMap.find(hSock);
	if (iter == m_oSockMap.end())
	{
		XLog(LEVEL_ERROR, "OnAddDataSock: socket:%u service not found!\n", hSock);
		return;
	}
	if (m_oSessionMap.find(nSessionID) != m_oSessionMap.end())
	{
		XLog(LEVEL_ERROR, "OnAddDataSock: socket:%u session:%d conflict, ignore!\n", hSock, nSessionID);
		return;
	}
	iter->second->SetSocket(hSock);
	iter->second->SetSessionID(nSessionID);
	m_oSessionMap[nSessionID] = iter->second;
	m_oSockMap.erase(iter);
}

void Router::OnRouterMsg(int nSessionID, Packet* poPacket)
{
	INNER_HEADER oHeader;
	int* pSessionArray = NULL;
	if (!poPacket->GetInnerHeader(oHeader, &pSessionArray, false))
	{
		XLog(LEVEL_ERROR, "OnRouterMsg: Packet header invalid\n");
		poPacket->Release();
		return;
	}
	g_poContext->GetPacketHandler()->OnRecvInnerPacket(nSessionID, poPacket, oHeader, pSessionArray);
}

ServiceNode* Router::GetService(int nServerID, int nServiceID)
{
	int nKey = ServiceNode::Key(nServerID, nServiceID);
	ServiceIter iter = m_oServiceMap.find(nKey);
	if (iter != m_oServiceMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void Router::BroadcastService(int nServerID, Packet* poPacket)
{
	uint16_t nWorldServerID = g_poContext->GetWorldServerID();
	for (ServiceIter iter = m_oServiceMap.begin(); iter != m_oServiceMap.end(); iter++)
	{
		ServiceNode* poService = iter->second;
		if (poService->GetServerID() == nServerID || poService->GetServerID() == nWorldServerID)
		{
			int nTarServerID = poService->GetServerID();
			Packet* poNewPacket = poPacket->DeepCopy();
			//注意路由本身不属于任何服,所以源服务器赋值为目标服务器
			INNER_HEADER oHeader(NSSysCmd::ssServiceClose, nServerID, GetServiceID(), nTarServerID, poService->GetServiceID(), 0);
			poNewPacket->AppendInnerHeader(oHeader, NULL, 0);
			if (!poService->GetInnerNet()->SendPacket(poService->GetSessionID(), poNewPacket))
			{
				poNewPacket->Release();
			}
		}
	}
	poPacket->Release();

}

bool Router::RegService(int nServerID, int nServiceID, int nSessionID)
{
	SessionIter iter = m_oSessionMap.find(nSessionID);
	if (iter == m_oSessionMap.end())
	{
		XLog(LEVEL_ERROR, "RegService: server:%d service:%d session not found!\n", nServerID, nServiceID);
		return false;
	}
	ServiceNode* poService = iter->second;
	int nKey = ServiceNode::Key(nServerID, nServiceID);
	if (m_oServiceMap.find(nKey) != m_oServiceMap.end())
	{
		poService->GetInnerNet()->Close(nSessionID);
		XLog(LEVEL_ERROR, "RegService: server:%d service:%d already register!\n", nServerID, nServiceID);
		return false;
	}
	poService->SetServerID(nServerID);
	poService->SetServiceID(nServiceID);
	m_oServiceMap[nKey] = poService;
	XLog(LEVEL_INFO, "RegService: server:%d service:%d register successful\n", nServerID, nServiceID);
	return true;
}
