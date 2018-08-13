#include "Server/Base/NetworkExport.h"

#include "Common/DataStruct/Array.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/Base/Service.h"

static Array<NetAdapter::SERVICE_NAVI> oNaviCache;
static int SendExter(lua_State* pState)
{
	uint16_t uCmd = (uint16_t)luaL_checkinteger(pState, 1);
	luaL_checktype(pState, 2, LUA_TLIGHTUSERDATA);
	Packet* poPacket = (Packet*)lua_touserdata(pState, 2);

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = g_poContext->GetServerID();
	oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
	oNavi.uTarServer = (uint16_t)luaL_checkinteger(pState, 3);
	oNavi.nTarService = (int8_t)luaL_checkinteger(pState, 4);
	oNavi.nTarSession = (int)luaL_checkinteger(pState, 5);
	uint32_t uCmdIdx = (uint32_t)luaL_checkinteger(pState, 6);
	if (oNavi.nTarSession <= 0 || oNavi.nTarService < 0 || oNavi.nTarService > MAX_SERVICE_NUM)
	{
		poPacket->Release();
		return LuaWrapper::luaM_error(pState, "Send exter param error!");
	}
	if (!NetAdapter::SendExter(uCmd, poPacket, oNavi, uCmdIdx))
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
	int nTableLen = (int)lua_rawlen(pState, 3);
	if (!lua_istable(pState, 3) || nTableLen <= 0 || nTableLen % 2 != 0)
	{
		poPacket->Release();
		LuaWrapper::luaM_error(pState, "Session table format error!");
	}

	oNaviCache.Clear();
	luaL_checkstack(pState, nTableLen, NULL);

	uint16_t uSrcServer = g_poContext->GetServerID();
	int8_t nSrcService = g_poContext->GetService()->GetServiceID();
	for (int i = 1; i <= nTableLen; i = i+2)
	{
		lua_rawgeti(pState, 3, i);
		lua_rawgeti(pState, 3, i+1);
		uint16_t uTarServer = (uint16_t)lua_tointeger(pState, -2);
		int nTarSession = (int)lua_tointeger(pState, -1);
		oNaviCache.PushBack(NetAdapter::SERVICE_NAVI(uSrcServer, nSrcService, uTarServer, 0, nTarSession));
	}
	if (!NetAdapter::BroadcastExter(uCmd, poPacket, oNaviCache))
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
	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = g_poContext->GetServerID();
	oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
	oNavi.uTarServer = (uint16_t)luaL_checkinteger(pState, 3);
	oNavi.nTarService = (int8_t)luaL_checkinteger(pState, 4);
	oNavi.nTarSession = (int)luaL_checkinteger(pState, 5);
	if (oNavi.uTarServer <= 0 || oNavi.nTarService <= 0 || oNavi.nTarService > MAX_SERVICE_NUM)
	{
		poPacket->Release();
		return LuaWrapper::luaM_error(pState, "Target server or service error!");
	}
	if (!NetAdapter::SendInner(uCmd, poPacket, oNavi))
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
	int nTableLen = (int)lua_rawlen(pState, 4);
	if (!lua_istable(pState, 4) || nTableLen <= 0 || nTableLen % 3 != 0)
	{
		poPacket->Release();
		LuaWrapper::luaM_error(pState, "Service table format error!");
	}

	oNaviCache.Clear();
	luaL_checkstack(pState, nTableLen, NULL);

	uint16_t uSrcServer = g_poContext->GetServerID();
	int8_t nSrcService = g_poContext->GetService()->GetServiceID();
	for (int i = 1; i <= nTableLen; i=i+3)
	{
		lua_rawgeti(pState, 4, i);
		lua_rawgeti(pState, 4, i+1);
		lua_rawgeti(pState, 4, i+2);
		uint16_t uTarServer = (uint16_t)lua_tointeger(pState, -3);
		int8_t nTarService = (int8_t)lua_tointeger(pState, -2);
		int nTarSession = (int)lua_tointeger(pState, -1);
		oNaviCache.PushBack(NetAdapter::SERVICE_NAVI(uSrcServer, nSrcService, uTarServer, nTarService, nTarSession));
	}

	//兼容RPCNet(无RawCmd和CMDNet(有RawCmd)
	if (uRawCmd > 0)
	{
		poPacket->WriteBuf(&uRawCmd, sizeof(uRawCmd));
	}
	if (!NetAdapter::BroadcastInner(uBroadcastCmd, poPacket, oNaviCache))
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

static int ClockMSTime(lua_State* pState)
{
	int64_t nMSTime = XTime::MSTime();
	lua_pushinteger(pState, nMSTime);
	return 1;
}

static int UnixMSTime(lua_State* pState)
{
	int64_t nMSTime = XTime::UnixMSTime();
	lua_pushinteger(pState, nMSTime);
	return 1;
}

static int Terminate(lua_State* pState)
{
	g_poContext->GetService()->Terminate();
	return 0;
}

static luaL_Reg _network_lua_func[] =
{
	{ "SendInner", SendInner },
	{ "SendExter", SendExter },
	{ "BroadcastExter", BroadcastExter },
	{ "BroadcastInner", BroadcastInner },
	{ "N2P", N2P },
	{ "ClockMSTime", ClockMSTime },
	{ "UnixMSTime", UnixMSTime },
	{ "Terminate", Terminate},
	{ NULL, NULL },
};

// Register network
void RegLuaNetwork(const char* psTable)
{
	LuaWrapper::Instance()->RegFnList(_network_lua_func, psTable);
}

