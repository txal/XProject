#include "Server/LoginServer/PacketProc/PacketProc.h"
#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"

#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/ServerContext.h"

extern void StartScriptEngine();
void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = (PacketHandler*)gpoContext->GetPacketHandler();
	// 内部消息
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaRpcMsg, (void*)OnLuaRpcMsg);
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaCmdMsg, (void*)OnLuaCmdMsgInner);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceRet, (void*)OnRegisterRouterCallback);
}

///////////////////////////内部处理函数/////////////////////////////////
void NSPacketProc::OnRegisterRouterCallback(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	gpoContext->GetRouterMgr()->OnRegisterRouterSuccess(oHeader.nSrcService);
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

void NSPacketProc::OnLuaCmdMsgInner(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_pushinteger(pState, oHeader.uCmd);
	lua_pushinteger(pState, oHeader.uSrcServer);
	lua_pushinteger(pState, oHeader.nSrcService);
	lua_pushinteger(pState, oHeader.uSessionNum > 0 ? pSessionArray[0] : 0);
	if (oHeader.uCmd >= CMD_MIN && oHeader.uCmd <= CMD_MAX)
	{
		if (oHeader.uCmd >= NSCltSrvPBCmd::eCMD_BEGIN && oHeader.uCmd <= NSCltSrvPBCmd::eCMD_END)
		{
			lua_pushlstring(pState, (char*)poPacket->GetRealData(), poPacket->GetRealDataSize());
		}
		else
		{
			lua_pushlightuserdata(pState, poPacket);
		}
		poLuaWrapper->CallLuaRef("CmdMessageCenter", 5);
	}
	else
	{
		XLog(LEVEL_ERROR, "Cmd:%d invalid!!!\n", oHeader.uCmd);
	}
}
