#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Include/Network/Network.hpp"
#include "Include/Logger/Logger.hpp"

#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/ServerContext.h"

extern ServerContext* g_poContext;
extern void StartScriptEngine();

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = (PacketHandler*)g_poContext->GetPacketHandler();
	// 内部消息
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaRpcMsg, (void*)OnLuaRpcMsg);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceRet, (void*)OnRegisterRouterCallback);
}

///////////////////////////内部处理函数/////////////////////////////////
void NSPacketProc::OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	g_poContext->GetRouterMgr()->OnRegisterRouterSuccess(oHeader.nSrc);
}

void NSPacketProc::OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_pushinteger(pState, oHeader.nSrc);
	lua_pushinteger(pState, oHeader.uSessions > 0 ? pSessionArray[0] : 0);
	lua_pushlightuserdata(pState, poPacket);
	poLuaWrapper->CallLuaRef("RpcMessageCenter", 3, 0);
}