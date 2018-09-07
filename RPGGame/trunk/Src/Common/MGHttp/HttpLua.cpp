#include "HttpLua.hpp"

HttpClient goHttpClient;
HttpServer goHttpServer;

//HTTP响应
static int HttpResponse(lua_State* pState)
{
	lua_settop(pState, 2);
	if (!lua_islightuserdata(pState, 1))
	{
		return LuaWrapper::luaM_error(pState, "参数1错误");
	}
	struct mg_connection* c = (struct mg_connection*)lua_topointer(pState, 1);
	const char* d = luaL_checkstring(pState, 2);

	HTTPMSG* pMsg = XNEW(HTTPMSG)();
	pMsg->c = c;
	pMsg->data = std::string(d);
	goHttpServer.Response(pMsg);
	return 0;
}

//HTTP请求
static int HttpRequest(lua_State* pState)
{
	lua_settop(pState, 4);
	const char* t = luaL_checkstring(pState, 1);
	const char* url = luaL_checkstring(pState, 2);
	const char* d = lua_tostring(pState, 3);
	int luaref = LUA_NOREF;
	if (!lua_isnoneornil(pState, 4))
	{
		luaref = luaL_ref(pState, LUA_REGISTRYINDEX);
	}

	HTTPMSG* pMsg = XNEW(HTTPMSG)();
	pMsg->url = std::string(url);
	pMsg->data = std::string(d?d:"");
	pMsg->luaref = luaref;

	if (strcmp(t, "GET") == 0)
	{
		goHttpClient.HttpGet(pMsg);
	}
	else
	{
		goHttpClient.HttpPost(pMsg);
	}
	return 0;
}


void RegHttpLua(const char* psTable)
{
	luaL_Reg _http_lua_func[] =
	{
		{ "Request", HttpRequest },
		{ "Response", HttpResponse },
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(_http_lua_func, psTable);
}


static void ProcessHttpRequest()
{
	HTTPMSG* poMsg = goHttpServer.GetRequest();
	if (poMsg == NULL)
	{
		return;
	}

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_State* pState = poLuaWrapper->GetLuaState();

	lua_pushlightuserdata(pState, poMsg->c);
	lua_pushstring(pState, poMsg->data.c_str());
	lua_pushinteger(pState, poMsg->type);
	lua_pushstring(pState, poMsg->url.c_str());
	poLuaWrapper->CallLuaRef("HttpRequestMessage", 4, 0);
	SAFE_DELETE(poMsg);
}

static void ProcessHttpResponse()
{
	HTTPMSG* poMsg = goHttpClient.GetResponse();
	if (poMsg == NULL)
	{
		return;
	}

	if (poMsg->luaref == LUA_NOREF)
	{
		SAFE_DELETE(poMsg);
		return;
	}
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	lua_pushstring(poLuaWrapper->GetLuaState(), poMsg->data.c_str());
	poLuaWrapper->CallLuaRef(poMsg->luaref, 1);
	SAFE_DELETE(poMsg);
}


void ProcessHttpMessage()
{
	ProcessHttpRequest();
	ProcessHttpResponse();
}
