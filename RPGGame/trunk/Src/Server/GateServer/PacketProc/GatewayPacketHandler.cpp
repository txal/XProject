#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/Gateway.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

extern ServerContext* g_poContext;

GatewayPacketHandler::GatewayPacketHandler()
{
	
}

void GatewayPacketHandler::OnRecvExterPacket(int nSrcSessionID, Packet *poPacket, EXTER_HEADER& oHeader)
{
	Gateway* poGateway = (Gateway*)g_poContext->GetService();
	if (oHeader.nTar == poGateway->GetServiceID() || oHeader.uCmd == NSCltSrvCmd::ppKeepAlive)
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
		//Send to logic server
		if (oHeader.nTar == 0)
		{
			oHeader.nTar = poGateway->GetClientMgr()->GetClientLogicService(nSrcSessionID);
			if (oHeader.nTar <= 0)
			{
				oHeader.nTar = g_poContext->GetRandomLogic();
			}
			if (oHeader.nTar <= 0)
			{
				XLog(LEVEL_ERROR, "%s: Player logic server error\n", poGateway->GetServiceName());
				poPacket->Release();
				return;
			}
		}
		if (!NetAdapter::SendInner(oHeader.uCmd, poPacket, oHeader.nTar, nSrcSessionID))
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
	super::CacheSessionArray(pSessionArray, oHeader.uSessions);
	Service* poService = g_poContext->GetService();
	INet* pExterNet = poService->GetExterNet();

	EXTER_HEADER oExterHeader;
	oExterHeader.uCmd = oHeader.uCmd;
	oExterHeader.nSrc = poService->GetServiceID();
	oExterHeader.nTar = 0;
	poPacket->AppendExterHeader(oExterHeader);
	for (int i = oHeader.uSessions - 1; i >= 0; --i)
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
