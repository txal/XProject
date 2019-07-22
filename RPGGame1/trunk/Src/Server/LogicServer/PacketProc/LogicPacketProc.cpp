#include "Server/LogicServer/PacketProc/LogicPacketProc.h"
#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketReader.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/LogicServer.h"

void NSPacketProc::RegisterPacketProc()
{
	PacketHandler* poPacketHandler = gpoContext->GetPacketHandler();
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaRpcMsg, (void*)OnLuaRpcMsg);
	poPacketHandler->RegsterInnerPacketProc(NSMsgType::eLuaCmdMsg, (void*)OnLuaCmdMsg);

	poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssRegServiceRet, (void*)OnRegisterRouterCallback);
	//poPacketHandler->RegsterInnerPacketProc(NSSysCmd::ssClientClose, (void*)OnClientClose);

	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cRoleStartRunReq, (void*)OnRoleStartRun);
	poPacketHandler->RegsterInnerPacketProc(NSCltSrvCmd::cRoleStopRunReq, (void*)OnRoleStopRun);
}

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
	poLuaWrapper->CallLuaRef("RpcMessageCenter", 4);
}

void NSPacketProc::OnLuaCmdMsg(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
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

//void NSPacketProc::OnClientClose(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
//{
//	LogicServer* poLogic = (LogicServer*)(gpoContext->GetService());
//	poLogic->OnClientClose(oHeader.uSrcServer, oHeader.nSrcService, oHeader.uSessionNum > 0 ? pSessionArray[0] : 0);
//	//OnLuaCmdMsg(nSrcSessionID, poPacket, oHeader, pSessionArray);
//}

void NSPacketProc::OnRoleStartRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessionNum > 0 ? pSessionArray[0] : 0;
	Role* poRole = ((LogicServer*)gpoContext->GetService())->GetRoleMgr()->GetRoleBySS(oHeader.uSrcServer, nSession);
	if (poRole == NULL)
	{
		XLog(LEVEL_INFO, "OnRoleStartRun: get role fail by server:%d session:%d\n", oHeader.uSrcServer, nSession);
		return;
	}
	SceneBase* poScene = poRole->GetScene();
	if (poScene == NULL)
	{
		XLog(LEVEL_INFO, "OnRoleStartRun: %s role not in scene\n", poRole->GetName());
		return;
	}

	double dTarAOIID = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> dTarAOIID;

	Role* poTarRole = (Role*)poScene->GetGameObjByObjID(dTarAOIID);
	if (poTarRole == NULL || poTarRole->GetType() != eOT_Role)
	{
		XLog(LEVEL_INFO, "OnRoleStartRun: target role not exist objid:%f\n", dTarAOIID);
		return;
	}

	poTarRole->RoleStartRunHandler(poPacket);
}

void NSPacketProc::OnRoleStopRun(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	int nSession = oHeader.uSessionNum > 0 ? pSessionArray[0] : 0;
	Role* poRole = ((LogicServer*)gpoContext->GetService())->GetRoleMgr()->GetRoleBySS(oHeader.uSrcServer, nSession);
	if (poRole == NULL)
	{
		XLog(LEVEL_INFO, "OnRoleStopRun: role not exist server:%d session:%d\n", oHeader.uSrcServer, nSession);
		return;
	}

	SceneBase* poScene = poRole->GetScene();
	if (poScene == NULL)
	{
		XLog(LEVEL_INFO, "OnRoleStopRun: %s role not in scene\n", poRole->GetName());
		return;
	}

	double dTarAOIID = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> dTarAOIID;

	Role* poTarRole = (Role*)poScene->GetGameObjByObjID(dTarAOIID);
	if (poTarRole == NULL || poTarRole->GetType() != eOT_Role)
	{
		XLog(LEVEL_INFO, "OnRoleStopRun: target role not exist objid:%f\n", dTarAOIID);
		return;
	}

	poTarRole->RoleStopRunHandler(poPacket);
}
