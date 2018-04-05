#include "RobotPacketProc.h"
#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketReader.h"
#include "RobotClient/RobotMgr.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/ServerContext.h"

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = g_poContext->GetPacketHandler();
	poPacketHandler->RegsterExterPacketProc(NSMsgType::eLuaRpcMsg, (void*)OnLuaRpcMsg);
	poPacketHandler->RegsterExterPacketProc(NSMsgType::eLuaCmdMsg, (void*)OnLuaCmdMsg);

	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::sSyncActorPosRet, (void*)OnSyncActorPos);
	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::sActorStartRunRet, (void*)OnBroadcastActorStartRun);
	poPacketHandler->RegsterExterPacketProc(NSCltSrvCmd::sActorStopRunRet, (void*)OnBroadcastActorStopRun);
}

void NSPacketProc::OnLuaRpcMsg(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_pushinteger(pState, 0);
	lua_pushinteger(pState, oHeader.nSrcService);
	lua_pushinteger(pState, nSrcSessionID);
	lua_pushlightuserdata(pState, poPacket);
	poLuaWrapper->CallLuaRef("RpcMessageCenter", 4, 0);
}

void NSPacketProc::OnLuaCmdMsg(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_pushinteger(pState, oHeader.uCmd);
	lua_pushinteger(pState, 0);
	lua_pushinteger(pState, oHeader.nSrcService);
	lua_pushinteger(pState, nSrcSessionID);
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
		poLuaWrapper->CallLuaRef("CmdMessageCenter", 5, 0);
	}
	else
	{
		XLog(LEVEL_ERROR, "Cmd:%d invalid!!!\n", oHeader.uCmd);
	}
}

void NSPacketProc::OnSyncActorPos(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{
	Robot* poRobot = ((RobotMgr*)g_poContext->GetService())->GetRobot(nSrcSessionID);
	if (poRobot == NULL)
	{
		return;
	}
	poRobot->OnSyncActorPosHandler(poPacket);
}

void NSPacketProc::OnBroadcastActorStartRun(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{

}

void NSPacketProc::OnBroadcastActorStopRun(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader)
{

}

