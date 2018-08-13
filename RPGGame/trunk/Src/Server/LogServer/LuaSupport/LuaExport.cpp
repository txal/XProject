#include "Include/DBDriver/DBDriver.hpp"
#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"

#include "Common/LuaCommon/LuaCmd.h"
#include "Common/LuaCommon/LuaPB.h"
#include "Common/LuaCommon/LuaRpc.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Common/DataStruct/XMath.h"
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

int EscapeString(lua_State* pState)
{
	static char sBuff[16384];
	size_t nLen = 0;
	const char* pStr = luaL_checklstring(pState, 1, &nLen);
	nLen = XMath::Min(nLen, sizeof(sBuff) / 2 - 1);
	int nRetLen = MysqlDriver::EscapeString(sBuff, pStr, nLen);
	sBuff[nRetLen] = '\0';
	lua_pushstring(pState, sBuff);
	return 1;
}

luaL_Reg _global_lua_func[] =
{
	{ "GetServiceID", GetServiceID},
	{ "EscapeString", EscapeString },
	{ NULL, NULL },
};


void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();
	RegLuaDebugger(NULL);
	RegTimerMgr("GlobalExport");
	poWrapper->RegFnList(_global_lua_func, "GlobalExport");

	RegLuaCmd("NetworkExport");
	RegLuaRpc("NetworkExport");
	RegLuaPBPack("NetworkExport");
	RegLuaNetwork("NetworkExport");


	RegClassMysqlDriver();
	RegWorkerMgr("WorkerMgr");

	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_protobuf_c(poWrapper->GetLuaState());
}





