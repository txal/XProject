#include "Server/RouterServer/PacketProc/RouterPacketProc.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/ServerContext.h"
#include "Server/RouterServer/Router.h"

extern ServerContext* g_poContext;

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = g_poContext->GetPacketHandler();
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceReq, (void*)OnRegisterService);
}


void NSPacketProc::OnRegisterService(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSesseionArray)
{
	Router* poRouter = (Router*)(g_poContext->GetService());
	if (oHeader.nTarService != poRouter->GetServiceID())
	{
		return;
	}
	if (poRouter->RegService(oHeader.uSrcServer, oHeader.nSrcService, nSrcSessionID))
	{
		ServiceNode* poTarService = poRouter->GetService(oHeader.uSrcServer, oHeader.nSrcService);
		if (poTarService == NULL)
		{
			return;
		}
		Packet* poPacketRet = Packet::Create();
		if (poPacketRet == NULL)
		{
			return;
		}

		//注意路由本身不属于任何服,所以源服务器赋值为目标服务器
		INNER_HEADER oHeaderRet(NSSysCmd::ssRegServiceRet, oHeader.uSrcServer, poRouter->GetServiceID(), oHeader.uSrcServer, oHeader.nSrcService, 0);
		poPacketRet->AppendInnerHeader(oHeaderRet, NULL, 0);
		INet* pNet = poRouter->GetNetPool()->GetNet(poTarService->GetNetIndex());
		if (!pNet->SendPacket(poTarService->GetSessionID(), poPacketRet))
		{
			poPacketRet->Release();
			XLog(LEVEL_ERROR, "Send packet fail\n");
		}
	}
}
