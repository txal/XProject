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
	Service* poService = g_poContext->GetService();
	if (oHeader.nTar != poService->GetServiceID())
	{
		return;
	}
	Router* poRouter = (Router*)poService;
	if (poRouter->RegService(oHeader.uServer, oHeader.nSrc, nSrcSessionID))
	{
		ServiceNode* poTarService = poRouter->GetService(oHeader.uServer, oHeader.nSrc);
		if (poTarService == NULL)
		{
			return;
		}
		Packet* poPacketRet = Packet::Create();
		if (poPacketRet == NULL) {
			return;
		}

		INNER_HEADER oHeaderRet(NSSysCmd::ssRegServiceRet, poService->GetServiceID(), oHeader.nSrc, 0, oHeader.uServer);
		poPacketRet->AppendInnerHeader(oHeaderRet, NULL, 0);
		if (!poTarService->GetInnerNet()->SendPacket(poTarService->GetSessionID(), poPacketRet))
		{
			poPacketRet->Release();
			XLog(LEVEL_ERROR, "Send packet fail\n");
		}
	}
}
