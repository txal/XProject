#include "Include/DBDriver/DBDriver.hpp"
#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Luacjson/Luacjson.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"
#include "Include/Script/Script.hpp"

#include "Common/DataStruct/Crypt/Md5.h"
#include "Common/LuaCommon/LuaCmd.h"
#include "Common/LuaCommon/LuaPB.h"
#include "Common/LuaCommon/LuaRpc.h"
#include "Common/LuaCommon/LuaTableSeri.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Common/WordFilter/WordFilter.h"

#include "Server/Base/NetworkExport.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/Player/PlayerMgr.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

//////////////////////////global funcitons/////////////////////////////
//取服务ID
int GetServiceID(lua_State* pState)
{
	int nService = g_poContext->GetService()->GetServiceID();
	lua_pushinteger(pState, nService);
	return 1;
}

//生成游戏唯一ID
int MakeObjID(lua_State* pState)
{
	OBJID oID = MakeObjID(g_poContext->GetService()->GetServiceID());
	lua_pushinteger(pState, oID.llID);
	return 1;
}

int GetSceneMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)g_poContext->GetService();
	SceneMgr* poMgr = poServer->GetSceneMgr();
	Lunar<SceneMgr>::push(pState, poMgr);
	return 1;
}

int GetPlayerMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)g_poContext->GetService();
	PlayerMgr* poMgr = poServer->GetPlayerMgr();
	Lunar<PlayerMgr>::push(pState, poMgr);
	return 1;
}

int GetMonsterMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)g_poContext->GetService();
	MonsterMgr* poMgr = poServer->GetMonsterMgr();
	Lunar<MonsterMgr>::push(pState, poMgr);
	return 1;
}

int GetDropItemMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)g_poContext->GetService();
	DropItemMgr* poMgr = poServer->GetDropItemMgr();
	Lunar<DropItemMgr>::push(pState, poMgr);
	return 1;
}

int GetRobotMgr(lua_State* pState)
{
	LogicServer* poServer = (LogicServer*)g_poContext->GetService();
	RobotMgr* poMgr = poServer->GetRobotMgr();
	Lunar<RobotMgr>::push(pState, poMgr);
	return 1;
}

int IsBlockUnit(lua_State* pState)
{
	int nMapID = (int)luaL_checkinteger(pState, 1);
	int nPosX = (int)luaL_checkinteger(pState, 2);
	int nPosY = (int)luaL_checkinteger(pState, 3);
	MapConf* poConf = ConfMgr::Instance()->GetMapMgr()->GetConf(nMapID);
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

int MD5(lua_State* pState)
{
	char sOutput[64] = {0};
	const char* psCont = luaL_checkstring(pState, 1);
	MD5String(sOutput, psCont);
	lua_pushstring(pState, sOutput);
	return 1;
}


luaL_Reg _global_lua_func[] =
{
	{ "GetServiceID", GetServiceID},
	{ "MakeGameObjID", MakeObjID},
	{ "GetSceneMgr", GetSceneMgr},
	{ "GetPlayerMgr", GetPlayerMgr},
	{ "GetMonsterMgr", GetMonsterMgr},
	{ "GetDropItemMgr", GetDropItemMgr},
	{ "GetRobotMgr", GetRobotMgr},
	{ "IsBlockUnit", IsBlockUnit},
	{ "MD5", MD5},
	{ NULL, NULL },
};

void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();
	RegLuaDebugger(NULL);
	RegTimerMgr("GlobalExport");
	RegWordFilter("GlobalExport");
	poWrapper->RegFnList(_global_lua_func, "GlobalExport");

    RegLuaCmd("NetworkExport");
    RegLuaRpc("NetworkExport");
	RegLuaPBPack("NetworkExport");
	RegLuaNetwork("NetworkExport");

	RegClassSSDBDriver();
	RegClassMysqlDriver();

	RegClassScene();
	RegClassObject();
	RegClassPlayer();
	RegClassMonster();
	RegClassRobot();
	RegClassDropItem();

	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_protobuf_c(poWrapper->GetLuaState());
	luaopen_cjson(poWrapper->GetLuaState());
	luaopen_cjson_raw(poWrapper->GetLuaState());
}





