#include "Include/DBDriver/DBDriver.hpp"
#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Luacjson/Luacjson.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"
#include "Include/Script/Script.hpp"

#include "Common/LuaCommon/LuaCmd.h"
#include "Common/LuaCommon/LuaPB.h"
#include "Common/LuaCommon/LuaRpc.h"
#include "Common/LuaCommon/LuaSerialize.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Common/WordFilter/WordFilter.h"

#include "Server/Base/NetworkExport.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/GameObject/Role/RoleMgr.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

//////////////////////////global funcitons/////////////////////////////
//取服务ID
int GetServiceID(lua_State* pState)
{
	int nService = gpoContext->GetService()->GetServiceID();
	lua_pushinteger(pState, nService);
	return 1;
}

int GetSceneMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)gpoContext->GetService();
	SceneMgr* poMgr = poServer->GetSceneMgr();
	Lunar<SceneMgr>::push(pState, poMgr);
	return 1;
}

int GetRoleMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)gpoContext->GetService();
	RoleMgr* poMgr = poServer->GetRoleMgr();
	Lunar<RoleMgr>::push(pState, poMgr);
	return 1;
}

int GetMonsterMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)gpoContext->GetService();
	MonsterMgr* poMgr = poServer->GetMonsterMgr();
	Lunar<MonsterMgr>::push(pState, poMgr);
	return 1;
}

int GetDropItemMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)gpoContext->GetService();
	DropItemMgr* poMgr = poServer->GetDropItemMgr();
	Lunar<DropItemMgr>::push(pState, poMgr);
	return 1;
}

int GetRobotMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)gpoContext->GetService();
	RobotMgr* poMgr = poServer->GetRobotMgr();
	Lunar<RobotMgr>::push(pState, poMgr);
	return 1;
}

int IsBlockUnit(lua_State* pState)
{
	int nMapID = (int)luaL_checkinteger(pState, 1);
	int nPosX = (int)luaL_checkinteger(pState, 2);
	int nPosY = (int)luaL_checkinteger(pState, 3);
	MAPCONF* poConf = ConfMgr::Instance()->GetMapMgr()->GetConf(nMapID);
	if (poConf == NULL)
	{
		return LuaWrapper::luaM_error(pState, "Map conf %d not found!\n", nMapID);
	}
	int nUnitX = nPosX / gnUnitWidth;
	int nUnitY = nPosY / gnUnitHeight;
	bool bRes = poConf->IsBlockUnit(nUnitX, nUnitY);
	lua_pushboolean(pState, bRes);
	return 1;
}

int AddBattleLog(lua_State* pState)
{
	const char* pFile = luaL_checkstring(pState, 1);
	const char* pCont = luaL_checkstring(pState, 2);
	BATTLELOG* pLog = XNEW(BATTLELOG)();
	pLog->oFile = pFile;
	pLog->oCont = pCont;
	goBattleLog.AddLog(pLog);
	return 0;
}

luaL_Reg _global_lua_func[] =
{
	{ "GetServiceID", GetServiceID},
	{ "GetSceneMgr", GetSceneMgr},
	{ "GetPlayerMgr", GetRoleMgr},
	{ "GetMonsterMgr", GetMonsterMgr},
	{ "GetDropItemMgr", GetDropItemMgr},
	{ "GetRobotMgr", GetRobotMgr},
	{ "IsBlockUnit", IsBlockUnit},
	{ "AddBattleLog", AddBattleLog},
	{ NULL, NULL },
};

void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();
	RegLuaDebugger(NULL);

	luaopen_protobuf_c(poWrapper->GetLuaState());
	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_cjson(poWrapper->GetLuaState());
	luaopen_cjson_raw(poWrapper->GetLuaState());

	RegTimerMgr("GlobalExport");
	//RegWordFilter("GlobalExport");
	poWrapper->RegFnList(_global_lua_func, "GlobalExport");

    RegLuaCmd("NetworkExport");
    RegLuaRpc("NetworkExport");
	RegLuaPBPack("NetworkExport");
	RegLuaNetwork("NetworkExport");
	RegLuaSerialize("cseri");

	RegClassSSDBDriver();
	RegClassMysqlDriver();

	RegClassScene();
	RegClassObject();
	RegClassRole();
	RegClassMonster();
	RegClassRobot();
	RegClassDropItem();

}





