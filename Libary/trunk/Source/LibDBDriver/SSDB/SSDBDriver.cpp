#include "Include/DBDriver/SSDBDriver.h"
#include "Include/Logger/Logger.h"

SSDBDriver::SSDBDriver(lua_State* pState)
{
	m_sIP[0] = '\0';
	m_sPwd[0] = '\0';
	m_uPort = 0;
	m_poSSDBClient = NULL;
}

SSDBDriver::~SSDBDriver()
{
	SAFE_DELETE(m_poSSDBClient);
	XLog(LEVEL_INFO, "SSDBDriver destruct!\n");
}

int SSDBDriver::Connect(lua_State* pState)
{
	const char* psIP = luaL_checkstring(pState, 1);
	strcpy(m_sIP, psIP);
	m_uPort = (uint16_t)luaL_checkinteger(pState, 2);
	SAFE_DELETE(m_poSSDBClient);
#ifdef __linux
	m_poSSDBClient = ssdb::Client::connect(m_sIP, m_uPort);
#else
	m_poSSDBClient = XNEW(SSDBClient);
	m_poSSDBClient->connect(m_sIP, m_uPort);
	if (!m_poSSDBClient->isConnect())
	{
		SAFE_DELETE(m_poSSDBClient);
	}
#endif
	if (m_poSSDBClient == NULL)
	{
		LuaWrapper::luaM_error(pState, "Connect SSDB %s:%d fail", m_sIP, m_uPort);
		return 0;
	}
	lua_pushboolean(pState, 1);
	return 1;
}

int SSDBDriver::HSet(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	size_t nSize = 0;
	const char* psKey = luaL_checklstring(pState, 2, &nSize);
	std::string oStrKey(psKey, nSize);
	if (oStrKey == "")
	{
		return LuaWrapper::luaM_error(pState, "HSet key empty");
	}
	nSize = 0;
	const char* psVal = luaL_checklstring(pState, 3, &nSize);
	std::string oStrVal(psVal, nSize);
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hset(psDB, oStrKey, oStrVal);
#else
	Status oStatus = m_poSSDBClient->hset(psDB, oStrKey, oStrVal);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	return 0;
}

int SSDBDriver::HGet(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	size_t nSize = 0;
	const char* psKey = luaL_checklstring(pState, 2, &nSize);
	std::string oStrKey(psKey, nSize);
	std::string oStrVal;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hget(psDB, oStrKey, &oStrVal);
#else
	Status oStatus = m_poSSDBClient->hget(psDB, oStrKey, &oStrVal);
#endif
	if (!oStatus.ok() && !oStatus.not_found())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushlstring(pState, oStrVal.c_str(), oStrVal.size());
	return 1;
}

int SSDBDriver::HSize(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	int64_t nSize = 0;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hsize(psDB, &nSize);
#else
	Status oStatus = m_poSSDBClient->hsize(psDB, &nSize);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushinteger(pState, nSize);
	return 1;
}

int SSDBDriver::HKeys(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	std::vector<std::string> oVecKeys;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hkeys(psDB, "", "", -1, &oVecKeys);
#else
	Status oStatus = m_poSSDBClient->hkeys(psDB, "", "", -1, &oVecKeys);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_newtable(pState);
	for (int i = 0; i < (int)oVecKeys.size(); i++)
	{
		std::string& oStrKey = oVecKeys[i];
		lua_pushlstring(pState, oStrKey.c_str(), oStrKey.size());
		lua_rawseti(pState, -2, i+1);
	}
	return 1;
}

int SSDBDriver::HScan(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	std::vector<std::string> oVecResult;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hscan(psDB, "", "", -1, &oVecResult);
#else
	Status oStatus = m_poSSDBClient->hscan(psDB, "", "", -1, &oVecResult);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_newtable(pState);
	for(int i = 0; i < (int)oVecResult.size(); i++)
	{
		if(i % 2 == 0)
		{
			std::string& oStrKey = oVecResult[i];
			lua_pushlstring(pState, oStrKey.c_str(), oStrKey.size());
		}
		else
		{
			std::string& oStrVal = oVecResult[i];
			lua_pushlstring(pState, oStrVal.c_str(), oStrVal.size());
			lua_settable(pState, -3);
		}
	}
	return 1;
}

int SSDBDriver::HDel(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	size_t nSize = 0;
	const char* psKey = luaL_checklstring(pState, 2, &nSize);
	std::string oStrKey(psKey, nSize);
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hdel(psDB, oStrKey);
#else
	Status oStatus = m_poSSDBClient->hdel(psDB, oStrKey);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushboolean(pState, 1);
	return 1;
}

int SSDBDriver::HClear(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	int64_t nRet = 0;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hclear(psDB, &nRet);
#else
	Status oStatus = m_poSSDBClient->hclear(psDB, &nRet);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushboolean(pState, 1);
	return 1;
}

int SSDBDriver::HIncr(lua_State* pState)
{
	const char* psDB = luaL_checkstring(pState, 1);
	const char* psKey = luaL_checkstring(pState, 2);
	std::string oStrKey(psKey);
	int64_t nRet = 0;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->hincr(psDB, oStrKey, 1, &nRet);
#else
	Status oStatus = m_poSSDBClient->hincr(psDB, oStrKey, 1, &nRet);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushinteger(pState, nRet);
	return 1;
}

int SSDBDriver::Setnx(lua_State* pState)
{
	size_t nSize = 0;
	const char* psKey = luaL_checklstring(pState, 1, &nSize);
	std::string oStrKey(psKey, nSize);
	if (oStrKey == "")
	{
		return LuaWrapper::luaM_error(pState, "Setnx key empty");
	}
	nSize = 0;
	const char* psVal = luaL_checklstring(pState, 2, &nSize);
	std::string oStrVal(psVal, nSize);

	std::string oRet;
#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->setnx(oStrKey, oStrVal, &oRet);
#else
	Status oStatus = m_poSSDBClient->setnx(oStrKey, oStrVal, &oRet);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushstring(pState, oRet.c_str());
	return 1;
}

int SSDBDriver::Del(lua_State* pState)
{
	size_t nSize = 0;
	const char* psKey = luaL_checklstring(pState, 1, &nSize);
	std::string oStrKey(psKey, nSize);

#ifdef __linux
	ssdb::Status oStatus = m_poSSDBClient->del(oStrKey);
#else
	Status oStatus = m_poSSDBClient->del(oStrKey);
#endif
	if (!oStatus.ok())
	{
		Reconnect();
		return LuaWrapper::luaM_error(pState, oStatus.code().c_str());
	}
	lua_pushboolean(pState, 1);
	return 1;
}

bool SSDBDriver::Reconnect()
{
#ifdef __linux
	ssdb::Client* poSSDBClient = ssdb::Client::connect(m_sIP, m_uPort);
#else
	SSDBClient* poSSDBClient = XNEW(SSDBClient);
	poSSDBClient->connect(m_sIP, m_uPort);
	if (!poSSDBClient->isConnect())
	{
		SAFE_DELETE(poSSDBClient);
	}
#endif
	if (poSSDBClient == NULL)
	{
		XLog(LEVEL_ERROR, "Reconnect SSDB %s:%d fail!\n", m_sIP, m_uPort);
		return false;
	}
	SAFE_DELETE(m_poSSDBClient);
	m_poSSDBClient = poSSDBClient;
	return true;
}


// Lua export 
char SSDBDriver::className[] = "SSDBDriver";
Lunar<SSDBDriver>::RegType SSDBDriver::methods[] =
{
	LUNAR_DECLARE_METHOD(SSDBDriver, Connect),
	LUNAR_DECLARE_METHOD(SSDBDriver, HGet),
	LUNAR_DECLARE_METHOD(SSDBDriver, HSet),
	LUNAR_DECLARE_METHOD(SSDBDriver, HSize),
	LUNAR_DECLARE_METHOD(SSDBDriver, HKeys),
	LUNAR_DECLARE_METHOD(SSDBDriver, HScan),
	LUNAR_DECLARE_METHOD(SSDBDriver, HDel),
	LUNAR_DECLARE_METHOD(SSDBDriver, HClear),
	LUNAR_DECLARE_METHOD(SSDBDriver, HIncr),
	LUNAR_DECLARE_METHOD(SSDBDriver, dispose),
	LUNAR_DECLARE_METHOD(SSDBDriver, Setnx),
	LUNAR_DECLARE_METHOD(SSDBDriver, Del),
	{0,0}
};


// Reg ssdb to mysql
void RegClassSSDBDriver()
{
	REG_CLASS(SSDBDriver, true, NULL); 
}