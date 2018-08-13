#include "Server/RouterServer/ServerCloseProgress.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "ServiceNode.h"
#include "Router.h"

ServerCloseProgress::ServerCloseProgress()
{
}
	
ServerCloseProgress::~ServerCloseProgress()
{
}

void ServerCloseProgress::CloseServer(int nServerID)
{
	XLog(LEVEL_INFO, "Closing server:%d\n", nServerID);

	Router* poRouter = (Router*)g_poContext->GetService();
	if (nServerID == g_poContext->GetWorldServerID())
	{
		int tServerList[128];
		int nNum = poRouter->GetServerList(tServerList, 128);
		for (int i = 0; i < nNum; i++)
			if (tServerList[i] != g_poContext->GetWorldServerID())
				m_oServerList.push_back(tServerList[i]);
		m_oServerList.push_back(nServerID);
	}
	else
	{
		m_oServerList.push_back(nServerID);
	}
	StartRoutine();
}

void ServerCloseProgress::BroadcastServerClose(ServiceNode** tServiceList, int nNum, int nTarServer, int nTarService)
{
	Router* poRouter = (Router*)g_poContext->GetService();
	for (int i = 0; i < nNum; i++)
	{
		Packet* poPacket = Packet::Create();
		if (poPacket == NULL)
			return;
		ServiceNode* poService = tServiceList[i];
		PacketWriter oPW(poPacket);
		if (nTarServer > 0 || nTarService > 0)
			oPW << nTarServer << nTarService;
		else
			oPW << poService->GetServerID() << poService->GetServiceID();

		INNER_HEADER oHeader(NSSysCmd::ssCloseServer, g_poContext->GetWorldServerID(), poRouter->GetServiceID(), poService->GetServerID(), poService->GetServiceID(), 0);
		poPacket->AppendInnerHeader(oHeader, NULL, 0);
		INet* pNet = poRouter->GetNetPool()->GetNet(poService->GetNetIndex());
		if (!pNet->SendPacket(poService->GetSessionID(), poPacket))
			poPacket->Release();
	}
}

void ServerCloseProgress::StartRoutine()
{
	if (m_oServerList.size() <= 0)
		return;
	CloseGate();
}

void ServerCloseProgress::CloseGate()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[128];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, 128, Service::SERVICE_GATE);
	if (nNum <= 0)
		CloseLogin();
	else
		BroadcastServerClose(tServiceList, nNum);
}

void ServerCloseProgress::CloseLogin()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[128];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, 128, Service::SERVICE_LOGIN);
	if (nNum <= 0)
		CloseLogic();
	else
		BroadcastServerClose(tServiceList, nNum);
}

void ServerCloseProgress::CloseLogic()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[128];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, 128, Service::SERVICE_LOGIC);
	if (nNum <= 0)
	{
		CloseGlobal();
	}
	else
	{
		
		BroadcastServerClose(tServiceList, nNum);

		if (nServerID != g_poContext->GetWorldServerID())
		{
			ServiceNode* tServiceListW[128];
			int nNumW = poRouter->GetServiceListByServer(g_poContext->GetWorldServerID(), tServiceListW, 128, Service::SERVICE_LOGIC);
			for (int i = 0; i < nNum; i++)
			{
				ServiceNode* poService = tServiceList[i];
				BroadcastServerClose(tServiceListW, nNum, poService->GetServerID(), poService->GetServiceID());
			}
		}
	}
}

void ServerCloseProgress::CloseGlobal()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[128];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, 128, Service::SERVICE_GLOBAL);
	if (nNum <= 0)
		CloseLog();
	else
		BroadcastServerClose(tServiceList, nNum);
}

void ServerCloseProgress::CloseLog()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[128];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, 128, Service::SERVICE_LOG);
	if (nNum <= 0)
		OnCloseServerFinish(nServerID);
	else
		BroadcastServerClose(tServiceList, nNum);
}

void ServerCloseProgress::OnCloseServerFinish(int nServerID)
{
	m_oServerList.pop_front();
	if (m_oServerList.size() <= 0)
		return;
	StartRoutine();
}

void ServerCloseProgress::OnServiceClose()
{
	StartRoutine();
}
