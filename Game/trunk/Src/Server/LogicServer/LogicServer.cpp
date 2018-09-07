#include "Server/LogicServer/LogicServer.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/ServerContext.h"

PacketReader g_oPKReader;
PacketWriter g_oPKWriter;
Packet* g_poPacketCache;
Array<int> g_oSessionCache;
bool g_bPrintBattle = false;

LogicServer::LogicServer()
{
	m_uInPackets = 0;
	m_uOutPackets = 0;
	m_oMsgBalancer.SetEventHandler(&m_oNetEventHandler);
	g_poPacketCache = Packet::Create();
	g_oPKWriter.SetPacket(g_poPacketCache);
}

LogicServer::~LogicServer()
{
	if (g_poPacketCache != NULL)
	{
		g_poPacketCache->Release();
	}
}

bool LogicServer::Init(int8_t nServiceID)
{
	char sServiceName[32];
	sprintf(sServiceName, "LogicServer:%d", nServiceID);
	m_oNetEventHandler.GetMailBox().SetName(sServiceName);

	if (!Service::Init(nServiceID, sServiceName))
	{
		return false;
	}

	// Init network
	m_pInnerNet = INet::CreateNet(NET_TYPE_INTERNAL, nServiceID, 1024, &m_oNetEventHandler);
	if (m_pInnerNet == NULL)
	{
		return false;
	}
	return true;
}

bool LogicServer::RegToRouter(int8_t nRouterServiceID)
{
	ROUTER* poRouter = g_poContext->GetRouterMgr()->GetRouter(nRouterServiceID);
	if (poRouter == NULL)
	{
		return false;
	}
	Packet* poPacket = Packet::Create();
	if (poPacket == NULL) {
		return false;
	}
	INNER_HEADER oHeader(NSSysCmd::ssRegServiceReq, 0, GetServiceID(), g_poContext->GetServerID(), poRouter->nService, 0);
	poPacket->AppendInnerHeader(oHeader, NULL, 0);
	if (!m_pInnerNet->SendPacket(poRouter->nSession, poPacket))
	{
		poPacket->Release();
		return false;
	}
	XLog(LEVEL_INFO, "RegToRouter %d\n", nRouterServiceID);
	return true;
}

bool LogicServer::Start()
{
	int64_t nNowMS = 0;
	for (;;)
	{
		ProcessNetEvent(1);
		nNowMS = XTime::MSTime();
		ProcessTimer(nNowMS);
	    m_oSceneMgr.UpdateScenes(nNowMS);
	    m_oPlayerMgr.UpdatePlayers(nNowMS);
	    m_oMonsterMgr.UpdateMonsters(nNowMS);
		m_oRobotMgr.UpdateRobots(nNowMS);
		m_oDropItemMgr.UpdateDropItems(nNowMS);
	}
	return true;
}

void LogicServer::ProcessNetEvent(int64_t nWaitMSTime)
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
			OnRevcMsg(oEvent.U.oRecv.nSessionID, oEvent.U.oRecv.poPacket);
			break;
		}
		case NSNetEvent::eEVT_ON_CONNECT:
		{
			OnConnected(oEvent.U.oConnect.nSessionID, oEvent.U.oConnect.uRemoteIP, oEvent.U.oConnect.uRemotePort);
			break;
		}
		case NSNetEvent::eEVT_ON_CLOSE:
		{
			OnDisconnect(oEvent.U.oClose.nSessionID);
			break;
		}
		case NSNetEvent::eEVT_ON_LISTEN:
		case NSNetEvent::eEVT_ON_ACCEPT:
		{
			XLog(LEVEL_ERROR, "Msg type invalid:%d\n", oEvent.uEventType);
			break;
		}
	}
}

void LogicServer::ProcessTimer(int64_t nNowMSTime)
{
	static int64_t nLastMSTime = XTime::MSTime();
	if (nNowMSTime - nLastMSTime < 10)
	{
		return;
	}
	nLastMSTime = nNowMSTime;
	TimerMgr::Instance()->ExecuteTimer(nNowMSTime);
}

void LogicServer::OnConnected(int nSessionID, int nRemoteIP, uint16_t nRemotePort)
{
	ROUTER* poRouter = g_poContext->GetRouterMgr()->OnConnectRouterSuccess(nRemotePort, nSessionID);
	assert(poRouter != NULL);
    RegToRouter(poRouter->nService);
}

void LogicServer::OnDisconnect(int nSessionID)
{
	XLog(LEVEL_INFO, "%s: On connection disconnect\n", GetServiceName());
	g_poContext->GetRouterMgr()->OnRouterDisconnected(nSessionID);
}

void LogicServer::OnRevcMsg(int nSessionID, Packet* poPacket) 
{
	assert(poPacket != NULL);
	m_uInPackets++;

	INNER_HEADER oHeader;
	int* pSessionArray = NULL;
	if (!poPacket->GetInnerHeader(oHeader, &pSessionArray, true))
	{
		XLog(LEVEL_ERROR, "%s: Packet get fail\n", GetServiceName());
		poPacket->Release();
		return;
	}
	if (oHeader.nTarService != GetServiceID())
	{
		XLog(LEVEL_ERROR, "%s: Packet target error\n", GetServiceName());
		poPacket->Release();
		return;
	}
	g_poContext->GetPacketHandler()->OnRecvInnerPacket(nSessionID, poPacket, oHeader, pSessionArray);
}

void LogicServer::ClientCloseHandler(int nSession)
{
	m_oMsgBalancer.RemoveConn(nSession);
	LuaWrapper::Instance()->FastCallLuaRef<void>("OnClientClose", 0, "i", nSession);
}