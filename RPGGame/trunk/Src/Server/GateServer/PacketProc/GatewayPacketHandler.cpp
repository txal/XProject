#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/Gateway.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

GatewayPacketHandler::GatewayPacketHandler()
{
	
}

void GatewayPacketHandler::OnRecvExterPacket(int nSrcSessionID, Packet *poPacket, EXTER_HEADER& oHeader)
{
	Gateway* poGateway = (Gateway*)g_poContext->GetService();
	if (oHeader.nTarService == poGateway->GetServiceID() || oHeader.uCmd == NSCltSrvCmd::ppKeepAlive)
	{
		PacketProcIter iter = m_poExterPacketProcMap->find(oHeader.uCmd);
		if (iter != m_poExterPacketProcMap->end())
		{
			(*(ExterPacketProc)(iter->second->pProc))(nSrcSessionID, poPacket, oHeader);
		}
		else
		{
			XLog(LEVEL_ERROR, "CMD:%d proc not found\n", oHeader.uCmd);
		}
		poPacket->Release(__FILE__, __LINE__);
	} 
	else
	{
		NetAdapter::SERVICE_NAVI oNavi;
		oNavi.uSrcServer = g_poContext->GetServerID();
		oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
		oNavi.uTarServer = g_poContext->GetServerID();
		oNavi.nTarService = oHeader.nTarService;
		oNavi.nTarSession = nSrcSessionID;

		//确定目标服务
		if (oNavi.nTarService == 0)
		{
			oNavi.nTarService = poGateway->GetClientMgr()->GetClientLogic(nSrcSessionID);
			if (oNavi.nTarService <= 0) //没有目标服务，选1个本服的LogicServer
			{
				oNavi.nTarService = g_poContext->SelectLogic(nSrcSessionID);
				XLog(LEVEL_INFO, "%s: cmd:%d use random logic service:%d\n", poGateway->GetServiceName(), oHeader.uCmd, oNavi.nTarService);
			}
			if (oNavi.nTarService <= 0)
			{
				poPacket->Release(__FILE__, __LINE__);
				XLog(LEVEL_ERROR, "%s: role logic service error\n", poGateway->GetServiceName());
				return;
			}
		}

		if (!NetAdapter::SendInner(oHeader.uCmd, poPacket, oNavi))
		{
			XLog(LEVEL_ERROR, "%s: send packet to router fail\n", poGateway->GetServiceName());
		}
	}
}

void GatewayPacketHandler::OnRecvInnerPacket(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	if ((oHeader.uCmd >= NSSysCmd::eCMD_BEGIN && oHeader.uCmd < NSSysCmd::eCMD_END)
		|| (oHeader.uCmd >= NSSrvSrvCmd::eCMD_BEGIN && oHeader.uCmd < NSSrvSrvCmd::eCMD_END))
	{
		PacketProcIter iter = m_poInnerPacketProcMap->find(oHeader.uCmd);
		if (iter != m_poInnerPacketProcMap->end())
		{
			(*(InnerPacketProc)(iter->second->pProc))(nSrcSessionID, poPacket, oHeader, pSessionArray);
		}
		else
		{
			XLog(LEVEL_ERROR, "CMD:%d proc not found\n", oHeader.uCmd);
		}
		poPacket->Release(__FILE__, __LINE__);
	}
	else
	{
		Forward(nSrcSessionID, poPacket, oHeader, pSessionArray);
	}
}

void GatewayPacketHandler::Forward(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	if (poPacket->GetDataSize() >= 4 * 1024)
	{
		XLog(LEVEL_WARNING, "Large parcket cmd:%d size:%d\n", oHeader.uCmd, poPacket->GetDataSize());
	}

	//fix pd
	if (oHeader.uCmd == 1025)
	{
		XLog(LEVEL_INFO, "router-gate mstime:%lld\n", XTime::UnixMSTime());
	}

	super::CacheSessionArray(pSessionArray, oHeader.uSessionNum);
	Service* poService = g_poContext->GetService();
	INet* pExterNet = poService->GetExterNet();

	EXTER_HEADER oExterHeader;
	oExterHeader.uCmd = oHeader.uCmd;
	oExterHeader.nSrcService = poService->GetServiceID();
	oExterHeader.nTarService = 0;
	poPacket->AppendExterHeader(oExterHeader);
	for (int i = oHeader.uSessionNum - 1; i >= 0; --i)
	{
		if (i == 0)
		{
			if (!pExterNet->SendPacket(m_oSessionCache[i], poPacket))
			{
				poPacket->Release(__FILE__, __LINE__);
			}
		}
		else
		{
			poPacket->Retain();
			if (!pExterNet->SendPacket(m_oSessionCache[i], poPacket))
			{
				poPacket->Release(__FILE__, __LINE__);
			}
		}
	}
}
