#ifndef __LMYSQLDRIVER_H__
#define __LMYSQLDRIVER_H__

#include "Include/Script/LuaWrapper.h"
#include "Include/DBDriver/MysqlDriver.h"

class LMysqlDriver : public MysqlDriver
{
public:
	static char className[];
	static Lunar<LMysqlDriver>::RegType methods[];

public:
	LMysqlDriver(lua_State* pState);

	int Connect(lua_State* pState);

	int Query(lua_State* pState);

	int FetchRow(lua_State* pState);

	int NumRows(lua_State* pState);

	int AffectedRows(lua_State* pState);

	int InsertID(lua_State* pState);

	int ToInt32(lua_State* pState);
	int ToInt64(lua_State* pState);
	int ToDouble(lua_State* pState);

	int ToString(lua_State* pState);
};

// Register mysql driver to lua
void RegClassMysqlDriver();

#endif