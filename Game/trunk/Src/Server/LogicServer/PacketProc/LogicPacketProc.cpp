#include "Server/LogicServer/PacketProc/LogicPacketProc.h"
#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketReader.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/LogicServer.h"

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = g_poContext->GetPacketHandler();
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaRpcMsg, (void*)OnLuaRpcMsg);
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaCmdMsg, (void*)OnLuaCmdMsg);

	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceRet, (void*)OnRegisterRouterCallback);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssServiceClose, (void*)OnServiceClose);
	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssClientClose, (void*)OnClientClose);

	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cPlayerRun, (void*)OnPlayerRun);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cPlayerStopRun, (void*)OnPlayerStopRun);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::ppActorStartAttack, (void*)OnActorStartAttack);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::ppActorStopAttack, (void*)OnActorStopAttack);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cActorHurted, (void*)OnActorHurted);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cActorDamage, (void*)OnActorDamage);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cEveHurted, (void*)OnEveHurted);
}

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
	poLuaWrapper->CallLuaRef("RpcMessageCenter", 3);
}

void NSPacketProc::OnLuaCmdMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_pushinteger(pState, oHeader.uCmd);
	lua_pushinteger(pState, oHeader.nSrc);
	lua_pushinteger(pState, oHeader.uSessions > 0 ? pSessionArray[0] : 0);
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
		poLuaWrapper->CallLuaRef("CmdMessageCenter", 4);
	}
	else
	{
		XLog(LEVEL_ERROR, "Cmd:%d invalid!!!\n", oHeader.uCmd);
	}
}

void NSPacketProc::OnClientClose(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	((LogicServer*)g_poContext->GetService())->ClientCloseHandler(oHeader.uSessions > 0 ? pSessionArray[0] : 0);
}

void NSPacketProc::OnServiceClose(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	PacketReader oPacketReader(poPacket);
	int nService = 0;
	oPacketReader >> nService;
	LuaWrapper::Instance()->FastCallLuaRef<void>("OnServiceClose", 0, "i", nService);
}

void NSPacketProc::OnPlayerRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->PlayerRunHandler(poPacket);
}

void NSPacketProc::OnPlayerStopRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->PlayerStopRunHandler(poPacket);
}

void NSPacketProc::OnActorStartAttack(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->PlayerStartAttackHandler(poPacket);
}

void NSPacketProc::OnActorStopAttack(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->PlayerStopAttackHandler(poPacket);
}

void NSPacketProc::OnActorHurted(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->PlayerHurtedHandler(poPacket);
}

void NSPacketProc::OnActorDamage(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->PlayerDamageHandler(poPacket);
}

void NSPacketProc::OnEveHurted(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessions > 0 ? pSessionArray[0] : 0;
	Player* poPlayer = ((LogicServer*)g_poContext->GetService())->GetPlayerMgr()->GetPlayerBySession(nSession);
	if (poPlayer == NULL)
	{
		return;
	}
	poPlayer->EveHurtedHandler(poPacket);
}