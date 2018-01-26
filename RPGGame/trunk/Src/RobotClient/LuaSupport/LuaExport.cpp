#include "Include/DBDriver/DBDriver.hpp"
#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Luacjson/Luacjson.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"

#include "Common/DataStruct/XTime.h"
#include "Common/LuaCommon/LuaCmd.h"
#include "Common/LuaCommon/LuaPB.h"
#include "Common/LuaCommon/LuaRpc.h"
#include "Common/LuaCommon/LuaTableSeri.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Common/WordFilter/WordFilter.h"

#include "RobotClient/RobotMgr.h"
#include "Server/Base/NetworkExport.h"
#include "Server/Base/ServerContext.h"

extern ServerContext* g_poContext;


////////////////////////////Global funcitons////////////////////////////
int GetRobotMgr(lua_State* pState)
{
	RobotMgr* pRobotMgr = (RobotMgr*)g_poContext->GetService();
	Lunar<RobotMgr>::push(pState, pRobotMgr);
	return 1;
}

luaL_Reg _global_lua_func[] =
{
	{ "GetRobotMgr", GetRobotMgr },
	{ NULL, NULL },
};


void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();

	RegLuaDebugger(NULL);
	RegTimerMgr("GlobalExport");
	RegWordFilter("GlobalExport");
	RegLuaTableSeri("GlobalExport");
	poWrapper->RegFnList(_global_lua_func, "GlobalExport");

    RegLuaCmd("NetworkExport");
    RegLuaRpc("NetworkExport");
	RegLuaPBPack("NetworkExport");
	RegLuaNetwork("NetworkExport");

	RegClassRobot();
	RegClassSSDBDriver();

	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_protobuf_c(poWrapper->GetLuaState());
	luaopen_cjson(poWrapper->GetLuaState());
}
