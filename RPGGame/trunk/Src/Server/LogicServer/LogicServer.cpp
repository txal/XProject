#include "Server/LogicServer/LogicServer.h"

#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"

PacketReader goPKReader;
PacketWriter goPKWriter;
Packet* gpoPacketCache;
Array<NetAdapter::SERVICE_NAVI> goNaviCache;

BattleLog goBattleLog;

LogicServer::LogicServer()
{
	m_uInPackets = 0;
	m_uOutPackets = 0;
	m_oMsgBalancer.SetEventHandler(&m_oNetEventHandler);
	gpoPacketCache = Packet::Create();
	goPKWriter.SetPacket(gpoPacketCache);
}

LogicServer::~LogicServer()
{
	if (gpoPacketCache != NULL)
	{
		gpoPacketCache->Release();
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

	PacketWriter oPW(poPacket);
	oPW << (int)Service::SERVICE_LOGIC;

	INNER_HEADER oHeader(NSSysCmd::ssRegServiceReq, g_poContext->GetServerID(), GetServiceID(), 0, poRouter->nService, 0);
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
	while (!IsTerminate())
	{
		ProcessNetEvent(1);
		nNowMS = XTime::MSTime();
		ProcessTimer(nNowMS);
		ProcessLoopCount(nNowMS);
	    m_oSceneMgr.Update(nNowMS);
	    m_oRoleMgr.Update(nNowMS);
	    m_oMonsterMgr.Update(nNowMS);
		
		//m_oRobotMgr.Update(nNowMS);
		//m_oDropItemMgr.Update(nNowMS);
	}
	return true;
}

void LogicServer::ProcessNetEvent(int64_t nWaitMSTime)
{
	NSNetEvent::EVENT oEvent;
	if (!m_oMsgBalancer.GetEvent(oEvent, (uint32_t)nWaitMSTime))
	//if (!m_oNetEventHandler.RecvEvent(oEvent, nWaitMSTime))
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

void LogicServer::ProcessLoopCount(int64_t nNowMSTime)
{
	static int64_t nLastMSTime = nNowMSTime;
	if (nNowMSTime - nLastMSTime >= 1000)
	{
		nLastMSTime = nNowMSTime;
		m_uMainLoopCount++;
	}
}

void LogicServer::OnConnected(int nSessionID, int nRemoteIP, uint16_t nRemotePort)
{
	char sIPBuf[128] = { 0 };
	XLog(LEVEL_INFO, "%s: On connectioned session:%d ip:%s\n", GetServiceName(), nSessionID, NetAPI::N2P(nRemoteIP, sIPBuf, sizeof(sIPBuf)));
	ROUTER* poRouter = g_poContext->GetRouterMgr()->OnConnectRouterSuccess(nRemotePort, nSessionID);
	assert(poRouter != NULL);
    RegToRouter(poRouter->nService);
}

void LogicServer::OnDisconnect(int nSessionID)
{
	XLog(LEVEL_INFO, "%s: On disconnect session:%d\n", GetServiceName(), nSessionID);
	g_poContext->GetRouterMgr()->OnRouterDisconnected(nSessionID);
	m_oMsgBalancer.RemoveConn(0, 0, nSessionID);
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
	if (oHeader.uTarServer != g_poContext->GetServerID() || oHeader.nTarService != GetServiceID())
	{
		XLog(LEVEL_INFO, "%s: Tar server:%d service:%d error\n", GetServiceName(), oHeader.uTarServer, oHeader.nTarService);
		poPacket->Release();
		return;
	}
	g_poContext->GetPacketHandler()->OnRecvInnerPacket(nSessionID, poPacket, oHeader, pSessionArray);
}

void LogicServer::OnClientClose(uint16_t uServer, int8_t nService, int nSession)
{
	m_oMsgBalancer.RemoveConn(uServer, nService, nSession);
}
