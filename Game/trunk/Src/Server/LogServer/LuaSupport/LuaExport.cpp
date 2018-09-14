#include "Include/DBDriver/DBDriver.hpp"
#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"

#include "Common/LuaCommon/LuaRpc.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/NetworkExport.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/WorkerMgr.h"

//////////////////////////Global funcitons/////////////////////////////
int GetServiceID(lua_State* pState)
{
	int nService = g_poContext->GetService()->GetServiceID();
	lua_pushinteger(pState, nService);
	return 1;
}

luaL_Reg _global_lua_func[] =
{
	{"GetServiceID", GetServiceID},
	{ NULL, NULL },
};


void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();
	RegLuaDebugger(NULL);
	RegTimerMgr("GlobalExport");
	poWrapper->RegFnList(_global_lua_func, "GlobalExport");

    RegLuaRpc("NetworkExport");
	RegLuaNetwork("NetworkExport");

	RegClassMysqlDriver();
	RegWorkerMgr("WorkerMgr");

	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_protobuf_c(poWrapper->GetLuaState());
}





