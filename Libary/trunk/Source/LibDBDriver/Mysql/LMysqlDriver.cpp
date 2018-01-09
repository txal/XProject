#include "Include/DBDriver/LMysqlDriver.h"

LMysqlDriver::LMysqlDriver(lua_State* pState)
{
}

int LMysqlDriver::Connect(lua_State* pState)
{
	const char* xVal0 = luaL_checkstring(pState, 1);
	uint16_t xVal1 = (uint16_t)luaL_checkinteger(pState, 2);
	const char* xVal2 = luaL_checkstring(pState, 3);
	const char* xVal3 = luaL_checkstring(pState, 4);
	const char* xVal4 = luaL_checkstring(pState, 5);
	const char* xVal5 = luaL_checkstring(pState, 6);
	lua_pushboolean(pState, MysqlDriver::Connect(xVal0,xVal1,xVal2,xVal3,xVal4,xVal5));
	return 1;
}

int LMysqlDriver::Query(lua_State* pState)
{
	const char* xVal0 = luaL_checkstring(pState, 1);
	lua_pushboolean(pState, MysqlDriver::Query(xVal0));
	return 1;
}

int LMysqlDriver::FetchRow(lua_State* pState)
{
	lua_pushboolean(pState, MysqlDriver::FetchRow());
	return 1;
}

int LMysqlDriver::NumRows(lua_State* pState)
{
	lua_pushinteger(pState, MysqlDriver::NumRows());
	return 1;
}

int LMysqlDriver::InsertID(lua_State* pState)
{
	lua_pushinteger(pState, MysqlDriver::InsertID());
	return 1;
}

int LMysqlDriver::AffectedRows(lua_State* pState)
{
	lua_pushinteger(pState, MysqlDriver::AffectedRows());
	return 1;
}

int LMysqlDriver::ToInt32(lua_State* pState)
{
	int nTop = lua_gettop(pState);
	for (int i = 0; i < nTop; i++)
	{
		const char* pColumn = luaL_checkstring(pState, i + 1);
		lua_pushinteger(pState, MysqlDriver::ToInt32(pColumn));
	}
	return nTop;
}

int LMysqlDriver::ToInt64(lua_State* pState)
{
	int nTop = lua_gettop(pState);
	for (int i = 0; i < nTop; i++)
	{
		const char* pColumn = luaL_checkstring(pState, i + 1);
		lua_pushinteger(pState, MysqlDriver::ToInt64(pColumn));
	}
	return nTop;
}

int LMysqlDriver::ToDouble(lua_State* pState)
{
	int nTop = lua_gettop(pState);
	for (int i = 0; i < nTop; i++)
	{
		const char* pColumn = luaL_checkstring(pState, i + 1);
		lua_pushnumber(pState, MysqlDriver::ToDouble(pColumn));
	}
	return nTop;
}
	
int LMysqlDriver::ToString(lua_State* pState)
{
	int nTop = lua_gettop(pState);
	for (int i = 0; i < nTop; i++)
	{
		const char* pColumn = luaL_checkstring(pState, i + 1);
		lua_pushstring(pState, MysqlDriver::ToString(pColumn));
	}
	return nTop;
}


char LMysqlDriver::className[] = "MysqlDriver";
Lunar<LMysqlDriver>::RegType LMysqlDriver::methods[] =
{
	LUNAR_DECLARE_METHOD(LMysqlDriver, Connect),
	LUNAR_DECLARE_METHOD(LMysqlDriver, Query),
	LUNAR_DECLARE_METHOD(LMysqlDriver, FetchRow),
	LUNAR_DECLARE_METHOD(LMysqlDriver, NumRows),
	LUNAR_DECLARE_METHOD(LMysqlDriver, InsertID),
	LUNAR_DECLARE_METHOD(LMysqlDriver, AffectedRows),
	LUNAR_DECLARE_METHOD(LMysqlDriver, ToInt32),
	LUNAR_DECLARE_METHOD(LMysqlDriver, ToInt64),
	LUNAR_DECLARE_METHOD(LMysqlDriver, ToDouble),
	LUNAR_DECLARE_METHOD(LMysqlDriver, ToString),
	{0,0}
};


void RegClassMysqlDriver()
{
	REG_CLASS(LMysqlDriver, true, NULL); 
}