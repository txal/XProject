#include "Server/LoginServer/LoginServer.h"
#include "Include/Network/Network.hpp"

#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Common/DataStruct/XMath.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/ServerContext.h"

extern ServerContext* g_poContext;

LoginServer::LoginServer()
{
	m_poInnerNet = NULL;
}

LoginServer::~LoginServer()
{
}

bool LoginServer::Init(int8_t nServiceID)
{
	char sServiceName[32];
	sprintf(sServiceName, "LoginServer:%d", nServiceID);
	m_oNetEventHandler.GetMailBox().SetName(sServiceName);

	if (!Service::Init(nServiceID, sServiceName))
	{
		return false;
	}
	m_poInnerNet = INet::CreateNet(NET_TYPE_INTERNAL, nServiceID, 1024, &m_oNetEventHandler);
	if (m_poInnerNet == NULL)
	{
		return false;
	}
	return true;
}

bool LoginServer::RegToRouter(int nRouterServiceID)
{
	ROUTER* poRouter = g_poContext->GetRouterMgr()->GetRouter(nRouterServiceID);
	assert(poRouter != NULL);
	Packet* poPacket = Packet::Create();

	PacketWriter oPW(poPacket);
	oPW << (int)Service::SERVICE_LOGIN;

	INNER_HEADER oHeader(NSSysCmd::ssRegServiceReq, g_poContext->GetServerID(), GetServiceID(), 0, nRouterServiceID, 0);
	poPacket->AppendInnerHeader(oHeader, NULL, 0);
	if (!m_poInnerNet->SendPacket(poRouter->nSession, poPacket))
	{
		poPacket->Release();
		return false;
	}
	return true;
}

bool LoginServer::Start()
{
	while(!IsTerminate())
	{
		ProcessNetEvent(10);
		int64_t nNowMS = XTime::MSTime();
		ProcessTimer(nNowMS);
	}
	return true;
}

void LoginServer::ProcessNetEvent(int64_t nWaitMSTime)
{
	NSNetEvent::EVENT oEvent;
	if (!m_oNetEventHandler.RecvEvent(oEvent, (uint32_t)nWaitMSTime))
	{
		return;
	}
	switch (oEvent.uEventType)
	{
		case NSNetEvent::eEVT_ON_RECV:
		{
			NSNetEvent::EVENT_RECV& oRecv = oEvent.U.oRecv;
			if (oEvent.pNet == m_poInnerNet)
			{
				OnInnerNetMsg(oRecv.nSessionID, oRecv.poPacket);
			}
			break;
		}
		case NSNetEvent::eEVT_ON_ACCEPT:
		{
			break;
		}
		case NSNetEvent::eEVT_ON_CLOSE:
		{
			if (oEvent.pNet == m_poInnerNet)
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

void LoginServer::ProcessTimer(int64_t nNowMSTime)
{
	static int64_t nLastMSTime = XTime::MSTime();
	if (nNowMSTime - nLastMSTime < 1000)
	{
		return;
	}
	nLastMSTime = nNowMSTime;
	TimerMgr::Instance()->ExecuteTimer(nNowMSTime);
}

void LoginServer::OnInnerNetConnect(int nSessionID, int nRemoteIP, uint16_t nRemotePort)
{
    ROUTER* poRouter = g_poContext->GetRouterMgr()->OnConnectRouterSuccess(nRemotePort, nSessionID);
    assert(poRouter != NULL);
    RegToRouter(poRouter->nService);
}

void LoginServer::OnInnerNetClose(int nSessionID)
{
	XLog(LEVEL_INFO, "On innernet disconnect\n");
	g_poContext->GetRouterMgr()->OnRouterDisconnected(nSessionID);
}

void LoginServer::OnInnerNetMsg(int nSessionID, Packet* poPacket)
{
	assert(poPacket != NULL);
	INNER_HEADER oHeader;
	int* pSessionArray = NULL;
	if (!poPacket->GetInnerHeader(oHeader, &pSessionArray, true))
	{
		XLog(LEVEL_INFO, "%s: Get inner header fail\n", GetServiceName());
		poPacket->Release();
		return;
	}
	if (oHeader.uTarServer != g_poContext->GetServerID() || oHeader.nTarService != GetServiceID())
	{
		XLog(LEVEL_INFO, "%s: Tar server:%d service:%d error\n", GetServiceName(), oHeader.uTarServer, oHeader.nTarService);
		poPacket->Release();
		return;
	}
	g_poContext->GetPacketHandler()->OnRecvInnerPacket(nSessionID, poPacket, oHeader, pSessionArray);
}
