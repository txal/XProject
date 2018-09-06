#include "Include/DBDriver/DBDriver.hpp"
#include "Include/Lpeg/Lpeg.hpp"
#include "Include/Luacjson/Luacjson.hpp"
#include "Include/Pbc/Pbc.hpp"
#include "Include/Script/Script.hpp"

#include "Common/DataStruct/ObjID.h"
#include "Common/LuaCommon/LuaCmd.h"
#include "Common/LuaCommon/LuaRpc.h"
#include "Common/LuaCommon/LuaPB.h"
#include "Common/LuaCommon/LuaSerialize.h"
#include "Common/HttpServer/HttpServer.h"
#include "Common/WordFilter/WordFilter.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/NetworkExport.h"
#include "Server/Base/ServerContext.h"
#include "Server/GlobalServer/GlobalServer.h"

extern HttpServer goHttpServer;

//////////////////////////Global funcitons/////////////////////////////
//服务ID
int GetServiceID(lua_State* pState)
{
	int nService = g_poContext->GetService()->GetServiceID();
	lua_pushinteger(pState, nService);
	return 1;
}

//Http响应
int HttpResponse(lua_State* pState)
{
	if (!lua_islightuserdata(pState, 1))
	{
		return LuaWrapper::luaM_error(pState, "参数1错误");
	}
	struct mg_connection* c = (struct mg_connection*)lua_topointer(pState, 1);
	const char* d = luaL_checkstring(pState, 2);
	std::string data(d);
	HTTPMSG* pMsg = XNEW(HTTPMSG)(c, data, 0);
	goHttpServer.Response(pMsg);
	return 0;
}

luaL_Reg _global_lua_func[] =
{
	{ "GetServiceID", GetServiceID},
	{ "HttpResponse", HttpResponse},
	{ NULL, NULL },
};


void OpenLuaExport()
{
	LuaWrapper* poWrapper = LuaWrapper::Instance();
	RegLuaDebugger(NULL);

	luaopen_lpeg(poWrapper->GetLuaState());
	luaopen_protobuf_c(poWrapper->GetLuaState());
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
}
