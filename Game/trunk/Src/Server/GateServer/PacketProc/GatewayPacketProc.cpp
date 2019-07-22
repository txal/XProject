#include "Server/GateServer/PacketProc/GatewayPacketProc.h"
#include "Include/Network/Network.hpp"
#include "Include/Logger/Logger.hpp"

#include "Common/PacketParser/PacketReader.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/Gateway.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"
#include "Server/GateServer/ClientMgr/ClientMgr.h"

extern ServerContext* gpoContext;

void NSPacketProc::RegisterPacketProc()
{
	GatewayPacketHandler* poPacketHandler = (GatewayPacketHandler*)gpoContext->GetPacketHandler();
	//外部消息
	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::ppPing, (void*)OnPing);
	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::ppKeepAlive, (void*)OnKeepAlive);

	// 内部消息
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceRet, (void*)OnRegisterRouterCallback);
	poPacketHandler->RegsterInnerPacketProc(NSSrvSrvCmd::ssSyncLogicService, (void*)OnSyncLogicService);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssKickClient, (void*)OnKickClient);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssBroadcastGate, (void*)OnBroadcastGate);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssClientIPReq, (void*)OnClientIPReq);
}

///////////////////////////////外部处理函数///////////////////////////////////
void NSPacketProc::OnPing(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	assert(poPacket != NULL);
	Packet* poPacketRet = Packet::Create();
	if (poPacketRet == NULL) {
		return;
	}
	EXTER_HEADER oExtHeader;
	oExtHeader.uCmd = NSCltSrvCmd::ppPing;
	poPacketRet->AppendExterHeader(oExtHeader);
	//poPacketRet->FillData((uint8_t*)"+PONG\r\n", 7); 
	if (!gpoContext->GetService()->GetExterNet()->SendPacket(nSrcSessionID, poPacketRet))
	{
		poPacketRet->Release();
	}
}

void NSPacketProc::OnKeepAlive(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	assert(poPacket != NULL);
	Packet* poPacketRet = Packet::Create();
	if (poPacketRet == NULL) {
		return;
	}
	int nTimeNow = (int)time(0);
	poPacketRet->WriteBuf(&nTimeNow, sizeof(nTimeNow));
	poPacketRet->AppendExterHeader(EXTER_HEADER(NSCltSrvCmd::ppKeepAlive, gpoContext->GetService()->GetServiceID(), 0));
	if (!gpoContext->GetService()->GetExterNet()->SendPacket(nSrcSessionID, poPacketRet))
	{
		poPacketRet->Release();
	}
}

/////////////////////////内部处理函数/////////////////////////////////////
void NSPacketProc::OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	gpoContext->GetRouterMgr()->OnRegisterRouterSuccess(oHeader.nSrcService);

}

void NSPacketProc::OnSyncLogicService(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession =oHeader.uSessionNum> 0 ? pSessionArray[0] : 0;
	Gateway* poGateway = (Gateway*)gpoContext->GetService();
	CLIENT* poClient = poGateway->GetClientMgr()->GetClient(nSession);	
	if (poClient == NULL)
	{
		XLog(LEVEL_INFO, "OnSyncLogicService: client already offline\n");
		return;
	}
	PacketReader oReader(poPacket);
	int nLogicService = 0;
	oReader >> nLogicService;
	poClient->nLogicService = nLogicService;
}

void NSPacketProc::OnKickClient(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession =oHeader.uSessionNum> 0 ? pSessionArray[0] : 0;
	if (nSession > 0)
	{
		Gateway* poGateway = (Gateway*)gpoContext->GetService();
		poGateway->GetExterNet()->Close(nSession);
	}
}

void NSPacketProc::OnClientIPReq(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession =oHeader.uSessionNum> 0 ? pSessionArray[0] : 0;
	if (nSession > 0)
	{
		Gateway* poGateway = (Gateway*)gpoContext->GetService();
		CLIENT* poClient = poGateway->GetClientMgr()->GetClient(nSession);	
		if (poClient == NULL)
		{
			XLog(LEVEL_INFO, "OnClientIPReq: client:%d not found!\n", nSession);
			return;
		}
		Packet* poPacket = Packet::Create(32);
		if (poPacket == NULL) {
			return;
		}
		poPacket->WriteBuf(&(poClient->uRemoteIP), sizeof(poClient->uRemoteIP));
		NetAdapter::SendInner(NSSysCmd::ssClientIPRet, poPacket, oHeader.nSrcService, nSession);
	}
}

void NSPacketProc::OnBroadcastGate(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	uint8_t* pData = poPacket->GetData();
	int nSize = poPacket->GetDataSize();
	if (nSize < nPACKET_OFFSET_SIZE + (int)sizeof(uint16_t))
	{
		return;
	}
	uint16_t uCmd = *(uint16_t*)(pData + nSize - sizeof(uint16_t));
	poPacket->CutData(sizeof(uint16_t));

	Gateway* poService = (Gateway*)gpoContext->GetService();
	INet* pExterNet = poService->GetExterNet();

	EXTER_HEADER oExterHeader(uCmd, poService->GetServiceID(), 0);
	poPacket->AppendExterHeader(oExterHeader);

	ClientMgr* poClientMgr = poService->GetClientMgr();
	ClientMgr::ClientIter iter = poClientMgr->GetClientIterBegin();
	ClientMgr::ClientIter iter_end = poClientMgr->GetClientIterEnd();
	for (int i = 0; iter != iter_end; iter++, i++)
	{
		poPacket->Retain(); //在这个函数处理完后会被释放,所以要Retain
		if (i == 0)
		{
			if (!pExterNet->SendPacket(iter->first, poPacket))
			{
				poPacket->Release();
			}
		}
		else
		{
			if (!pExterNet->SendPacket(iter->first, poPacket))
			{
				poPacket->Release();
			}
		}
	}
}