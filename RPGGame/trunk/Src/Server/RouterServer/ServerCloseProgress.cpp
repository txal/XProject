#include "Server/RouterServer/ServerCloseProgress.h"

#include "Include/Script/Script.hpp"
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
	if (m_oServerList.size() > 0)
	{
		XLog(LEVEL_ERROR, "Close server routine is working server:%d!\n", m_oServerList.back());
		return;
	}
	XLog(LEVEL_INFO, "Closing server:%d\n", nServerID);

	Router* poRouter = (Router*)g_poContext->GetService();
	if (nServerID == g_poContext->GetWorldServerID())
	{
		int tServerList[MAX_SERVICE_NUM];
		int nNum = poRouter->GetServerList(tServerList, MAX_SERVICE_NUM);
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

void ServerCloseProgress::BroadcastPrepServerClose(ServiceNode** tServiceList, int nNum, int nTarServer, int nTarService)
{
	Router* poRouter = (Router*)g_poContext->GetService();
	for (int i = 0; i < nNum; i++)
	{
		Packet* poPacket = Packet::Create();
		if (poPacket == NULL)
			return;

		PacketWriter oPW(poPacket);
		ServiceNode* poService = tServiceList[i];
		if (nTarServer > 0 || nTarService > 0)
			oPW << nTarServer << nTarService;
		else
			oPW << poService->GetServerID() << poService->GetServiceID();

		INNER_HEADER oHeader(NSSysCmd::ssPrepCloseServer, g_poContext->GetWorldServerID(), poRouter->GetServiceID(), poService->GetServerID(), poService->GetServiceID(), 0);
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
	ServiceNode* tServiceList[MAX_SERVICE_NUM];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, MAX_SERVICE_NUM, Service::SERVICE_GATE);
	if (nNum <= 0)
		CloseLogin();
	else
		BroadcastPrepServerClose(tServiceList, nNum);
}

void ServerCloseProgress::CloseLogin()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[MAX_SERVICE_NUM];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, MAX_SERVICE_NUM, Service::SERVICE_LOGIN);
	if (nNum <= 0)
		CloseLogic();
	else
		BroadcastPrepServerClose(tServiceList, nNum);
}

void ServerCloseProgress::CloseLogic()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[MAX_SERVICE_NUM];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, MAX_SERVICE_NUM, Service::SERVICE_LOGIC);
	if (nNum <= 0)
	{
		CloseGlobal();
	}
	else
	{
		
		BroadcastPrepServerClose(tServiceList, nNum);

		if (nServerID != g_poContext->GetWorldServerID())
		{
			ServiceNode* tServiceListW[MAX_SERVICE_NUM];
			int nNumW = poRouter->GetServiceListByServer(g_poContext->GetWorldServerID(), tServiceListW, MAX_SERVICE_NUM, Service::SERVICE_LOGIC);
			for (int i = 0; i < nNum; i++)
			{
				ServiceNode* poService = tServiceList[i];
				BroadcastPrepServerClose(tServiceListW, nNumW, poService->GetServerID(), poService->GetServiceID());
			}
		}
	}
}

void ServerCloseProgress::CloseGlobal()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[MAX_SERVICE_NUM];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, MAX_SERVICE_NUM, Service::SERVICE_GLOBAL);
	if (nNum <= 0)
		CloseLog();
	else
		BroadcastPrepServerClose(tServiceList, nNum);
}

void ServerCloseProgress::CloseLog()
{
	Router* poRouter = (Router*)g_poContext->GetService();
	ServiceNode* tServiceList[MAX_SERVICE_NUM];
	int nServerID = m_oServerList.front();
	int nNum = poRouter->GetServiceListByServer(nServerID, tServiceList, MAX_SERVICE_NUM, Service::SERVICE_LOG);
	if (nNum <= 0)
		OnCloseServerFinish(nServerID);
	else
		BroadcastPrepServerClose(tServiceList, nNum);
}

void ServerCloseProgress::OnCloseServerFinish(int nServerID)
{
	Router* poRouter = (Router*)g_poContext->GetService();

	m_oServerList.pop_front();
	if (m_oServerList.size() <= 0)
	{
		if (poRouter->GetServiceNum() <= 0)
		{
			poRouter->Terminate();
			return;
		}
	}

	StartRoutine();
}

void ServerCloseProgress::OnServiceClose(int nServerID, int nServiceID, int nServiceType)
{
	bool bNormalClose = false;
	for (std::list<int>::iterator iter = m_oServerList.begin(); iter != m_oServerList.end(); iter++)
	{
		if (*iter == nServerID)
		{
			bNormalClose = true;
			break;
		}
	}
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	//poLuaWrapper->FastCallLuaRef<void>("OnServiceClose", 0, "iiib", nServerID, nServiceID, nServiceType, bNormalClose);

	StartRoutine();
}
