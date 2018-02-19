#include "Server/GateServer/Gateway.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Include/Network/Network.hpp"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

extern ServerContext* g_poContext;

Gateway::Gateway()
{
	m_uListenPort = 0;
	m_poExterNet = NULL;
	m_poInnerNet = NULL;

	m_uInPackets = 0;
	m_uOutPackets = 0;
	m_bDebugNetwork = false;
}

Gateway::~Gateway()
{
}

bool Gateway::Init(GateNode* poConf)
{
	char sServiceName[32];
	sprintf(sServiceName, "Gateway:%d", poConf->uID);
	m_oNetEventHandler.GetMailBox().SetName(sServiceName);

	if (!Service::Init((int8_t)poConf->uID, sServiceName))
	{
		return false;
	}
	m_uListenPort = poConf->uPort;
	m_poExterNet = INet::CreateNet(NET_TYPE_WEBSOCKET, poConf->uID, poConf->uMaxConns, &m_oNetEventHandler
		, poConf->uSecureCPM, poConf->uSecureQPM, poConf->uSecureBlock, poConf->uDeadLinkTime);
	if (m_poExterNet == NULL)
	{
		return false;
	}
	m_poInnerNet = INet::CreateNet(NET_TYPE_INTERNAL, poConf->uID, 1024, &m_oNetEventHandler);
	if (m_poInnerNet == NULL)
	{
		return false;
	}
	if (Platform::FileExist("network.txt"))
	{
		m_bDebugNetwork = true;
	}
	return true;
}

bool Gateway::RegToRouter(int nRouterServiceID)
{
	ROUTER* poRouter = g_poContext->GetRouterMgr()->GetRouter(nRouterServiceID);
	assert(poRouter != NULL);
	Packet* poPacket = Packet::Create();
	if (poPacket == NULL) 
	{
		return false;
	}
	INNER_HEADER oHeader(NSSysCmd::ssRegServiceReq, g_poContext->GetServerID(), GetServiceID(), 0, nRouterServiceID, 0);
	poPacket->AppendInnerHeader(oHeader, NULL, 0);
	if (!m_poInnerNet->SendPacket(poRouter->nSession, poPacket))
	{
		poPacket->Release();
		return false;
	}
	return true;
}

bool Gateway::Start()
{
	if (!m_poExterNet->Listen(NULL, m_uListenPort))
	{
		return false;
	}

	for (;;)
	{
		ProcessNetEvent(10);
		int64_t nNowMSTime = XTime::MSTime();
		ProcessTimer(nNowMSTime);
	}
	return true;
}

void Gateway::ProcessNetEvent(int64_t nWaitMSTime)
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
											   OnExterNetAccept(oEvent.U.oAccept.nSessionID, oEvent.U.oAccept.uRemoteIP);
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

void Gateway::ProcessTimer(int64_t nNowMSTime)
{
	static int64_t nLastMSTime = XTime::MSTime();
	if (nNowMSTime - nLastMSTime < 1000)
	{
		return;
	}
	nLastMSTime = nNowMSTime;
	TimerMgr::Instance()->ExecuteTimer(nNowMSTime);
}

void Gateway::OnExterNetAccept(int nSessionID, uint32_t uRemoteIP)
{
	m_oClientMgr.CreateClient(nSessionID, uRemoteIP);
}

void Gateway::OnExterNetClose(int nSessionID)
{
	CLIENT* poClient = m_oClientMgr.GetClient(nSessionID);
	if (poClient == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Client:%d not found\n", GetServiceName(), nSessionID);
		return;
	}
	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = g_poContext->GetServerID();
	oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
	oNavi.uTarServer = g_poContext->GetServerID();
	oNavi.nTarService = (int8_t)g_poContext->GetServerConfig().oLoginList[0].uID;
	oNavi.nTarSession = nSessionID;

	m_oClientMgr.RemoveClient(nSessionID);
	Packet* poPacket = Packet::Create();
	if (poPacket == NULL)
	{
		return;
	}
	if (!NetAdapter::SendInner(NSSysCmd::ssClientClose, poPacket, oNavi))
	{
		XLog(LEVEL_ERROR, "%s: Send packet back fail\n", GetServiceName());
	}
}

void Gateway::DecodeMask(Packet* poPacket)
{
	if (!poPacket->IsMasking())
	{
		return;
	}
	uint8_t* tMaskingKey = poPacket->GetMaskingKey();
	uint8_t* pRealData = poPacket->GetRealData();
	int nSize = poPacket->GetRealDataSize();
	for (int i = 0; i < nSize; i++)
	{
		int j = i % 4;
		pRealData[i] = pRealData[i] ^ tMaskingKey[j];
	}
}

void Gateway::OnExterNetMsg(int nSessionID, Packet* poPacket)
{
	m_uInPackets++;
	CLIENT* poClient = m_oClientMgr.GetClient(nSessionID);
	if (poClient == NULL)
	{
		poPacket->Release();
		XLog(LEVEL_ERROR, "%s: OnExterNetMsg: client:%d not found\n", GetServiceName(), nSessionID);
		return;
	}
	//Websocket masking decode
	DecodeMask(poPacket);
	EXTER_HEADER oExterHeader;
	if (!poPacket->GetExterHeader(oExterHeader, true))
	{
		poPacket->Release();
		GetExterNet()->Close(nSessionID);
		XLog(LEVEL_ERROR, "%s: OnExterNetMsg: packet get exter header fail\n", GetServiceName());
		return;
	}
	if (m_bDebugNetwork) {
		int nDataSize = poPacket->GetDataSize();
		XLog(LEVEL_INFO, "%s, OnExterNetMsg: cmd:%d size:%d target:%d \n", GetServiceName(), oExterHeader.uCmd, nDataSize, oExterHeader.nTarService);
	}

	//重放攻击检测
	if (oExterHeader.uPacketIdx <= poClient->uCmdIndex)
	{
		poPacket->Release();
		GetExterNet()->Close(nSessionID);
		XLog(LEVEL_ERROR, "%s: OnExterNetMsg: packet cmd index error(%d,%d)\n", GetServiceName(), oExterHeader.uPacketIdx, poClient->uCmdIndex);
		return;
	}
	poClient->uCmdIndex = oExterHeader.uPacketIdx;

	// Short connection
	if (oExterHeader.nSrcService == -1)
	{
		m_poExterNet->SetSentClose(nSessionID);
	}
	GatewayPacketHandler* pPacketHandler = (GatewayPacketHandler*)g_poContext->GetPacketHandler();
	pPacketHandler->OnRecvExterPacket(nSessionID, poPacket, oExterHeader);
}

void Gateway::OnInnerNetAccept(int nListenPort, int nSessionID)
{
	XLog(LEVEL_INFO, "On innernet accept\n");
}

void Gateway::OnInnerNetConnect(int nSessionID, int nRemoteIP, uint16_t nRemotePort)
{
    ROUTER* poRouter = g_poContext->GetRouterMgr()->OnConnectRouterSuccess(nRemotePort, nSessionID);
    assert(poRouter != NULL);
    RegToRouter(poRouter->nService);
}

void Gateway::OnInnerNetClose(int nSessionID)
{
	XLog(LEVEL_INFO, "On innernet disconnect\n");
	g_poContext->GetRouterMgr()->OnRouterDisconnected(nSessionID);
}

void Gateway::OnInnerNetMsg(int nSessionID, Packet* poPacket)
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
	if (m_bDebugNetwork) {
		int nDataSize = poPacket->GetDataSize();
		XLog(LEVEL_INFO, "%s, OnExterNetMsg: cmd:%d size:%d target:%d \n", GetServiceName(), oHeader.uCmd, nDataSize, oHeader.nTarService);
	}
	g_poContext->GetPacketHandler()->OnRecvInnerPacket(nSessionID, poPacket, oHeader, pSessionArray);
}
