#include "Server/RouterServer/PacketProc/RouterPacketHanderl.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/ServerContext.h"
#include "Server/RouterServer/Router.h"

RouterPacketHandler::RouterPacketHandler()
{

}

void RouterPacketHandler::OnRecvInnerPacket(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	Service* poService = g_poContext->GetService();
	if (oHeader.nTarService == poService->GetServiceID())
	{
		poPacket->RemoveInnerHeader();
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
		Forward(nSrcSessionID, poPacket, oHeader);
	}
}

void RouterPacketHandler::Forward(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader)
{
	//目标服务器ID特殊处理(1-100:本服; 101-127:世界)
	if (oHeader.nTarService > 100)
	{
		oHeader.uTarServer = g_poContext->GetWorldServerID();
		assert(oHeader.uTarServer >= 10000);
	}

	Router* poService = (Router*)g_poContext->GetService();
	ServiceNode* poTarService = poService->GetService(oHeader.uTarServer, oHeader.nTarService);
	if (poTarService == NULL)
	{
		poPacket->Release();
		XLog(LEVEL_ERROR, "Target server:%d service:%d not found\n", oHeader.uTarServer, oHeader.nTarService);
		return;
	}
	if (!poTarService->GetInnerNet()->SendPacket(poTarService->GetSessionID(), poPacket))
	{
		poPacket->Release();
		XLog(LEVEL_ERROR, "Send packet to server:%d service:%d fail\n", oHeader.uTarServer, oHeader.nTarService);
	}
}
