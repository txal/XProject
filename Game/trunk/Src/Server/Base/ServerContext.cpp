#include "Server/Base/ServerContext.h"
#include "Common/DataStruct/XMath.h"

ServerContext::ServerContext()
{
    m_uServerID = 0;
	m_poService = NULL;
	m_poRouterMgr = NULL;
	m_poPacketHandler = NULL;

	m_poLuaTableSeri = NULL;
	m_poLuaSerialize = NULL;
}

ServerContext::~ServerContext()
{
	SAFE_DELETE(m_poLuaTableSeri);
	SAFE_DELETE(m_poLuaSerialize);
}

int ServerContext::GetRandomLogic()
{
	int nCount = (int)m_oSrvConf.oLogicList.size();
	if (nCount <= 0)
	{
		return 0;
	}
	int nIndex = XMath::Random(1, nCount);
	return m_oSrvConf.oLogicList[nIndex-1].oLogic.uService;
}

bool ServerContext::LoadServerConfig()
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	if (!poLuaWrapper->RawDoFile("ServerConf.lua"))
	{
		XLog(LEVEL_ERROR, "ServerContext::LoadServerConfig fail!\n");
		return false;
	}

	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_settop(pState, 0);
	lua_getglobal(pState, "gnServerID");
	m_oSrvConf.uServerID = (uint16_t)luaL_checkinteger(pState, -1);

	lua_getglobal(pState, "gtNetConf");
	int nTbIdx = lua_gettop(pState);

	//网关
	m_oSrvConf.oGateList.clear();
	lua_getfield(pState, -1, "tGateService");
	int nTbIdx1 = lua_gettop(pState);
	lua_pushnil(pState);
	while (lua_next(pState, nTbIdx1))
	{
		ServerNode oConf;
		oConf.oGate.uService = (int8_t)lua_tointeger(pState, -2);
		lua_getfield(pState, -1, "nPort");
		oConf.oGate.uPort = (uint16_t)lua_tointeger(pState, -1);
		lua_getfield(pState, -2, "nMaxConns");
		oConf.oGate.uMaxConns = (uint16_t)lua_tointeger(pState, -1);
		lua_getfield(pState, -3, "nSecureCPM");
		oConf.oGate.uSecureCPM = (uint16_t)lua_tointeger(pState, -1);
		lua_getfield(pState, -4, "nSecureQPM");
		oConf.oGate.uSecureQPM = (uint16_t)lua_tointeger(pState, -1);
		lua_getfield(pState, -5, "nSecureBlock");
		oConf.oGate.uSecureBlock = (uint32_t)lua_tointeger(pState, -1);
		lua_getfield(pState, -6, "nDeadLinkTime");
		oConf.oGate.uDeadLinkTime = (uint16_t)lua_tointeger(pState, -1);
		m_oSrvConf.oGateList.push_back(oConf);
		lua_pop(pState, 7);
	}

	//路由
	m_oSrvConf.oRouterList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tRouterService");
	nTbIdx1 = lua_gettop(pState);
	lua_pushnil(pState);
	while (lua_next(pState, nTbIdx1))
	{
		ServerNode oConf;
		oConf.oRouter.uService = (int8_t)lua_tointeger(pState, -2);
		lua_getfield(pState, -1, "sIP");
		const char* psIP = lua_tostring(pState, -1);
		strcpy(oConf.oRouter.sIP, psIP);
		lua_getfield(pState, -2, "nPort");
		oConf.oRouter.uPort = (uint16_t)lua_tointeger(pState, -1);
		m_oSrvConf.oRouterList.push_back(oConf);
		lua_pop(pState, 3);
	}

	//逻辑
	m_oSrvConf.oLogicList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tLogicService");
	nTbIdx1 = lua_gettop(pState);
	lua_pushnil(pState);
	while (lua_next(pState, nTbIdx1))
	{
		ServerNode oConf;
		oConf.oLogic.uService = (int8_t)lua_tointeger(pState, -2);
		m_oSrvConf.oLogicList.push_back(oConf);
		lua_pop(pState, 1);
	}

	//全局
	m_oSrvConf.oGlobalList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tGlobalService");
	nTbIdx1 = lua_gettop(pState);
	lua_pushnil(pState);
	while (lua_next(pState, nTbIdx1))
	{
		ServerNode oConf;
		oConf.oGlobal.uService = (int8_t)lua_tointeger(pState, -2);
		lua_getfield(pState, -1, "sIP");
		const char* psIP = lua_tostring(pState, -1);
		strcpy(oConf.oGlobal.sIP, psIP);
		lua_getfield(pState, -2, "nPort");
		oConf.oGlobal.uPort = (uint16_t)lua_tointeger(pState, -1);
		m_oSrvConf.oGlobalList.push_back(oConf);
		lua_pop(pState, 3);
	}

	//日志
	m_oSrvConf.oLogList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tLogService");
	nTbIdx1 = lua_gettop(pState);
	lua_pushnil(pState);
	while (lua_next(pState, nTbIdx1))
	{
		ServerNode oConf;
		oConf.oLog.uService = (int8_t)lua_tointeger(pState, -2);
		lua_getfield(pState, -1, "nWorkers");
		oConf.oLog.uWorkers = (uint8_t)lua_tointeger(pState, -1);
		lua_getfield(pState, -2, "nMysqlConns");
		oConf.oLog.uMysqlConns = (uint8_t)lua_tointeger(pState, -1);
		m_oSrvConf.oLogList.push_back(oConf);
		lua_pop(pState, 3);
	}

	return true;
}
