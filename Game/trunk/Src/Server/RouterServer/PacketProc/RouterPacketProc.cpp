#include "Server/RouterServer/PacketProc/RouterPacketProc.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/ServerContext.h"
#include "Server/RouterServer/Router.h"

extern ServerContext* gpoContext;

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = gpoContext->GetPacketHandler();
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceReq, (void*)OnRegisterService);
}


void NSPacketProc::OnRegisterService(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSesseionArray)
{
	Service* poService = gpoContext->GetService();
	if (oHeader.nTarService != poService->GetServiceID())
	{
		return;
	}
	Router* poRouter = (Router*)poService;
	if (poRouter->RegService(oHeader.uTarServer, oHeader.nSrcService, nSrcSessionID))
	{
		ServiceNode* poTarService = poRouter->GetService(oHeader.uTarServer, oHeader.nSrcService);
		if (poTarService == NULL)
		{
			return;
		}
		Packet* poPacketRet = Packet::Create();
		if (poPacketRet == NULL) {
			return;
		}

		INNER_HEADER oHeaderRet(NSSysCmd::ssRegServiceRet, 0, poService->GetServiceID(), oHeader.uTarServer, oHeader.nSrcService, 0);
		poPacketRet->AppendInnerHeader(oHeaderRet, NULL, 0);
		if (!poTarService->GetInnerNet()->SendPacket(poTarService->GetSessionID(), poPacketRet))
		{
			poPacketRet->Release();
			XLog(LEVEL_ERROR, "Send packet fail\n");
		}
	}
}
