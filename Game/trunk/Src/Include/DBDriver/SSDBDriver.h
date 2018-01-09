#ifndef __SSDB_H__
#define __SSDB_H__

#include "Include/Script/LuaWrapper.h"

#ifdef __linux
#include "SSDB_client.h"
#else
#include "Include/DBDriver/ssdb_win/ssdb_client.h"
#endif

class SSDBDriver
{
public:
	static char className[];
	static Lunar<SSDBDriver>::RegType methods[];

public:
    SSDBDriver(lua_State* pState);
    virtual ~SSDBDriver();
    int dispose(lua_State* pState) { delete this; return 0; }

public:
	int Connect(lua_State* pState);
	int HSet(lua_State* pState);
	int HGet(lua_State* pState);
	int HSize(lua_State* pState);
	int HKeys(lua_State* pState);
	int HScan(lua_State* pState);
	int HDel(lua_State* pState);
	int HClear(lua_State* pState);
	int HIncr(lua_State* pState);
	int Setnx(lua_State* pState);
	int Del(lua_State* pState);

private:
	bool Reconnect();

private:
	char m_sIP[128];
	uint16_t m_uPort;
	char m_sPwd[32];

#ifdef __linux
	ssdb::Client* m_poSSDBClient;
#else
	SSDBClient* m_poSSDBClient;
#endif
	DISALLOW_COPY_AND_ASSIGN(SSDBDriver);
};

// Register ssdb driver to lua
void RegClassSSDBDriver();

#endif