#include "Server/RouterServer/PacketProc/RouterPacketProc.h"
#include "Common/PacketParser/PacketReader.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/ServerContext.h"
#include "Server/RouterServer/Router.h"

extern ServerContext* g_poContext;

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = g_poContext->GetPacketHandler();
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceReq, (void*)OnRegisterService);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssCloseServerReq, (void*)OnCloseServerReq);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssPrepCloseServer, (void*)OnPrepCloseServer);
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaRpcMsg, (void*)OnLuaRpcMsg);
}


void NSPacketProc::OnRegisterService(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSesseionArray)
{
	Router* poRouter = (Router*)(g_poContext->GetService());
	if (oHeader.nTarService != poRouter->GetServiceID())
		return;

	PacketReader oPR(poPacket);
	int nServiceType = 0;
	oPR >> nServiceType;

	if (poRouter->RegService(oHeader.uSrcServer, oHeader.nSrcService, nSrcSessionID, nServiceType))
	{
		ServiceNode* poTarService = poRouter->GetService(oHeader.uSrcServer, oHeader.nSrcService);
		if (poTarService == NULL)
			return;
	
		Packet* poPacketRet = Packet::Create();
		if (poPacketRet == NULL)
			return;

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

void NSPacketProc::OnCloseServerReq(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSesseionArray)
{
	PacketReader oPR(poPacket);
	int nServerID = 0;
	oPR >> nServerID;
	Router* poRouter = (Router*)(g_poContext->GetService());
	poRouter->GetServerClose().CloseServer(nServerID);
}

//收到这个消息,表明服务准备好关服了
void NSPacketProc::OnPrepCloseServer(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	Router* poRouter = (Router*)(g_poContext->GetService());

	ServiceNode* poTarService = poRouter->GetService(oHeader.uSrcServer, oHeader.nSrcService);
	if (poTarService == NULL)
		return;

	Packet* poPacketRet = Packet::Create();
	if (poPacketRet == NULL)
		return;

	PacketWriter oPW(poPacketRet);
	oPW << (int)oHeader.uSrcServer << (int)oHeader.nSrcService;

	INNER_HEADER oHeaderRet(NSSysCmd::ssImplCloseServer, g_poContext->GetWorldServerID(), poRouter->GetServiceID(), oHeader.uSrcServer, oHeader.nSrcService, 0);
	poPacketRet->AppendInnerHeader(oHeaderRet, NULL, 0);

	INet* pNet = poRouter->GetNetPool()->GetNet(poTarService->GetNetIndex());
	if (!pNet->SendPacket(poTarService->GetSessionID(), poPacketRet))
		poPacketRet->Release();
}

void NSPacketProc::OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_pushinteger(pState, oHeader.uSrcServer);
	lua_pushinteger(pState, oHeader.nSrcService);
	lua_pushinteger(pState, oHeader.uSessionNum > 0 ? pSessionArray[0] : 0);
	lua_pushlightuserdata(pState, poPacket);
	poLuaWrapper->CallLuaRef("RpcMessageCenter", 4, 0);
}