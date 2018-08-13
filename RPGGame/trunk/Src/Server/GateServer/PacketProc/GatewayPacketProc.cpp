#include "Server/GateServer/PacketProc/GatewayPacketProc.h"

#include "Include/Network/Network.hpp"
#include "Include/Logger/Logger.hpp"

#include "Common/PacketParser/PacketReader.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/ClientMgr/ClientMgr.h"
#include "Server/GateServer/Gateway.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

extern ServerContext* g_poContext;
void NSPacketProc::RegisterPacketProc()
{
	GatewayPacketHandler* poPacketHandler = (GatewayPacketHandler*)g_poContext->GetPacketHandler();
	//外部消息
	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::ppPing, (void*)OnPing);
	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::ppKeepAlive, (void*)OnKeepAlive);

	// 内部消息
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssKickClient, (void*)OnKickClient);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceRet, (void*)OnRegisterRouterCallback);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssCloseServer, (void*)OnCloseServer);
	poPacketHandler->RegsterInnerPacketProc(NSSrvSrvCmd::ssSyncLogicService, (void*)OnSyncRoleLogic);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssBroadcastGate, (void*)OnBroadcastGate);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssClientIPReq, (void*)OnClientIPReq);
}

///////////////////////////////外部处理函数///////////////////////////////////
void NSPacketProc::OnPing(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	assert(poPacket != NULL);
	Packet* poPacketRet = Packet::Create();
	if (poPacketRet == NULL) 
	{
		return;
	}
	
	poPacketRet->AppendExterHeader(EXTER_HEADER(NSCltSrvCmd::ppPing, g_poContext->GetService()->GetServiceID()));
	if (!g_poContext->GetService()->GetExterNet()->SendPacket(nSrcSessionID, poPacketRet))
	{
		poPacketRet->Release();
	}
}

void NSPacketProc::OnKeepAlive(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	assert(poPacket != NULL);
	Packet* poPacketRet = Packet::Create(32);
	if (poPacketRet == NULL)
	{
		return;
	}

	int nTimeNow = (int)time(0);
	poPacketRet->WriteBuf(&nTimeNow, sizeof(nTimeNow));
	poPacketRet->AppendExterHeader(EXTER_HEADER(NSCltSrvCmd::ppKeepAlive, g_poContext->GetService()->GetServiceID()));
	if (!g_poContext->GetService()->GetExterNet()->SendPacket(nSrcSessionID, poPacketRet))
	{
		poPacketRet->Release();
	}
}

/////////////////////////内部处理函数/////////////////////////////////////
void NSPacketProc::OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	g_poContext->GetRouterMgr()->OnRegisterRouterSuccess(oHeader.nSrcService);

}

void NSPacketProc::OnCloseServer(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	XLog(LEVEL_INFO, "Closing server======\n");
	g_poContext->GetService()->Terminate();

}

void NSPacketProc::OnSyncRoleLogic(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	Gateway* poGateway = (Gateway*)g_poContext->GetService();
	int nSession = oHeader.uSessionNum > 0 ? pSessionArray[0] : 0;

	PacketReader oReader(poPacket);
	int nRoleID = 0;
	int nRelease = 0;
	oReader >> nRoleID >> nRelease;


	ClientMgr* poClientMgr = poGateway->GetClientMgr();
	Client* poClientRoleID = poClientMgr->GetClientByRoleID(nRoleID);
	Client* poClientSession = poClientMgr->GetClientBySession(nSession);	

	XLog(LEVEL_DEBUG, "SyncRoleLogic: session:%d role:%d release:%d logic:%d clientsession:0x%x clientroleid:0x%x\n", nSession, nRoleID, nRelease, oHeader.nSrcService, poClientSession, poClientRoleID);

	if (poClientSession == NULL && poClientRoleID == NULL)
	{
		XLog(LEVEL_ERROR, "OnSyncRoleLogic: client roleid:%d session:%d not exist\n", nRoleID, nSession);
		return;
	}
	if (nRelease == 1) 
	{
		poClientMgr->OnRoleRelease(nRoleID);
		return;
	}
	if (poClientSession != NULL && poClientRoleID != NULL)
	{
		poClientSession->m_nRoleID = nRoleID;
		poClientSession->m_nLogicService = oHeader.nSrcService;
		if (poClientSession != poClientRoleID)
			poClientMgr->AddRoleIDMap(nRoleID, poClientSession);
		return;
	}
	if (poClientSession != NULL)
	{
		poClientSession->m_nRoleID = nRoleID;
		poClientSession->m_nLogicService = oHeader.nSrcService;
		poClientMgr->AddRoleIDMap(nRoleID, poClientSession);
		return;
	}
	if (poClientRoleID != NULL)
	{
		poClientRoleID->m_nRoleID = nRoleID;
		poClientRoleID->m_nLogicService = oHeader.nSrcService;
		return;
	}
}

void NSPacketProc::OnKickClient(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSessionID = oHeader.uSessionNum > 0 ? pSessionArray[0] : 0;
	if (nSessionID > 0)
	{
		Gateway* poGateway = (Gateway*)g_poContext->GetService();
		poGateway->GetExterNet()->Close(nSessionID);
	}
}

void NSPacketProc::OnClientIPReq(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSessionID = oHeader.uSessionNum > 0 ? pSessionArray[0] : 0;
	if (nSessionID > 0)
	{
		Gateway* poGateway = (Gateway*)g_poContext->GetService();
		Client* poClient = poGateway->GetClientMgr()->GetClientBySession(nSessionID);	
		if (poClient == NULL)
		{
			XLog(LEVEL_INFO, "OnClientIPReq: client:%d not found!\n", nSessionID);
			return;
		}
		Packet* poPacket = Packet::Create(32);
		if (poPacket == NULL)
		{
			return;
		}
		poPacket->WriteBuf(&(poClient->m_uRemoteIP), sizeof(poClient->m_uRemoteIP));
		uint16_t uSrcServer = g_poContext->GetServerID();
		int8_t nSrcService = g_poContext->GetService()->GetServiceID();
		NetAdapter::SERVICE_NAVI oNavi(uSrcServer, nSrcService, oHeader.uSrcServer, oHeader.nSrcService, nSessionID);
		NetAdapter::SendInner(NSSysCmd::ssClientIPRet, poPacket, oNavi);
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

	Gateway* poService = (Gateway*)g_poContext->GetService();
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
