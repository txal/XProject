﻿#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Luacjson/Luacjson.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"

#include "Common/LuaCommon/LuaCmd.h"
#include "Common/LuaCommon/LuaRpc.h"
#include "Common/LuaCommon/LuaPB.h"

#include "Common/MGHttp/HttpLua.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/NetworkExport.h"
#include "Server/Base/ServerContext.h"

//////////////////////////Global funcitons/////////////////////////////
int GetServiceID(lua_State* pState)
{
	int nService = g_poContext->GetService()->GetServiceID();
	lua_pushinteger(pState, nService);
	return 1;
}

luaL_Reg _global_lua_func[] =
{
	{ "GetServiceID", GetServiceID },
	{ NULL, NULL },
};

void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();
	luaopen_cjson_raw(poWrapper->GetLuaState());
	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_protobuf_c(poWrapper->GetLuaState());

	RegTimerMgr("GlobalExport");
	poWrapper->RegFnList(_global_lua_func, "GlobalExport");

    RegLuaCmd("NetworkExport");
    RegLuaRpc("NetworkExport");
	RegLuaPBPack("NetworkExport");
	RegLuaNetwork("NetworkExport");
	RegHttpLua("http");
}

