#include "Server/Base/NetworkExport.h"
#include "Common/DataStruct/Array.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/Service.h"

static Array<int> oSessionCache;
static Array<int> oServiceCache;
static Array<int> oServerCache;

static int SendExter(lua_State* pState)
{
	uint16_t uCmd = (uint16_t)luaL_checkinteger(pState, 1);
	luaL_checktype(pState, 2, LUA_TLIGHTUSERDATA);
	Packet* poPacket = (Packet*)lua_touserdata(pState, 2);
	int8_t nToService = (int8_t)luaL_checkinteger(pState, 3);
	int nToSession = (int)luaL_checkinteger(pState, 4);
	uint32_t uCmdIdx = (uint32_t)lua_tointeger(pState, 5);
	if (nToSession <= 0 || nToService < 0 || nToService > MAX_SERVICE_NUM)
	{
		poPacket->Release();
		return LuaWrapper::luaM_error(pState, "Send exter param error!");
	}
	if (!NetAdapter::SendExter(uCmd, poPacket, nToService, nToSession, uCmdIdx))
	{
		return LuaWrapper::luaM_error(pState, "Send exter packet fail!");
	}
	return 0;
}

static int BroadcastExter(lua_State* pState)
{
	uint16_t uCmd = (uint16_t)luaL_checkinteger(pState, 1);
	luaL_checktype(pState, 2, LUA_TLIGHTUSERDATA);
	Packet* poPacket = (Packet*)lua_touserdata(pState, 2);
	if (!lua_istable(pState, 3) || lua_rawlen(pState, 3) <= 0)
	{
		poPacket->Release();
		LuaWrapper::luaM_error(pState, "Param index 3 must be a not empty table!");
	}

	oSessionCache.Clear();
	int nLen = (int)lua_rawlen(pState, 3);
	luaL_checkstack(pState, nLen, NULL);
	for (int i = 1; i <= nLen; i++)
	{
		lua_rawgeti(pState, 3, i);
		int nSession = (int)lua_tointeger(pState, -1);
		oSessionCache.PushBack(nSession);
	}
	if (!NetAdapter::BroadcastExter(uCmd, poPacket, oSessionCache.Ptr(), oSessionCache.Size()))
	{
		return LuaWrapper::luaM_error(pState, "Broadcast exter packet fail!");
	}
	return 0;
}

static int SendInner(lua_State* pState)
{
	uint16_t uCmd = (uint16_t)luaL_checkinteger(pState, 1);
	luaL_checktype(pState, 2, LUA_TLIGHTUSERDATA);
	Packet* poPacket = (Packet*)lua_touserdata(pState, 2);
	int8_t nToService = (int8_t)luaL_checkinteger(pState, 3);
	if (nToService <= 0 || nToService > MAX_SERVICE_NUM)
	{
		poPacket->Release();
		return LuaWrapper::luaM_error(pState, "Packet or target service error!");
	}
	int nToSession = (int)luaL_checkinteger(pState, 4);
	int16_t nToServer = (int16_t)lua_tointeger(pState, 5);
	if (!NetAdapter::SendInner(uCmd, poPacket, nToService, nToSession, nToServer))
	{
		return LuaWrapper::luaM_error(pState, "Send inner packet fail!");
	}
	return 0;
}

static int BroadcastInner(lua_State* pState)
{
	uint16_t uBroadcastCmd = (uint16_t)luaL_checkinteger(pState, 1);
	uint16_t uRawCmd = (uint16_t)luaL_checkinteger(pState, 2);
	luaL_checktype(pState, 3, LUA_TLIGHTUSERDATA);
	Packet* poPacket = (Packet*)lua_touserdata(pState, 3);
	if (!lua_istable(pState, 4) || lua_rawlen(pState, 4) <= 0)
	{
		poPacket->Release();
		LuaWrapper::luaM_error(pState, "Param index 3 must be a not empty table!");
	}

	oServiceCache.Clear();
	int nLen = (int)lua_rawlen(pState, 4);
	luaL_checkstack(pState, nLen, NULL);
	for (int i = 1; i <= nLen; i++)
	{
		lua_rawgeti(pState, 4, i);
		int nService = (int)lua_tointeger(pState, -1);
		oServiceCache.PushBack(nService);
	}

	oServerCache.Clear();
	if (lua_istable(pState, 5) && lua_rawlen(pState, 5) > 0)
	{
		int nLen = (int)lua_rawlen(pState, 5);
		luaL_checkstack(pState, nLen, NULL);
		for (int i = 1; i <= nLen; i++)
		{
			lua_rawgeti(pState, 5, i);
			int16_t nServer = (int16_t)lua_tointeger(pState, -1);
			oServerCache.PushBack(nServer);
		}
	}
	if (oServerCache.Size() > 0 && oServiceCache.Size() != oServerCache.Size())
	{
		return LuaWrapper::luaM_error(pState, "Broadcast inner service list not match serverlist!");
	}

	poPacket->WriteBuf(&uRawCmd, sizeof(uRawCmd));
	if (!NetAdapter::BroadcastInner(uBroadcastCmd, poPacket, oServiceCache.Ptr(), oServiceCache.Size(), oServerCache.Size()>0 ? oServerCache.Ptr():NULL))
	{
		return LuaWrapper::luaM_error(pState, "Broadcast inner packet fail!");
	}
	return 0;
}

static int N2P(lua_State* pState)
{
	char sBuf[136] = { 0 };
	uint32_t uIP = (uint32_t)luaL_checkinteger(pState, 1);
	NetAPI::N2P(uIP, sBuf, sizeof(sBuf));
	lua_pushstring(pState, sBuf);
	return 1;
}


static luaL_Reg _network_lua_func[] =
{
	{ "SendInner", SendInner },
	{ "SendExter", SendExter },
	{ "BroadcastExter", BroadcastExter },
	{ "BroadcastInner", BroadcastInner },
	{ "N2P", N2P },
	{ NULL, NULL },
};

// Register network
void RegLuaNetwork(const char* psTable)
{
	LuaWrapper::Instance()->RegFnList(_network_lua_func, psTable);
}

