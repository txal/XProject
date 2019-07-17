#include "Server/GlobalServer/GlobalServer.h"
#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketWriter.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/MGHttp/HttpLua.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/ServerContext.h"

extern ServerContext* gpoContext;

GlobalServer::GlobalServer()
{
	m_uListenPort = 0;
	m_poExterNet = NULL;
	m_poInnerNet = NULL;
	memset(m_sListenIP, 0, sizeof(m_sListenIP));
	m_oMsgBalancer.SetEventHandler(&m_oNetEventHandler);
}

GlobalServer::~GlobalServer()
{
	m_oMonitorThread.Join();

	if (m_poExterNet != NULL)
	{
		m_poExterNet->Release();
	}
	if (m_poInnerNet != NULL)
	{
		m_poInnerNet->Release();
	}
}

bool GlobalServer::Init(int8_t nServiceID, const char* psListenIP, uint16_t uListenPort)
{
	char sServiceName[32];
	sprintf(sServiceName, "GlobalServer:%d", nServiceID);
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
	m_poExterNet = INet::CreateNet(NET_TYPE_EXTERNAL, nServiceID, 32, &m_oNetEventHandler);
	if (m_poExterNet == NULL)
	{
		return false;
	}

	m_poInnerNet = INet::CreateNet(NET_TYPE_INTERNAL, nServiceID, 8, &m_oNetEventHandler);
	if (m_poInnerNet == NULL)
	{
		return false;
	}
	return m_oMonitorThread.Create(GlobalServer::DeadLoopMonitorFunc, this, false);
}

bool GlobalServer::RegToRouter(int nRouterServiceID)
{
	ROUTER* poRouter = gpoContext->GetRouterMgr()->GetRouterByServiceID(nRouterServiceID);
	assert(poRouter != NULL);
	Packet* poPacket = Packet::Create(nPACKET_DEFAULT_SIZE, nPACKET_OFFSET_SIZE, __FILE__, __LINE__);
	if (poPacket == NULL)
	{
		return false;
	}

	PacketWriter oPW(poPacket);
	oPW << (int)Service::SERVICE_GLOBAL;

	INNER_HEADER oHeader(NSSysCmd::ssRegServiceReq, gpoContext->GetServerConfig().GetServerID(), GetServiceID(), 0, nRouterServiceID, 0);
	poPacket->AppendInnerHeader(oHeader, NULL, 0);
	if (!m_poInnerNet->SendPacket(poRouter->nSession, poPacket))
	{
		poPacket->Release(__FILE__, __LINE__);
		return false;
	}
	return true;
}

bool GlobalServer::Start()
{
	if (m_uListenPort > 0)
	{
		if (!m_poExterNet->Listen(NULL, m_uListenPort))
		{
			return false;
		}
	}

	while (!IsTerminate())
	{
		ProcessNetEvent(10);
		int64_t nNowMS = XTime::MSTime();
		ProcessLoopCount(nNowMS);
		Service::Update(nNowMS);
		ProcessTimer(nNowMS);
		ProcessHttpMessage();
	}
	return true;
}

void GlobalServer::ProcessNetEvent(int64_t nWaitMSTime)
{
	NSNetEvent::EVENT oEvent;
	if (!m_oMsgBalancer.GetEvent(oEvent, (uint32_t)nWaitMSTime))
	{
		return;
	}
	switch (oEvent.uEventType)
	{
		case NSNetEvent::eEVT_ON_RECV:
		{
			NSNetEvent::EVENT_RECV& oRecv = oEvent.U.oRecv;
			if (oEvent.pNet == m_poExterNet)
			{
				OnExterNetMsg(oRecv.nSessionID, oRecv.poPacket);
			}
			else if (oEvent.pNet == m_poInnerNet)
			{
				OnInnerNetMsg(oRecv.nSessionID, oRecv.poPacket);
			}
			break;
		}
		case NSNetEvent::eEVT_ON_ACCEPT:
		{
			if (oEvent.pNet == m_poExterNet)
			{
				OnExterNetAccept(oEvent.U.oAccept.nSessionID);
			}
			break;
		}
		case NSNetEvent::eEVT_ON_CLOSE:
		{
			if (oEvent.pNet == m_poExterNet)
			{
				OnExterNetClose(oEvent.U.oClose.nSessionID);
			}
			else if (oEvent.pNet == m_poInnerNet)
			{
				OnInnerNetClose(oEvent.U.oClose.nSessionID);
			}
			break;
		}
		case NSNetEvent::eEVT_ON_LISTEN:
		{
			break;
		}
		case NSNetEvent::eEVT_ON_CONNECT:
		{
			if (oEvent.pNet == m_poInnerNet)
			{
				OnInnerNetConnect(oEvent.U.oConnect.nSessionID, oEvent.U.oConnect.uRemoteIP, oEvent.U.oConnect.uRemotePort);
			}
			break;
		}
		default:
		{
			XLog(LEVEL_ERROR, "Msg type error:%d\n", oEvent.uEventType);
			break;
		}
	}
}

void GlobalServer::ProcessTimer(int64_t nNowMSTime)
{
	static int64_t nLastMSTime = XTime::MSTime();
	if (nNowMSTime - nLastMSTime < 100)
	{
		return;
	}
	nLastMSTime = nNowMSTime;
	TimerMgr::Instance()->ExecuteTimer(nNowMSTime);
}

void GlobalServer::ProcessLoopCount(int64_t nNowMSTime)
{
	static int64_t nLastMSTime = nNowMSTime;
	if (nNowMSTime - nLastMSTime >= 1000)
	{
		nLastMSTime = nNowMSTime;
		m_uMainLoopCount++;
	}
}

void GlobalServer::OnExterNetAccept(int nSessionID)
{
	//XLog(LEVEL_INFO, "On externet accept\n");
}

void GlobalServer::OnExterNetClose(int nSessionID)
{
	//XLog(LEVEL_INFO, "On externet close\n");
	m_oMsgBalancer.RemoveConn(0, GetServiceID(), nSessionID);
}

void GlobalServer::OnExterNetMsg(int nSessionID, Packet* poPacket)
{
	EXTER_HEADER oExterHeader;
	if (!poPacket->GetExterHeader(oExterHeader, true))
	{
		poPacket->Release(__FILE__, __LINE__);
		XLog(LEVEL_ERROR, "%s: OnExterNetMsg: packet get exter header fail\n", GetServiceName());
		return;
	}
	//m_poExterNet->SetSentClose(nSessionID);
	gpoContext->GetPacketHandler()->OnRecvExterPacket(nSessionID, poPacket, oExterHeader);
}


void GlobalServer::OnInnerNetConnect(int nSessionID, uint32_t uRemoteIP, uint16_t nRemotePort)
{
    ROUTER* poRouter = gpoContext->GetRouterMgr()->OnConnectRouterSuccess(nRemotePort, nSessionID);
    assert(poRouter != NULL);
    RegToRouter(poRouter->nService);
}

void GlobalServer::OnInnerNetClose(int nSessionID)
{
	XLog(LEVEL_INFO, "On innernet disconnect\n");
	gpoContext->GetRouterMgr()->OnRouterDisconnected(nSessionID);
	m_oMsgBalancer.RemoveConn(0, 0, nSessionID);
}

void GlobalServer::OnInnerNetMsg(int nSessionID, Packet* poPacket)
{
	assert(poPacket != NULL);
	INNER_HEADER oHeader;
	int* pSessionArray = NULL;
	if (!poPacket->GetInnerHeader(oHeader, &pSessionArray, true))
	{
		XLog(LEVEL_INFO, "%s: Get inner header fail\n", GetServiceName());
		poPacket->Release(__FILE__, __LINE__);
		return;
	}
	if (oHeader.uTarServer != gpoContext->GetServerConfig().GetServerID() || oHeader.nTarService != GetServiceID())
	{
		XLog(LEVEL_INFO, "%s: Tar server:%d service:%d error\n", GetServiceName(), oHeader.uTarServer, oHeader.nTarService);
		poPacket->Release(__FILE__, __LINE__);
		return;
	}
	gpoContext->GetPacketHandler()->OnRecvInnerPacket(nSessionID, poPacket, oHeader, pSessionArray);
}

void GlobalServer::DeadLoopMonitorFunc(void* pParam)
{
	GlobalServer* poService = (GlobalServer*)pParam;

	uint32_t uLastMainLoops = 0;
	uint32_t uNowMainLoops = 0;
	uint32_t nTimeCount = 0;
	while (!poService->IsTerminate())
	{
		XTime::MSSleep(1000);
		if (++nTimeCount < 30)
		{
			continue;
		}
		nTimeCount = 0;
		uNowMainLoops = poService->GetMainLoopCount();
		if (uNowMainLoops == uLastMainLoops && !LuaWrapper::Instance()->IsBreaking())
		{
			XLog(LEVEL_ERROR, "May endless loop!!!\n");
			LuaWrapper::Instance()->SetEndlessLoop(1);
		}
		uLastMainLoops = uNowMainLoops;
	}
}
