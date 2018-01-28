#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"
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
		poPacket->Release();
	} 
	else
	{
		NetAdapter::SERVICE_NAVI oNavi;
		oNavi.uSrcServer = g_poContext->GetServerID();
		oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
		oNavi.nTarSession = nSrcSessionID;

		//确定目标服务
		if (oHeader.nTarService == 0)
		{
			oNavi.nTarService = poGateway->GetClientMgr()->GetClientLogicService(nSrcSessionID);
			if (oNavi.nTarService <= 0) //没有目标服务，随机1个本服的LogicServer
			{
				oNavi.nTarService = g_poContext->GetRandomLogic();
			}
			if (oNavi.nTarService <= 0)
			{
				poPacket->Release();
				XLog(LEVEL_ERROR, "%s: Player logic server error\n", poGateway->GetServiceName());
				return;
			}
		}

		//确定目标服务器(1-100:本服; 101-127:世界)
		if (oNavi.nTarService <= 100)
			oNavi.uTarServer = g_poContext->GetServerID();
		else
			oNavi.uTarServer = g_poContext->GetWorldServerID();

		if (!NetAdapter::SendInner(oHeader.uCmd, poPacket, oNavi))
		{
			XLog(LEVEL_ERROR, "%s: Send packet to router fail\n", poGateway->GetServiceName());
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
		poPacket->Release();
	}
	else
	{
		Forward(nSrcSessionID, poPacket, oHeader, pSessionArray);
	}
}

void GatewayPacketHandler::Forward(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
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
				poPacket->Release();
			}
		}
		else
		{
			poPacket->Retain();
			if (!pExterNet->SendPacket(m_oSessionCache[i], poPacket))
			{
				poPacket->Release();
			}
		}
	}
}
